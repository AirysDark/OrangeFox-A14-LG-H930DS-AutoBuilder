# ==============================================
# OrangeFox Bootstrap Loader v2
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
# SILENT TEMP CLEANUP
# ------------------------------------------------

try {

    $temp = $env:TEMP

    # Remove old boot loader copy
    if (Test-Path $TempBoot) {
        Remove-Item $TempBoot -Force -ErrorAction SilentlyContinue
    }

    # Remove previous OrangeFox temp project folders
    Get-ChildItem $temp -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "OrangeFox*" -or $_.Name -like "*A14*" } |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    # Remove previous temp shell scripts
    Get-ChildItem $temp -Filter "*_a14.sh" -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue

}
catch {
    # Silent cleanup failure allowed
}

# ------------------------------------------------
# DOWNLOAD FRESH BOOT CORE
# ------------------------------------------------

try {
    Invoke-WebRequest $BootUrl -OutFile $TempBoot -UseBasicParsing
}
catch {
    Write-Host ""
    Write-Host "❌ Failed to download boot core."
    Pause
    exit
}

# ------------------------------------------------
# EXECUTE BOOT CORE
# ------------------------------------------------

Start-Process powershell `
    -ArgumentList "-ExecutionPolicy Bypass -File `"$TempBoot`"" `
    -Wait
