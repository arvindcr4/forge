# Forge PowerShell Plugin

A PowerShell plugin that provides intelligent command transformation, file tagging, and conversation management for the Forge AI assistant.

## Features

- **Smart Command Transformation**: Convert `:command` syntax into forge executions
- **Agent Selection**: Tab completion for available agents using `:agent_name`
- **File Tagging**: Interactive file selection with `@[filename]` syntax
- **Conversation Continuity**: Automatic session management across commands
- **Interactive Completion**: Fuzzy finding for files and agents via fzf
- **Prompt Integration**: Model, agent, and token info in prompt

## Prerequisites

- **PowerShell 7+** (pwsh) — works on Windows, macOS, Linux
- **PSReadLine** module (included with PowerShell 7+)
- **fzf** - Command-line fuzzy finder
- **fd** - Fast file finder (optional but recommended)
- **forge** - The Forge CLI tool

### Installation of Prerequisites

```powershell
# Windows (using winget)
winget install junegunn.fzf
winget install sharkdp.fd
winget install sharkdp.bat

# macOS (using Homebrew)
brew install fzf fd bat

# Linux
sudo apt install fzf fd-find bat  # Debian/Ubuntu
sudo pacman -S fzf fd bat         # Arch
```

## Installation

### Option 1: Add to $PROFILE

```powershell
# Open your profile
notepad $PROFILE

# Add these lines:
. "C:\path\to\shell-plugin-pwsh\forge.plugin.ps1"
. "C:\path\to\shell-plugin-pwsh\forge.theme.ps1"
```

### Option 2: Source directly

```powershell
. /path/to/shell-plugin-pwsh/forge.plugin.ps1
. /path/to/shell-plugin-pwsh/forge.theme.ps1
```

## Usage

### Starting a Conversation

```powershell
: Get the current time
```

### Using Specific Agents

```powershell
:sage How does caching work in this system?
:muse Create a deployment strategy for my app
```

### File Tagging

```powershell
: Review this code @[src/main.rs]
```

Press Tab after `@` for interactive file selection.

### Session Management

```powershell
:new                  # Start new conversation
:info                 # Show session info
:conversation         # List/switch conversations
:conversation -       # Toggle previous conversation
:model               # Select model for session
:config-model        # Set model in config
:commit              # AI-generated commit
:doctor              # Environment diagnostics
:clone               # Clone a conversation
:copy                # Copy last response to clipboard
:sync                # Sync workspace for search
:provider-login      # Login to a provider
```

### Aliases

| Command | Alias |
|---------|-------|
| `:new` | `:n` |
| `:info` | `:i` |
| `:conversation` | `:c` |
| `:model` | `:m` |
| `:agent` | `:a` |
| `:tools` | `:t` |
| `:retry` | `:r` |
| `:rename` | `:rn` |
| `:keyboard-shortcuts` | `:kb` |

## Configuration

```powershell
# Custom forge binary location
$env:FORGE_BIN = "C:\path\to\forge.exe"

# Editor for :edit command
$env:FORGE_EDITOR = "code"

# Enable/disable workspace sync
$env:FORGE_SYNC_ENABLED = "true"

# Max diff size for commit messages
$env:FORGE_MAX_COMMIT_DIFF = "100000"
```

## Environment Diagnostics

```powershell
:doctor
```

Checks PowerShell version, PSReadLine, forge installation, plugin loading, dependencies, and system configuration.
