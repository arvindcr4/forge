@echo off
setlocal EnableDelayedExpansion

:: Command dispatcher for forge CMD plugin
:: Usage: dispatcher.cmd ":command" "args"

set "CMD=%~1"
set "ARGS=%~2"

:: Strip leading/trailing spaces from ARGS
for /f "tokens=* delims= " %%a in ("%ARGS%") do set "ARGS=%%a"

:: Load helpers
call "%~dp0helpers.cmd" 2>/dev/null

:: Handle aliases
if "%CMD%"==":n" set "CMD=:new"
if "%CMD%"==":i" set "CMD=:info"
if "%CMD%"==":e" set "CMD=:env"
if "%CMD%"==":c" set "CMD=:conversation"
if "%CMD%"==":m" set "CMD=:model"
if "%CMD%"==":a" set "CMD=:agent"
if "%CMD%"==":t" set "CMD=:tools"
if "%CMD%"==":r" set "CMD=:retry"
if "%CMD%"==":d" set "CMD=:dump"
if "%CMD%"==":cm" set "CMD=:config-model"
if "%CMD%"==":cr" set "CMD=:config-reload"
if "%CMD%"==":mr" set "CMD=:model-reset"
if "%CMD%"==":re" set "CMD=:reasoning-effort"
if "%CMD%"==":rn" set "CMD=:rename"
if "%CMD%"==":kb" set "CMD=:keyboard-shortcuts"

:: Dispatch
if "%CMD%"==":new" goto action_new
if "%CMD%"==":info" goto action_info
if "%CMD%"==":env" goto action_env
if "%CMD%"==":dump" goto action_dump
if "%CMD%"==":compact" goto action_compact
if "%CMD%"==":retry" goto action_retry
if "%CMD%"==":conversation" goto action_conversation
if "%CMD%"==":agent" goto action_agent
if "%CMD%"==":model" goto action_model
if "%CMD%"==":config-model" goto action_config_model
if "%CMD%"==":config-reload" goto action_config_reload
if "%CMD%"==":model-reset" goto action_config_reload
if "%CMD%"==":reasoning-effort" goto action_reasoning_effort
if "%CMD%"==":tools" goto action_tools
if "%CMD%"==":config" goto action_config
if "%CMD%"==":skill" goto action_skill
if "%CMD%"==":commit" goto action_commit
if "%CMD%"==":commit-preview" goto action_commit_preview
if "%CMD%"==":clone" goto action_clone
if "%CMD%"==":rename" goto action_rename
if "%CMD%"==":copy" goto action_copy
if "%CMD%"==":sync" goto action_sync
if "%CMD%"==":workspace-sync" goto action_sync
if "%CMD%"==":sync-init" goto action_sync_init
if "%CMD%"==":workspace-init" goto action_sync_init
if "%CMD%"==":sync-status" goto action_sync_status
if "%CMD%"==":sync-info" goto action_sync_info
if "%CMD%"==":login" goto action_login
if "%CMD%"==":provider-login" goto action_login
if "%CMD%"==":provider" goto action_login
if "%CMD%"==":logout" goto action_logout
if "%CMD%"==":doctor" goto action_doctor
if "%CMD%"==":keyboard-shortcuts" goto action_keyboard

:: Handle ": prompt" (default prompt)
if "%CMD%"==":" goto action_default_prompt

:: Unknown command
echo Unknown command: %CMD%
echo Run "forge" without arguments for help.
exit /b 1

:: --- Action implementations ---

:action_new
if "%_FORGE_CONVERSATION_ID%" neq "" set "_FORGE_PREVIOUS_CONVERSATION_ID=%_FORGE_CONVERSATION_ID%"
set "_FORGE_CONVERSATION_ID="
set "_FORGE_ACTIVE_AGENT=forge"
echo.
if "%ARGS%"=="" (
    call :forge_exec banner
) else (
    for /f "delims=" %%i in ('%FORGE_BIN% conversation new') do set "_FORGE_CONVERSATION_ID=%%i"
    call :forge_exec -p "%ARGS%" --cid %_FORGE_CONVERSATION_ID%
)
exit /b 0

:action_info
echo.
if "%_FORGE_CONVERSATION_ID%"=="" (
    call :forge_exec info
) else (
    call :forge_exec info --cid %_FORGE_CONVERSATION_ID%
)
exit /b 0

:action_env
echo.
call :forge_exec env
exit /b 0

:action_dump
echo.
if "%_FORGE_CONVERSATION_ID%"=="" (
    call :forge_log error "No active conversation"
    exit /b 0
)
if "%ARGS%"=="html" (
    call :forge_exec conversation dump %_FORGE_CONVERSATION_ID% --html
) else (
    call :forge_exec conversation dump %_FORGE_CONVERSATION_ID%
)
exit /b 0

:action_compact
echo.
if "%_FORGE_CONVERSATION_ID%"=="" (
    call :forge_log error "No active conversation"
    exit /b 0
)
call :forge_exec conversation compact %_FORGE_CONVERSATION_ID%
exit /b 0

:action_retry
echo.
if "%_FORGE_CONVERSATION_ID%"=="" (
    call :forge_log error "No active conversation"
    exit /b 0
)
call :forge_exec conversation retry %_FORGE_CONVERSATION_ID%
exit /b 0

:action_conversation
echo.
if "%ARGS%"=="-" (
    if "%_FORGE_PREVIOUS_CONVERSATION_ID%"=="" (
        %FORGE_BIN% conversation list --porcelain
    ) else (
        set "TEMP_ID=%_FORGE_CONVERSATION_ID%"
        set "_FORGE_CONVERSATION_ID=%_FORGE_PREVIOUS_CONVERSATION_ID%"
        set "_FORGE_PREVIOUS_CONVERSATION_ID=%TEMP_ID%"
        call :forge_exec conversation show %_FORGE_CONVERSATION_ID%
        call :forge_exec conversation info %_FORGE_CONVERSATION_ID%
        call :forge_log success "Switched to conversation %_FORGE_CONVERSATION_ID%"
    )
    exit /b 0
)
if "%ARGS%" neq "" (
    if "%_FORGE_CONVERSATION_ID%" neq "" set "_FORGE_PREVIOUS_CONVERSATION_ID=%_FORGE_CONVERSATION_ID%"
    set "_FORGE_CONVERSATION_ID=%ARGS%"
    call :forge_exec conversation show %ARGS%
    call :forge_exec conversation info %ARGS%
    call :forge_log success "Switched to conversation %ARGS%"
    exit /b 0
)
:: List conversations
%FORGE_BIN% conversation list --porcelain
exit /b 0

:action_agent
echo.
if "%ARGS%" neq "" (
    set "_FORGE_ACTIVE_AGENT=%ARGS%"
    call :forge_log success "Switched to agent %ARGS%"
) else (
    %FORGE_BIN% list agents --porcelain
)
exit /b 0

:action_model
echo.
%FORGE_BIN% list models --porcelain
echo.
echo Use: forge :model-set ^<model_id^> to set a model
exit /b 0

:action_config_model
echo.
if "%ARGS%" neq "" (
    call :forge_exec config set model %ARGS%
) else (
    %FORGE_BIN% list models --porcelain
)
exit /b 0

:action_config_reload
echo.
set "_FORGE_SESSION_MODEL="
set "_FORGE_SESSION_PROVIDER="
call :forge_log success "Session overrides cleared — using global config"
exit /b 0

:action_reasoning_effort
echo.
echo Available reasoning efforts: none, minimal, low, medium, high, xhigh, max
if "%ARGS%" neq "" (
    set "_FORGE_SESSION_REASONING_EFFORT=%ARGS%"
    call :forge_log success "Session reasoning effort set to %ARGS%"
)
exit /b 0

:action_tools
echo.
set "AGENT_ID=%_FORGE_ACTIVE_AGENT%"
if "%AGENT_ID%"=="" set "AGENT_ID=forge"
call :forge_exec list tools %AGENT_ID%
exit /b 0

:action_config
echo.
%FORGE_BIN% config list
exit /b 0

:action_skill
echo.
call :forge_exec list skill
exit /b 0

:action_commit
echo.
set "FORCE_COLOR=true"
set "CLICOLOR_FORCE=1"
if "%ARGS%"=="" (
    %FORGE_BIN% commit --max-diff %FORGE_MAX_COMMIT_DIFF%
) else (
    %FORGE_BIN% commit --max-diff %FORGE_MAX_COMMIT_DIFF% %ARGS%
)
exit /b 0

:action_commit_preview
echo.
set "FORCE_COLOR=true"
set "CLICOLOR_FORCE=1"
if "%ARGS%"=="" (
    %FORGE_BIN% commit --preview --max-diff %FORGE_MAX_COMMIT_DIFF%
) else (
    %FORGE_BIN% commit --preview --max-diff %FORGE_MAX_COMMIT_DIFF% %ARGS%
)
exit /b 0

:action_clone
echo.
if "%ARGS%"=="" (
    if "%_FORGE_CONVERSATION_ID%"=="" (
        call :forge_log error "No active conversation to clone. Provide a conversation ID."
        exit /b 0
    )
    set "CLONE_TARGET=%_FORGE_CONVERSATION_ID%"
) else (
    set "CLONE_TARGET=%ARGS%"
)
call :forge_log info "Cloning conversation %CLONE_TARGET%"
for /f "delims=" %%i in ('%FORGE_BIN% conversation clone %CLONE_TARGET%') do set "CLONE_OUTPUT=%%i"
:: Try to extract UUID from output
for /f "tokens=*" %%i in ('echo %CLONE_OUTPUT% ^| findstr /r "[a-f0-9-][a-f0-9-]*"') do (
    if "%_FORGE_CONVERSATION_ID%" neq "" set "_FORGE_PREVIOUS_CONVERSATION_ID=%_FORGE_CONVERSATION_ID%"
    set "_FORGE_CONVERSATION_ID=%%i"
    call :forge_log success "Switched to cloned conversation"
)
exit /b 0

:action_rename
echo.
if "%_FORGE_CONVERSATION_ID%"=="" (
    call :forge_log error "No active conversation"
    exit /b 0
)
if "%ARGS%"=="" (
    call :forge_log error "Usage: forge :rename <name>"
    exit /b 0
)
call :forge_exec conversation rename %_FORGE_CONVERSATION_ID% %ARGS%
exit /b 0

:action_copy
echo.
if "%_FORGE_CONVERSATION_ID%"=="" (
    call :forge_log error "No active conversation"
    exit /b 0
)
%FORGE_BIN% conversation show --md %_FORGE_CONVERSATION_ID% | clip
call :forge_log success "Copied to clipboard"
exit /b 0

:action_sync
echo.
call :forge_exec workspace sync --init
exit /b 0

:action_sync_init
echo.
call :forge_exec workspace init
exit /b 0

:action_sync_status
echo.
call :forge_exec workspace status "."
exit /b 0

:action_sync_info
echo.
call :forge_exec workspace info "."
exit /b 0

:action_login
echo.
if "%ARGS%" neq "" (
    call :forge_exec provider login %ARGS%
) else (
    %FORGE_BIN% list provider --porcelain
    echo.
    echo Use: forge :login ^<provider_id^> to login
)
exit /b 0

:action_logout
echo.
if "%ARGS%" neq "" (
    call :forge_exec provider logout %ARGS%
) else (
    %FORGE_BIN% list provider --porcelain
    echo.
    echo Use: forge :logout ^<provider_id^> to logout
)
exit /b 0

:action_doctor
echo.
%FORGE_BIN% zsh doctor
exit /b 0

:action_keyboard
echo.
%FORGE_BIN% zsh keyboard
exit /b 0

:action_default_prompt
echo.
if "%ARGS%"=="" exit /b 0
if "%_FORGE_CONVERSATION_ID%"=="" (
    for /f "delims=" %%i in ('%FORGE_BIN% conversation new') do set "_FORGE_CONVERSATION_ID=%%i"
)
call :forge_exec -p "%ARGS%" --cid %_FORGE_CONVERSATION_ID%
exit /b 0
