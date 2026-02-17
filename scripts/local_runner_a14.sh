#!/bin/bash

# ==========================================
# OrangeFox Android 14 LOCAL BUILD
# LG V30 H930DS (joan)
# ==========================================

set -euo pipefail
trap 'echo ""; echo "❌ Build failed. See local_runner.log"; exit 1' ERR

ROOT="$HOME/android14"
DEVICE="joan"
THREADS="$(nproc)"
LOGFILE="$ROOT/local_runner.log"
DATE_TAG="$(date +%Y.%m.%d-%H%M)"
VERSION="A14-${DATE_TAG}"

mkdir -p "$ROOT"
cd "$ROOT"

exec > >(tee -a "$LOGFILE") 2>&1

echo "==============================================="
echo " OrangeFox Android 14 LOCAL BUILD"
echo " Device  : $DEVICE"
echo " Threads : $THREADS"
echo " Root    : $ROOT"
echo "==============================================="

# --------------------------------
# Disk Check
# --------------------------------

AVAILABLE=$(df --output=avail -BG "$HOME" | tail -1 | tr -dc '0-9')

if [ "$AVAILABLE" -lt 50 ]; then
    echo "❌ Minimum 50GB required."
    exit 1
fi

echo "Disk OK (${AVAILABLE}GB available)"

# --------------------------------
# Initialize Repo
# --------------------------------

if [ ! -d ".repo" ]; then
    echo "Initializing LineageOS 21..."
    repo init -u https://github.com/LineageOS/android.git -b lineage-21.0 --depth=1
fi

# --------------------------------
# Sync Source
# --------------------------------

echo "Syncing source..."
repo sync -c --no-tags --prune --optimized-fetch -j"$THREADS"

# --------------------------------
# Inject OrangeFox
# --------------------------------

echo "Injecting OrangeFox..."
rm -rf bootable/recovery
git clone -b fox_14.1 https://gitlab.com/OrangeFox/bootable/Recovery.git bootable/recovery

# --------------------------------
# Device / Kernel / Vendor
# --------------------------------

echo "Cloning device trees..."

[ ! -d "device/lge/$DEVICE" ] && git clone https://github.com/LineageOS/android_device_lge_joan.git device/lge/$DEVICE
[ ! -d "kernel/lge/msm8998" ] && git clone https://github.com/LineageOS/android_kernel_lge_msm8998.git kernel/lge/msm8998
[ ! -d "vendor/lge" ] && git clone https://github.com/TheMuppets/proprietary_vendor_lge.git vendor/lge

# --------------------------------
# Build
# --------------------------------

echo "Building recovery..."

export USE_CCACHE=1
ccache -M 30G

source build/envsetup.sh
lunch lineage_${DEVICE}-eng
mka recoveryimage -j"$THREADS"

# --------------------------------
# Package
# --------------------------------

OUTDIR="$ROOT/out/target/product/$DEVICE"
ZIPNAME="OrangeFox-${DEVICE}-${VERSION}.zip"

cd "$OUTDIR"

if [ ! -f recovery.img ]; then
    echo "❌ recovery.img not found!"
    exit 1
fi

zip -9 "$ZIPNAME" recovery.img
sha256sum "$ZIPNAME" > "$ZIPNAME.sha256"

echo ""
echo "==============================================="
echo " BUILD COMPLETE"
echo " Artifact : $OUTDIR/$ZIPNAME"
echo " Checksum : $OUTDIR/$ZIPNAME.sha256"
echo " Log File : $LOGFILE"
echo "==============================================="
