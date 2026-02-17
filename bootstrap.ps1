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
    Write-Host "⚠ WARNING:"
    Write-Host "WSL build requires:"
    Write-Host "- 80-120GB free disk"
    Write-Host "- 6GB+ RAM allocated to WSL"
    Write-Host "- Build time: 1-3 hours"
    Write-Host ""

    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        Write-Host "❌ WSL is not installed."
        exit
    }

    $scriptUrl = "$baseUrl/build_orangefox_a14.sh"
    $localScript = "$tempFile.sh"

    Invoke-WebRequest $scriptUrl -OutFile $localScript

    $wslPath = "/mnt/c/" + ($localScript.Substring(3) -replace '\\','/')

    wsl bash -c "chmod +x $wslPath"
    wsl bash -c "$wslPath"

    Remove-Item $localScript -Force
}
else {
    Write-Host "Invalid selection."
}
