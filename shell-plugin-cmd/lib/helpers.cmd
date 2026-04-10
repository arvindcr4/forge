@echo off

:: Helper subroutines for forge CMD plugin

:: Execute forge with agent context
:: Usage: call :forge_exec <args...>
:forge_exec
setlocal
set "AGENT_ID=%_FORGE_ACTIVE_AGENT%"
if "%AGENT_ID%"=="" set "AGENT_ID=forge"

if defined _FORGE_SESSION_MODEL set "FORGE_SESSION__MODEL_ID=%_FORGE_SESSION_MODEL%"
if defined _FORGE_SESSION_PROVIDER set "FORGE_SESSION__PROVIDER_ID=%_FORGE_SESSION_PROVIDER%"

%FORGE_BIN% --agent %AGENT_ID% %*
endlocal
exit /b %ERRORLEVEL%

:: Log message with level
:: Usage: call :forge_log <level> <message>
:forge_log
setlocal
set "LEVEL=%~1"
set "MSG=%~2"
set "TS=%TIME:~0,8%"

if "%LEVEL%"=="error"   echo [%TS%] ERROR: %MSG%
if "%LEVEL%"=="info"    echo [%TS%] INFO: %MSG%
if "%LEVEL%"=="success" echo [%TS%] OK: %MSG%
if "%LEVEL%"=="warning" echo [%TS%] WARN: %MSG%
endlocal
exit /b 0
