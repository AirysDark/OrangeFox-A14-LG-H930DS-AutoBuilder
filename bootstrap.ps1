# ==============================================
# OrangeFox Android 14 ELITE Bootstrap v5
# ==============================================

$RepoOwner    = "AirysDark"
$RepoName     = "OrangeFox-A14-LG-H930DS-AutoBuilder"
$BootstrapUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/main/bootstrap.ps1"
$ScriptBase   = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/main/scripts"
$Version      = "5.0.0"

$LogFile    = "$env:TEMP\of_bootstrap.log"
$TempScript = "$env:TEMP\of_bootstrap_elevated.ps1"

if ($env:OF_ALREADY_ELEVATED -eq "1") {
    $AlreadyElevated = $true
} else {
    $AlreadyElevated = $false
}

Start-Transcript -Path $LogFile -Append -ErrorAction SilentlyContinue | Out-Null

function Require-Admin {

    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin -and -not $AlreadyElevated) {

        Invoke-WebRequest $BootstrapUrl -OutFile $TempScript -UseBasicParsing

        Start-Process -FilePath "powershell.exe" `
            -Verb RunAs `
            -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$TempScript`"" `
            -Environment @{ OF_ALREADY_ELEVATED = "1" }

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

Write-Host "1) Local WSL Build"
Write-Host "2) Cloud GitHub Build"
Write-Host ""
$choice = Read-Host "Select option"

# ============================================================
# LOCAL BUILD
# ============================================================

if ($choice -eq "1") {

    # Disk check ONLY for local builds
    $freeGB = [math]::Round((Get-PSDrive C).Free / 1GB)

    if ($freeGB -lt 120) {
        Write-Host "❌ Minimum 120GB free space required for LOCAL build."
        Pause
        exit
    }

    Write-Host "Disk OK ($freeGB GB free)"
    Write-Host ""

    Write-Host "Preparing WSL Environment..."

    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null

    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        wsl --install -d Ubuntu
        Write-Host "Reboot required. Please restart Windows and re-run."
        Pause
        exit
    }

    wsl --set-default-version 2

    $distros = wsl -l -q
    if ($distros -notmatch "Ubuntu") {
        wsl --install -d Ubuntu
        Write-Host "Reboot required. Please restart Windows and re-run."
        Pause
        exit
    }

    $configPath = "$env:USERPROFILE\.wslconfig"

@"
[wsl2]
memory=6GB
processors=4
swap=8GB
"@ | Out-File $configPath -Encoding ASCII -Force

    wsl --shutdown

    $localScript = "$env:TEMP\of_build.sh"
    Invoke-WebRequest "$ScriptBase/build_orangefox_a14.sh" -OutFile $localScript

    $drive = $localScript.Substring(0,1).ToLower()
    $path  = $localScript.Substring(3) -replace '\\','/'
    $wslPath = "/mnt/$drive/$path"

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

    $body = @{ ref = "main" } | ConvertTo-Json

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
Write-Host ""
Pause

Stop-Transcript | Out-Null
