# ==============================================
# OrangeFox Android 14 ELITE Bootstrap
# ==============================================

$RepoOwner = "AirysDark"
$RepoName  = "OrangeFox-A14-LG-H930DS-AutoBuilder"
$BootstrapUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/main/bootstrap.ps1"
$Version = "1.0.0"

function Require-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent() `
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

        Start-Process powershell `
            -Verb runAs `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm $BootstrapUrl | iex`""
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
# Self Update Check
# --------------------------------------------

try {
    $remote = Invoke-WebRequest $BootstrapUrl -UseBasicParsing
    if ($remote.Content -notmatch $Version) {
        Write-Host "Updating bootstrap..."
        iex $remote.Content
        exit
    }
} catch {}

# --------------------------------------------
# Disk Check
# --------------------------------------------

$freeGB = [math]::Round((Get-PSDrive C).Free / 1GB)
if ($freeGB -lt 120) {
    Write-Host "❌ Minimum 120GB free space required."
    exit
}

Write-Host "Disk OK ($freeGB GB free)"
Write-Host ""

Write-Host "1) Local WSL Build"
Write-Host "2) Cloud GitHub Build"
Write-Host ""
$choice = Read-Host "Select option"

# ============================================================
# LOCAL BUILD
# ============================================================

if ($choice -eq "1") {

    Write-Host "Preparing WSL..."

    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null

    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        wsl --install -d Ubuntu
        Write-Host "Reboot required. Re-run installer after reboot."
        exit
    }

    wsl --set-default-version 2

    # Auto configure WSL memory
    $configPath = "$env:USERPROFILE\.wslconfig"
    @"
[wsl2]
memory=6GB
processors=4
swap=8GB
"@ | Out-File $configPath -Encoding ASCII -Force

    wsl --shutdown

    # Download Linux builder
    $scriptUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/main/scripts/build_orangefox_a14.sh"
    $localScript = "$env:TEMP\of_build.sh"
    Invoke-WebRequest $scriptUrl -OutFile $localScript

    $wslPath = "/mnt/c/" + ($localScript.Substring(3) -replace '\\','/')

    wsl bash -c "chmod +x $wslPath"
    wsl bash -c "$wslPath"

    Remove-Item $localScript -Force
}

# ============================================================
# CLOUD BUILD (GitHub Actions Trigger)
# ============================================================

elseif ($choice -eq "2") {

    Write-Host "Triggering GitHub Cloud Build..."

    $workflowUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/actions/workflows/build.yml/dispatches"

    $token = Read-Host "Enter GitHub Personal Access Token"

    $headers = @{
        Authorization = "token $token"
        Accept = "application/vnd.github.v3+json"
    }

    $body = @{
        ref = "main"
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $workflowUrl -Method POST -Headers $headers -Body $body

    Write-Host "Cloud build triggered."
    Write-Host "Check GitHub Actions tab."
}

else {
    Write-Host "Invalid selection."
}
