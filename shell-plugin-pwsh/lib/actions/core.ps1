# Core action handlers

function script:Invoke-ForgeActionNew {
    param([string]$InputText)

    Clear-ForgeConversation
    $script:ForgeActiveAgent = "forge"

    Write-Host ""

    if ($InputText) {
        $newId = & $script:ForgeBin conversation new
        Switch-ForgeConversation $newId
        Invoke-Forge -p "$InputText" --cid $script:ForgeConversationId
        Start-ForgeBackgroundSync
        Start-ForgeBackgroundUpdate
    } else {
        Invoke-Forge banner
    }
}

function script:Invoke-ForgeActionInfo {
    Write-Host ""
    if ($script:ForgeConversationId) {
        Invoke-Forge info --cid $script:ForgeConversationId
    } else {
        Invoke-Forge info
    }
}

function script:Invoke-ForgeActionEnv {
    Write-Host ""
    Invoke-Forge env
}

function script:Invoke-ForgeActionDump {
    param([string]$InputText)
    if ($InputText -eq "html") {
        Invoke-ForgeConversationCommand "dump" "--html"
    } else {
        Invoke-ForgeConversationCommand "dump"
    }
}

function script:Invoke-ForgeActionCompact {
    Invoke-ForgeConversationCommand "compact"
}

function script:Invoke-ForgeActionRetry {
    Invoke-ForgeConversationCommand "retry"
}

function script:Invoke-ForgeConversationCommand {
    param([string]$Subcommand, [string[]]$ExtraArgs)

    Write-Host ""

    if (-not $script:ForgeConversationId) {
        Write-ForgeLog "error" "No active conversation. Start a conversation first or use :conversation to see existing ones"
        return
    }

    $args = @("conversation", $Subcommand, $script:ForgeConversationId) + $ExtraArgs
    Invoke-Forge @args
}

function script:Invoke-ForgeActionTools {
    Write-Host ""
    $agentId = if ($script:ForgeActiveAgent) { $script:ForgeActiveAgent } else { "forge" }
    Invoke-Forge list tools $agentId
}

function script:Invoke-ForgeActionSkill {
    Write-Host ""
    Invoke-Forge list skill
}

function script:Invoke-ForgeActionConfig {
    Write-Host ""
    & $script:ForgeBin config list
}

function script:Invoke-ForgeActionCopy {
    Write-Host ""

    if (-not $script:ForgeConversationId) {
        Write-ForgeLog "error" "No active conversation. Start a conversation first or use :conversation to see existing ones"
        return
    }

    $content = & $script:ForgeBin conversation show --md $script:ForgeConversationId 2>$null

    if (-not $content) {
        Write-ForgeLog "error" "No assistant message found in the current conversation"
        return
    }

    $contentStr = $content -join "`n"
    Set-Clipboard -Value $contentStr

    $lineCount = ($content | Measure-Object -Line).Lines
    $byteCount = [System.Text.Encoding]::UTF8.GetByteCount($contentStr)

    Write-ForgeLog "success" "Copied to clipboard [$lineCount lines, $byteCount bytes]"
}

function script:Invoke-ForgeActionRename {
    param([string]$InputText)

    Write-Host ""

    if (-not $script:ForgeConversationId) {
        Write-ForgeLog "error" "No active conversation. Start a conversation first or use :conversation to select one"
        return
    }

    if (-not $InputText) {
        Write-ForgeLog "error" "Usage: :rename <name>"
        return
    }

    Invoke-Forge conversation rename $script:ForgeConversationId $InputText
}

function script:Invoke-ForgeActionSync {
    Write-Host ""
    Invoke-Forge workspace sync --init
}

function script:Invoke-ForgeActionSyncInit {
    Write-Host ""
    Invoke-Forge workspace init
}

function script:Invoke-ForgeActionSyncStatus {
    Write-Host ""
    Invoke-Forge workspace status "."
}

function script:Invoke-ForgeActionSyncInfo {
    Write-Host ""
    Invoke-Forge workspace info "."
}
