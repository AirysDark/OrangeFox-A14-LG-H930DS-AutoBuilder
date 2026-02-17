Clear-Host

Write-Host "==============================================="
Write-Host " OrangeFox Android 14 Auto Builder"
Write-Host " LG V30 H930DS (joan)"
Write-Host "==============================================="
Write-Host ""

Write-Host "1) Windows PowerShell (Download Source Only)"
Write-Host "2) WSL Ubuntu (Full Android 14 Build)"
Write-Host ""

$choice = Read-Host "Select option (1 or 2)"

$baseUrl = "https://raw.githubusercontent.com/AirysDark/OrangeFox-A14-LG-H930DS-AutoBuilder/main/scripts"
$tempDir = "$env:TEMP"
$tempFile = "$tempDir\of_temp_script"

if ($choice -eq "1") {

    Write-Host ""
    Write-Host "⚠ WARNING:"
    Write-Host "Windows CANNOT build Android."
    Write-Host "This will only download the source tree."
    Write-Host ""

    $scriptUrl = "$baseUrl/setup_orangefox_a14.ps1"
    $localScript = "$tempFile.ps1"

    Invoke-WebRequest $scriptUrl -OutFile $localScript
    & $localScript
    Remove-Item $localScript -Force
}

elseif ($choice -eq "2") {

    Write-Host ""
    Write-Host "Preparing WSL Environment..."
    Write-Host ""

    # -----------------------------
    # Check Admin
    # -----------------------------
    if (-not ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent() `
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

        Write-Host "❌ Please run PowerShell as Administrator."
        exit
    }

    # -----------------------------
    # Install WSL if missing
    # -----------------------------
    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {

        Write-Host "Installing WSL..."
        wsl --install -d Ubuntu
        Write-Host "WSL Installed. Please reboot and re-run script."
        exit
    }

    # -----------------------------
    # Ensure WSL2 default
    # -----------------------------
    Write-Host "Setting WSL default version to 2..."
    wsl --set-default-version 2

    # -----------------------------
    # Ensure Ubuntu installed
    # -----------------------------
    $distros = wsl -l -q

    if ($distros -notmatch "Ubuntu") {
        Write-Host "Installing Ubuntu..."
        wsl --install -d Ubuntu
        Write-Host "Ubuntu Installed. Please reboot and re-run script."
        exit
    }

    Write-Host "WSL + Ubuntu Ready."
    Write-Host ""

    # -----------------------------
    # Download Build Script
    # -----------------------------
    $scriptUrl = "$baseUrl/build_orangefox_a14.sh"
    $localScript = "$tempFile.sh"

    Invoke-WebRequest $scriptUrl -OutFile $localScript

    # Convert Windows path to WSL path
    $wslPath = "/mnt/c/" + ($localScript.Substring(3) -replace '\\','/')

    Write-Host "Starting Linux build script..."
    Write-Host ""

    wsl bash -c "chmod +x $wslPath"
    wsl bash -c "$wslPath"

    Remove-Item $localScript -Force
}

else {
    Write-Host "Invalid selection."
}
