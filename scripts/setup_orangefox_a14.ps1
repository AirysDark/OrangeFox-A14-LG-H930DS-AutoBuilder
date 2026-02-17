# ================================
# OrangeFox Android 14 Setup Script
# LG V30 (joan)
# ================================

$ROOT = "C:\Android14"
$REPO_DIR = "$ROOT\repo"
$THREADS = 4

Write-Host "`n=== Creating Base Directory ==="
New-Item -ItemType Directory -Force -Path $ROOT | Out-Null
Set-Location $ROOT

# ================================
# Install repo tool
# ================================
Write-Host "`n=== Downloading repo tool ==="
New-Item -ItemType Directory -Force -Path $REPO_DIR | Out-Null
Set-Location $REPO_DIR

Invoke-WebRequest `
    -Uri "https://storage.googleapis.com/git-repo-downloads/repo" `
    -OutFile "repo.py"

# ================================
# Initialize LineageOS 21 (Android 14)
# ================================
Write-Host "`n=== Initializing LineageOS 21 ==="
python repo.py init `
    -u https://github.com/LineageOS/android.git `
    -b lineage-21.0

# ================================
# Sync Source
# ================================
Write-Host "`n=== Syncing Source (This will take time) ==="
python repo.py sync -j$THREADS

# ================================
# Replace Recovery with OrangeFox
# ================================
Write-Host "`n=== Replacing Recovery with OrangeFox fox_14.1 ==="

Remove-Item -Recurse -Force "$ROOT\bootable\recovery"

git clone `
    -b fox_14.1 `
    https://gitlab.com/OrangeFox/bootable/Recovery.git `
    "$ROOT\bootable\recovery"

# ================================
# Clone Device Tree
# ================================
Write-Host "`n=== Cloning LG V30 Device Tree ==="
git clone `
    https://github.com/LineageOS/android_device_lge_joan.git `
    "$ROOT\device\lge\joan"

# ================================
# Clone Kernel
# ================================
Write-Host "`n=== Cloning Kernel ==="
git clone `
    https://github.com/LineageOS/android_kernel_lge_msm8998.git `
    "$ROOT\kernel\lge\msm8998"

# ================================
# Clone Vendor Blobs
# ================================
Write-Host "`n=== Cloning Vendor Blobs ==="
git clone `
    https://github.com/TheMuppets/proprietary_vendor_lge.git `
    "$ROOT\vendor\lge"

Write-Host "`n======================================="
Write-Host "✔ Android 14 Tree Prepared"
Write-Host "✔ OrangeFox fox_14.1 Injected"
Write-Host ""
Write-Host "Next Step:"
Write-Host "Build inside WSL:"
Write-Host "cd /mnt/c/Android14"
Write-Host "source build/envsetup.sh"
Write-Host "lunch lineage_joan-eng"
Write-Host "mka recoveryimage -j4"
Write-Host "======================================="
