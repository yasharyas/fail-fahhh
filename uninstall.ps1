# uninstall.ps1 - FAHHH uninstaller for Windows PowerShell
# Run: irm https://raw.githubusercontent.com/yasharyas/fail-fahhh/main/uninstall.ps1 | iex

$ErrorActionPreference = "Stop"

$FahhhDir = Join-Path $env:USERPROFILE ".fahhh"
$HookMarker = "# FAHHH - Terminal Failure Sound Hook"

function Write-FahhhInfo { param($msg) Write-Host "[fahhh] $msg" }

if (-not (Test-Path $FahhhDir)) {
    Write-FahhhInfo "FAHHH is not installed (no $FahhhDir directory found)."
    return
}

Write-FahhhInfo "Uninstalling FAHHH..."

# Remove hook from PowerShell profile
$profilePath = $PROFILE.CurrentUserAllHosts

if (Test-Path $profilePath) {
    $lines = Get-Content $profilePath
    $filtered = $lines | Where-Object {
        $_ -notmatch "FAHHH" -and $_ -notmatch "fahhh\.ps1"
    }
    Set-Content -Path $profilePath -Value $filtered
    Write-FahhhInfo "Hook removed from $profilePath"

    # Clean up backup
    $backupPath = "$profilePath.fahhh.bak"
    if (Test-Path $backupPath) {
        Remove-Item $backupPath -Force
        Write-FahhhInfo "Removed backup $backupPath"
    }
}

# Remove the .fahhh directory
Remove-Item -Recurse -Force $FahhhDir
Write-FahhhInfo "Removed $FahhhDir"

Write-Host ""
Write-FahhhInfo "FAHHH has been uninstalled."
Write-FahhhInfo "Restart your terminal to complete the process."
Write-Host ""
