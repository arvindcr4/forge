# Forge Workflow Foundation Design

## Summary

Phase 1 adds workflow foundation features that make Forge more useful before any advanced agent orchestration is built. The scope is limited to three user-facing command groups and matching shell shortcuts:

- `forge mcp doctor` diagnoses configured MCP servers.
- `forge project scan` creates a compact project profile.
- `forge memory` manages persistent repo notes.
- zsh, fish, and PowerShell plugins expose shortcuts for the new workflows.

This phase deliberately excludes plugin marketplace support, multi-agent worktrees, PR automation, time-travel conversations, eval orchestration, TUI settings screens, and dependency-aware semantic search. Those features should build on the data and command surfaces introduced here.

## Goals

- Give users immediate diagnostics for common MCP setup failures.
- Let Forge learn and reuse basic project facts without re-discovering them each session.
- Provide an explicit memory surface for repo-specific conventions and decisions.
- Keep all features available from the CLI first, with shell plugin shortcuts as thin wrappers.
- Add small, well-bounded domain types and services that later phases can reuse.

## Non-Goals

- No automatic editing of MCP config in Phase 1. Doctor can recommend commands and config changes, but it does not mutate config.
- No AI-generated project profiles. The first version uses deterministic filesystem and config inspection.
- No background daemon or file watcher.
- No cross-device sync.
- No marketplace registry or remote plugin download.
- No TUI-only behavior. The CLI remains the source of truth.

## User Experience

### MCP Doctor

`forge mcp doctor` reads the effective MCP configuration through the existing MCP config API and emits a diagnostic report.

It checks:

- command existence for stdio servers
- missing command arguments
- missing configured environment variables
- empty configured environment variables
- malformed HTTP/SSE URLs
- unreachable HTTP/SSE endpoints when a network check is requested
- duplicate server names after scope merge
- OAuth-authenticated servers that are not logged in when status is available

Default output is human-readable. `--json` produces a stable machine-readable report. `--strict` exits non-zero when any warning or error is found. Without `--strict`, only fatal internal failures exit non-zero.

### Project Scan

`forge project scan` inspects the current workspace and writes a project profile. The command is deterministic and safe to run repeatedly.

The initial profile includes:

- detected languages and package managers
- candidate test, lint, format, build, and dev commands
- repo root and git default branch when available
- important config files
- shell plugin availability for the current shell
- MCP server names visible to this workspace

`forge project scan --print` prints the detected profile without writing it. `forge project scan --refresh` overwrites the stored profile.

### Memory

`forge memory` provides explicit repo-scoped notes. The initial commands are:

- `forge memory add <text>`
- `forge memory list`
- `forge memory remove <id>`
- `forge memory clear`

Memory entries include an ID, text, created timestamp, and optional tags. The first version supports `--tag <tag>` on `add` and `--json` on `list`.

Agent prompt integration is limited to reading the current repo memory and appending a compact memory section to the system context. If the memory file is missing or malformed, Forge reports a warning and continues without memory.

### Shell Shortcuts

Shell plugins remain wrappers around CLI behavior:

- `:mcp doctor` runs `forge mcp doctor`
- `:scan` runs `forge project scan`
- `:memory add <text>` runs `forge memory add <text>`
- `:memory` runs `forge memory list`

The shortcuts must be implemented for zsh, fish, and PowerShell. They do not duplicate business logic.

## Architecture

### Domain Types

Add domain models in `forge_domain`:

- `McpDoctorReport`
- `McpDoctorFinding`
- `McpDoctorSeverity`
- `ProjectProfile`
- `ProjectCommandCandidate`
- `ProjectProfileSource`
- `MemoryEntry`
- `MemoryStore`

Domain types are serializable, testable, and independent of filesystem or process execution.

### API Surface

Extend `forge_api::ForgeAPI` with:

- `mcp_doctor(options) -> Result<McpDoctorReport>`
- `scan_project(options) -> Result<ProjectProfile>`
- `read_project_profile() -> Result<Option<ProjectProfile>>`
- `add_memory(entry) -> Result<MemoryEntry>`
- `list_memory() -> Result<Vec<MemoryEntry>>`
- `remove_memory(id) -> Result<bool>`
- `clear_memory() -> Result<()>`

These methods keep CLI code thin and make the behavior reusable by the TUI or later recipes.

### App Services

Add services in `forge_app`:

- `McpDoctorService`
- `ProjectScanService`
- `MemoryService`

Services should follow the repository's existing service rules: no service-to-service dependencies, at most one infrastructure generic parameter, and infrastructure dependencies behind existing traits or small new traits where needed.

### Storage

Project profile and memory are stored under Forge's existing workspace-aware storage conventions. The implementation should avoid writing into the application source tree unless the user explicitly sets a local project configuration path.

Suggested logical filenames:

- `project-profile.json`
- `memory.json`

The exact physical path should reuse the existing environment/config repository paths rather than inventing a new home directory layout.

### CLI

Extend `crates/forge_main/src/cli.rs` using singular command names, matching the repository note:

- `Mcp(McpCommandGroup)` gains `Doctor(McpDoctorArgs)`.
- Add top-level `Project(ProjectCommandGroup)` with `Scan(ProjectScanArgs)`.
- Add top-level `Memory(MemoryCommandGroup)`.

Command handlers should live near existing command dispatch code in `forge_main` and delegate to `ForgeAPI`.

## Data Flow

`forge mcp doctor`:

1. CLI parses options.
2. Handler calls `ForgeAPI::mcp_doctor`.
3. Service reads effective MCP config.
4. Service validates config, commands, env vars, and optional network status.
5. Handler renders text or JSON.

`forge project scan`:

1. CLI parses options.
2. Handler calls `ForgeAPI::scan_project`.
3. Service inspects filesystem and git metadata.
4. Service detects commands and config files.
5. Service writes or prints the profile.

`forge memory`:

1. CLI parses subcommand.
2. Handler calls the relevant memory API method.
3. Service reads and writes the repo-scoped memory store atomically.
4. Handler renders text or JSON.

## Error Handling

- Use `anyhow::Result` in services and command handlers.
- Use domain errors only when callers need structured behavior.
- MCP doctor findings are report data, not process failures.
- Malformed stored profile or memory should produce a warning and continue where possible.
- Writes should be atomic: write temp file, then rename.

## Testing

Add tests in the same files as the implementation where possible.

Required tests:

- MCP doctor reports missing command as an error.
- MCP doctor reports empty required env vars as an error.
- MCP doctor accepts a valid stdio server with an executable command.
- Project scan detects Rust workspace from `Cargo.toml`.
- Project scan detects Node package manager from `package-lock.json`.
- Memory add/list/remove preserves IDs and timestamps.
- Malformed memory storage does not crash command rendering.
- Shell plugin shortcuts dispatch to the expected Forge commands for zsh, fish, and PowerShell.

Verification commands:

- `cargo fmt`
- `cargo check`
- targeted `cargo test` for changed crates
- existing shell plugin smoke tests for zsh/fish/pwsh where available

## Acceptance Criteria

- `forge mcp doctor` works with human-readable and JSON output.
- `forge project scan --print` prints a profile without writing.
- `forge project scan --refresh` writes a workspace profile.
- `forge memory add/list/remove/clear` work in a git workspace.
- zsh, fish, and PowerShell shortcuts call the new CLI commands.
- Existing MCP, provider, conversation, and shell setup commands continue to work.
- The implementation does not introduce background processes or implicit config mutation.
