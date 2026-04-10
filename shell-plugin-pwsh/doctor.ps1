# PowerShell Doctor - Diagnostic tool for Forge shell environment

$passed = 0
$failed = 0
$warnings = 0

function Print-Section { param([string]$Title); Write-Host ""; Write-Host "`e[1m$Title`e[0m" }
function Print-Result {
    param([string]$Status, [string]$Message, [string]$Detail)
    switch ($Status) {
        "pass"  { Write-Host "  `e[32m[OK]`e[0m $Message"; $script:passed++ }
        "fail"  { Write-Host "  `e[31m[ERROR]`e[0m $Message"; if ($Detail) { Write-Host "  `e[2m· $Detail`e[0m" }; $script:failed++ }
        "warn"  { Write-Host "  `e[33m[WARN]`e[0m $Message"; if ($Detail) { Write-Host "  `e[2m· $Detail`e[0m" }; $script:warnings++ }
        "info"  { Write-Host "  `e[2m· $Message`e[0m" }
    }
}

Write-Host "`e[1mFORGE ENVIRONMENT DIAGNOSTICS`e[0m"

# 1. Check PowerShell version
Print-Section "Shell Environment"
$psVer = $PSVersionTable.PSVersion
if ($psVer.Major -ge 7) {
    Print-Result "pass" "PowerShell: $psVer"
} elseif ($psVer.Major -ge 5) {
    Print-Result "warn" "PowerShell: $psVer" "Recommended: PowerShell 7+ (pwsh)"
} else {
    Print-Result "fail" "PowerShell: $psVer" "Minimum: PowerShell 5.1"
}

if ($env:TERM_PROGRAM) {
    Print-Result "pass" "Terminal: $env:TERM_PROGRAM"
} elseif ($env:WT_SESSION) {
    Print-Result "pass" "Terminal: Windows Terminal"
} else {
    Print-Result "info" "Terminal: unknown"
}

# 2. Check forge installation
Print-Section "Forge Installation"
$forgePath = Get-Command forge -ErrorAction SilentlyContinue
if ($forgePath) {
    $forgeVersion = (forge --version 2>$null) -split '\s+' | Select-Object -Index 1
    if ($forgeVersion) {
        Print-Result "pass" "forge: $forgeVersion"
        Print-Result "info" "$($forgePath.Source)"
    } else {
        Print-Result "pass" "forge: installed"
        Print-Result "info" "$($forgePath.Source)"
    }
} else {
    Print-Result "fail" "Forge binary not found in PATH" "Installation: iwr -useb https://forgecode.dev/cli | iex"
}

# 3. Check plugin
Print-Section "Plugin"
if ($env:_FORGE_PLUGIN_LOADED) {
    Print-Result "pass" "Forge PowerShell plugin loaded"
} else {
    Print-Result "fail" "Forge PowerShell plugin not loaded"
    Print-Result "info" 'Add to $PROFILE:'
    Print-Result "info" '. "path\to\forge.plugin.ps1"'
}

# 4. Check PSReadLine
Print-Section "PSReadLine"
$psrl = Get-Module PSReadLine -ErrorAction SilentlyContinue
if ($psrl) {
    Print-Result "pass" "PSReadLine: $($psrl.Version)"
} else {
    Print-Result "fail" "PSReadLine not loaded" "Required for key bindings. Install: Install-Module PSReadLine -Force"
}

# 5. Check dependencies
Print-Section "Dependencies"

if (Get-Command fzf -ErrorAction SilentlyContinue) {
    $fzfVer = (fzf --version 2>$null) -split '\s+' | Select-Object -First 1
    Print-Result "pass" "fzf: $fzfVer"
} else {
    Print-Result "fail" "fzf not found" "Required for interactive features. Install: winget install junegunn.fzf"
}

if (Get-Command fd -ErrorAction SilentlyContinue) {
    $fdVer = ((fd --version 2>$null) -split '\s+')[1]
    Print-Result "pass" "fd: $fdVer"
} else {
    Print-Result "warn" "fd not found" "Enhanced file discovery. Install: winget install sharkdp.fd"
}

if (Get-Command bat -ErrorAction SilentlyContinue) {
    $batVer = ((bat --version 2>$null) -split '\s+')[1]
    Print-Result "pass" "bat: $batVer"
} else {
    Print-Result "warn" "bat not found" "Enhanced preview. Install: winget install sharkdp.bat"
}

# 6. System
Print-Section "System"
if ($env:FORGE_EDITOR) {
    Print-Result "pass" "FORGE_EDITOR: $env:FORGE_EDITOR"
} elseif ($env:EDITOR) {
    Print-Result "pass" "EDITOR: $env:EDITOR"
} else {
    Print-Result "warn" "No editor configured" '$env:FORGE_EDITOR = "code" or $env:EDITOR = "notepad"'
}

# Summary
Write-Host ""
if ($failed -eq 0 -and $warnings -eq 0) {
    Write-Host "`e[32m[OK]`e[0m `e[1mAll checks passed`e[0m `e[2m($passed)`e[0m"
} elseif ($failed -eq 0) {
    Write-Host "`e[33m[WARN]`e[0m `e[1m$warnings warnings`e[0m `e[2m($passed passed)`e[0m"
} else {
    Write-Host "`e[31m[ERROR]`e[0m `e[1m$failed failed`e[0m `e[2m($warnings warnings, $passed passed)`e[0m"
}
