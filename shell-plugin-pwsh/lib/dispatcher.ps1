# Main command dispatcher with PSReadLine Enter key handler

function script:Invoke-ForgeDispatch {
    param([string]$Line)

    $userAction = ""
    $inputText = ""

    if ($Line -match '^:([a-zA-Z][a-zA-Z0-9_-]*)(\s+(.*))?$') {
        $userAction = $Matches[1]
        $inputText = if ($Matches[3]) { $Matches[3] } else { "" }
    } elseif ($Line -match '^:\s+(.+)$') {
        $userAction = ""
        $inputText = $Matches[1]
    } else {
        return $false
    }

    # Handle aliases
    switch ($userAction) {
        "ask" { $userAction = "sage" }
        "plan" { $userAction = "muse" }
    }

    # Dispatch
    switch ($userAction) {
        { $_ -in "new", "n" }                                   { Invoke-ForgeActionNew $inputText }
        { $_ -in "info", "i" }                                  { Invoke-ForgeActionInfo }
        { $_ -in "env", "e" }                                   { Invoke-ForgeActionEnv }
        { $_ -in "dump", "d" }                                  { Invoke-ForgeActionDump $inputText }
        "compact"                                                { Invoke-ForgeActionCompact }
        { $_ -in "retry", "r" }                                 { Invoke-ForgeActionRetry }
        { $_ -in "agent", "a" }                                 { Invoke-ForgeActionAgent $inputText }
        { $_ -in "conversation", "c" }                           { Invoke-ForgeActionConversation $inputText }
        { $_ -in "config-model", "cm" }                          { Invoke-ForgeActionModel $inputText }
        { $_ -in "model", "m" }                                  { Invoke-ForgeActionSessionModel $inputText }
        { $_ -in "config-reload", "cr", "model-reset", "mr" }   { Invoke-ForgeActionConfigReload }
        { $_ -in "reasoning-effort", "re" }                      { Invoke-ForgeActionReasoningEffort $inputText }
        { $_ -in "tools", "t" }                                  { Invoke-ForgeActionTools }
        "config"                                                 { Invoke-ForgeActionConfig }
        "skill"                                                  { Invoke-ForgeActionSkill }
        { $_ -in "edit", "ed" }                                  { Invoke-ForgeActionEditor $inputText }
        "commit"                                                 { Invoke-ForgeActionCommit $inputText }
        "commit-preview"                                         { Invoke-ForgeActionCommitPreview $inputText }
        "clone"                                                  { Invoke-ForgeActionClone $inputText }
        { $_ -in "rename", "rn" }                                { Invoke-ForgeActionRename $inputText }
        "copy"                                                   { Invoke-ForgeActionCopy }
        { $_ -in "workspace-sync", "sync" }                      { Invoke-ForgeActionSync }
        { $_ -in "workspace-init", "sync-init" }                 { Invoke-ForgeActionSyncInit }
        { $_ -in "workspace-status", "sync-status" }             { Invoke-ForgeActionSyncStatus }
        { $_ -in "workspace-info", "sync-info" }                 { Invoke-ForgeActionSyncInfo }
        { $_ -in "provider-login", "login", "provider" }         { Invoke-ForgeActionLogin $inputText }
        "logout"                                                 { Invoke-ForgeActionLogout $inputText }
        "doctor"                                                 { Invoke-ForgeActionDoctor }
        { $_ -in "keyboard-shortcuts", "kb" }                    { Invoke-ForgeActionKeyboard }
        default {
            # Default handler for agent commands and custom commands
            Invoke-ForgeActionDefault $userAction $inputText
        }
    }

    return $true
}

# Default action handler
function script:Invoke-ForgeActionDefault {
    param([string]$UserAction, [string]$InputText)

    $commandType = ""

    if ($UserAction) {
        $commandsList = Get-ForgeCommands
        if ($commandsList) {
            $commandRow = ($commandsList -split "`n") | Where-Object { $_ -match "^$UserAction\b" }
            if (-not $commandRow) {
                Write-Host ""
                Write-ForgeLog "error" "Command '$UserAction' not found"
                return
            }

            $commandType = ($commandRow -split '\s+')[1]
            if ($commandType -and $commandType.ToLower() -eq "custom") {
                if (-not $script:ForgeConversationId) {
                    $script:ForgeConversationId = & $script:ForgeBin conversation new
                }

                Write-Host ""
                if ($InputText) {
                    Invoke-Forge cmd execute --cid $script:ForgeConversationId $UserAction $InputText
                } else {
                    Invoke-Forge cmd execute --cid $script:ForgeConversationId $UserAction
                }
                return
            }
        }
    }

    if (-not $InputText) {
        if ($UserAction) {
            if ($commandType -and $commandType.ToLower() -ne "agent") {
                Write-Host ""
                Write-ForgeLog "error" "Command '$UserAction' not found"
                return
            }
            Write-Host ""
            $script:ForgeActiveAgent = $UserAction
            Write-ForgeLog "info" "$($UserAction.ToUpper()) is now the active agent"
        }
        return
    }

    if (-not $script:ForgeConversationId) {
        $script:ForgeConversationId = & $script:ForgeBin conversation new
    }

    Write-Host ""

    if ($UserAction) {
        $script:ForgeActiveAgent = $UserAction
    }

    Invoke-Forge -p "$InputText" --cid $script:ForgeConversationId

    Start-ForgeBackgroundSync
    Start-ForgeBackgroundUpdate
}

# Register PSReadLine Enter key handler to intercept :commands
if (Get-Module PSReadLine -ErrorAction SilentlyContinue) {
    Set-PSReadLineKeyHandler -Key Enter -ScriptBlock {
        param($key, $arg)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        if ($line -match '^:') {
            # Add to history
            [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($line)
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("")

            # Accept line to clear the prompt
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()

            # Dispatch after accepting
            $global:_ForgeLastCommand = $line
        } else {
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
        }
    }

    # Process forge commands via prompt function hook
    $script:OriginalPromptFunction = $function:prompt

    function global:prompt {
        if ($global:_ForgeLastCommand) {
            $cmd = $global:_ForgeLastCommand
            $global:_ForgeLastCommand = $null
            Invoke-ForgeDispatch $cmd
        }

        if ($script:OriginalPromptFunction) {
            & $script:OriginalPromptFunction
        } else {
            "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
        }
    }
}
