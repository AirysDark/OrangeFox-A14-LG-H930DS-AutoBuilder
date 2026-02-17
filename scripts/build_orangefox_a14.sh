#!/bin/bash

# ==========================================
# OrangeFox Android 14 Fully Automatic Builder
# LG V30 H930DS (joan)
# ==========================================

set -e

ROOT=$HOME/android14
THREADS=$(nproc)
LOGFILE=$ROOT/build.log

echo "==============================================="
echo " OrangeFox Android 14 Automatic Builder"
echo " LG V30 H930DS (joan)"
echo "==============================================="

# --------------------------------
# Pre-flight checks
# --------------------------------

echo "=== Checking Disk Space ==="
AVAILABLE=$(df --output=avail -BG "$HOME" | tail -1 | tr -dc '0-9')

if [ "$AVAILABLE" -lt 80 ]; then
    echo "❌ ERROR: At least 80GB free space required."
    exit 1
fi

echo "Disk space OK (${AVAILABLE}GB available)"

echo "=== Detecting CPU Threads ==="
echo "Using $THREADS threads"

# --------------------------------
# Ensure Git Identity
# --------------------------------

echo "=== Setting Git Identity ==="
git config --global user.name "Android Builder"
git config --global user.email "builder@local"

# --------------------------------
# Install Dependencies
# --------------------------------

echo "=== Installing Dependencies ==="
sudo dpkg --add-architecture i386
sudo apt update

sudo apt install -y \
    bc bison build-essential ccache curl flex g++-multilib gcc-multilib \
    git gnupg gperf imagemagick lib32z1-dev liblz4-tool \
    libncurses5-dev libncurses-dev libsdl1.2-dev \
    libssl-dev libxml2 libxml2-utils lzop pngcrush rsync \
    schedtool squashfs-tools xsltproc zip zlib1g-dev \
    openjdk-11-jdk python3

# --------------------------------
# Setup repo tool
# --------------------------------

echo "=== Setting up repo tool ==="
mkdir -p ~/bin
curl -s https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
export PATH=~/bin:$PATH

# --------------------------------
# Prepare Build Directory
# --------------------------------

echo "=== Creating Build Directory ==="
mkdir -p "$ROOT"
cd "$ROOT"

# --------------------------------
# Initialize LineageOS 21
# --------------------------------

if [ ! -d ".repo" ]; then
    echo "=== Initializing LineageOS 21 (Android 14) ==="
    repo init -u https://github.com/LineageOS/android.git -b lineage-21.0
fi

# --------------------------------
# Sync Source
# --------------------------------

echo "=== Syncing Source ==="
repo sync -j"$THREADS" --force-sync --no-clone-bundle --no-tags

# --------------------------------
# Inject OrangeFox
# --------------------------------

echo "=== Injecting OrangeFox fox_14.1 ==="
rm -rf bootable/recovery
git clone -b fox_14.1 https://gitlab.com/OrangeFox/bootable/Recovery.git bootable/recovery

# --------------------------------
# Clone Device Tree
# --------------------------------

if [ ! -d "device/lge/joan" ]; then
    echo "=== Cloning Device Tree ==="
    git clone https://github.com/LineageOS/android_device_lge_joan.git device/lge/joan
fi

# --------------------------------
# Clone Kernel
# --------------------------------

if [ ! -d "kernel/lge/msm8998" ]; then
    echo "=== Cloning Kernel ==="
    git clone https://github.com/LineageOS/android_kernel_lge_msm8998.git kernel/lge/msm8998
fi

# --------------------------------
# Clone Vendor
# --------------------------------

if [ ! -d "vendor/lge" ]; then
    echo "=== Cloning Vendor Blobs ==="
    git clone https://github.com/TheMuppets/proprietary_vendor_lge.git vendor/lge
fi

# --------------------------------
# Enable ccache
# --------------------------------

echo "=== Enabling ccache ==="
export USE_CCACHE=1
ccache -M 30G

# --------------------------------
# Start Build
# --------------------------------

echo "=== Starting Build ==="
source build/envsetup.sh
lunch lineage_joan-eng

echo "=== Building Recovery (logging to build.log) ==="
mka recoveryimage -j"$THREADS" 2>&1 | tee "$LOGFILE"

echo ""
echo "==============================================="
echo " BUILD COMPLETE"
echo " Recovery Image:"
echo " $ROOT/out/target/product/joan/recovery.img"
echo " Log File:"
echo " $LOGFILE"
echo "==============================================="
