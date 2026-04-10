#!/usr/bin/env fish

# Core utility functions for forge plugin

function _forge_get_commands
    if test -z "$_FORGE_COMMANDS"
        set -g _FORGE_COMMANDS (CLICOLOR_FORCE=0 $_FORGE_BIN list commands --porcelain 2>/dev/null)
    end
    echo "$_FORGE_COMMANDS"
end

function _forge_fzf
    fzf --reverse --exact --cycle --select-1 --height 80% --no-scrollbar --ansi --color="header:bold" $argv
end

function _forge_exec
    set -l agent_id (_forge_active_agent_or_default)
    set -l cmd $_FORGE_BIN --agent $agent_id $argv

    set -lx FORGE_SESSION__MODEL_ID
    set -lx FORGE_SESSION__PROVIDER_ID
    set -lx FORGE_REASONING__EFFORT

    if test -n "$_FORGE_SESSION_MODEL"
        set -lx FORGE_SESSION__MODEL_ID "$_FORGE_SESSION_MODEL"
    end
    if test -n "$_FORGE_SESSION_PROVIDER"
        set -lx FORGE_SESSION__PROVIDER_ID "$_FORGE_SESSION_PROVIDER"
    end
    if test -n "$_FORGE_SESSION_REASONING_EFFORT"
        set -lx FORGE_REASONING__EFFORT "$_FORGE_SESSION_REASONING_EFFORT"
    end

    $cmd
end

function _forge_exec_interactive
    set -l agent_id (_forge_active_agent_or_default)
    set -l cmd $_FORGE_BIN --agent $agent_id $argv

    if test -n "$_FORGE_SESSION_MODEL"
        set -lx FORGE_SESSION__MODEL_ID "$_FORGE_SESSION_MODEL"
    end
    if test -n "$_FORGE_SESSION_PROVIDER"
        set -lx FORGE_SESSION__PROVIDER_ID "$_FORGE_SESSION_PROVIDER"
    end
    if test -n "$_FORGE_SESSION_REASONING_EFFORT"
        set -lx FORGE_REASONING__EFFORT "$_FORGE_SESSION_REASONING_EFFORT"
    end

    $cmd </dev/tty >/dev/tty
end

function _forge_active_agent_or_default
    if test -n "$_FORGE_ACTIVE_AGENT"
        echo "$_FORGE_ACTIVE_AGENT"
    else
        echo "forge"
    end
end

function _forge_switch_conversation
    set -l new_id $argv[1]
    if test -n "$_FORGE_CONVERSATION_ID"; and test "$_FORGE_CONVERSATION_ID" != "$new_id"
        set -g _FORGE_PREVIOUS_CONVERSATION_ID "$_FORGE_CONVERSATION_ID"
    end
    set -g _FORGE_CONVERSATION_ID "$new_id"
end

function _forge_clear_conversation
    if test -n "$_FORGE_CONVERSATION_ID"
        set -g _FORGE_PREVIOUS_CONVERSATION_ID "$_FORGE_CONVERSATION_ID"
    end
    set -g _FORGE_CONVERSATION_ID ""
end

function _forge_start_background_sync
    set -l sync_enabled true
    if set -q FORGE_SYNC_ENABLED
        set sync_enabled $FORGE_SYNC_ENABLED
    end
    if test "$sync_enabled" != true
        return 0
    end

    set -l workspace_path (pwd -P)

    # Run sync in background
    fish -c "
        $_FORGE_BIN workspace info '$workspace_path' >/dev/null 2>&1
        and $_FORGE_BIN workspace sync '$workspace_path' >/dev/null 2>&1
    " &
    disown
end

function _forge_start_background_update
    fish -c "$_FORGE_BIN update --no-confirm >/dev/null 2>&1" &
    disown
end
