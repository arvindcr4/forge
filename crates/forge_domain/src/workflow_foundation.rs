use chrono::{DateTime, Utc};
use derive_setters::Setters;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Severity for a workflow foundation diagnostic finding.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum McpDoctorSeverity {
    Info,
    Warning,
    Error,
}

/// A single MCP doctor diagnostic finding.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, Setters)]
#[serde(rename_all = "camelCase")]
#[setters(strip_option, into)]
pub struct McpDoctorFinding {
    pub server: String,
    pub severity: McpDoctorSeverity,
    pub message: String,
}

impl McpDoctorFinding {
    /// Creates a diagnostic finding for a server.
    ///
    /// # Arguments
    /// * `server` - The configured MCP server name.
    /// * `severity` - The diagnostic severity.
    /// * `message` - Human-readable diagnostic text.
    pub fn new(
        server: impl Into<String>,
        severity: McpDoctorSeverity,
        message: impl Into<String>,
    ) -> Self {
        Self { server: server.into(), severity, message: message.into() }
    }
}

/// MCP doctor diagnostic report.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct McpDoctorReport {
    pub findings: Vec<McpDoctorFinding>,
}

impl McpDoctorReport {
    /// Creates a report from diagnostic findings.
    ///
    /// # Arguments
    /// * `findings` - Diagnostic findings to include in the report.
    pub fn new(findings: Vec<McpDoctorFinding>) -> Self {
        Self { findings }
    }

    /// Returns true when any finding is an error.
    pub fn has_errors(&self) -> bool {
        self.findings
            .iter()
            .any(|finding| finding.severity == McpDoctorSeverity::Error)
    }

    /// Returns true when any finding is a warning or error.
    pub fn has_warnings_or_errors(&self) -> bool {
        self.findings.iter().any(|finding| {
            matches!(
                finding.severity,
                McpDoctorSeverity::Warning | McpDoctorSeverity::Error
            )
        })
    }
}

/// Candidate command detected for a project workflow.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, Setters)]
#[serde(rename_all = "camelCase")]
#[setters(strip_option, into)]
pub struct ProjectCommandCandidate {
    pub kind: String,
    pub command: String,
    pub source: String,
}

impl ProjectCommandCandidate {
    /// Creates a project command candidate.
    ///
    /// # Arguments
    /// * `kind` - Command purpose, such as `test` or `build`.
    /// * `command` - Shell command to run.
    /// * `source` - File or signal that produced the candidate.
    pub fn new(
        kind: impl Into<String>,
        command: impl Into<String>,
        source: impl Into<String>,
    ) -> Self {
        Self { kind: kind.into(), command: command.into(), source: source.into() }
    }
}

/// Deterministic project profile detected from a workspace.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize, Setters)]
#[serde(rename_all = "camelCase")]
#[setters(strip_option, into)]
pub struct ProjectProfile {
    pub root: String,
    pub languages: Vec<String>,
    pub package_managers: Vec<String>,
    pub commands: Vec<ProjectCommandCandidate>,
    pub config_files: Vec<String>,
    pub default_branch: Option<String>,
    pub mcp_servers: Vec<String>,
}

/// A repo-scoped memory note.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, Setters)]
#[serde(rename_all = "camelCase")]
#[setters(strip_option, into)]
pub struct MemoryEntry {
    pub id: String,
    pub text: String,
    pub created_at: DateTime<Utc>,
    #[serde(default)]
    pub tags: Vec<String>,
}

impl MemoryEntry {
    /// Creates a memory entry with a generated ID and current timestamp.
    ///
    /// # Arguments
    /// * `text` - Memory text to persist.
    pub fn new(text: impl Into<String>) -> Self {
        Self {
            id: format!("mem_{}", Uuid::new_v4().simple()),
            text: text.into(),
            created_at: Utc::now(),
            tags: Vec::new(),
        }
    }
}

/// Collection of repo-scoped memory notes.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MemoryStore {
    pub entries: Vec<MemoryEntry>,
}

impl MemoryStore {
    /// Adds a memory entry and returns the updated store.
    ///
    /// # Arguments
    /// * `entry` - Entry to append.
    pub fn add(mut self, entry: MemoryEntry) -> Self {
        self.entries.push(entry);
        self
    }

    /// Removes a memory entry by ID and returns the updated store and result.
    ///
    /// # Arguments
    /// * `id` - Entry ID to remove.
    pub fn remove(mut self, id: &str) -> (Self, bool) {
        let before = self.entries.len();
        self.entries.retain(|entry| entry.id != id);
        let removed = self.entries.len() != before;
        (self, removed)
    }
}

#[cfg(test)]
mod tests {
    use pretty_assertions::assert_eq;

    use super::*;

    #[test]
    fn report_has_error_when_any_finding_is_error() {
        let fixture = McpDoctorReport::new(vec![McpDoctorFinding::new(
            "broken",
            McpDoctorSeverity::Error,
            "command missing",
        )]);

        let actual = fixture.has_errors();
        let expected = true;

        assert_eq!(actual, expected);
    }

    #[test]
    fn memory_store_removes_entry_by_id() {
        let entry = MemoryEntry::new("Use cargo check before commits").id("mem_1");
        let fixture = MemoryStore::default().add(entry);

        let actual = fixture.remove("mem_1");
        let expected = (MemoryStore::default(), true);

        assert_eq!(actual, expected);
    }
}
