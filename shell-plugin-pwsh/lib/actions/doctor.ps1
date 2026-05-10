# Doctor action handler

function script:Invoke-ForgeActionDoctor {
    Write-Host ""
    & $script:ForgeBin zsh doctor 2>$null
}

function script:Invoke-ForgeActionMcp {
    param([string]$InputText)

    Write-Host ""
    if ($InputText -eq "doctor") {
        Invoke-Forge mcp doctor
    } elseif ($InputText) {
        Invoke-Forge mcp @($InputText -split '\s+')
    } else {
        Invoke-Forge mcp list
    }
}

function script:Invoke-ForgeActionScan {
    Write-Host ""
    Invoke-Forge project scan
}

function script:Invoke-ForgeActionMemory {
    param([string]$InputText)

    Write-Host ""
    if (-not $InputText) {
        Invoke-Forge memory list
    } elseif ($InputText -match '^add\s+(.+)$') {
        Invoke-Forge memory add $Matches[1]
    } else {
        Invoke-Forge memory @($InputText -split '\s+')
    }
}
