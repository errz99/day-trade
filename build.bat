@echo off
setlocal enabledelayedexpansion

set "TARGET=%~1"
if "%TARGET%"=="" set "TARGET=tui"

if /i "%TARGET%"=="all" (
    call :build_target tui
    call :build_target iup
    call :build_target gtk
    call :build_target winforms
    exit /b %ERRORLEVEL%
)

if /i "%TARGET%"=="gtk4" set "TARGET=gtk"

if /i "%TARGET%"=="gtk" (
    call :build_target gtk
) else if /i "%TARGET%"=="iup" (
    call :build_target iup
) else if /i "%TARGET%"=="winforms" (
    call :build_target winforms
) else if /i "%TARGET%"=="tui" (
    call :build_target tui
) else (
    echo [ERROR] Unknown target: %TARGET%
    echo Usage: build [tui ^| iup ^| gtk ^| winforms ^| all]
    exit /b 1
)

exit /b 0

:build_target
set "UI=%~1"
set "OUT=day-trade-%UI%.exe"
echo [BUILD] Compiling %UI% -^> %OUT%

rem GUI targets (iup/gtk/winforms) run as Windows applications so no console
rem window appears; the tui stays a console application (default console subsystem).
set "SUBSYS="
if /i "%UI%"=="iup" set "SUBSYS=-subsystem:windows"
if /i "%UI%"=="gtk" set "SUBSYS=-subsystem:windows"
if /i "%UI%"=="winforms" set "SUBSYS=-subsystem:windows"

odin build . -out:%OUT% -define:UI="%UI%" %SUBSYS%
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Build failed for %UI%
    exit /b %ERRORLEVEL%
)
echo [OK] Successfully built %OUT%

rem Embed the manifest into the executable when one exists next to it
if exist "%OUT%.manifest" (
    if not exist "_embed_manifest.exe" (
        odin build tools/embed_manifest -out:_embed_manifest.exe
        if errorlevel 1 exit /b %errorlevel%
    )
    _embed_manifest.exe "%OUT%" "%OUT%.manifest"
    if errorlevel 1 (
        echo [ERROR] Manifest embedding failed for %UI%
        exit /b %errorlevel%
    )
    echo [OK] Manifest embedded into %OUT%
)
exit /b 0
