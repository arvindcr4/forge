# Forge Workflow Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Phase 1 workflow foundation: MCP diagnostics, deterministic project scan, repo memory, and shell shortcuts.

**Architecture:** Add serializable domain models in `forge_domain`, API methods in `forge_api`, app-level implementations in `forge_app`, and CLI rendering/dispatch in `forge_main`. Keep shell integrations as thin wrappers around new CLI commands.

**Tech Stack:** Rust 2024, clap, serde, anyhow, tokio, existing Forge service/API/CLI crates, zsh/fish/PowerShell shell plugin scripts.

---

### Task 1: Domain Models

**Files:**
- Create: `crates/forge_domain/src/workflow_foundation.rs`
- Modify: `crates/forge_domain/src/lib.rs`

- [ ] Add `McpDoctorSeverity`, `McpDoctorFinding`, `McpDoctorReport`, `ProjectProfile`, `ProjectCommandCandidate`, `MemoryEntry`, and `MemoryStore`.
- [ ] Add constructors/helpers needed by tests and CLI rendering.
- [ ] Re-export the module from `forge_domain::lib`.
- [ ] Add same-file unit tests for memory add/remove behavior and MCP report error detection.
- [ ] Run `cargo test -p forge_domain workflow_foundation`.
- [ ] Commit with `feat(domain): add workflow foundation models`.

### Task 2: App Services

**Files:**
- Create: `crates/forge_app/src/workflow_foundation.rs`
- Modify: `crates/forge_app/src/lib.rs`
- Modify: `crates/forge_app/src/services.rs`

- [ ] Add `McpDoctorService` that validates a `McpConfig` for command presence, env presence, empty env values, disabled servers, and malformed HTTP URLs.
- [ ] Add `ProjectScanService` that inspects a workspace path for `Cargo.toml`, `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `package.json`, `.git`, and common command candidates.
- [ ] Add `MemoryService` that reads/writes `memory.json` atomically under a workspace data directory.
- [ ] Use deterministic data only; do not call an LLM.
- [ ] Add unit tests with temp directories for MCP doctor, Rust/Node project scan, and memory add/list/remove.
- [ ] Run `cargo test -p forge_app workflow_foundation`.
- [ ] Commit with `feat(app): add workflow foundation services`.

### Task 3: API Methods

**Files:**
- Modify: `crates/forge_api/src/api.rs`
- Modify: `crates/forge_api/src/forge_api.rs`

- [ ] Add API methods for `mcp_doctor`, `scan_project`, `read_project_profile`, `add_memory`, `list_memory`, `remove_memory`, and `clear_memory`.
- [ ] Delegate to app services through the existing service/repository stack.
- [ ] Keep signatures simple and serializable for later TUI use.
- [ ] Run `cargo check -p forge_api`.
- [ ] Commit with `feat(api): expose workflow foundation operations`.

### Task 4: CLI Parsing

**Files:**
- Modify: `crates/forge_main/src/cli.rs`

- [ ] Add `McpCommand::Doctor(McpDoctorArgs)` with `--json`, `--strict`, and `--network`.
- [ ] Add top-level `Project(ProjectCommandGroup)` with `project scan --print --refresh --json`.
- [ ] Add top-level `Memory(MemoryCommandGroup)` with `add`, `list`, `remove`, and `clear`.
- [ ] Add parser tests for the new commands.
- [ ] Run `cargo test -p forge_main cli`.
- [ ] Commit with `feat(cli): parse workflow foundation commands`.

### Task 5: CLI Dispatch and Rendering

**Files:**
- Modify: `crates/forge_main/src/ui.rs`

- [ ] Dispatch `forge mcp doctor` and render human-readable or JSON output.
- [ ] Dispatch `forge project scan` and support print/write behavior.
- [ ] Dispatch `forge memory` subcommands and render text or JSON output.
- [ ] Make `--strict` return an error when the doctor report has warnings or errors.
- [ ] Add focused rendering tests where existing test seams allow it.
- [ ] Run `cargo check -p forge_main`.
- [ ] Commit with `feat(main): handle workflow foundation commands`.

### Task 6: Shell Shortcuts

**Files:**
- Modify zsh plugin files under `shell-plugin/`
- Modify fish plugin files under `shell-plugin-fish/`
- Modify PowerShell plugin files under `shell-plugin-pwsh/`
- Modify generated shell includes in `crates/forge_main/src/shell_plugin.rs` only if new files are introduced.

- [ ] Add `:mcp doctor`, `:scan`, `:memory`, and `:memory add <text>` shortcuts for zsh.
- [ ] Add the same shortcuts for fish.
- [ ] Add the same shortcuts for PowerShell.
- [ ] Add or update shell plugin smoke tests.
- [ ] Run available shell plugin test scripts.
- [ ] Commit with `feat(shell): add workflow foundation shortcuts`.

### Task 7: Final Verification

**Files:**
- Modify: none unless verification exposes defects.

- [ ] Run `cargo fmt`.
- [ ] Run `cargo check`.
- [ ] Run targeted tests for changed crates.
- [ ] Run shell plugin smoke tests.
- [ ] Run `git status --short` and ensure only intended files changed.
- [ ] Commit any verification fixes.
