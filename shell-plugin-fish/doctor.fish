#!/usr/bin/env fish

# Fish Doctor - Diagnostic tool for Forge shell environment

# ANSI codes via set_color
set RESET (set_color normal)
set BOLD (set_color --bold)
set DIM (set_color 888888)
set GREEN (set_color green)
set RED (set_color red)
set YELLOW (set_color yellow)
set CYAN (set_color cyan)

set PASS "[OK]"
set FAIL "[ERROR]"
set WARN "[WARN]"

set passed 0
set failed 0
set warnings 0

function print_section
    echo ""
    echo $BOLD$argv[1]$RESET
end

function print_result
    set -l result_status $argv[1]
    set -l message $argv[2]
    set -l detail $argv[3]

    switch $result_status
        case pass
            echo "  "$GREEN$PASS$RESET" $message"
            set passed (math $passed + 1)
        case fail
            echo "  "$RED$FAIL$RESET" $message"
            if test -n "$detail"
                echo "  "$DIM"· $detail"$RESET
            end
            set failed (math $failed + 1)
        case warn
            echo "  "$YELLOW$WARN$RESET" $message"
            if test -n "$detail"
                echo "  "$DIM"· $detail"$RESET
            end
            set warnings (math $warnings + 1)
        case info
            echo "  "$DIM"· $message"$RESET
        case code
            echo "  "$DIM"· $message"$RESET
    end
end

echo $BOLD"FORGE ENVIRONMENT DIAGNOSTICS"$RESET

# 1. Check Fish version
print_section "Shell Environment"
set -l fish_ver (fish --version 2>&1 | string replace 'fish, version ' '')
if test -n "$fish_ver"
    set -l major (string split '.' -- $fish_ver)[1]
    if test "$major" -ge 3
        print_result pass "fish: $fish_ver"
    else
        print_result warn "fish: $fish_ver" "Recommended: 3.0+"
    end
else
    print_result fail "Unable to detect Fish version"
end

if test -n "$TERM_PROGRAM"
    if test -n "$TERM_PROGRAM_VERSION"
        print_result pass "Terminal: $TERM_PROGRAM $TERM_PROGRAM_VERSION"
    else
        print_result pass "Terminal: $TERM_PROGRAM"
    end
else if test -n "$TERM"
    print_result pass "Terminal: $TERM"
else
    print_result info "Terminal: unknown"
end

# 2. Check forge installation
print_section "Forge Installation"
if command -v forge >/dev/null 2>&1
    set -l forge_path (command -v forge)
    set -l forge_version (forge --version 2>&1 | head -n1 | awk '{print $2}')
    if test -n "$forge_version"
        print_result pass "forge: $forge_version"
        print_result info "$forge_path"
    else
        print_result pass "forge: installed"
        print_result info "$forge_path"
    end
else
    print_result fail "Forge binary not found in PATH" "Installation: curl -fsSL https://forgecode.dev/cli | sh"
end

# 3. Check plugin
print_section "Plugin"
if set -q _FORGE_PLUGIN_LOADED
    print_result pass "Forge Fish plugin loaded"
else
    print_result fail "Forge Fish plugin not loaded"
    print_result info "Add to ~/.config/fish/config.fish:"
    print_result code "source /path/to/shell-plugin-fish/forge.plugin.fish"
end

# 4. Check theme
print_section "FORGE RIGHT PROMPT"
if set -q _FORGE_THEME_LOADED
    print_result pass "Forge theme loaded"
else
    print_result warn "Forge theme not loaded"
    print_result info "Source forge.theme.fish in your config.fish"
end

# 5. Check dependencies
print_section "Dependencies"

if command -v fzf >/dev/null 2>&1
    set -l fzf_version (fzf --version 2>&1 | head -n1 | awk '{print $1}')
    print_result pass "fzf: $fzf_version"
else
    print_result fail "fzf not found" "Required for interactive features. See: https://github.com/junegunn/fzf#installation"
end

if command -v fd >/dev/null 2>&1
    set -l fd_version (fd --version 2>&1 | awk '{print $2}')
    print_result pass "fd: $fd_version"
else if command -v fdfind >/dev/null 2>&1
    set -l fd_version (fdfind --version 2>&1 | awk '{print $2}')
    print_result pass "fdfind: $fd_version"
else
    print_result warn "fd/fdfind not found" "Enhanced file discovery. See: https://github.com/sharkdp/fd#installation"
end

if command -v bat >/dev/null 2>&1
    set -l bat_version (bat --version 2>&1 | awk '{print $2}')
    print_result pass "bat: $bat_version"
else
    print_result warn "bat not found" "Enhanced preview. See: https://github.com/sharkdp/bat#installation"
end

# 6. System
print_section "System"
if test -n "$FORGE_EDITOR"
    print_result pass "FORGE_EDITOR: $FORGE_EDITOR"
else if test -n "$EDITOR"
    print_result pass "EDITOR: $EDITOR"
else
    print_result warn "No editor configured" "set -gx EDITOR vim or set -gx FORGE_EDITOR vim"
end

# Summary
echo ""
if test $failed -eq 0; and test $warnings -eq 0
    echo $GREEN$PASS$RESET" "$BOLD"All checks passed"$RESET" "$DIM"($passed)"$RESET
    exit 0
else if test $failed -eq 0
    echo $YELLOW$WARN$RESET" "$BOLD"$warnings warnings"$RESET" "$DIM"($passed passed)"$RESET
    exit 0
else
    echo $RED$FAIL$RESET" "$BOLD"$failed failed"$RESET" "$DIM"($warnings warnings, $passed passed)"$RESET
    exit 1
end
