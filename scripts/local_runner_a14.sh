#!/bin/bash

# ==========================================
# OrangeFox Android 14 LOCAL RUNNER MODE
# LG V30 H930DS (joan)
# ==========================================

set -euo pipefail
trap 'echo ""; echo "❌ Pipeline failed."; exit 1' ERR

ROOT="$HOME/android14"
DEVICE="joan"
THREADS="$(nproc)"
LOGFILE="$ROOT/local_runner.log"
DATE_TAG="$(date +%Y.%m.%d-%H%M)"
VERSION="A14-${DATE_TAG}"

mkdir -p "$ROOT"
cd "$ROOT"

exec > >(tee -a "$LOGFILE") 2>&1

TOTAL_STEPS=6
CURRENT_STEP=0

progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    echo ""
    echo "-----------------------------------------------"
    echo "STEP $CURRENT_STEP/$TOTAL_STEPS — $1"
    echo "Progress: ${PERCENT}%"
    echo "-----------------------------------------------"
}

echo "==============================================="
echo " OrangeFox Android 14 LOCAL RUNNER"
echo " Device  : $DEVICE"
echo " Threads : $THREADS"
echo "==============================================="

# --------------------------------
# Step 1 — Disk Check
# --------------------------------

progress "Checking Disk Space"

AVAILABLE=$(df --output=avail -BG "$HOME" | tail -1 | tr -dc '0-9')

if [ "$AVAILABLE" -lt 50 ]; then
    echo "❌ Minimum 50GB required."
    exit 1
fi

echo "Disk OK (${AVAILABLE}GB available)"

# --------------------------------
# Step 2 — Initialize Repo
# --------------------------------

progress "Initializing Repo"

if [ ! -d ".repo" ]; then
    repo init -u https://github.com/LineageOS/android.git -b lineage-21.0 --depth=1
fi

# --------------------------------
# Step 3 — Sync Source
# --------------------------------

progress "Syncing Source"

repo sync -c --no-tags --prune --optimized-fetch -j"$THREADS"

# --------------------------------
# Step 4 — Inject OrangeFox
# --------------------------------

progress "Injecting OrangeFox"

rm -rf bootable/recovery
git clone -b fox_14.1 https://gitlab.com/OrangeFox/bootable/Recovery.git bootable/recovery

# --------------------------------
# Step 5 — Device Trees
# --------------------------------

progress "Cloning Device Trees"

[ ! -d "device/lge/$DEVICE" ] && git clone https://github.com/LineageOS/android_device_lge_joan.git device/lge/$DEVICE
[ ! -d "kernel/lge/msm8998" ] && git clone https://github.com/LineageOS/android_kernel_lge_msm8998.git kernel/lge/msm8998
[ ! -d "vendor/lge" ] && git clone https://github.com/TheMuppets/proprietary_vendor_lge.git vendor/lge

# --------------------------------
# Step 6 — Build Recovery
# --------------------------------

progress "Building Recovery"

export USE_CCACHE=1
ccache -M 30G

source build/envsetup.sh
lunch lineage_${DEVICE}-eng
mka recoveryimage -j"$THREADS"

OUTDIR="$ROOT/out/target/product/$DEVICE"
ZIPNAME="OrangeFox-${DEVICE}-${VERSION}.zip"

cd "$OUTDIR"
zip -9 "$ZIPNAME" recovery.img
sha256sum "$ZIPNAME" > "$ZIPNAME.sha256"

echo ""
echo "==============================================="
echo " LOCAL RUNNER BUILD COMPLETE"
echo " Artifact : $OUTDIR/$ZIPNAME"
echo " Checksum : $OUTDIR/$ZIPNAME.sha256"
echo " Log File : $LOGFILE"
echo "==============================================="
