# ==============================================
# OrangeFox Android 14 Bootstrap v11
# ==============================================

$RepoOwner  = "AirysDark"
$RepoName   = "OrangeFox-A14-LG-H930DS-AutoBuilder"
$ScriptBase = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/main/scripts"
$Version    = "11.0.0"

# ------------------------------------------------
# ADMIN CHECK (NO AUTO ELEVATION)
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
    Write-Host "Please close this window and reopen PowerShell"
    Write-Host "using: Run as Administrator"
    Write-Host ""
    Pause
    exit
}

# ------------------------------------------------
# FUNCTIONS
# ------------------------------------------------

function Ensure-WSL {

    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null

    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        wsl --install -d Ubuntu
        Write-Host "Reboot required. Restart Windows."
        Pause
        exit
    }

    wsl --set-default-version 2

    $distros = wsl -l -q
    if ($distros -notmatch "Ubuntu") {
        wsl --install -d Ubuntu
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
}

function Run-LocalDirect {

    $freeGB = [math]::Round((Get-PSDrive C).Free / 1GB)

    if ($freeGB -lt 50) {
        Write-Host "❌ Minimum 50GB required."
        Pause
        exit
    }

    Write-Host "Disk OK ($freeGB GB free)"
    Ensure-WSL

    $localScript = "$env:TEMP\of_build.sh"
    Invoke-WebRequest "$ScriptBase/build_orangefox_a14.sh" -OutFile $localScript

    $drive = $localScript.Substring(0,1).ToLower()
    $path  = $localScript.Substring(3) -replace '\\','/'
    $wslPath = "/mnt/$drive/$path"

    wsl bash -c "chmod +x $wslPath"
    wsl bash -c "$wslPath"

    Remove-Item $localScript -Force
}

function Run-LocalRunner {

    $steps = @(
        "Validating Disk Space",
        "Preparing WSL Environment",
        "Downloading Build Script",
        "Executing Android Build",
        "Finalizing"
    )

    $total = $steps.Count
    $current = 0

    foreach ($step in $steps) {

        $current++
        $percent = [int](($current / $total) * 100)

        Write-Progress -Activity "Local Runner Pipeline" `
            -Status $step `
            -PercentComplete $percent

        switch ($step) {

            "Validating Disk Space" {
                $freeGB = [math]::Round((Get-PSDrive C).Free / 1GB)
                if ($freeGB -lt 50) {
                    Write-Host "❌ Minimum 50GB required."
                    Pause
                    exit
                }
            }

            "Preparing WSL Environment" {
                Ensure-WSL
            }

            "Downloading Build Script" {
                $global:localScript = "$env:TEMP\of_build.sh"
                Invoke-WebRequest "$ScriptBase/build_orangefox_a14.sh" -OutFile $localScript
            }

            "Executing Android Build" {
                $drive = $localScript.Substring(0,1).ToLower()
                $path  = $localScript.Substring(3) -replace '\\','/'
                $wslPath = "/mnt/$drive/$path"
                wsl bash -c "chmod +x $wslPath"
                wsl bash -c "$wslPath"
            }
        }

        Start-Sleep -Seconds 1
    }

    Write-Progress -Activity "Local Runner Pipeline" -Completed
    Remove-Item $localScript -Force -ErrorAction SilentlyContinue
}

function Run-CloudBuild {

    $workflowUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/actions/workflows/build.yml/dispatches"
    $runsUrl     = "https://api.github.com/repos/$RepoOwner/$RepoName/actions/runs"

    $token = Read-Host "Enter GitHub Personal Access Token" -AsSecureString
    $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($token)
    )

    $headers = @{
        Authorization = "token $plain"
        Accept        = "application/vnd.github+json"
    }

    $body = @{ ref = "main" } | ConvertTo-Json

    Invoke-RestMethod -Uri $workflowUrl -Method POST -Headers $headers -Body $body

    Write-Host "Build triggered..."
    Start-Sleep -Seconds 5

    $run = (Invoke-RestMethod -Uri $runsUrl -Headers $headers).workflow_runs |
           Sort-Object created_at -Descending |
           Select-Object -First 1

    if (-not $run) {
        Write-Host "Unable to locate workflow run."
        Pause
        return
    }

    $runId = $run.id
    $progress = 5

    while ($true) {

        $runStatus = Invoke-RestMethod -Uri "$runsUrl/$runId" -Headers $headers

        switch ($runStatus.status) {

            "queued" {
                $progress = 10
                Write-Progress -Activity "Cloud Build" -Status "Queued..." -PercentComplete $progress
            }

            "in_progress" {
                if ($progress -lt 90) { $progress += 4 }
                Write-Progress -Activity "Cloud Build Running" -Status "Building..." -PercentComplete $progress
            }

            "completed" {
                Write-Progress -Activity "Cloud Build Completed" -Status $runStatus.conclusion -PercentComplete 100
                break
            }
        }

        Start-Sleep -Seconds 8
    }

    Write-Host ""
    Write-Host "Build Result: $($runStatus.conclusion)"

    if ($runStatus.conclusion -eq "success") {
        Start-Process "https://github.com/$RepoOwner/$RepoName/releases"
    }
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
Write-Host "3) Cloud GitHub Build (Live Progress)"
Write-Host ""
$choice = Read-Host "Select option"

switch ($choice) {
    "1" { Run-LocalDirect }
    "2" { Run-LocalRunner }
    "3" { Run-CloudBuild }
    default { Write-Host "Invalid selection." }
}

Write-Host ""
Write-Host "Done."
Pause
