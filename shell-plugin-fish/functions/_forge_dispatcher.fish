#!/usr/bin/env fish

# Main command dispatcher
# Intercepts lines starting with : and routes to appropriate handlers

function forge_dispatch
    set -l line $argv[1]

    set -l user_action ""
    set -l input_text ""

    # Parse :action params or : params
    if string match -rq '^:([a-zA-Z][a-zA-Z0-9_-]*)( (.*))?$' -- "$line"
        set user_action (string match -r '^:([a-zA-Z][a-zA-Z0-9_-]*)' -- "$line" | tail -1)
        set input_text (string replace -r '^:[a-zA-Z][a-zA-Z0-9_-]*\s*' '' -- "$line")
    else if string match -rq '^: (.+)$' -- "$line"
        set user_action ""
        set input_text (string replace -r '^: ' '' -- "$line")
    else
        # Not a :command, execute normally
        eval $line
        return
    end

    # Handle aliases
    switch $user_action
        case ask
            set user_action sage
        case plan
            set user_action muse
    end

    # Dispatch to action handlers
    switch $user_action
        case new n
            _forge_action_new "$input_text"
        case info i
            _forge_action_info
        case env e
            _forge_action_env
        case dump d
            _forge_action_dump "$input_text"
        case compact
            _forge_action_compact
        case retry r
            _forge_action_retry
        case agent a
            _forge_action_agent "$input_text"
        case conversation c
            _forge_action_conversation "$input_text"
        case config-model cm
            _forge_action_model "$input_text"
        case model m
            _forge_action_session_model "$input_text"
        case config-reload cr model-reset mr
            _forge_action_config_reload
        case reasoning-effort re
            _forge_action_reasoning_effort "$input_text"
        case tools t
            _forge_action_tools
        case config
            _forge_action_config
        case skill
            _forge_action_skill
        case commit
            _forge_action_commit "$input_text"
        case commit-preview
            _forge_action_commit_preview "$input_text"
        case clone
            _forge_action_clone "$input_text"
        case rename rn
            _forge_action_rename "$input_text"
        case copy
            _forge_action_copy
        case workspace-sync sync
            _forge_action_sync
        case workspace-init sync-init
            _forge_action_sync_init
        case workspace-status sync-status
            _forge_action_sync_status
        case workspace-info sync-info
            _forge_action_sync_info
        case provider-login login provider
            _forge_action_login "$input_text"
        case logout
            _forge_action_logout "$input_text"
        case doctor
            _forge_action_doctor
        case keyboard-shortcuts kb
            _forge_action_keyboard
        case '*'
            _forge_action_default "$user_action" "$input_text"
    end
end

# Fish key binding: override Enter to intercept :commands
function _forge_on_enter
    set -l cmd (commandline)

    if string match -rq '^:' -- "$cmd"
        commandline -f repaint
        # Add to history
        builtin history merge 2>/dev/null
        commandline ''
        forge_dispatch "$cmd"
        commandline -f repaint
    else
        commandline -f execute
    end
end

# Bind Enter key to our handler
bind \r _forge_on_enter
bind \n _forge_on_enter
