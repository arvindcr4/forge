# Forge CMD Plugin

A Windows CMD (batch) plugin that provides basic command routing for the Forge AI assistant.

> **Note**: CMD has significant limitations compared to PowerShell, Fish, or ZSH. For the full feature set (tab completion, fuzzy finding, syntax highlighting, prompt customization), use PowerShell (pwsh) instead.

## Features

- **Command Routing**: `:command` syntax dispatched to forge CLI
- **Conversation Management**: Basic session tracking via environment variables
- **DOSKEY Macros**: Quick aliases for common commands
- **Environment Diagnostics**: `:doctor` command

## Limitations (compared to pwsh/fish/zsh)

- No tab completion for commands or files
- No syntax highlighting
- No fuzzy finder integration (fzf not used interactively)
- No prompt customization (no right-prompt)
- No background jobs for sync/update
- Limited argument parsing

## Prerequisites

- **Windows** with CMD
- **forge** - The Forge CLI tool in PATH

## Installation

### Option 1: Run setup script per session

```cmd
path\to\shell-plugin-cmd\forge-setup.cmd
```

This registers DOSKEY macros for the current CMD session.

### Option 2: Auto-load via Registry

To load macros automatically when CMD starts, set the AutoRun registry key:

```cmd
reg add "HKCU\Software\Microsoft\Command Processor" /v AutoRun /d "path\to\shell-plugin-cmd\forge-setup.cmd" /f
```

### Option 3: Use forge.cmd directly

```cmd
path\to\forge.cmd :new Hello world
path\to\forge.cmd :info
path\to\forge.cmd :commit
```

## Usage

After running `forge-setup.cmd`, use DOSKEY macros:

```cmd
:new Hello world
:info
:conversation
:conversation -
:model
:commit
:doctor
:agent sage
: What is the meaning of life?
```

### Available Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `:new` | `:n` | Start new conversation |
| `:info` | `:i` | Show session info |
| `:env` | `:e` | Show environment info |
| `:conversation` | `:c` | List/switch conversations |
| `:model` | `:m` | List available models |
| `:agent` | `:a` | Switch agent |
| `:tools` | `:t` | Show available tools |
| `:commit` | | AI-generated commit |
| `:clone` | | Clone conversation |
| `:copy` | | Copy last response to clipboard |
| `:sync` | | Sync workspace |
| `:login` | | Login to provider |
| `:logout` | | Logout from provider |
| `:doctor` | | Environment diagnostics |
| `:retry` | `:r` | Retry last message |
| `:rename` | `:rn` | Rename conversation |
| `:keyboard-shortcuts` | `:kb` | Show keyboard shortcuts |

## Configuration

Set environment variables before running:

```cmd
set FORGE_BIN=C:\path\to\forge.exe
set FORGE_MAX_COMMIT_DIFF=100000
set FORGE_EDITOR=notepad
```

## Environment Diagnostics

```cmd
:doctor
:: or
forge-doctor.cmd
```

Checks forge installation, dependencies (fzf, fd, git), and editor configuration.
