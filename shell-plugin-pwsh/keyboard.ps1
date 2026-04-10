# PowerShell Keyboard Shortcuts Display

function Print-Section { param([string]$Title); Write-Host ""; Write-Host "`e[1m$Title`e[0m" }
function Print-Shortcut {
    param([string]$Key, [string]$Description)
    if (-not $Description) {
        Write-Host "  `e[2m$Key`e[0m"
    } else {
        $padding = 20 - $Key.Length
        if ($padding -lt 1) { $padding = 1 }
        Write-Host ("  `e[36m{0}`e[0m{1}{2}" -f $Key, (" " * $padding), $Description)
    }
}

$platform = if ($IsWindows -or $env:OS -eq "Windows_NT") { "Windows" }
            elseif ($IsMacOS) { "macOS" }
            else { "Linux" }

$altKey = if ($platform -eq "macOS") { "Option" } else { "Alt" }

Print-Section "Configuration"
Print-Shortcut "Platform: $platform"
Print-Shortcut "Shell: PowerShell $($PSVersionTable.PSVersion)"

Print-Section "Line Navigation"
Print-Shortcut "Home" "Move to beginning of line"
Print-Shortcut "End" "Move to end of line"
Print-Shortcut "Ctrl+←" "Move backward one word"
Print-Shortcut "Ctrl+→" "Move forward one word"

Print-Section "Editing"
Print-Shortcut "Ctrl+Backspace" "Delete word before cursor"
Print-Shortcut "Ctrl+Delete" "Delete word after cursor"
Print-Shortcut "Ctrl+U" "Delete from cursor to start"
Print-Shortcut "Ctrl+K" "Delete from cursor to end"
Print-Shortcut "Ctrl+Z" "Undo"
Print-Shortcut "Ctrl+Y" "Redo"

Print-Section "History"
Print-Shortcut "↑ / ↓" "Navigate history"
Print-Shortcut "Ctrl+R" "Search history backward"
Print-Shortcut "F8" "Search history by prefix"

Print-Section "Other"
Print-Shortcut "Ctrl+L" "Clear screen"
Print-Shortcut "Ctrl+C" "Cancel current command"
Print-Shortcut "Tab" "Complete command/path"

Write-Host ""
