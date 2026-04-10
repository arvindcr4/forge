# Forge PowerShell Theme - Prompt integration

function script:Get-ForgePromptInfo {
    $forgeBin = if ($script:ForgeBin) { $script:ForgeBin } else { "forge" }

    $envBackup = @{}
    if ($script:ForgeSessionModel) {
        $envBackup['FORGE_SESSION__MODEL_ID'] = $env:FORGE_SESSION__MODEL_ID
        $env:FORGE_SESSION__MODEL_ID = $script:ForgeSessionModel
    }
    if ($script:ForgeSessionProvider) {
        $envBackup['FORGE_SESSION__PROVIDER_ID'] = $env:FORGE_SESSION__PROVIDER_ID
        $env:FORGE_SESSION__PROVIDER_ID = $script:ForgeSessionProvider
    }
    if ($script:ForgeSessionReasoningEffort) {
        $envBackup['FORGE_REASONING__EFFORT'] = $env:FORGE_REASONING__EFFORT
        $env:FORGE_REASONING__EFFORT = $script:ForgeSessionReasoningEffort
    }

    $env:_FORGE_CONVERSATION_ID = $script:ForgeConversationId
    $env:_FORGE_ACTIVE_AGENT = $script:ForgeActiveAgent

    try {
        & $forgeBin zsh rprompt 2>$null
    } finally {
        foreach ($key in $envBackup.Keys) {
            if ($null -eq $envBackup[$key]) {
                Remove-Item "Env:$key" -ErrorAction SilentlyContinue
            } else {
                Set-Item "Env:$key" $envBackup[$key]
            }
        }
    }
}

# Append forge info to the prompt
if (-not $env:_FORGE_THEME_LOADED) {
    # Save existing prompt
    if (Test-Path Function:\prompt) {
        $script:ForgeOriginalPrompt = ${function:prompt}
    }

    function global:prompt {
        $forgeInfo = Get-ForgePromptInfo

        $originalOutput = if ($script:ForgeOriginalPrompt) {
            & $script:ForgeOriginalPrompt
        } else {
            "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
        }

        if ($forgeInfo) {
            # Display forge info on the right side using console width
            $consoleWidth = $Host.UI.RawUI.WindowSize.Width
            $cleanForgeInfo = $forgeInfo -replace "`e\[[0-9;]*m", ""
            $padding = $consoleWidth - $cleanForgeInfo.Length
            if ($padding -gt 0) {
                Write-Host (" " * $padding + $forgeInfo) -NoNewline
                Write-Host ""
            }
        }

        return $originalOutput
    }

    $env:_FORGE_THEME_LOADED = "1"
}
