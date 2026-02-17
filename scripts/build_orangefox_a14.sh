#!/bin/bash

# ==============================
# OrangeFox Android 14 Build Script
# LG V30 (joan)
# ==============================

set -e

echo "==============================================="
echo " OrangeFox Android 14 Builder"
echo " LG V30 H930DS (joan)"
echo "==============================================="
echo ""

# --------------------------------
# Ask for Build Directory
# --------------------------------
read -p "Enter build directory [default: \$HOME/android14]: " USER_ROOT
ROOT=${USER_ROOT:-$HOME/android14}

# --------------------------------
# Ask for Thread Count
# --------------------------------
read -p "Enter build threads (CPU cores) [default: 4]: " USER_THREADS
THREADS=${USER_THREADS:-4}

echo ""
echo "Build Directory: $ROOT"
echo "Threads: $THREADS"
echo ""
read -p "Continue? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
    echo "Aborted."
    exit 1
fi

# --------------------------------
# Git Identity Check
# --------------------------------
echo ""
echo "=== Checking Git Identity ==="

if ! git config --global user.name >/dev/null 2>&1; then
    read -p "Enter your Git name: " gitname
    git config --global user.name "$gitname"
fi

if ! git config --global user.email >/dev/null 2>&1; then
    read -p "Enter your Git email: " gitemail
    git config --global user.email "$gitemail"
fi

echo "Git identity configured."
echo ""

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
# Setup repo
# --------------------------------
echo "=== Setting up repo tool ==="
mkdir -p ~/bin
curl -s https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
export PATH=~/bin:$PATH

# --------------------------------
# Create Build Directory
# --------------------------------
echo "=== Creating Android 14 Directory ==="
mkdir -p "$ROOT"
cd "$ROOT"

# --------------------------------
# Initialize LineageOS
# --------------------------------
echo "=== Initializing LineageOS 21 (Android 14) ==="
repo init -u https://github.com/LineageOS/android.git -b lineage-21.0

# --------------------------------
# Sync Source
# --------------------------------
echo ""
echo "⚠ This will download 40-60GB."
read -p "Proceed with repo sync? (y/n): " syncconfirm
if [[ "$syncconfirm" != "y" ]]; then
    echo "Aborted."
    exit 1
fi

echo "=== Syncing Source ==="
repo sync -j"$THREADS" --force-sync --no-clone-bundle --no-tags

# --------------------------------
# Inject OrangeFox
# --------------------------------
echo "=== Replacing Recovery with OrangeFox fox_14.1 ==="
rm -rf bootable/recovery
git clone -b fox_14.1 https://gitlab.com/OrangeFox/bootable/Recovery.git bootable/recovery

# --------------------------------
# Clone Device Tree
# --------------------------------
echo "=== Cloning LG V30 Device Tree ==="
git clone https://github.com/LineageOS/android_device_lge_joan.git device/lge/joan

# --------------------------------
# Clone Kernel
# --------------------------------
echo "=== Cloning Kernel ==="
git clone https://github.com/LineageOS/android_kernel_lge_msm8998.git kernel/lge/msm8998

# --------------------------------
# Clone Vendor
# --------------------------------
echo "=== Cloning Vendor Blobs ==="
git clone https://github.com/TheMuppets/proprietary_vendor_lge.git vendor/lge

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
mka recoveryimage -j"$THREADS"

echo ""
echo "=================================="
echo " Build Complete."
echo " Recovery image location:"
echo " $ROOT/out/target/product/joan/recovery.img"
echo "=================================="
