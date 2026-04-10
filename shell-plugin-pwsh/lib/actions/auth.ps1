# Authentication action handlers

function script:Invoke-ForgeActionLogin {
    param([string]$InputText)

    Write-Host ""

    $output = & $script:ForgeBin list provider --porcelain 2>$null
    if (-not $output) {
        Write-ForgeLog "error" "No providers available"
        return
    }

    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        $fzfArgs = @("--header-lines=1", "--prompt", "Provider > ", "--reverse", "--exact", "--cycle", "--height", "80%", "--no-scrollbar", "--ansi")
        if ($InputText) { $fzfArgs += @("--query", $InputText) }

        $selected = $output | fzf @fzfArgs
        if ($selected) {
            $provider = ($selected -split '\s+')[1]
            Invoke-Forge provider login $provider
        }
    } else {
        Write-Host $output
    }
}

function script:Invoke-ForgeActionLogout {
    param([string]$InputText)

    Write-Host ""

    $output = & $script:ForgeBin list provider --porcelain 2>$null
    if (-not $output) {
        Write-ForgeLog "error" "No providers available"
        return
    }

    # Filter to logged-in providers
    $header = ($output -split "`n")[0]
    $filtered = ($output -split "`n" | Select-Object -Skip 1) | Where-Object { $_ -match '\[yes\]' }
    if (-not $filtered) {
        Write-ForgeLog "error" "No logged-in providers found"
        return
    }
    $output = @($header) + @($filtered)

    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        $fzfArgs = @("--header-lines=1", "--prompt", "Provider > ", "--reverse", "--exact", "--cycle", "--height", "80%", "--no-scrollbar", "--ansi")
        if ($InputText) { $fzfArgs += @("--query", $InputText) }

        $selected = $output | fzf @fzfArgs
        if ($selected) {
            $provider = ($selected -split '\s+')[1]
            Invoke-Forge provider logout $provider
        }
    } else {
        Write-Host $output
    }
}
