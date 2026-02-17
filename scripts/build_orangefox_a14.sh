#!/bin/bash

# ==========================================
# OrangeFox Android 14 ELITE Builder v4
# LG V30 H930DS (joan)
# ==========================================

set -euo pipefail
trap 'echo ""; echo "❌ Build failed. See build.log"; exit 1' ERR

ROOT="$HOME/android14"
DEVICE="joan"
THREADS="$(nproc)"
LOGFILE="$ROOT/build.log"
DATE_TAG="$(date +%Y.%m.%d-%H%M)"
VERSION="A14-${DATE_TAG}"

mkdir -p "$ROOT"
cd "$ROOT"

exec > >(tee -a "$LOGFILE") 2>&1

echo "==============================================="
echo " OrangeFox Android 14 ELITE Builder v4"
echo " Device  : $DEVICE"
echo " Threads : $THREADS"
echo " Root    : $ROOT"
echo "==============================================="

# --------------------------------
# Disk Space Check (100GB Minimum)
# --------------------------------

AVAILABLE=$(df --output=avail -BG "$HOME" | tail -1 | tr -dc '0-9')

if [ "$AVAILABLE" -lt 100 ]; then
    echo ""
    echo "❌ ERROR: Minimum 100GB free space required."
    echo "   Available: ${AVAILABLE}GB"
    echo ""
    exit 1
fi

echo "Disk OK (${AVAILABLE}GB available)"

# --------------------------------
# Git Identity (Non-interactive)
# --------------------------------

git config --global user.name "Android Builder"
git config --global user.email "builder@local"

# --------------------------------
# Dependencies
# --------------------------------

echo ""
echo "Installing dependencies..."

sudo dpkg --add-architecture i386 || true
sudo apt update

sudo apt install -y \
    bc bison build-essential ccache curl flex g++-multilib gcc-multilib \
    git gnupg gperf imagemagick lib32z1-dev liblz4-tool \
    libncurses5-dev libssl-dev libxml2-utils lzop \
    pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev \
    openjdk-11-jdk python3

# --------------------------------
# Setup repo tool
# --------------------------------

mkdir -p "$HOME/bin"

if [ ! -f "$HOME/bin/repo" ]; then
    curl -s https://storage.googleapis.com/git-repo-downloads/repo > "$HOME/bin/repo"
    chmod a+x "$HOME/bin/repo"
fi

export PATH="$HOME/bin:$PATH"

# --------------------------------
# Initialize Android Base
# --------------------------------

if [ ! -d ".repo" ]; then
    echo ""
    echo "Initializing LineageOS 21 (Android 14)..."
    repo init -u https://github.com/LineageOS/android.git -b lineage-21.0 --depth=1
fi

# --------------------------------
# Sync (Low Disk Optimized)
# --------------------------------

echo ""
echo "Syncing source (optimized)..."
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

if [ ! -d "device/lge/$DEVICE" ]; then
    git clone https://github.com/LineageOS/android_device_lge_joan.git device/lge/$DEVICE
fi

if [ ! -d "kernel/lge/msm8998" ]; then
    git clone https://github.com/LineageOS/android_kernel_lge_msm8998.git kernel/lge/msm8998
fi

if [ ! -d "vendor/lge" ]; then
    git clone https://github.com/TheMuppets/proprietary_vendor_lge.git vendor/lge
fi

# --------------------------------
# Enable ccache
# --------------------------------

echo ""
echo "Configuring ccache..."

export USE_CCACHE=1
ccache -M 30G

# --------------------------------
# Build
# --------------------------------

echo ""
echo "Preparing build environment..."

source build/envsetup.sh
lunch lineage_${DEVICE}-eng

echo ""
echo "Building recovery image..."
mka recoveryimage -j"$THREADS"

# --------------------------------
# Package
# --------------------------------

OUTDIR="$ROOT/out/target/product/$DEVICE"
ZIPNAME="OrangeFox-${DEVICE}-${VERSION}.zip"

cd "$OUTDIR"

echo ""
echo "Packaging artifact..."

if [ ! -f recovery.img ]; then
    echo "❌ recovery.img not found!"
    exit 1
fi

zip -9 "$ZIPNAME" recovery.img

echo "Generating checksum..."
sha256sum "$ZIPNAME" > "$ZIPNAME.sha256"

echo "Embedding metadata..."
cat <<EOF > build_info.txt
Build Version: $VERSION
Build Date   : $(date)
Device       : $DEVICE
Threads Used : $THREADS
EOF

zip -u "$ZIPNAME" build_info.txt
rm build_info.txt

# --------------------------------
# Summary
# --------------------------------

echo ""
echo "==============================================="
echo " BUILD COMPLETE"
echo "-----------------------------------------------"
echo " Artifact : $OUTDIR/$ZIPNAME"
echo " Checksum : $OUTDIR/$ZIPNAME.sha256"
echo " Log File : $LOGFILE"
echo "==============================================="
echo ""
