# install.ps1 - FAHHH installer for Windows PowerShell
# One-line install: irm https://raw.githubusercontent.com/yasharyas/fail-fahhh/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

$FahhhDir = Join-Path $env:USERPROFILE ".fahhh"
$SoundsDir = Join-Path $FahhhDir "sounds"
$RepoBase = "https://raw.githubusercontent.com/yasharyas/fail-fahhh/main"
$HookMarker = "# FAHHH - Terminal Failure Sound Hook"

function Write-FahhhInfo { param($msg) Write-Host "[fahhh] $msg" }
function Write-FahhhError { param($msg) Write-Host "[fahhh] ERROR: $msg" -ForegroundColor Red }

# Prevent duplicate installs
if (Test-Path $FahhhDir) {
    Write-FahhhInfo "FAHHH is already installed at $FahhhDir"
    Write-FahhhInfo "To reinstall, run: Remove-Item -Recurse -Force $FahhhDir"
    return
}

Write-FahhhInfo "Installing FAHHH..."

# Create directory structure
New-Item -ItemType Directory -Path $SoundsDir -Force | Out-Null

# Download files
Write-FahhhInfo "Downloading fahhh.ps1..."
Invoke-WebRequest -Uri "$RepoBase/fahhh.ps1" -OutFile (Join-Path $FahhhDir "fahhh.ps1") -UseBasicParsing

Write-FahhhInfo "Downloading sound file..."
Invoke-WebRequest -Uri "$RepoBase/sounds/fahhh.mp3" -OutFile (Join-Path $SoundsDir "fahhh.mp3") -UseBasicParsing

# Inject hook into PowerShell profile
$profilePath = $PROFILE.CurrentUserAllHosts
$profileDir = Split-Path $profilePath -Parent

if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
if ($profileContent -and $profileContent.Contains($HookMarker)) {
    Write-FahhhInfo "Hook already present in $profilePath, skipping."
} else {
    # Backup profile
    Copy-Item $profilePath "$profilePath.fahhh.bak" -Force
    $hookLines = @(
        ""
        $HookMarker
        ". `"$FahhhDir\fahhh.ps1`""
    )
    Add-Content -Path $profilePath -Value ($hookLines -join "`n")
    Write-FahhhInfo "Hook added to $profilePath (backup: $profilePath.fahhh.bak)"
}

Write-Host ""
Write-FahhhInfo "FAHHH installed successfully!"
Write-FahhhInfo "Restart your terminal or run: . `$PROFILE"
Write-FahhhInfo "Try it: Get-Item C:\nonexistent"
Write-Host ""
