# Configuration variables for forge plugin

$script:ForgeBin = if ($env:FORGE_BIN) { $env:FORGE_BIN } else { "forge" }
$script:ForgeMaxCommitDiff = if ($env:FORGE_MAX_COMMIT_DIFF) { $env:FORGE_MAX_COMMIT_DIFF } else { "100000" }

# Detect fd command
$script:ForgeFdCmd = if (Get-Command fdfind -ErrorAction SilentlyContinue) { "fdfind" }
                     elseif (Get-Command fd -ErrorAction SilentlyContinue) { "fd" }
                     else { "fd" }

# Detect bat command
$script:ForgeCatCmd = if (Get-Command bat -ErrorAction SilentlyContinue) { "bat --color=always --style=numbers,changes --line-range=:500" }
                      else { "Get-Content" }

# Commands cache
$script:ForgeCommands = ""

# Session state
$script:ForgeConversationId = ""
$script:ForgeActiveAgent = ""
$script:ForgePreviousConversationId = ""

# Session-scoped model and provider overrides
$script:ForgeSessionModel = ""
$script:ForgeSessionProvider = ""
$script:ForgeSessionReasoningEffort = ""
