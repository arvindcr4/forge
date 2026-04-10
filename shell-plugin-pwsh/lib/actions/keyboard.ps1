# Keyboard action handler

function script:Invoke-ForgeActionKeyboard {
    Write-Host ""
    & $script:ForgeBin zsh keyboard 2>$null
}
