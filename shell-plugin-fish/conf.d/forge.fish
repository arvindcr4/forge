#!/usr/bin/env fish

# Configuration variables for forge plugin

# Forge binary path
set -g _FORGE_BIN (command -v forge 2>/dev/null; or echo "forge")
if set -q FORGE_BIN
    set -g _FORGE_BIN $FORGE_BIN
end

# Conversation pattern
set -g _FORGE_CONVERSATION_PATTERN ":"

# Max commit diff size
set -g _FORGE_MAX_COMMIT_DIFF 100000
if set -q FORGE_MAX_COMMIT_DIFF
    set -g _FORGE_MAX_COMMIT_DIFF $FORGE_MAX_COMMIT_DIFF
end

# Detect fd command - Ubuntu/Debian use 'fdfind', others use 'fd'
if command -v fdfind >/dev/null 2>&1
    set -g _FORGE_FD_CMD fdfind
else if command -v fd >/dev/null 2>&1
    set -g _FORGE_FD_CMD fd
else
    set -g _FORGE_FD_CMD fd
end

# Detect bat command
if command -v bat >/dev/null 2>&1
    set -g _FORGE_CAT_CMD "bat --color=always --style=numbers,changes --line-range=:500"
else
    set -g _FORGE_CAT_CMD cat
end

# Commands cache - loaded lazily
set -g _FORGE_COMMANDS ""

# Session state
set -g _FORGE_CONVERSATION_ID ""
set -g _FORGE_ACTIVE_AGENT ""
set -g _FORGE_PREVIOUS_CONVERSATION_ID ""

# Session-scoped model and provider overrides
set -g _FORGE_SESSION_MODEL ""
set -g _FORGE_SESSION_PROVIDER ""
set -g _FORGE_SESSION_REASONING_EFFORT ""
