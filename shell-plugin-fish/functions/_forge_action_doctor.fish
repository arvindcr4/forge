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
