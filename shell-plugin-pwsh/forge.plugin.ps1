# Forge PowerShell Plugin
# Documentation in README.md

$script:PluginDir = $PSScriptRoot

# Configuration variables
. "$script:PluginDir\lib\config.ps1"

# Core utilities
. "$script:PluginDir\lib\helpers.ps1"

# Action handlers
. "$script:PluginDir\lib\actions\core.ps1"
. "$script:PluginDir\lib\actions\config.ps1"
. "$script:PluginDir\lib\actions\conversation.ps1"
. "$script:PluginDir\lib\actions\git.ps1"
. "$script:PluginDir\lib\actions\auth.ps1"
. "$script:PluginDir\lib\actions\editor.ps1"
. "$script:PluginDir\lib\actions\provider.ps1"
. "$script:PluginDir\lib\actions\doctor.ps1"
. "$script:PluginDir\lib\actions\keyboard.ps1"

# Main dispatcher and PSReadLine handler
. "$script:PluginDir\lib\dispatcher.ps1"

# Tab completion
. "$script:PluginDir\lib\completion.ps1"

$script:ForgePluginLoaded = $true
$env:_FORGE_PLUGIN_LOADED = "1"
