# Core utility functions for forge plugin

function script:Get-ForgeCommands {
    if (-not $script:ForgeCommands) {
        $env:CLICOLOR_FORCE = "0"
        $script:ForgeCommands = & $script:ForgeBin list commands --porcelain 2>$null
        Remove-Item Env:CLICOLOR_FORCE -ErrorAction SilentlyContinue
    }
    return $script:ForgeCommands
}

function script:Invoke-Forge {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments)

    $agentId = if ($script:ForgeActiveAgent) { $script:ForgeActiveAgent } else { "forge" }
    $cmd = @($script:ForgeBin, "--agent", $agentId) + $Arguments

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

    try {
        & $cmd[0] $cmd[1..($cmd.Length-1)]
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

function script:Write-ForgeLog {
    param(
        [string]$Level,
        [string]$Message
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    $dimTs = "`e[90m[$timestamp]`e[0m"

    switch ($Level) {
        "error"   { Write-Host "`e[31m⏺`e[0m $dimTs `e[31m$Message`e[0m" }
        "info"    { Write-Host "`e[37m⏺`e[0m $dimTs `e[37m$Message`e[0m" }
        "success" { Write-Host "`e[33m⏺`e[0m $dimTs `e[37m$Message`e[0m" }
        "warning" { Write-Host "`e[93m⚠️`e[0m $dimTs `e[93m$Message`e[0m" }
        "debug"   { Write-Host "`e[36m⏺`e[0m $dimTs `e[90m$Message`e[0m" }
        default   { Write-Host $Message }
    }
}

function script:Switch-ForgeConversation {
    param([string]$NewId)
    if ($script:ForgeConversationId -and $script:ForgeConversationId -ne $NewId) {
        $script:ForgePreviousConversationId = $script:ForgeConversationId
    }
    $script:ForgeConversationId = $NewId
}

function script:Clear-ForgeConversation {
    if ($script:ForgeConversationId) {
        $script:ForgePreviousConversationId = $script:ForgeConversationId
    }
    $script:ForgeConversationId = ""
}

function script:Start-ForgeBackgroundSync {
    $syncEnabled = if ($env:FORGE_SYNC_ENABLED) { $env:FORGE_SYNC_ENABLED } else { "true" }
    if ($syncEnabled -ne "true") { return }

    $workspacePath = (Get-Location).Path
    $forgeBin = $script:ForgeBin

    Start-Job -ScriptBlock {
        param($bin, $path)
        $null = & $bin workspace info $path 2>$null
        if ($LASTEXITCODE -eq 0) {
            $null = & $bin workspace sync $path 2>$null
        }
    } -ArgumentList $forgeBin, $workspacePath | Out-Null
}

function script:Start-ForgeBackgroundUpdate {
    $forgeBin = $script:ForgeBin
    Start-Job -ScriptBlock {
        param($bin)
        $null = & $bin update --no-confirm 2>$null
    } -ArgumentList $forgeBin | Out-Null
}
