# ==============================================
# OrangeFox Android 14 Pro Bootstrap Installer
# LG V30 H930DS (joan)
# ==============================================

function Require-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent() `
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

        Write-Host "Restarting as Administrator..."
        Start-Process powershell `
            -Verb runAs `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/AirysDark/OrangeFox-A14-LG-H930DS-AutoBuilder/main/bootstrap.ps1 | iex`""
        exit
    }
}

Require-Admin

Clear-Host
Write-Host "==============================================="
Write-Host " OrangeFox Android 14 PRO Installer"
Write-Host " LG V30 H930DS (joan)"
Write-Host "==============================================="
Write-Host ""

# --------------------------------------------
# Windows Disk Check
# --------------------------------------------

$drive = Get-PSDrive C
$freeGB = [math]::Round($drive.Free / 1GB)

if ($freeGB -lt 120) {
    Write-Host "❌ At least 120GB free space required."
    exit
}

Write-Host "Disk Space OK ($freeGB GB free)"
Write-Host ""

Write-Host "1) Windows (Download Source Only)"
Write-Host "2) WSL Ubuntu (Full Build)"
Write-Host ""

$choice = Read-Host "Select option (1 or 2)"

$baseUrl = "https://raw.githubusercontent.com/AirysDark/OrangeFox-A14-LG-H930DS-AutoBuilder/main/scripts"
$tempFile = "$env:TEMP\of_temp_script"

# ============================================================
# OPTION 1 – Windows Only
# ============================================================

if ($choice -eq "1") {

    Write-Host "⚠ Windows cannot build Android."
    Write-Host "Preparing source only..."
    $scriptUrl = "$baseUrl/setup_orangefox_a14.ps1"
    $localScript = "$tempFile.ps1"

    Invoke-WebRequest $scriptUrl -OutFile $localScript
    & $localScript
    Remove-Item $localScript -Force
    exit
}

# ============================================================
# OPTION 2 – WSL Full Build
# ============================================================

elseif ($choice -eq "2") {

    Write-Host "Preparing WSL Environment..."

    # Enable required Windows features
    Write-Host "Enabling WSL + Virtual Machine Platform..."
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null

    # Install WSL if missing
    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        Write-Host "Installing WSL..."
        wsl --install -d Ubuntu
        Write-Host "Reboot required. Please restart Windows and re-run."
        exit
    }

    wsl --set-default-version 2

    # Ensure Ubuntu exists
    $distros = wsl -l -q
    if ($distros -notmatch "Ubuntu") {
        Write-Host "Installing Ubuntu..."
        wsl --install -d Ubuntu
        Write-Host "Reboot required. Please restart Windows and re-run."
        exit
    }

    Write-Host "WSL + Ubuntu Ready."

    # --------------------------------------------
    # Configure .wslconfig Automatically
    # --------------------------------------------

    $configPath = "$env:USERPROFILE\.wslconfig"

    if (-not (Test-Path $configPath)) {
        Write-Host "Configuring WSL memory settings..."
        @"
[wsl2]
memory=6GB
processors=4
swap=8GB
"@ | Out-File $configPath -Encoding ASCII
    }

    wsl --shutdown

    # --------------------------------------------
    # Download Linux Build Script
    # --------------------------------------------

    $scriptUrl = "$baseUrl/build_orangefox_a14.sh"
    $localScript = "$tempFile.sh"

    Invoke-WebRequest $scriptUrl -OutFile $localScript

    $wslPath = "/mnt/c/" + ($localScript.Substring(3) -replace '\\','/')

    Write-Host "Starting Linux build..."

    wsl bash -c "chmod +x $wslPath"
    wsl bash -c "$wslPath"

    Remove-Item $localScript -Force

    Write-Host ""
    Write-Host "Build process launched inside WSL."
    Write-Host ""
}

else {
    Write-Host "Invalid selection."
}
