#!/bin/bash

# ==========================================
# OrangeFox Android 14 ELITE Builder v2
# LG V30 H930DS (joan)
# ==========================================

set -e
trap 'echo "❌ Build failed. See build.log"; exit 1' ERR

ROOT=$HOME/android14
DEVICE="joan"
THREADS=$(nproc)
LOGFILE=$ROOT/build.log
VERSION="A14-$(date +%Y.%m.%d)-$(git rev-parse --short HEAD 2>/dev/null || echo initial)"

mkdir -p "$ROOT"
cd "$ROOT"

exec > >(tee -a "$LOGFILE") 2>&1

echo "==============================================="
echo " OrangeFox Android 14 ELITE Builder"
echo " Device: $DEVICE"
echo " Threads: $THREADS"
echo "==============================================="

# --------------------------------
# Disk Space Check
# --------------------------------

AVAILABLE=$(df --output=avail -BG "$ROOT" | tail -1 | tr -dc '0-9')

if [ "$AVAILABLE" -lt 100 ]; then
    echo "❌ Minimum 100GB free space required."
    exit 1
fi

echo "Disk OK (${AVAILABLE}GB available)"

# --------------------------------
# Git Identity
# --------------------------------

git config --global user.name "Android Builder"
git config --global user.email "builder@local"

# --------------------------------
# Dependencies
# --------------------------------

echo "Installing dependencies..."
sudo dpkg --add-architecture i386
sudo apt update

sudo apt install -y \
    bc bison build-essential ccache curl flex g++-multilib gcc-multilib \
    git gnupg gperf imagemagick lib32z1-dev liblz4-tool \
    libncurses5-dev libssl-dev libxml2-utils lzop \
    pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev \
    openjdk-11-jdk python3

# --------------------------------
# Setup repo
# --------------------------------

mkdir -p ~/bin
if [ ! -f ~/bin/repo ]; then
    curl -s https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
    chmod a+x ~/bin/repo
fi

export PATH=~/bin:$PATH

# --------------------------------
# Initialize Android Base
# --------------------------------

if [ ! -d ".repo" ]; then
    echo "Initializing LineageOS 21..."
    repo init -u https://github.com/LineageOS/android.git -b lineage-21.0 --depth=1
fi

# --------------------------------
# Sync (Optimized)
# --------------------------------

echo "Syncing source..."
repo sync -c --optimized-fetch --prune -j"$THREADS"

# --------------------------------
# Inject OrangeFox
# --------------------------------

if [ -d "bootable/recovery" ]; then
    rm -rf bootable/recovery
fi

git clone -b fox_14.1 https://gitlab.com/OrangeFox/bootable/Recovery.git bootable/recovery

# --------------------------------
# Device / Kernel / Vendor
# --------------------------------

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

export USE_CCACHE=1
ccache -M 40G

# --------------------------------
# Build
# --------------------------------

source build/envsetup.sh
lunch lineage_${DEVICE}-eng

echo "Building recovery..."
mka recoveryimage -j"$THREADS"

# --------------------------------
# Package
# --------------------------------

OUTDIR=$ROOT/out/target/product/$DEVICE
ZIPNAME="OrangeFox-${DEVICE}-${VERSION}.zip"

cd "$OUTDIR"

echo "Creating package..."
zip "$ZIPNAME" recovery.img

echo "Generating checksum..."
sha256sum "$ZIPNAME" > "$ZIPNAME.sha256"

echo "Embedding build metadata..."
echo "Build Version: $VERSION" > build_info.txt
echo "Build Date: $(date)" >> build_info.txt
echo "Device: $DEVICE" >> build_info.txt

zip -u "$ZIPNAME" build_info.txt

# --------------------------------
# Complete
# --------------------------------

echo ""
echo "==============================================="
echo " BUILD COMPLETE"
echo " Artifact: $OUTDIR/$ZIPNAME"
echo " Checksum: $OUTDIR/$ZIPNAME.sha256"
echo " Log File: $LOGFILE"
echo "==============================================="
