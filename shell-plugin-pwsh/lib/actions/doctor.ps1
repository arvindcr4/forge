# Doctor action handler

function script:Invoke-ForgeActionDoctor {
    Write-Host ""
    & $script:ForgeBin zsh doctor 2>$null
}
