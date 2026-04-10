#!/usr/bin/env fish

# Action handler: Show session info
function _forge_action_info
    echo
    if test -n "$_FORGE_CONVERSATION_ID"
        _forge_exec info --cid "$_FORGE_CONVERSATION_ID"
    else
        _forge_exec info
    end
end

# Action handler: Show environment info
function _forge_action_env
    echo
    _forge_exec env
end

# Action handler: Dump conversation
function _forge_action_dump
    set -l input_text $argv[1]
    if test "$input_text" = html
        _forge_handle_conversation_command dump --html
    else
        _forge_handle_conversation_command dump
    end
end

# Action handler: Compact conversation
function _forge_action_compact
    _forge_handle_conversation_command compact
end

# Action handler: Retry last message
function _forge_action_retry
    _forge_handle_conversation_command retry
end

# Helper: handle conversation commands that require active conversation
function _forge_handle_conversation_command
    set -l subcommand $argv[1]
    set -e argv[1]

    echo

    if test -z "$_FORGE_CONVERSATION_ID"
        _forge_log error "No active conversation. Start a conversation first or use :conversation to see existing ones"
        return 0
    end

    _forge_exec conversation $subcommand "$_FORGE_CONVERSATION_ID" $argv
end

# Action handler: Show tools
function _forge_action_tools
    echo
    set -l agent_id (_forge_active_agent_or_default)
    _forge_exec list tools $agent_id
end

# Action handler: Show skills
function _forge_action_skill
    echo
    _forge_exec list skill
end

# Action handler: Show config
function _forge_action_config
    echo
    $_FORGE_BIN config list
end

# Action handler: Copy last assistant message to clipboard
function _forge_action_copy
    echo

    if test -z "$_FORGE_CONVERSATION_ID"
        _forge_log error "No active conversation. Start a conversation first or use :conversation to see existing ones"
        return 0
    end

    set -l content ($_FORGE_BIN conversation show --md "$_FORGE_CONVERSATION_ID" 2>/dev/null)

    if test -z "$content"
        _forge_log error "No assistant message found in the current conversation"
        return 0
    end

    if command -v pbcopy >/dev/null 2>&1
        echo -n "$content" | pbcopy
    else if command -v xclip >/dev/null 2>&1
        echo -n "$content" | xclip -selection clipboard
    else if command -v xsel >/dev/null 2>&1
        echo -n "$content" | xsel --clipboard --input
    else
        _forge_log error "No clipboard utility found (pbcopy, xclip, or xsel required)"
        return 0
    end

    set -l line_count (echo "$content" | wc -l | string trim)
    set -l byte_count (echo -n "$content" | wc -c | string trim)

    _forge_log success "Copied to clipboard [$line_count lines, $byte_count bytes]"
end

# Action handler: Rename current conversation
function _forge_action_rename
    set -l input_text $argv[1]

    echo

    if test -z "$_FORGE_CONVERSATION_ID"
        _forge_log error "No active conversation. Start a conversation first or use :conversation to select one"
        return 0
    end

    if test -z "$input_text"
        _forge_log error "Usage: :rename <name>"
        return 0
    end

    _forge_exec conversation rename "$_FORGE_CONVERSATION_ID" $input_text
end

# Action handler: Sync workspace
function _forge_action_sync
    echo
    _forge_exec_interactive workspace sync --init
end

# Action handler: Init workspace
function _forge_action_sync_init
    echo
    _forge_exec_interactive workspace init
end

# Action handler: Show sync status
function _forge_action_sync_status
    echo
    _forge_exec workspace status "."
end

# Action handler: Show workspace info
function _forge_action_sync_info
    echo
    _forge_exec workspace info "."
end

# Action handler: Login
function _forge_action_login
    set -l input_text $argv[1]
    echo
    set -l output ($_FORGE_BIN list provider --porcelain 2>/dev/null)
    if test -z "$output"
        _forge_log error "No providers available"
        return 1
    end

    set -l fzf_args --prompt "Provider ❯ " --header-lines=1
    if test -n "$input_text"
        set fzf_args $fzf_args --query "$input_text"
    end

    set -l selected (echo "$output" | _forge_fzf $fzf_args)
    if test -n "$selected"
        set -l provider (echo "$selected" | awk '{print $2}')
        _forge_exec_interactive provider login $provider
    end
end

# Action handler: Logout
function _forge_action_logout
    set -l input_text $argv[1]
    echo
    set -l output ($_FORGE_BIN list provider --porcelain 2>/dev/null)
    if test -z "$output"
        _forge_log error "No providers available"
        return 1
    end

    # Filter to logged-in providers
    set -l header (echo "$output" | head -n 1)
    set -l filtered (echo "$output" | tail -n +2 | grep -i '\[yes\]')
    if test -z "$filtered"
        _forge_log error "No logged-in providers found"
        return 1
    end
    set output (printf "%s\n%s" "$header" "$filtered")

    set -l fzf_args --prompt "Provider ❯ " --header-lines=1
    if test -n "$input_text"
        set fzf_args $fzf_args --query "$input_text"
    end

    set -l selected (echo "$output" | _forge_fzf $fzf_args)
    if test -n "$selected"
        set -l provider (echo "$selected" | awk '{print $2}')
        _forge_exec provider logout $provider
    end
end
