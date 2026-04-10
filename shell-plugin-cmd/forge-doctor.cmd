@echo off

:: Forge CMD Doctor - Environment diagnostics

echo FORGE ENVIRONMENT DIAGNOSTICS
echo.

set PASSED=0
set FAILED=0
set WARNINGS=0

:: Check CMD version
echo Shell Environment
echo   [OK] CMD: %ComSpec%
set /a PASSED+=1

:: Check forge installation
echo.
echo Forge Installation
where forge >/dev/null 2>/dev/null
if %ERRORLEVEL% equ 0 (
    for /f "tokens=2" %%v in ('forge --version 2^>nul') do (
        echo   [OK] forge: %%v
        set /a PASSED+=1
    )
) else (
    echo   [ERROR] Forge binary not found in PATH
    echo     Install: https://forgecode.dev/cli
    set /a FAILED+=1
)

:: Check fzf
echo.
echo Dependencies
where fzf >/dev/null 2>/dev/null
if %ERRORLEVEL% equ 0 (
    for /f "tokens=1" %%v in ('fzf --version 2^>nul') do (
        echo   [OK] fzf: %%v
        set /a PASSED+=1
    )
) else (
    echo   [WARN] fzf not found ^(interactive features unavailable^)
    echo     Install: winget install junegunn.fzf
    set /a WARNINGS+=1
)

where fd >/dev/null 2>/dev/null
if %ERRORLEVEL% equ 0 (
    echo   [OK] fd: installed
    set /a PASSED+=1
) else (
    echo   [WARN] fd not found
    echo     Install: winget install sharkdp.fd
    set /a WARNINGS+=1
)

where git >/dev/null 2>/dev/null
if %ERRORLEVEL% equ 0 (
    echo   [OK] git: installed
    set /a PASSED+=1
) else (
    echo   [WARN] git not found
    set /a WARNINGS+=1
)

:: Check editor
echo.
echo System
if defined FORGE_EDITOR (
    echo   [OK] FORGE_EDITOR: %FORGE_EDITOR%
    set /a PASSED+=1
) else if defined EDITOR (
    echo   [OK] EDITOR: %EDITOR%
    set /a PASSED+=1
) else (
    echo   [WARN] No editor configured
    echo     Set FORGE_EDITOR or EDITOR environment variable
    set /a WARNINGS+=1
)

:: Summary
echo.
if %FAILED% equ 0 if %WARNINGS% equ 0 (
    echo [OK] All checks passed ^(%PASSED%^)
) else if %FAILED% equ 0 (
    echo [WARN] %WARNINGS% warnings ^(%PASSED% passed^)
) else (
    echo [ERROR] %FAILED% failed ^(%WARNINGS% warnings, %PASSED% passed^)
)
