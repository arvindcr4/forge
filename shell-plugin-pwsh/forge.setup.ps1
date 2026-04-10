# Forge PowerShell Plugin Setup
# Add this to your $PROFILE (run: notepad $PROFILE)

# Load forge shell plugin if not already loaded
if (-not $env:_FORGE_PLUGIN_LOADED) {
    $forgPluginPath = Join-Path $PSScriptRoot "forge.plugin.ps1"
    if (Test-Path $forgPluginPath) {
        . $forgPluginPath
    }
}

# Load forge shell theme if not already loaded
if (-not $env:_FORGE_THEME_LOADED) {
    $forgeThemePath = Join-Path $PSScriptRoot "forge.theme.ps1"
    if (Test-Path $forgeThemePath) {
        . $forgeThemePath
    }
}
