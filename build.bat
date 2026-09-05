@echo off
setlocal enabledelayedexpansion

set "TARGET=%~1"
if "%TARGET%"=="" set "TARGET=tui"

if /i "%TARGET%"=="all" (
    call :build_target tui
    call :build_target iup
    call :build_target gtk
    exit /b %ERRORLEVEL%
)

if /i "%TARGET%"=="gtk4" set "TARGET=gtk"

if /i "%TARGET%"=="gtk" (
    call :build_target gtk
) else if /i "%TARGET%"=="iup" (
    call :build_target iup
) else if /i "%TARGET%"=="tui" (
    call :build_target tui
) else (
    echo [ERROR] Unknown target: %TARGET%
    echo Usage: build [tui ^| iup ^| gtk ^| all]
    exit /b 1
)

exit /b 0

:build_target
set "UI=%~1"
set "OUT=day-trade-%UI%.exe"
echo [BUILD] Compiling %UI% -^> %OUT%
odin build . -out:%OUT% -define:UI="%UI%"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Build failed for %UI%
    exit /b %ERRORLEVEL%
)
echo [OK] Successfully built %OUT%
exit /b 0
