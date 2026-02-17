# ==============================================
# OrangeFox Android 14 ELITE Bootstrap v3
# ==============================================

$RepoOwner    = "AirysDark"
$RepoName     = "OrangeFox-A14-LG-H930DS-AutoBuilder"
$BootstrapUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/main/bootstrap.ps1"
$ScriptBase   = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/main/scripts"
$Version      = "3.0.0"
$LogFile      = "$env:TEMP\of_bootstrap.log"
$TempScript   = "$env:TEMP\of_bootstrap_elevated.ps1"

Start-Transcript -Path $LogFile -Append | Out-Null

function Require-Admin {

    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {

        Write-Host "Restarting as Administrator..."

        # Download latest bootstrap to temp file
        Invoke-WebRequest $BootstrapUrl -OutFile $TempScript -UseBasicParsing

        # Relaunch using -File instead of -Command
        Start-Process powershell `
            -Verb RunAs `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$TempScript`""

        Stop-Transcript | Out-Null
        exit
    }
}

Require-Admin

Clear-Host
Write-Host "==============================================="
Write-Host " OrangeFox Android 14 ELITE Installer v$Version"
Write-Host "==============================================="
Write-Host ""

# --------------------------------------------
# Windows Version Check
# --------------------------------------------

if ([Environment]::OSVersion.Version.Major -lt 10) {
    Write-Host "❌ Windows 10 or newer required."
    Pause
    exit
}

# --------------------------------------------
# Disk Check
# --------------------------------------------

$freeGB = [math]::Round((Get-PSDrive C).Free / 1GB)

if ($freeGB -lt 120) {
    Write-Host "❌ Minimum 120GB free space required."
    Pause
    exit
}

Write-Host "Disk OK ($freeGB GB free)"
Write-Host ""

Write-Host "1) Local WSL Build"
Write-Host "2) Cloud GitHub Build"
Write-Host ""
$choice = Read-Host "Select option"

# ============================================================
# LOCAL WSL BUILD
# ============================================================

if ($choice -eq "1") {

    Write-Host "Preparing WSL Environment..."

    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null

    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        Write-Host "Installing WSL + Ubuntu..."
        wsl --install -d Ubuntu
        Write-Host "Reboot required. Re-run installer after reboot."
        Pause
        exit
    }

    wsl --set-default-version 2

    $distros = wsl -l -q
    if ($distros -notmatch "Ubuntu") {
        Write-Host "Installing Ubuntu..."
        wsl --install -d Ubuntu
        Write-Host "Reboot required. Re-run installer after reboot."
        Pause
        exit
    }

    # Configure WSL memory safely
    $configPath = "$env:USERPROFILE\.wslconfig"

    @"
[wsl2]
memory=6GB
processors=4
swap=8GB
"@ | Out-File $configPath -Encoding ASCII -Force

    wsl --shutdown

    Write-Host "WSL ready."

    # Download Linux build script
    $localScript = "$env:TEMP\of_build.sh"
    Invoke-WebRequest "$ScriptBase/build_orangefox_a14.sh" -OutFile $localScript

    $drive = $localScript.Substring(0,1).ToLower()
    $path  = $localScript.Substring(3) -replace '\\','/'
    $wslPath = "/mnt/$drive/$path"

    Write-Host "Launching Linux build..."

    wsl bash -c "chmod +x $wslPath"
    wsl bash -c "$wslPath"

    Remove-Item $localScript -Force
}

# ============================================================
# CLOUD BUILD
# ============================================================

elseif ($choice -eq "2") {

    Write-Host "Triggering GitHub Cloud Build..."

    $workflowUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/actions/workflows/build.yml/dispatches"

    $token = Read-Host "Enter GitHub Personal Access Token" -AsSecureString
    $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($token)
    )

    $headers = @{
        Authorization = "token $plain"
        Accept = "application/vnd.github+json"
    }

    $body = @{
        ref = "main"
    } | ConvertTo-Json

    try {
        Invoke-RestMethod -Uri $workflowUrl -Method POST -Headers $headers -Body $body
        Write-Host "Cloud build triggered successfully."
    }
    catch {
        Write-Host "❌ Failed to trigger cloud build."
    }
}

else {
    Write-Host "Invalid selection."
}

Write-Host ""
Write-Host "Process complete."
Write-Host "Log file: $LogFile"
Write-Host ""
Pause

Stop-Transcript | Out-Null
