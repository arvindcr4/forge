#!/usr/bin/env fish

# Forge Fish Theme - Right prompt integration

function _forge_prompt_info
    set -l forge_bin "$_FORGE_BIN"
    if test -z "$forge_bin"
        set forge_bin forge
    end

    if test -n "$_FORGE_SESSION_MODEL"
        set -lx FORGE_SESSION__MODEL_ID "$_FORGE_SESSION_MODEL"
    end
    if test -n "$_FORGE_SESSION_PROVIDER"
        set -lx FORGE_SESSION__PROVIDER_ID "$_FORGE_SESSION_PROVIDER"
    end
    if test -n "$_FORGE_SESSION_REASONING_EFFORT"
        set -lx FORGE_REASONING__EFFORT "$_FORGE_SESSION_REASONING_EFFORT"
    end

    _FORGE_CONVERSATION_ID=$_FORGE_CONVERSATION_ID _FORGE_ACTIVE_AGENT=$_FORGE_ACTIVE_AGENT $forge_bin zsh rprompt 2>/dev/null
end

# Override fish_right_prompt if not already done
if not set -q _FORGE_THEME_LOADED
    # Save existing right prompt if any
    if functions -q fish_right_prompt
        functions -c fish_right_prompt _forge_original_right_prompt
    end

    function fish_right_prompt
        set -l forge_info (_forge_prompt_info)
        set -l original ""
        if functions -q _forge_original_right_prompt
            set original (_forge_original_right_prompt)
        end
        if test -n "$forge_info"
            echo -n "$forge_info"
            if test -n "$original"
                echo -n " $original"
            end
        else if test -n "$original"
            echo -n "$original"
        end
    end

    set -g _FORGE_THEME_LOADED 1
end
