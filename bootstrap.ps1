# ==============================================
# OrangeFox Android 14 Bootstrap v6 (Stable)
# ==============================================

$RepoOwner  = "AirysDark"
$RepoName   = "OrangeFox-A14-LG-H930DS-AutoBuilder"
$ScriptBase = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/main/scripts"
$Version    = "6.0.0"

# --------------------------------------------
# Check Admin FIRST — do nothing else before
# --------------------------------------------

$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {

    Write-Host ""
    Write-Host "This installer requires Administrator privileges."
    Write-Host "Relaunching as Administrator..."
    Write-Host ""

    Start-Process -FilePath "powershell.exe" `
        -Verb RunAs `
        -ArgumentList "-NoExit -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/$RepoOwner/$RepoName/main/bootstrap.ps1 | iex`""

    exit
}

# --------------------------------------------
# From here down, we are guaranteed Admin
# --------------------------------------------

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

    $freeGB = [math]::Round((Get-PSDrive C).Free / 1GB)

    if ($freeGB -lt 120) {
        Write-Host ""
        Write-Host "❌ Minimum 120GB free space required for LOCAL build."
        Pause
        exit
    }

    Write-Host "Disk OK ($freeGB GB free)"
    Write-Host ""

    Write-Host "Enabling WSL features..."

    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        Write-Host "Installing WSL + Ubuntu..."
        wsl --install -d Ubuntu
        Write-Host ""
        Write-Host "Reboot required. Restart Windows and re-run installer."
        Pause
        exit
    }

    wsl --set-default-version 2

    $distros = wsl -l -q
    if ($distros -notmatch "Ubuntu") {
        wsl --install -d Ubuntu
        Write-Host "Reboot required. Restart Windows and re-run."
        Pause
        exit
    }

    # Configure WSL memory
    @"
[wsl2]
memory=6GB
processors=4
swap=8GB
"@ | Out-File "$env:USERPROFILE\.wslconfig" -Encoding ASCII -Force

    wsl --shutdown

    Write-Host "WSL ready."
    Write-Host ""

    # Download build script
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

    Write-Host ""
    Write-Host "Triggering GitHub Cloud Build..."
    Write-Host ""

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
Write-Host "Done."
Pause
