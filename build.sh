#!/usr/bin/env bash
set -e

TARGET="${1:-tui}"

build_target() {
    UI="$1"
    OUT="day-trade-${UI}"
    
    # Append .exe extension on Windows / MSYS / Cygwin environments
    case "$(uname -s)" in
        CYGWIN*|MINGW*|MSYS*) OUT="${OUT}.exe" ;;
    esac

    echo "[BUILD] Compiling ${UI} -> ${OUT}"
    odin build . -out:"${OUT}" -define:UI="${UI}"
    echo "[OK] Successfully built ${OUT}"
}

# Convert TARGET to lowercase for case-insensitive matching
TARGET_LOWER=$(echo "$TARGET" | tr '[:upper:]' '[:lower:]')

case "$TARGET_LOWER" in
    all)
        build_target "tui"
        build_target "iup"
        build_target "gtk"
        ;;
    gtk|gtk4)
        build_target "gtk"
        ;;
    iup)
        build_target "iup"
        ;;
    tui)
        build_target "tui"
        ;;
    *)
        echo "[ERROR] Unknown target: ${TARGET}"
        echo "Usage: ./build.sh [tui | iup | gtk | all]"
        exit 1
        ;;
esac
