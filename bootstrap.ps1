Clear-Host

Write-Host "====================================="
Write-Host " OrangeFox Android 14 Auto Builder"
Write-Host " LG V30 (joan)"
Write-Host "====================================="
Write-Host ""
Write-Host "Select build environment:"
Write-Host "1) Windows PowerShell (Download only)"
Write-Host "2) WSL Ubuntu (Full Build)"
Write-Host ""

$choice = Read-Host "Enter choice (1 or 2)"

$baseUrl = "https://raw.githubusercontent.com/YOURNAME/OrangeFox-A14-AutoBuilder/main/scripts"

$tempFile = "$env:TEMP\of_build_script"

if ($choice -eq "1") {

    Write-Host "`nWARNING:"
    Write-Host "Windows cannot compile Android."
    Write-Host "This will only download source."
    Write-Host ""

    $scriptUrl = "$baseUrl/setup_orangefox_a14.ps1"
    $localScript = "$tempFile.ps1"

    Invoke-WebRequest $scriptUrl -OutFile $localScript
    & $localScript
    Remove-Item $localScript -Force

}
elseif ($choice -eq "2") {

    Write-Host "`nWARNING:"
    Write-Host "WSL build requires 80-120GB free disk."
    Write-Host "Build time: 1-3 hours."
    Write-Host ""

    $scriptUrl = "$baseUrl/build_orangefox_a14.sh"
    $localScript = "$tempFile.sh"

    Invoke-WebRequest $scriptUrl -OutFile $localScript

    wsl bash -c "chmod +x /mnt/c$(($localScript -replace ':',''))"
    wsl bash -c "/mnt/c$(($localScript -replace ':',''))"

    Remove-Item $localScript -Force
}
else {
    Write-Host "Invalid selection."
}
