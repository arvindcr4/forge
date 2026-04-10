@echo off
setlocal EnableDelayedExpansion

:: Forge CMD Plugin - Main entry wrapper
:: Intercepts :command syntax and routes to forge CLI

:: Load configuration
call "%~dp0lib\config.cmd"

:: If no arguments, show help
if "%~1"=="" (
    echo Forge Shell Plugin for CMD
    echo.
    echo Usage:
    echo   forge :new [prompt]         Start new conversation
    echo   forge :info                 Show session info
    echo   forge :conversation [id]    List/switch conversations
    echo   forge :model [query]        Select model
    echo   forge :commit [context]     AI-generated commit
    echo   forge :doctor               Environment diagnostics
    echo   forge :agent [name]         Switch agent
    echo   forge :tools                Show available tools
    echo   forge :config               Show configuration
    echo   forge :login [query]        Login to provider
    echo   forge :logout [query]       Logout from provider
    echo   forge :sync                 Sync workspace
    echo   forge :copy                 Copy last response
    echo   forge : [prompt]            Send prompt to active agent
    echo.
    echo Aliases: :n=new :i=info :c=conversation :m=model :a=agent :t=tools :r=retry
    echo.
    echo For full features, use PowerShell (pwsh) or Fish shell.
    exit /b 0
)

:: Parse command
set "CMD=%~1"
shift

:: Collect remaining arguments
set "ARGS="
:collect_args
if "%~1"=="" goto dispatch
set "ARGS=!ARGS! %~1"
shift
goto collect_args

:dispatch
:: Route commands
call "%~dp0lib\dispatcher.cmd" "!CMD!" "!ARGS!"
exit /b %ERRORLEVEL%
