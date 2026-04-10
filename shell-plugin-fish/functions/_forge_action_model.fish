#!/usr/bin/env fish

# Model and agent selection actions

function _forge_action_agent
    set -l input_text $argv[1]

    echo

    if test -n "$input_text"
        set -l agent_exists ($_FORGE_BIN list agents --porcelain 2>/dev/null | tail -n +2 | grep -q "^$input_text\b"; and echo true; or echo false)
        if test "$agent_exists" = false
            _forge_log error "Agent '$input_text' not found"
            return 0
        end
        set -g _FORGE_ACTIVE_AGENT "$input_text"
        _forge_log success "Switched to agent $input_text"
        return 0
    end

    set -l agents_output ($_FORGE_BIN list agents --porcelain 2>/dev/null)
    if test -z "$agents_output"
        _forge_log error "No agents found"
        return 0
    end

    set -l selected (echo "$agents_output" | _forge_fzf --header-lines=1 --prompt "Agent ❯ ")
    if test -n "$selected"
        set -l agent_id (echo "$selected" | awk '{print $1}')
        set -g _FORGE_ACTIVE_AGENT "$agent_id"
        _forge_log success "Switched to agent $agent_id"
    end
end

function _forge_action_session_model
    set -l input_text $argv[1]
    echo

    set -l output ($_FORGE_BIN list models --porcelain 2>/dev/null)
    if test -z "$output"
        _forge_log error "No models found"
        return 0
    end

    set -l fzf_args --header-lines=1 --prompt "Session Model ❯ "
    if test -n "$input_text"
        set fzf_args $fzf_args --query "$input_text"
    end

    set -l selected (echo "$output" | _forge_fzf $fzf_args)
    if test -n "$selected"
        set -l model_id (echo "$selected" | awk -F '  +' '{print $1}' | string trim)
        set -l provider_id (echo "$selected" | awk -F '  +' '{print $4}' | string trim)

        set -g _FORGE_SESSION_MODEL "$model_id"
        set -g _FORGE_SESSION_PROVIDER "$provider_id"

        _forge_log success "Session model set to $model_id (provider: $provider_id)"
    end
end

function _forge_action_model
    set -l input_text $argv[1]
    echo

    set -l current_model ($_FORGE_BIN config get model 2>/dev/null)
    set -l output ($_FORGE_BIN list models --porcelain 2>/dev/null)
    if test -z "$output"
        _forge_log error "No models found"
        return 0
    end

    set -l fzf_args --header-lines=1 --prompt "Model ❯ "
    if test -n "$input_text"
        set fzf_args $fzf_args --query "$input_text"
    end

    set -l selected (echo "$output" | _forge_fzf $fzf_args)
    if test -n "$selected"
        set -l model_id (echo "$selected" | awk -F '  +' '{print $1}' | string trim)
        set -l provider_id (echo "$selected" | awk -F '  +' '{print $4}' | string trim)
        _forge_exec config set model "$model_id"
    end
end

function _forge_action_config_reload
    echo

    if test -z "$_FORGE_SESSION_MODEL" -a -z "$_FORGE_SESSION_PROVIDER" -a -z "$_FORGE_SESSION_REASONING_EFFORT"
        _forge_log info "No session overrides active (already using global config)"
        return 0
    end

    set -g _FORGE_SESSION_MODEL ""
    set -g _FORGE_SESSION_PROVIDER ""
    set -g _FORGE_SESSION_REASONING_EFFORT ""

    _forge_log success "Session overrides cleared — using global config"
end

function _forge_action_reasoning_effort
    set -l input_text $argv[1]
    echo

    set -l efforts "EFFORT\nnone\nminimal\nlow\nmedium\nhigh\nxhigh\nmax"

    set -l fzf_args --header-lines=1 --prompt "Reasoning Effort ❯ "
    if test -n "$input_text"
        set fzf_args $fzf_args --query "$input_text"
    end

    set -l selected (printf $efforts | _forge_fzf $fzf_args)
    if test -n "$selected"
        set -g _FORGE_SESSION_REASONING_EFFORT "$selected"
        _forge_log success "Session reasoning effort set to $selected"
    end
end
