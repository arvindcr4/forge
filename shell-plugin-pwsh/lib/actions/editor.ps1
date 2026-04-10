# Editor action handler

function script:Invoke-ForgeActionEditor {
    param([string]$InitialText)

    Write-Host ""

    $editorCmd = if ($env:FORGE_EDITOR) { $env:FORGE_EDITOR }
                 elseif ($env:EDITOR) { $env:EDITOR }
                 else { "notepad" }

    $forgeDir = ".forge"
    if (-not (Test-Path $forgeDir)) {
        New-Item -ItemType Directory -Path $forgeDir -Force | Out-Null
    }

    $tempFile = Join-Path $forgeDir "FORGE_EDITMSG.md"

    if ($InitialText) {
        $InitialText | Set-Content -Path $tempFile
    } else {
        "" | Set-Content -Path $tempFile
    }

    # Open editor
    & $editorCmd $tempFile
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        Write-ForgeLog "error" "Editor exited with error code $exitCode"
        return
    }

    $content = (Get-Content -Path $tempFile -Raw) -replace "`r", ""

    if (-not $content -or $content.Trim() -eq "") {
        Write-ForgeLog "info" "Editor closed with no content"
        return
    }

    # Dispatch content as a :command
    Invoke-ForgeDispatch ": $content"
}
