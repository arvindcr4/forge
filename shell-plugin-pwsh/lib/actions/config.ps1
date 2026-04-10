# Configuration action handlers (agent, model, reasoning effort)

function script:Invoke-ForgeActionAgent {
    param([string]$InputText)

    Write-Host ""

    if ($InputText) {
        $agents = & $script:ForgeBin list agents --porcelain 2>$null
        $found = $agents | Select-Object -Skip 1 | Where-Object { $_ -match "^$InputText\b" }
        if (-not $found) {
            Write-ForgeLog "error" "Agent '$InputText' not found"
            return
        }
        $script:ForgeActiveAgent = $InputText
        Write-ForgeLog "success" "Switched to agent $InputText"
        return
    }

    $agentsOutput = & $script:ForgeBin list agents --porcelain 2>$null
    if (-not $agentsOutput) {
        Write-ForgeLog "error" "No agents found"
        return
    }

    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        $selected = $agentsOutput | fzf --reverse --exact --cycle --select-1 --height 80% --no-scrollbar --ansi --header-lines=1 --prompt "Agent > "
        if ($selected) {
            $agentId = ($selected -split '\s+')[0]
            $script:ForgeActiveAgent = $agentId
            Write-ForgeLog "success" "Switched to agent $agentId"
        }
    } else {
        Write-Host $agentsOutput
    }
}

function script:Invoke-ForgeActionSessionModel {
    param([string]$InputText)

    Write-Host ""

    $output = & $script:ForgeBin list models --porcelain 2>$null
    if (-not $output) {
        Write-ForgeLog "error" "No models found"
        return
    }

    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        $fzfArgs = @("--header-lines=1", "--prompt", "Session Model > ", "--reverse", "--exact", "--cycle", "--height", "80%", "--no-scrollbar", "--ansi")
        if ($InputText) { $fzfArgs += @("--query", $InputText) }

        $selected = $output | fzf @fzfArgs
        if ($selected) {
            $fields = $selected -split '\s{2,}'
            $script:ForgeSessionModel = $fields[0].Trim()
            if ($fields.Length -ge 4) {
                $script:ForgeSessionProvider = $fields[3].Trim()
            }
            Write-ForgeLog "success" "Session model set to $($script:ForgeSessionModel) (provider: $($script:ForgeSessionProvider))"
        }
    } else {
        Write-Host $output
    }
}

function script:Invoke-ForgeActionModel {
    param([string]$InputText)

    Write-Host ""

    $output = & $script:ForgeBin list models --porcelain 2>$null
    if (-not $output) {
        Write-ForgeLog "error" "No models found"
        return
    }

    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        $fzfArgs = @("--header-lines=1", "--prompt", "Model > ", "--reverse", "--exact", "--cycle", "--height", "80%", "--no-scrollbar", "--ansi")
        if ($InputText) { $fzfArgs += @("--query", $InputText) }

        $selected = $output | fzf @fzfArgs
        if ($selected) {
            $fields = $selected -split '\s{2,}'
            $modelId = $fields[0].Trim()
            Invoke-Forge config set model $modelId
        }
    } else {
        Write-Host $output
    }
}

function script:Invoke-ForgeActionConfigReload {
    Write-Host ""

    if (-not $script:ForgeSessionModel -and -not $script:ForgeSessionProvider -and -not $script:ForgeSessionReasoningEffort) {
        Write-ForgeLog "info" "No session overrides active (already using global config)"
        return
    }

    $script:ForgeSessionModel = ""
    $script:ForgeSessionProvider = ""
    $script:ForgeSessionReasoningEffort = ""

    Write-ForgeLog "success" "Session overrides cleared - using global config"
}

function script:Invoke-ForgeActionReasoningEffort {
    param([string]$InputText)

    Write-Host ""

    $efforts = @("EFFORT", "none", "minimal", "low", "medium", "high", "xhigh", "max")

    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        $fzfArgs = @("--header-lines=1", "--prompt", "Reasoning Effort > ", "--reverse", "--exact", "--cycle", "--height", "80%", "--no-scrollbar")
        if ($InputText) { $fzfArgs += @("--query", $InputText) }

        $selected = $efforts | fzf @fzfArgs
        if ($selected) {
            $script:ForgeSessionReasoningEffort = $selected
            Write-ForgeLog "success" "Session reasoning effort set to $selected"
        }
    } else {
        Write-Host ($efforts -join "`n")
    }
}
