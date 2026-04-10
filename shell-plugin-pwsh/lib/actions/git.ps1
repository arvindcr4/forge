# Git integration actions

function script:Invoke-ForgeActionCommit {
    param([string]$AdditionalContext)

    Write-Host ""

    $env:FORCE_COLOR = "true"
    $env:CLICOLOR_FORCE = "1"

    if ($AdditionalContext) {
        & $script:ForgeBin commit --max-diff $script:ForgeMaxCommitDiff $AdditionalContext
    } else {
        & $script:ForgeBin commit --max-diff $script:ForgeMaxCommitDiff
    }

    Remove-Item Env:FORCE_COLOR -ErrorAction SilentlyContinue
    Remove-Item Env:CLICOLOR_FORCE -ErrorAction SilentlyContinue
}

function script:Invoke-ForgeActionCommitPreview {
    param([string]$AdditionalContext)

    Write-Host ""

    $env:FORCE_COLOR = "true"
    $env:CLICOLOR_FORCE = "1"

    $commitMessage = if ($AdditionalContext) {
        & $script:ForgeBin commit --preview --max-diff $script:ForgeMaxCommitDiff $AdditionalContext
    } else {
        & $script:ForgeBin commit --preview --max-diff $script:ForgeMaxCommitDiff
    }

    Remove-Item Env:FORCE_COLOR -ErrorAction SilentlyContinue
    Remove-Item Env:CLICOLOR_FORCE -ErrorAction SilentlyContinue

    if ($commitMessage) {
        $staged = git diff --staged --quiet 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "git commit -m '$commitMessage'"
        } else {
            Write-Host "git commit -am '$commitMessage'"
        }
    }
}
