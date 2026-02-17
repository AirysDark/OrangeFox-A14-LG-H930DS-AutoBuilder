#!/bin/bash

# ==========================================
# OrangeFox Android 14 LAUNCHER v3
# LG V30 H930DS (joan)
# ==========================================

set -u
set -o pipefail

ROOT="$HOME/android14"
DEVICE="joan"
THREADS="$(nproc)"
LOGFILE="$ROOT/local_runner.log"
DATE_TAG="$(date +%Y.%m.%d-%H%M)"
VERSION="A14-${DATE_TAG}"
CCACHE_SIZE="30G"

mkdir -p "$ROOT"

# --------------------------------
# Verify Linux Environment
# --------------------------------

if [[ "$(uname -s)" != "Linux" ]]; then
    echo "❌ This script must be run inside Linux / WSL."
    exit 1
fi

# --------------------------------
# Helper: ensure repo tool exists
# --------------------------------

ensure_repo() {
    if ! command -v repo >/dev/null 2>&1; then
        echo ""
        echo "❌ repo tool not found."
        echo ""
        echo "Install it with:"
        echo "mkdir -p ~/bin"
        echo "curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo"
        echo "chmod +x ~/bin/repo"
        echo "export PATH=~/bin:\$PATH"
        echo ""
        return 1
    fi
    return 0
}

# --------------------------------
# Build Core
# --------------------------------

direct_build() {

    ensure_repo || return

    echo ""
    echo "=== CLIENT MODE: Direct Build ==="
    echo ""

    cd "$ROOT" || return

    exec > >(tee -a "$LOGFILE") 2>&1

    if [ ! -d ".repo" ]; then
        repo init -u https://github.com/LineageOS/android.git -b lineage-21.0 --depth=1
    fi

    repo sync -c --no-tags --prune --optimized-fetch -j"$THREADS"

    rm -rf bootable/recovery
    git clone -b fox_14.1 https://gitlab.com/OrangeFox/bootable/Recovery.git bootable/recovery

    [ ! -d "device/lge/$DEVICE" ] && \
        git clone https://github.com/LineageOS/android_device_lge_joan.git device/lge/$DEVICE

    [ ! -d "kernel/lge/msm8998" ] && \
        git clone https://github.com/LineageOS/android_kernel_lge_msm8998.git kernel/lge/msm8998

    [ ! -d "vendor/lge" ] && \
        git clone https://github.com/TheMuppets/proprietary_vendor_lge.git vendor/lge

    export USE_CCACHE=1
    ccache -M "$CCACHE_SIZE"

    source build/envsetup.sh || return
    lunch lineage_${DEVICE}-eng
    mka recoveryimage -j"$THREADS"

    package_artifact
}

runner_build() {

    ensure_repo || return

    echo ""
    echo "=== SERVER MODE: Runner Pipeline ==="
    echo ""

    # Runner mode can add future features
    direct_build
}

# --------------------------------
# Packaging
# --------------------------------

package_artifact() {

    OUTDIR="$ROOT/out/target/product/$DEVICE"
    ZIPNAME="OrangeFox-${DEVICE}-${VERSION}.zip"

    cd "$OUTDIR" || return

    if [ ! -f recovery.img ]; then
        echo "❌ recovery.img not found!"
        return
    fi

    zip -9 "$ZIPNAME" recovery.img
    sha256sum "$ZIPNAME" > "$ZIPNAME.sha256"

    echo ""
    echo "==============================================="
    echo " BUILD COMPLETE"
    echo " Artifact : $OUTDIR/$ZIPNAME"
    echo "==============================================="
}

# --------------------------------
# Options Menu
# --------------------------------

options_menu() {

    while true; do
        clear
        echo "==============================================="
        echo " OPTIONS"
        echo "==============================================="
        echo ""
        echo "1) Change Thread Count (Current: $THREADS)"
        echo "2) Change ccache Size (Current: $CCACHE_SIZE)"
        echo "3) Back"
        echo ""

        read -p "Select option: " opt

        case "$opt" in
            1)
                read -p "Enter thread count: " new_threads
                if [[ "$new_threads" =~ ^[0-9]+$ ]]; then
                    THREADS="$new_threads"
                fi
                ;;
            2)
                read -p "Enter ccache size (e.g. 20G): " new_ccache
                CCACHE_SIZE="$new_ccache"
                ;;
            3)
                break
                ;;
        esac
    done
}

# --------------------------------
# Main Menu
# --------------------------------

while true; do

    clear
    echo "==============================================="
    echo " OrangeFox Android 14 Launcher"
    echo " LG V30 (joan)"
    echo "==============================================="
    echo ""
    echo "1) Client Mode (Direct Build)"
    echo "2) Server Mode (Runner Build)"
    echo "3) Options"
    echo "4) Exit"
    echo ""

    read -p "Select option: " choice

    case "$choice" in
        1) direct_build ;;
        2) runner_build ;;
        3) options_menu ;;
        4) exit 0 ;;
        *) echo "Invalid option"; sleep 1 ;;
    esac

    echo ""
    read -p "Press Enter to continue..."
done
