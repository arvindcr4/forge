#!/usr/bin/env fish

# Doctor action handler
function _forge_action_doctor
    echo
    $_FORGE_BIN fish doctor 2>/dev/null; or $_FORGE_BIN zsh doctor 2>/dev/null
end

# Keyboard action handler
function _forge_action_keyboard
    echo
    $_FORGE_BIN fish keyboard 2>/dev/null; or $_FORGE_BIN zsh keyboard 2>/dev/null
end

function _forge_action_mcp
    set -l input_text $argv[1]

    echo
    if test "$input_text" = doctor
        _forge_exec mcp doctor
    else
        _forge_exec mcp $input_text
    end
end

function _forge_action_scan
    echo
    _forge_exec project scan
end

function _forge_action_memory
    set -l input_text $argv[1]

    echo
    if test -z "$input_text"
        _forge_exec memory list
    else if string match -q 'add *' -- "$input_text"
        set -l text (string replace -r '^add\s+' '' -- "$input_text")
        _forge_exec memory add "$text"
    else
        _forge_exec memory $input_text
    end
end
