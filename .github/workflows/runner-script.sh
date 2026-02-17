#!/bin/bash

# ==========================================
# OrangeFox Android 14 Runner Script
# Core Build + Sync Logic
# ==========================================

set -euo pipefail
trap 'echo ""; echo "❌ Runner failed."; exit 1' ERR

ROOT="$HOME/android14"
DEVICE="joan"
THREADS="$(nproc)"

cd "$ROOT"

echo ""
echo "==============================================="
echo " RUNNER SCRIPT STARTED"
echo "==============================================="

# --------------------------------
# Initialize Android Base
# --------------------------------

if [ ! -d ".repo" ]; then
    echo "Initializing LineageOS 21 (Android 14)..."
    repo init -u https://github.com/LineageOS/android.git -b lineage-21.0 --depth=1
fi

# --------------------------------
# Sync
# --------------------------------

echo ""
echo "Syncing source..."
repo sync -c --no-tags --prune --optimized-fetch -j"$THREADS"

# --------------------------------
# Inject OrangeFox
# --------------------------------

echo ""
echo "Injecting OrangeFox..."

rm -rf bootable/recovery
git clone -b fox_14.1 https://gitlab.com/OrangeFox/bootable/Recovery.git bootable/recovery

# --------------------------------
# Device / Kernel / Vendor
# --------------------------------

echo ""
echo "Cloning device trees..."

[ ! -d "device/lge/$DEVICE" ] && \
git clone https://github.com/LineageOS/android_device_lge_joan.git device/lge/$DEVICE

[ ! -d "kernel/lge/msm8998" ] && \
git clone https://github.com/LineageOS/android_kernel_lge_msm8998.git kernel/lge/msm8998

[ ! -d "vendor/lge" ] && \
git clone https://github.com/TheMuppets/proprietary_vendor_lge.git vendor/lge

# --------------------------------
# Build
# --------------------------------

echo ""
echo "Preparing build environment..."

export USE_CCACHE=1
ccache -M 30G

source build/envsetup.sh
lunch lineage_${DEVICE}-eng

echo ""
echo "Building recovery..."
mka recoveryimage -j"$THREADS"

echo ""
echo "Runner build stage complete."
