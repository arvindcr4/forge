#!/usr/bin/env fish

# Fish Keyboard Shortcuts Display

set RESET (set_color normal)
set BOLD (set_color --bold)
set DIM (set_color 888888)
set CYAN (set_color cyan)

function print_section
    echo ""
    echo $BOLD$argv[1]$RESET
end

function print_shortcut
    set -l key $argv[1]
    set -l description $argv[2]

    if test -z "$description"
        echo "  "$DIM"$key"$RESET
    else
        printf "  %s%-20s%s%s\n" $CYAN $key $RESET "$description"
    end
end

# Detect platform
set platform unknown
set alt_key Alt
switch (uname)
    case Darwin
        set platform macOS
        set alt_key Option
    case Linux
        set platform Linux
end

print_section "Configuration"
if test "$platform" != unknown
    print_shortcut "Platform: $platform"
end
print_shortcut "Mode: Fish default keybindings"

print_section "Line Navigation"
print_shortcut "Ctrl+A" "Move to beginning of line"
print_shortcut "Ctrl+E" "Move to end of line"
print_shortcut "$alt_key+F" "Move forward one word"
print_shortcut "$alt_key+B" "Move backward one word"

print_section "Editing"
print_shortcut "Ctrl+U" "Kill line before cursor"
print_shortcut "Ctrl+K" "Kill line after cursor"
print_shortcut "Ctrl+W" "Kill word before cursor"
print_shortcut "$alt_key+D" "Kill word after cursor"
print_shortcut "Ctrl+Y" "Yank (paste) killed text"
print_shortcut "Ctrl+Z" "Undo last edit"

print_section "History"
print_shortcut "Ctrl+R" "Search command history"
print_shortcut "↑ / ↓" "Navigate history"
print_shortcut "$alt_key+↑" "Search history for token under cursor"

print_section "Other"
print_shortcut "Ctrl+L" "Clear screen"
print_shortcut "Ctrl+C" "Cancel current command"
print_shortcut "Tab" "Complete command/path"

echo ""
if test "$platform" = macOS
    echo "  "$DIM"If Option key shortcuts don't work, check terminal Meta key settings."$RESET
end
echo ""
