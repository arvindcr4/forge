use std::env;
use std::ffi::OsString;
use std::fs;
use std::path::{Path, PathBuf};

use anyhow::Context;
use forge_domain::{
    McpConfig, McpDoctorFinding, McpDoctorReport, McpDoctorSeverity, McpServerConfig, MemoryEntry,
    MemoryStore, ProjectCommandCandidate, ProjectProfile,
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
                }
            }
        }

        McpDoctorReport::new(findings)
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
            config_files.push("package.json".to_string());
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
