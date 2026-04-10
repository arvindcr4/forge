#!/usr/bin/env fish

# Conversation management actions

function _forge_action_conversation
    set -l input_text $argv[1]

    echo

    # Toggle to previous conversation (like cd -)
    if test "$input_text" = "-"
        if test -z "$_FORGE_PREVIOUS_CONVERSATION_ID"
            set input_text ""
            # Fall through to list
        else
            set -l temp "$_FORGE_CONVERSATION_ID"
            set -g _FORGE_CONVERSATION_ID "$_FORGE_PREVIOUS_CONVERSATION_ID"
            set -g _FORGE_PREVIOUS_CONVERSATION_ID "$temp"

            echo
            _forge_exec conversation show "$_FORGE_CONVERSATION_ID"
            _forge_exec conversation info "$_FORGE_CONVERSATION_ID"
            _forge_log success "Switched to conversation $_FORGE_CONVERSATION_ID"
            return 0
        end
    end

    # Switch to specific conversation by ID
    if test -n "$input_text"
        _forge_switch_conversation "$input_text"

        echo
        _forge_exec conversation show "$input_text"
        _forge_exec conversation info "$input_text"
        _forge_log success "Switched to conversation $input_text"
        return 0
    end

    # Interactive conversation picker
    set -l conversations_output ($_FORGE_BIN conversation list --porcelain 2>/dev/null)

    if test -z "$conversations_output"
        _forge_log error "No conversations found"
        return 0
    end

    set -l fzf_args --prompt "Conversation ❯ " --header-lines=1 \
        --preview "CLICOLOR_FORCE=1 $_FORGE_BIN conversation info {1}; echo; CLICOLOR_FORCE=1 $_FORGE_BIN conversation show {1}" \
        --preview-window "bottom:75%:wrap:border-sharp"

    set -l selected (echo "$conversations_output" | _forge_fzf $fzf_args)

    if test -n "$selected"
        set -l conversation_id (echo "$selected" | string replace -r '  .*' '')
        _forge_switch_conversation "$conversation_id"

        echo
        _forge_exec conversation show "$conversation_id"
        _forge_exec conversation info "$conversation_id"
        _forge_log success "Switched to conversation $conversation_id"
    end
end

# Action handler: Clone conversation
function _forge_action_clone
    set -l input_text $argv[1]

    echo

    if test -n "$input_text"
        _forge_clone_and_switch "$input_text"
        return 0
    end

    set -l conversations_output ($_FORGE_BIN conversation list --porcelain 2>/dev/null)

    if test -z "$conversations_output"
        _forge_log error "No conversations found"
        return 0
    end

    set -l fzf_args --prompt "Clone Conversation ❯ " --header-lines=1 \
        --preview "CLICOLOR_FORCE=1 $_FORGE_BIN conversation info {1}; echo; CLICOLOR_FORCE=1 $_FORGE_BIN conversation show {1}" \
        --preview-window "bottom:75%:wrap:border-sharp"

    set -l selected (echo "$conversations_output" | _forge_fzf $fzf_args)

    if test -n "$selected"
        set -l conversation_id (echo "$selected" | string replace -r '  .*' '')
        _forge_clone_and_switch "$conversation_id"
    end
end

function _forge_clone_and_switch
    set -l clone_target $argv[1]
    set -l original_id "$_FORGE_CONVERSATION_ID"

    _forge_log info "Cloning conversation $clone_target"
    set -l clone_output ($_FORGE_BIN conversation clone "$clone_target" 2>&1)
    set -l clone_status $status

    if test $clone_status -eq 0
        set -l new_id (echo "$clone_output" | grep -oE '[a-f0-9-]{36}' | tail -1)
        if test -n "$new_id"
            _forge_switch_conversation "$new_id"
            _forge_log success "└─ Switched to conversation $new_id"

            if test "$clone_target" != "$original_id"
                echo
                _forge_exec conversation show "$new_id"
                echo
                _forge_exec conversation info "$new_id"
            end
        else
            _forge_log error "Failed to extract new conversation ID from clone output"
        end
    else
        _forge_log error "Failed to clone conversation: $clone_output"
    end
end
