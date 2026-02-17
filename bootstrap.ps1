# ==============================================
# OrangeFox Bootstrap Loader
# ==============================================

$RepoOwner = "AirysDark"
$RepoName  = "OrangeFox-A14-LG-H930DS-AutoBuilder"
$BootUrl   = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/main/boot.ps1"
$TempBoot  = "$env:TEMP\orangefox_boot.ps1"

# ------------------------------------------------
# ADMIN CHECK
# ------------------------------------------------

$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {

    Write-Host ""
    Write-Host "==============================================="
    Write-Host " ADMINISTRATOR PRIVILEGES REQUIRED"
    Write-Host "==============================================="
    Write-Host ""
    Write-Host "Please reopen PowerShell using:"
    Write-Host "Run as Administrator"
    Write-Host ""
    Pause
    exit
}

# ------------------------------------------------
# CLEAN OLD TEMP
# ------------------------------------------------

try {
    Remove-Item $TempBoot -Force -ErrorAction SilentlyContinue
} catch {}

# ------------------------------------------------
# DOWNLOAD BOOT CORE
# ------------------------------------------------

try {
    Invoke-WebRequest $BootUrl -OutFile $TempBoot -UseBasicParsing
}
catch {
    Write-Host "❌ Failed to download boot core."
    Pause
    exit
}

# ------------------------------------------------
# EXECUTE BOOT CORE
# ------------------------------------------------

powershell -ExecutionPolicy Bypass -File $TempBoot
