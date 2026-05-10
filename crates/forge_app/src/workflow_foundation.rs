use std::env;
use std::ffi::OsString;
use std::fs;
use std::path::{Path, PathBuf};
use std::time::Duration;

use anyhow::Context;
use forge_domain::{
    McpConfig, McpDoctorFinding, McpDoctorReport, McpDoctorSeverity, McpOAuthSetting,
    McpServerConfig, MemoryEntry, MemoryStore, ProjectCommandCandidate, ProjectProfile,
};

/// Diagnoses MCP server configuration without mutating it.
pub struct McpDoctorService;

impl McpDoctorService {
    /// Creates an MCP doctor service.
    pub fn new() -> Self {
        Self
    }

    /// Checks an MCP config and returns diagnostic findings.
    ///
    /// # Arguments
    /// * `config` - Effective MCP configuration to validate.
    pub fn check_config(&self, config: &McpConfig) -> McpDoctorReport {
        let mut findings = Vec::new();

        for (name, server) in &config.mcp_servers {
            match server {
                McpServerConfig::Stdio(stdio) => {
                    if stdio.disable {
                        findings.push(McpDoctorFinding::new(
                            name.to_string(),
                            McpDoctorSeverity::Info,
                            "server is disabled",
                        ));
                        continue;
                    }

                    if stdio.command.trim().is_empty() {
                        findings.push(McpDoctorFinding::new(
                            name.to_string(),
                            McpDoctorSeverity::Error,
                            "stdio command is empty",
                        ));
                    } else if !command_exists(&stdio.command) {
                        findings.push(McpDoctorFinding::new(
                            name.to_string(),
                            McpDoctorSeverity::Error,
                            format!("command not found: {}", stdio.command),
                        ));
                    }

                    for (key, value) in &stdio.env {
                        if value.trim().is_empty() {
                            findings.push(McpDoctorFinding::new(
                                name.to_string(),
                                McpDoctorSeverity::Error,
                                format!("environment variable {key} is empty"),
                            ));
                        }
                    }
                }
                McpServerConfig::Http(http) => {
                    if http.disable {
                        findings.push(McpDoctorFinding::new(
                            name.to_string(),
                            McpDoctorSeverity::Info,
                            "server is disabled",
                        ));
                        continue;
                    }

                    if url::Url::parse(&http.url).is_err() {
                        findings.push(McpDoctorFinding::new(
                            name.to_string(),
                            McpDoctorSeverity::Error,
                            format!("invalid url: {}", http.url),
                        ));
                    }

                    if let McpOAuthSetting::Configured(oauth) = &http.oauth {
                        for (label, value) in [
                            ("auth_url", oauth.auth_url.as_ref()),
                            ("token_url", oauth.token_url.as_ref()),
                            ("redirect_uri", oauth.redirect_uri.as_ref()),
                        ] {
                            if let Some(value) = value
                                && url::Url::parse(value).is_err()
                            {
                                findings.push(McpDoctorFinding::new(
                                    name.to_string(),
                                    McpDoctorSeverity::Error,
                                    format!("invalid OAuth {label}: {value}"),
                                ));
                            }
                        }
                    }
                }
            }
        }

        McpDoctorReport::new(findings)
    }

    /// Checks an MCP config and performs HTTP reachability checks.
    ///
    /// # Arguments
    /// * `config` - Effective MCP configuration to validate.
    ///
    /// # Errors
    /// Returns an error when the HTTP client cannot be constructed.
    pub async fn check_config_with_network(
        &self,
        config: &McpConfig,
    ) -> anyhow::Result<McpDoctorReport> {
        let mut findings = self.check_config(config).findings;
        let client = reqwest::Client::builder()
            .timeout(Duration::from_secs(5))
            .redirect(reqwest::redirect::Policy::limited(3))
            .build()
            .context("failed to build MCP doctor HTTP client")?;

        for (name, server) in &config.mcp_servers {
            let McpServerConfig::Http(http) = server else {
                continue;
            };
            if http.disable || url::Url::parse(&http.url).is_err() {
                continue;
            }

            match client.get(&http.url).send().await {
                Ok(response)
                    if response.status().is_success() || response.status().is_redirection() =>
                {
                    findings.push(McpDoctorFinding::new(
                        name.to_string(),
                        McpDoctorSeverity::Info,
                        "network reachable",
                    ));
                }
                Ok(response)
                    if response.status().as_u16() == 401 || response.status().as_u16() == 403 =>
                {
                    findings.push(McpDoctorFinding::new(
                        name.to_string(),
                        McpDoctorSeverity::Warning,
                        format!(
                            "network reachable but authentication returned {}",
                            response.status()
                        ),
                    ));
                }
                Ok(response) => {
                    findings.push(McpDoctorFinding::new(
                        name.to_string(),
                        McpDoctorSeverity::Warning,
                        format!("network returned {}", response.status()),
                    ));
                }
                Err(error) => {
                    findings.push(McpDoctorFinding::new(
                        name.to_string(),
                        McpDoctorSeverity::Warning,
                        format!("network unreachable: {error}"),
                    ));
                }
            }
        }

        Ok(McpDoctorReport::new(findings))
    }
}

impl Default for McpDoctorService {
    fn default() -> Self {
        Self::new()
    }
}

/// Scans a workspace and creates a deterministic project profile.
pub struct ProjectScanService;

impl ProjectScanService {
    /// Creates a project scan service.
    pub fn new() -> Self {
        Self
    }

    /// Scans a workspace path.
    ///
    /// # Arguments
    /// * `root` - Workspace root to scan.
    /// * `mcp_servers` - Effective MCP server names visible to the workspace.
    pub fn scan(&self, root: &Path, mcp_servers: Vec<String>) -> anyhow::Result<ProjectProfile> {
        let mut languages = Vec::new();
        let mut package_managers = Vec::new();
        let mut commands = Vec::new();
        let mut config_files = Vec::new();

        if root.join("Cargo.toml").exists() {
            languages.push("Rust".to_string());
            package_managers.push("cargo".to_string());
            config_files.push("Cargo.toml".to_string());
            commands.extend([
                ProjectCommandCandidate::new("check", "cargo check", "Cargo.toml"),
                ProjectCommandCandidate::new("test", "cargo test", "Cargo.toml"),
                ProjectCommandCandidate::new("format", "cargo fmt", "Cargo.toml"),
            ]);
        }

        if root.join("package-lock.json").exists() {
            languages.push("JavaScript".to_string());
            package_managers.push("npm".to_string());
            config_files.push("package-lock.json".to_string());
            commands.extend([
                ProjectCommandCandidate::new("test", "npm test", "package-lock.json"),
                ProjectCommandCandidate::new("build", "npm run build", "package-lock.json"),
            ]);
        }

        if root.join("pnpm-lock.yaml").exists() {
            push_unique(&mut languages, "JavaScript");
            package_managers.push("pnpm".to_string());
            config_files.push("pnpm-lock.yaml".to_string());
        }

        if root.join("yarn.lock").exists() {
            push_unique(&mut languages, "JavaScript");
            package_managers.push("yarn".to_string());
            config_files.push("yarn.lock".to_string());
        }

        if root.join("package.json").exists() {
            push_unique(&mut languages, "JavaScript");
            if package_managers.is_empty() {
                package_managers.push("npm".to_string());
            }
            config_files.push("package.json".to_string());
            commands.extend(read_package_json_scripts(
                root,
                preferred_node_runner(&package_managers),
            ));
        }

        let default_branch = detect_default_branch(root);

        Ok(ProjectProfile {
            root: root.display().to_string(),
            languages,
            package_managers,
            commands,
            config_files,
            default_branch,
            mcp_servers,
        })
    }

    /// Reads a stored project profile.
    ///
    /// # Arguments
    /// * `root` - Workspace root.
    pub fn read_profile(&self, root: &Path) -> anyhow::Result<Option<ProjectProfile>> {
        let path = project_profile_path(root);
        if !path.exists() {
            return Ok(None);
        }

        let content = fs::read_to_string(&path)
            .with_context(|| format!("failed to read project profile {}", path.display()))?;
        let profile = serde_json::from_str(&content)
            .with_context(|| format!("failed to parse project profile {}", path.display()))?;
        Ok(Some(profile))
    }

    /// Writes a project profile atomically.
    ///
    /// # Arguments
    /// * `root` - Workspace root.
    /// * `profile` - Profile to persist.
    pub fn write_profile(&self, root: &Path, profile: &ProjectProfile) -> anyhow::Result<()> {
        let path = project_profile_path(root);
        let parent = path
            .parent()
            .context("project profile path should always have parent directory")?;
        fs::create_dir_all(parent)
            .with_context(|| format!("failed to create {}", parent.display()))?;
        let tmp_path = path.with_extension("json.tmp");
        let content = serde_json::to_string_pretty(profile)?;
        fs::write(&tmp_path, content)
            .with_context(|| format!("failed to write {}", tmp_path.display()))?;
        fs::rename(&tmp_path, &path)
            .with_context(|| format!("failed to move project profile to {}", path.display()))?;
        Ok(())
    }
}

impl Default for ProjectScanService {
    fn default() -> Self {
        Self::new()
    }
}

/// Manages repo-scoped workflow memory.
pub struct MemoryService {
    root: PathBuf,
}

impl MemoryService {
    /// Creates a memory service rooted at a workspace path.
    ///
    /// # Arguments
    /// * `root` - Workspace root.
    pub fn new(root: impl Into<PathBuf>) -> Self {
        Self { root: root.into() }
    }

    /// Adds a memory entry.
    ///
    /// # Arguments
    /// * `text` - Memory text.
    /// * `tags` - Optional memory tags.
    pub fn add(&self, text: impl Into<String>, tags: Vec<String>) -> anyhow::Result<MemoryEntry> {
        let mut store = self.read_store()?;
        let entry = MemoryEntry::new(text).tags(tags);
        store.entries.push(entry.clone());
        self.write_store(&store)?;
        Ok(entry)
    }

    /// Lists all memory entries.
    pub fn list(&self) -> anyhow::Result<Vec<MemoryEntry>> {
        Ok(self.read_store()?.entries)
    }

    /// Removes a memory entry by ID.
    ///
    /// # Arguments
    /// * `id` - Entry ID to remove.
    pub fn remove(&self, id: &str) -> anyhow::Result<bool> {
        let store = self.read_store()?;
        let (store, removed) = store.remove(id);
        self.write_store(&store)?;
        Ok(removed)
    }

    /// Clears all memory entries.
    pub fn clear(&self) -> anyhow::Result<()> {
        self.write_store(&MemoryStore::default())
    }

    fn memory_path(&self) -> PathBuf {
        self.root.join(".forge").join("memory.json")
    }

    fn read_store(&self) -> anyhow::Result<MemoryStore> {
        let path = self.memory_path();
        if !path.exists() {
            return Ok(MemoryStore::default());
        }

        let content = fs::read_to_string(&path)
            .with_context(|| format!("failed to read memory store {}", path.display()))?;
        serde_json::from_str(&content)
            .with_context(|| format!("failed to parse memory store {}", path.display()))
    }

    fn write_store(&self, store: &MemoryStore) -> anyhow::Result<()> {
        let path = self.memory_path();
        let parent = path
            .parent()
            .context("memory path should always have parent directory")?;
        fs::create_dir_all(parent)
            .with_context(|| format!("failed to create {}", parent.display()))?;

        let tmp_path = path.with_extension("json.tmp");
        let content = serde_json::to_string_pretty(store)?;
        fs::write(&tmp_path, content)
            .with_context(|| format!("failed to write {}", tmp_path.display()))?;
        fs::rename(&tmp_path, &path)
            .with_context(|| format!("failed to move memory store to {}", path.display()))?;
        Ok(())
    }
}

fn command_exists(command: &str) -> bool {
    let path = Path::new(command);
    if path.components().count() > 1 {
        return path.exists();
    }

    env::split_paths(&env::var_os("PATH").unwrap_or_else(OsString::new))
        .any(|dir| dir.join(command).exists())
}

fn push_unique(values: &mut Vec<String>, value: &str) {
    if !values.iter().any(|existing| existing == value) {
        values.push(value.to_string());
    }
}

fn detect_default_branch(root: &Path) -> Option<String> {
    let head = fs::read_to_string(root.join(".git").join("HEAD")).ok()?;
    head.strip_prefix("ref: refs/heads/")
        .map(str::trim)
        .map(ToString::to_string)
}

fn project_profile_path(root: &Path) -> PathBuf {
    root.join(".forge").join("project-profile.json")
}

fn preferred_node_runner(package_managers: &[String]) -> &'static str {
    if package_managers.iter().any(|manager| manager == "pnpm") {
        "pnpm"
    } else if package_managers.iter().any(|manager| manager == "yarn") {
        "yarn"
    } else {
        "npm"
    }
}

fn read_package_json_scripts(root: &Path, runner: &str) -> Vec<ProjectCommandCandidate> {
    let Ok(content) = fs::read_to_string(root.join("package.json")) else {
        return Vec::new();
    };
    let Ok(package) = serde_json::from_str::<serde_json::Value>(&content) else {
        return Vec::new();
    };
    let Some(scripts) = package.get("scripts").and_then(|value| value.as_object()) else {
        return Vec::new();
    };

    let mut commands = scripts
        .keys()
        .filter(|script| {
            matches!(
                script.as_str(),
                "build" | "check" | "format" | "lint" | "test"
            )
        })
        .map(|script| {
            ProjectCommandCandidate::new(
                script.as_str(),
                format!("{runner} run {script}"),
                "package.json",
            )
        })
        .collect::<Vec<_>>();
    commands.sort_by_key(|command| script_priority(&command.kind));
    commands
}

fn script_priority(kind: &str) -> usize {
    match kind {
        "build" => 0,
        "test" => 1,
        "check" => 2,
        "lint" => 3,
        "format" => 4,
        _ => usize::MAX,
    }
}

#[cfg(test)]
mod tests {
    use std::collections::BTreeMap;

    use forge_domain::{McpConfig, McpServerConfig, McpStdioServer, ServerName};
    use pretty_assertions::assert_eq;

    use super::*;

    #[test]
    fn mcp_doctor_reports_missing_command_as_error() {
        let fixture = McpConfig::from(BTreeMap::from([(
            ServerName::from("broken".to_string()),
            McpServerConfig::Stdio(McpStdioServer {
                command: "missing-forge-test-command".to_string(),
                ..Default::default()
            }),
        )]));

        let actual = McpDoctorService::new().check_config(&fixture);

        assert_eq!(actual.has_errors(), true);
    }

    #[tokio::test]
    async fn mcp_doctor_network_reports_reachable_http_server() {
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();
        let handle = tokio::spawn(async move {
            let (mut socket, _) = listener.accept().await.unwrap();
            tokio::io::AsyncWriteExt::write_all(
                &mut socket,
                b"HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n",
            )
            .await
            .unwrap();
        });
        let fixture = McpConfig::from(BTreeMap::from([(
            ServerName::from("reachable".to_string()),
            McpServerConfig::new_http(format!("http://{addr}/mcp")),
        )]));

        let actual = McpDoctorService::new()
            .check_config_with_network(&fixture)
            .await
            .unwrap();
        handle.await.unwrap();
        let expected = McpDoctorReport::new(vec![McpDoctorFinding::new(
            "reachable",
            McpDoctorSeverity::Info,
            "network reachable",
        )]);

        assert_eq!(actual, expected);
    }

    #[tokio::test]
    async fn mcp_doctor_network_reports_unreachable_http_server() {
        let fixture = McpConfig::from(BTreeMap::from([(
            ServerName::from("unreachable".to_string()),
            McpServerConfig::new_http("http://127.0.0.1:9/mcp"),
        )]));

        let actual = McpDoctorService::new()
            .check_config_with_network(&fixture)
            .await
            .unwrap();

        assert_eq!(actual.has_warnings_or_errors(), true);
    }

    #[test]
    fn project_scan_detects_rust_and_node_project() {
        let temp = tempfile::tempdir().unwrap();
        std::fs::write(temp.path().join("Cargo.toml"), "[workspace]\n").unwrap();
        std::fs::write(temp.path().join("package-lock.json"), "{}\n").unwrap();

        let actual = ProjectScanService::new()
            .scan(temp.path(), Vec::new())
            .unwrap();

        assert_eq!(
            actual.languages,
            vec!["Rust".to_string(), "JavaScript".to_string()]
        );
        assert_eq!(
            actual.package_managers,
            vec!["cargo".to_string(), "npm".to_string()]
        );
    }

    #[test]
    fn project_scan_detects_package_json_scripts() {
        let temp = tempfile::tempdir().unwrap();
        std::fs::write(
            temp.path().join("package.json"),
            r#"{"scripts":{"build":"vite build","test":"vitest","lint":"eslint ."}}"#,
        )
        .unwrap();

        let actual = ProjectScanService::new()
            .scan(temp.path(), Vec::new())
            .unwrap();
        let expected = vec![
            ProjectCommandCandidate::new("build", "npm run build", "package.json"),
            ProjectCommandCandidate::new("test", "npm run test", "package.json"),
            ProjectCommandCandidate::new("lint", "npm run lint", "package.json"),
        ];

        assert_eq!(actual.commands, expected);
    }

    #[test]
    fn project_scan_writes_and_reads_profile() {
        let temp = tempfile::tempdir().unwrap();
        let fixture = ProjectScanService::new();
        let profile = ProjectProfile {
            root: temp.path().display().to_string(),
            languages: vec!["Rust".to_string()],
            ..Default::default()
        };

        fixture.write_profile(temp.path(), &profile).unwrap();
        let actual = fixture.read_profile(temp.path()).unwrap();
        let expected = Some(profile);

        assert_eq!(actual, expected);
    }

    #[test]
    fn memory_service_adds_lists_and_removes_entries() {
        let temp = tempfile::tempdir().unwrap();
        let fixture = MemoryService::new(temp.path());

        let entry = fixture
            .add("Use cargo check", vec!["workflow".to_string()])
            .unwrap();
        let after_add = fixture.list().unwrap();
        let removed = fixture.remove(&entry.id).unwrap();
        let after_remove = fixture.list().unwrap();

        assert_eq!(after_add.len(), 1);
        assert_eq!(removed, true);
        assert_eq!(after_remove.len(), 0);
    }
}
