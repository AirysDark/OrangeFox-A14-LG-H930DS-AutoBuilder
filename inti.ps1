# ==============================================
# OrangeFox Boot Core v2
# ==============================================

$RepoOwner  = "AirysDark"
$RepoName   = "OrangeFox-A14-LG-H930DS-AutoBuilder"
$ScriptBase = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/main/scripts"
$Version    = "Core-2.0.0"

# ------------------------------------------------
# IMMEDIATE DEEP TEMP CLEAN
# ------------------------------------------------

try {

    $temp = $env:TEMP

    # Remove previous boot loader temp copy
    Remove-Item "$temp\orangefox_boot.ps1" -Force -ErrorAction SilentlyContinue

    # Remove previous bootstrap temp copies
    Get-ChildItem $temp -Filter "bootstrap*.ps1" -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue

    # Remove old helper shell scripts
    Get-ChildItem $temp -Filter "*_a14.sh" -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue

    Remove-Item "$temp\direct_build_a14.sh" -Force -ErrorAction SilentlyContinue
    Remove-Item "$temp\local_runner_a14.sh" -Force -ErrorAction SilentlyContinue

}
catch {
    # Silent fail allowed
}

# ------------------------------------------------
# WSL INSTALLER (ONLY OPTION 1)
# ------------------------------------------------

function Install-And-Configure-WSL {

    Write-Host ""
    Write-Host "Installing / Configuring WSL..."

    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null

    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        wsl --install -d Ubuntu
        Write-Host ""
        Write-Host "Reboot required. Restart Windows and run again."
        Pause
        exit
    }

    wsl --set-default-version 2

@"
[wsl2]
memory=6GB
processors=4
swap=8GB
"@ | Out-File "$env:USERPROFILE\.wslconfig" -Encoding ASCII -Force

    wsl --shutdown
}

# ------------------------------------------------
# MODE 1
# ------------------------------------------------

function Run-LocalInstallBuild {

    Clear-Host
    Write-Host "=== MODE 1: INSTALL WSL + DIRECT BUILD ==="

    Install-And-Configure-WSL

    wsl bash -c "cd ~ && curl -s $ScriptBase/build_orangefox_a14.sh -o direct_build_a14.sh && chmod +x direct_build_a14.sh && ./direct_build_a14.sh"
}

# ------------------------------------------------
# MODE 2
# ------------------------------------------------

function Run-LocalRunner {

    Clear-Host
    Write-Host "=== MODE 2: LOCAL RUNNER ==="

    wsl bash -c "cd ~ && curl -s $ScriptBase/local_runner_a14.sh -o local_runner_a14.sh && chmod +x local_runner_a14.sh && ./local_runner_a14.sh"
}

# ------------------------------------------------
# MODE 3
# ------------------------------------------------

function Run-CloudBuild {

    Clear-Host
    Write-Host "=== MODE 3: CLOUD BUILD ==="

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
Write-Host " OrangeFox Android 14 Installer $Version"
Write-Host "==============================================="
Write-Host ""

Write-Host "1) Install WSL + Local Direct Build"
Write-Host "2) Local Runner (Just Run .sh)"
Write-Host "3) Cloud GitHub Build"
Write-Host ""
$choice = Read-Host "Select option"

switch ($choice) {
    "1" { Run-LocalInstallBuild }
    "2" { Run-LocalRunner }
    "3" { Run-CloudBuild }
    default { Write-Host "Invalid selection."; Pause }
}

Write-Host ""
Write-Host "Done."
Pause
