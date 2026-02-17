# ==============================================
# OrangeFox Android 14 Bootstrap v7 (Logging)
# ==============================================

$RepoOwner  = "AirysDark"
$RepoName   = "OrangeFox-A14-LG-H930DS-AutoBuilder"
$ScriptBase = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/main/scripts"
$Version    = "7.0.0"

$ErrorLog = "C:\orangefox_error.log"

# ------------------------------------------------
# Error Logging System
# ------------------------------------------------

function Write-ErrorLog {
    param ($Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $ErrorLog -Value "[$timestamp] $Message"
}

# Catch all terminating errors
$ErrorActionPreference = "Stop"

trap {
    Write-ErrorLog "UNHANDLED ERROR: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "❌ A fatal error occurred."
    Write-Host "See log file: $ErrorLog"
    Pause
    exit 1
}

# ------------------------------------------------
# Elevation Check
# ------------------------------------------------

$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {

    Write-Host ""
    Write-Host "Administrator privileges required."
    Write-Host "Relaunching..."
    Write-Host ""

    try {
        Start-Process -FilePath "powershell.exe" `
            -Verb RunAs `
            -ArgumentList "-NoExit -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/$RepoOwner/$RepoName/main/bootstrap.ps1 | iex`""
    }
    catch {
        Write-ErrorLog "Failed to elevate: $($_.Exception.Message)"
    }

    exit
}

# ------------------------------------------------
# Admin Section Starts Here
# ------------------------------------------------

Clear-Host
Write-Host "==============================================="
Write-Host " OrangeFox Android 14 Installer v$Version"
Write-Host "==============================================="
Write-Host ""

Write-Host "1) Local WSL Build"
Write-Host "2) Cloud GitHub Build"
Write-Host ""
$choice = Read-Host "Select option"

# ============================================================
# LOCAL BUILD
# ============================================================

if ($choice -eq "1") {

    try {
        $freeGB = [math]::Round((Get-PSDrive C).Free / 1GB)

        if ($freeGB -lt 120) {
            Write-ErrorLog "Insufficient disk space: $freeGB GB"
            Write-Host "❌ Minimum 120GB required."
            Pause
            exit
        }

        Write-Host "Disk OK ($freeGB GB free)"

        Write-Host "Enabling WSL features..."
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

        if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
            Write-Host "Installing WSL + Ubuntu..."
            wsl --install -d Ubuntu
            Write-ErrorLog "WSL installed — reboot required"
            Write-Host "Reboot required. Restart Windows."
            Pause
            exit
        }

        wsl --set-default-version 2

        $distros = wsl -l -q
        if ($distros -notmatch "Ubuntu") {
            wsl --install -d Ubuntu
            Write-ErrorLog "Ubuntu installed — reboot required"
            Write-Host "Reboot required. Restart Windows."
            Pause
            exit
        }

        @"
[wsl2]
memory=6GB
processors=4
swap=8GB
"@ | Out-File "$env:USERPROFILE\.wslconfig" -Encoding ASCII -Force

        wsl --shutdown

        Write-Host "WSL ready."

        $localScript = "$env:TEMP\of_build.sh"
        Invoke-WebRequest "$ScriptBase/build_orangefox_a14.sh" -OutFile $localScript

        $drive = $localScript.Substring(0,1).ToLower()
        $path  = $localScript.Substring(3) -replace '\\','/'
        $wslPath = "/mnt/$drive/$path"

        wsl bash -c "chmod +x $wslPath"
        wsl bash -c "$wslPath"

        Remove-Item $localScript -Force
    }
    catch {
        Write-ErrorLog "Local build error: $($_.Exception.Message)"
        throw
    }
}

# ============================================================
# CLOUD BUILD
# ============================================================

elseif ($choice -eq "2") {

    try {
        $workflowUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/actions/workflows/build.yml/dispatches"

        $token = Read-Host "Enter GitHub Personal Access Token" -AsSecureString
        $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($token)
        )

        $headers = @{
            Authorization = "token $plain"
            Accept = "application/vnd.github+json"
        }

        $body = @{ ref = "main" } | ConvertTo-Json

        Invoke-RestMethod -Uri $workflowUrl -Method POST -Headers $headers -Body $body
        Write-Host "Cloud build triggered successfully."
    }
    catch {
        Write-ErrorLog "Cloud trigger failed: $($_.Exception.Message)"
        throw
    }
}

else {
    Write-ErrorLog "Invalid menu selection"
    Write-Host "Invalid selection."
}

Write-Host ""
Write-Host "Done."
Pause
