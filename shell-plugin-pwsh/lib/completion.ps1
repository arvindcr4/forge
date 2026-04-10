# Tab completion for :commands and @files using Register-ArgumentCompleter

# Register a custom completer for lines starting with :
if (Get-Module PSReadLine -ErrorAction SilentlyContinue) {
    Set-PSReadLineKeyHandler -Key Tab -ScriptBlock {
        param($key, $arg)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        $currentWord = ""
        if ($cursor -gt 0) {
            $beforeCursor = $line.Substring(0, $cursor)
            $words = $beforeCursor -split '\s+'
            $currentWord = $words[-1]
        }

        # Handle @file completion
        if ($currentWord -match '^@') {
            $filter = $currentWord.Substring(1)
            if (Get-Command fzf -ErrorAction SilentlyContinue) {
                $fdCmd = if (Get-Command fd -ErrorAction SilentlyContinue) { "fd" }
                         elseif (Get-Command fdfind -ErrorAction SilentlyContinue) { "fdfind" }
                         else { $null }

                if ($fdCmd) {
                    $fzfArgs = @("--reverse", "--exact", "--cycle", "--height", "80%", "--no-scrollbar")
                    if ($filter) { $fzfArgs += @("--query", $filter) }

                    $selected = & $fdCmd --type f --type d --hidden --exclude .git | fzf @fzfArgs
                    if ($selected) {
                        $replacement = "@[$selected]"
                        $prefix = $line.Substring(0, $cursor - $currentWord.Length)
                        $suffix = $line.Substring($cursor)
                        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
                        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$prefix$replacement$suffix")
                    }
                }
            }
            return
        }

        # Handle :command completion
        if ($line -match '^:([a-zA-Z][a-zA-Z0-9_-]*)?$') {
            $filter = if ($Matches[1]) { $Matches[1] } else { "" }
            $commandsList = Get-ForgeCommands

            if ($commandsList -and (Get-Command fzf -ErrorAction SilentlyContinue)) {
                $fzfArgs = @("--header-lines=1", "--prompt", "Command > ", "--reverse", "--exact", "--cycle", "--height", "80%", "--no-scrollbar", "--ansi")
                if ($filter) { $fzfArgs += @("--query", $filter) }

                $selected = $commandsList | fzf @fzfArgs
                if ($selected) {
                    $commandName = ($selected -split '\s+')[0]
                    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
                    [Microsoft.PowerShell.PSConsoleReadLine]::Insert(":$commandName ")
                }
            }
            return
        }

        # Fall back to default tab completion
        [Microsoft.PowerShell.PSConsoleReadLine]::TabCompleteNext()
    }
}
