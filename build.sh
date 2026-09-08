#!/usr/bin/env bash
set -e

TARGET="${1:-tui}"

# Only Windows/MSYS shells can build the winforms target
IS_WINDOWS_SHELL=0
case "$(uname -s)" in
    CYGWIN*|MINGW*|MSYS*) IS_WINDOWS_SHELL=1 ;;
esac

build_target() {
    UI="$1"
    OUT="day-trade-${UI}"

    # GUI targets (iup/gtk/winforms) run as Windows applications on Windows/MSYS
    # shells, so no console window appears; the tui stays a console application.
    SUBSYS=""
    if [ "${IS_WINDOWS_SHELL}" = "1" ]; then
        OUT="${OUT}.exe"
        if [ "${UI}" = "iup" ] || [ "${UI}" = "gtk" ] || [ "${UI}" = "winforms" ]; then
            SUBSYS="-subsystem:windows"
        fi
    fi

    echo "[BUILD] Compiling ${UI} -> ${OUT}"
    odin build . -out:"${OUT}" -define:UI="${UI}" ${SUBSYS}
    echo "[OK] Successfully built ${OUT}"

    # Embed the manifest into the executable when one exists next to it
    if [ "${IS_WINDOWS_SHELL}" = "1" ] && [ -f "${OUT}.manifest" ]; then
        if [ ! -f "_embed_manifest.exe" ]; then
            odin build tools/embed_manifest -out:_embed_manifest.exe
        fi
        ./_embed_manifest.exe "${OUT}" "${OUT}.manifest"
        echo "[OK] Manifest embedded into ${OUT}"
    fi
}

# Convert TARGET to lowercase for case-insensitive matching
TARGET_LOWER=$(echo "$TARGET" | tr '[:upper:]' '[:lower:]')

case "$TARGET_LOWER" in
    all)
        build_target "tui"
        build_target "iup"
        build_target "gtk"
        if [ "${IS_WINDOWS_SHELL}" = "1" ]; then
            build_target "winforms"
        fi
        ;;
    gtk|gtk4)
        build_target "gtk"
        ;;
    iup)
        build_target "iup"
        ;;
    winforms)
        build_target "winforms"
        ;;
    tui)
        build_target "tui"
        ;;
    *)
        echo "[ERROR] Unknown target: ${TARGET}"
        echo "Usage: ./build.sh [tui | iup | gtk | winforms | all]"
        exit 1
        ;;
esac
