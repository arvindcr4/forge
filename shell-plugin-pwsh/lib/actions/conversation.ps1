# Conversation management actions

function script:Invoke-ForgeActionConversation {
    param([string]$InputText)

    Write-Host ""

    # Toggle to previous
    if ($InputText -eq "-") {
        if (-not $script:ForgePreviousConversationId) {
            $InputText = ""
        } else {
            $temp = $script:ForgeConversationId
            $script:ForgeConversationId = $script:ForgePreviousConversationId
            $script:ForgePreviousConversationId = $temp

            Write-Host ""
            Invoke-Forge conversation show $script:ForgeConversationId
            Invoke-Forge conversation info $script:ForgeConversationId
            Write-ForgeLog "success" "Switched to conversation $($script:ForgeConversationId)"
            return
        }
    }

    # Switch by ID
    if ($InputText) {
        Switch-ForgeConversation $InputText
        Write-Host ""
        Invoke-Forge conversation show $InputText
        Invoke-Forge conversation info $InputText
        Write-ForgeLog "success" "Switched to conversation $InputText"
        return
    }

    # Interactive picker
    $conversationsOutput = & $script:ForgeBin conversation list --porcelain 2>$null
    if (-not $conversationsOutput) {
        Write-ForgeLog "error" "No conversations found"
        return
    }

    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        $selected = $conversationsOutput | fzf --reverse --exact --cycle --select-1 --height 80% --no-scrollbar --ansi --header-lines=1 --prompt "Conversation > " --preview "$($script:ForgeBin) conversation info {1}; echo; $($script:ForgeBin) conversation show {1}" --preview-window "bottom:75%:wrap:border-sharp"
        if ($selected) {
            $conversationId = ($selected -split '\s{2,}')[0].Trim()
            Switch-ForgeConversation $conversationId
            Write-Host ""
            Invoke-Forge conversation show $conversationId
            Invoke-Forge conversation info $conversationId
            Write-ForgeLog "success" "Switched to conversation $conversationId"
        }
    } else {
        Write-Host $conversationsOutput
    }
}

function script:Invoke-ForgeActionClone {
    param([string]$InputText)

    Write-Host ""

    if ($InputText) {
        Invoke-ForgeCloneAndSwitch $InputText
        return
    }

    $conversationsOutput = & $script:ForgeBin conversation list --porcelain 2>$null
    if (-not $conversationsOutput) {
        Write-ForgeLog "error" "No conversations found"
        return
    }

    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        $selected = $conversationsOutput | fzf --reverse --exact --cycle --select-1 --height 80% --no-scrollbar --ansi --header-lines=1 --prompt "Clone Conversation > "
        if ($selected) {
            $conversationId = ($selected -split '\s{2,}')[0].Trim()
            Invoke-ForgeCloneAndSwitch $conversationId
        }
    } else {
        Write-Host $conversationsOutput
    }
}

function script:Invoke-ForgeCloneAndSwitch {
    param([string]$CloneTarget)

    $originalId = $script:ForgeConversationId

    Write-ForgeLog "info" "Cloning conversation $CloneTarget"
    $cloneOutput = & $script:ForgeBin conversation clone $CloneTarget 2>&1

    if ($LASTEXITCODE -eq 0) {
        $newId = [regex]::Match($cloneOutput, '[a-f0-9-]{36}').Value
        if ($newId) {
            Switch-ForgeConversation $newId
            Write-ForgeLog "success" "Switched to conversation $newId"

            if ($CloneTarget -ne $originalId) {
                Write-Host ""
                Invoke-Forge conversation show $newId
                Write-Host ""
                Invoke-Forge conversation info $newId
            }
        } else {
            Write-ForgeLog "error" "Failed to extract new conversation ID from clone output"
        }
    } else {
        Write-ForgeLog "error" "Failed to clone conversation: $cloneOutput"
    }
}
