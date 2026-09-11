@echo off
setlocal enabledelayedexpansion

set "TARGET=%~1"
if "%TARGET%"=="" set "TARGET=gtk"

if /i "%TARGET%"=="all" (
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
) else (
    echo [ERROR] Unknown target: %TARGET%
    echo Usage: build [iup ^| gtk ^| winforms ^| all]
    exit /b 1
)

exit /b 0

:build_target
set "UI=%~1"
set "OUT=day-trade-%UI%.exe"
echo [BUILD] Compiling %UI% -^> %OUT%

rem All targets are GUI applications (Windows subsystem so no console window
rem appears). The text UI is available at runtime with -t.
set "SUBSYS=-subsystem:windows"

odin build . -out:%OUT% -define:UI="%UI%" %SUBSYS%
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Build failed for %UI%
    exit /b %ERRORLEVEL%
)
echo [OK] Successfully built %OUT%

rem Embed the manifest into the executable when one exists next to it
if exist "tools/%OUT%.manifest" (
    if not exist "_embed_manifest.exe" (
        odin build tools/embed_manifest -out:_embed_manifest.exe
        if errorlevel 1 exit /b %errorlevel%
    )
    _embed_manifest.exe "%OUT%" "tools/%OUT%.manifest"
    if errorlevel 1 (
        echo [ERROR] Manifest embedding failed for %UI%
        exit /b %errorlevel%
    )
    echo [OK] Manifest embedded into %OUT%
)
exit /b 0
