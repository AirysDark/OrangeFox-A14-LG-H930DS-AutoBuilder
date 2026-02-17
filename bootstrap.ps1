# ==============================================
# OrangeFox Android 14 Bootstrap v15
# ==============================================

$RepoOwner  = "AirysDark"
$RepoName   = "OrangeFox-A14-LG-H930DS-AutoBuilder"
$ScriptBase = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/main/scripts"
$Version    = "15.0.0"

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
    Write-Host "Please reopen PowerShell as Administrator."
    Write-Host ""
    Pause
    exit
}

# ------------------------------------------------
# FUNCTIONS
# ------------------------------------------------

function Ensure-WSL {

    Write-Host "Preparing WSL environment..."

    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null

    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        wsl --install -d Ubuntu
        Write-Host "Reboot required."
        Pause
        exit
    }

    wsl --set-default-version 2
    wsl --shutdown
}

function Invoke-WSLScript {
    param (
        [string]$ScriptUrl,
        [string]$LocalName
    )

    $localScript = Join-Path $env:TEMP $LocalName

    if (Test-Path $localScript) {
        Remove-Item $localScript -Force
    }

    Write-Host ""
    Write-Host "Downloading: $LocalName"
    Write-Host ""

    try {
        Invoke-WebRequest $ScriptUrl -OutFile $localScript -UseBasicParsing
    }
    catch {
        Write-Host "❌ Download failed."
        Pause
        return
    }

    $wslPath = wsl wslpath "`"$localScript`""

    Write-Host ""
    Write-Host "Executing inside WSL: $LocalName"
    Write-Host ""

    wsl bash -c "chmod +x $wslPath"
    wsl bash -c "$wslPath"

    Remove-Item $localScript -Force -ErrorAction SilentlyContinue
}

function Run-LocalDirect {

    Clear-Host
    Write-Host "=== MODE: LOCAL DIRECT BUILD ==="

    Ensure-WSL

    Invoke-WSLScript `
        "$ScriptBase/build_orangefox_a14.sh" `
        "direct_build_a14.sh"
}

function Run-LocalRunner {

    Clear-Host
    Write-Host "=== MODE: LOCAL RUNNER PIPELINE ==="

    Ensure-WSL

    Invoke-WSLScript `
        "$ScriptBase/local_runner_a14.sh" `
        "runner_build_a14.sh"
}

function Run-CloudBuild {

    Clear-Host
    Write-Host "=== MODE: CLOUD BUILD ==="

    $workflowUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/actions/workflows/build.yml/dispatches"

    $token = Read-Host "Enter GitHub Personal Access Token" -AsSecureString
    $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($token)
    )

    $headers = @{
        Authorization = "token $plain"
        Accept        = "application/vnd.github+json"
    }

    try {
        Invoke-RestMethod -Uri $workflowUrl -Method POST -Headers $headers -Body (@{ ref = "main" } | ConvertTo-Json)
        Write-Host ""
        Write-Host "Cloud build triggered."
    }
    catch {
        Write-Host "❌ Failed to trigger cloud build."
    }

    Pause
}

# ------------------------------------------------
# MAIN MENU
# ------------------------------------------------

Clear-Host
Write-Host "==============================================="
Write-Host " OrangeFox Android 14 Installer v$Version"
Write-Host "==============================================="
Write-Host ""

Write-Host "1) Local Direct WSL Build"
Write-Host "2) Local Runner Mode (Pipeline UI)"
Write-Host "3) Cloud GitHub Build"
Write-Host ""
$choice = Read-Host "Select option"

switch ($choice) {
    "1" { Run-LocalDirect }
    "2" { Run-LocalRunner }
    "3" { Run-CloudBuild }
    default { Write-Host "Invalid selection."; Pause }
}
