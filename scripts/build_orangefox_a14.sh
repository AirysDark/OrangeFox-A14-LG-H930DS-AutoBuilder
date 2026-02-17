#!/bin/bash

# ==============================
# OrangeFox Android 14 Build Script
# LG V30 (joan)
# ==============================

set -e

ROOT=$HOME/android14
THREADS=4

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

echo "=== Setting up repo tool ==="
mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
export PATH=~/bin:$PATH

echo "=== Creating Android 14 Directory ==="
mkdir -p $ROOT
cd $ROOT

echo "=== Initializing LineageOS 21 (Android 14) ==="
repo init -u https://github.com/LineageOS/android.git -b lineage-21.0

echo "=== Syncing Source (this will take a while) ==="
repo sync -j$THREADS --force-sync --no-clone-bundle --no-tags

echo "=== Replacing Recovery with OrangeFox fox_14.1 ==="
rm -rf bootable/recovery
git clone -b fox_14.1 https://gitlab.com/OrangeFox/bootable/Recovery.git bootable/recovery

echo "=== Cloning LG V30 Device Tree ==="
git clone https://github.com/LineageOS/android_device_lge_joan.git device/lge/joan

echo "=== Cloning Kernel ==="
git clone https://github.com/LineageOS/android_kernel_lge_msm8998.git kernel/lge/msm8998

echo "=== Cloning Vendor Blobs ==="
git clone https://github.com/TheMuppets/proprietary_vendor_lge.git vendor/lge

echo "=== Enabling ccache ==="
export USE_CCACHE=1
ccache -M 30G

echo "=== Starting Build ==="
source build/envsetup.sh
lunch lineage_joan-eng
mka recoveryimage -j$THREADS

echo "=================================="
echo "Build Complete."
echo "Recovery image location:"
echo "$ROOT/out/target/product/joan/recovery.img"
echo "=================================="
