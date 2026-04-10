# Forge Fish Shell Plugin

A Fish shell plugin that provides intelligent command transformation, file tagging, and conversation management for the Forge AI assistant.

## Features

- **Smart Command Transformation**: Convert `:command` syntax into forge executions
- **Agent Selection**: Tab completion for available agents using `:agent_name`
- **File Tagging**: Interactive file selection with `@[filename]` syntax
- **Conversation Continuity**: Automatic session management across commands
- **Interactive Completion**: Fuzzy finding for files and agents
- **Right Prompt**: Model, agent, and token info via `fish_right_prompt`

## Prerequisites

- **Fish** 3.0+ (uses modern Fish features)
- **fzf** - Command-line fuzzy finder
- **fd** - Fast file finder (alternative to find)
- **forge** - The Forge CLI tool

### Installation of Prerequisites

```bash
# macOS (using Homebrew)
brew install fish fzf fd

# Ubuntu/Debian
sudo apt install fish fzf fd-find

# Arch Linux
sudo pacman -S fish fzf fd
```

## Installation

### Option 1: Source directly in config.fish

Add to `~/.config/fish/config.fish`:

```fish
source /path/to/shell-plugin-fish/forge.plugin.fish
source /path/to/shell-plugin-fish/forge.theme.fish
```

### Option 2: Symlink into Fish functions

```bash
ln -s /path/to/shell-plugin-fish/conf.d/forge.fish ~/.config/fish/conf.d/forge.fish
```

### Option 3: Fisher / Oh My Fish

Copy the plugin directory into your Fish plugin path and source it from `config.fish`.

## Usage

### Starting a Conversation

```fish
: Get the current time
```

### Using Specific Agents

```fish
:sage How does caching work in this system?
:muse Create a deployment strategy for my app
```

### File Tagging

```fish
: Review this code @[src/main.rs]
```

### Session Management

```fish
:new                  # Start new conversation
:info                 # Show session info
:conversation         # List/switch conversations
:conversation -       # Toggle previous conversation (like cd -)
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

```fish
# Custom forge binary location
set -gx FORGE_BIN /path/to/custom/forge

# Editor for :edit command
set -gx FORGE_EDITOR vim

# Enable/disable workspace sync
set -gx FORGE_SYNC_ENABLED true

# Max diff size for commit messages
set -gx FORGE_MAX_COMMIT_DIFF 100000
```

## Environment Diagnostics

```fish
:doctor
```

Checks Fish version, forge installation, plugin loading, dependencies, and system configuration.
