# fahhh.ps1 - Terminal Failure Sound Hook for PowerShell
# Plays a sound when a command exits with a non-zero status

$global:FahhhDir = Join-Path $env:USERPROFILE ".fahhh"
$global:FahhhSoundsDir = Join-Path $global:FahhhDir "sounds"
$global:FahhhConfigFile = Join-Path $global:FahhhDir "config.ps1"
$global:FahhhDefaultSound = Join-Path $global:FahhhSoundsDir "fahhh.mp3"

# Load WPF assembly once at startup
Add-Type -AssemblyName presentationCore -ErrorAction SilentlyContinue

# Load saved config if it exists
if (Test-Path $global:FahhhConfigFile) {
    . $global:FahhhConfigFile
}
if (-not $global:FahhhSound) {
    $global:FahhhSound = $global:FahhhDefaultSound
}

# Override from env if set
if ($env:FAHHH_SOUND) {
    $global:FahhhSound = $env:FAHHH_SOUND
}

function Save-FahhhConfig {
    "`$global:FahhhSound = `"$($global:FahhhSound)`"" | Out-File $global:FahhhConfigFile -Encoding utf8
}

# Track error count to detect failures between prompts
$global:FahhhLastErrorCount = $Error.Count

function fahhh {
    param([string]$Command, [string]$Arg)
    switch ($Command) {
        "help" {
            Write-Host "fahhh - terminal failure sound hook"
            Write-Host ""
            Write-Host "Commands:"
            Write-Host "  fahhh help              Show this help"
            Write-Host "  fahhh test              Play the current sound"
            Write-Host "  fahhh sound             Show the current sound file"
            Write-Host "  fahhh sound <file>      Set a custom sound file"
            Write-Host "  fahhh sound reset       Reset to the default sound"
            Write-Host "  fahhh status            Show current configuration"
            Write-Host ""
            Write-Host "Examples:"
            Write-Host "  fahhh sound C:\Users\me\mysound.mp3"
            Write-Host "  fahhh sound reset"
        }
        "test" {
            if (-not (Test-Path $global:FahhhSound)) {
                Write-Host "[fahhh] Sound file not found: $($global:FahhhSound)"
                return
            }
            Write-Host "[fahhh] Sound: $($global:FahhhSound)"
            Write-Host "[fahhh] Playing test sound..."
            try {
                $player = New-Object System.Windows.Media.MediaPlayer
                $player.Open([Uri](Resolve-Path $global:FahhhSound).Path)
                $player.Play()
                Start-Sleep -Milliseconds 3000
                $player.Close()
                Write-Host "[fahhh] Sound played successfully."
            } catch {
                Write-Host "[fahhh] Playback failed: $_"
            }
        }
        "sound" {
            if (-not $Arg) {
                Write-Host "[fahhh] Current sound: $($global:FahhhSound)"
                if (Test-Path $global:FahhhSound) {
                    Write-Host "[fahhh] Status: found"
                } else {
                    Write-Host "[fahhh] Status: NOT FOUND"
                }
                return
            }
            if ($Arg -eq "reset") {
                $global:FahhhSound = $global:FahhhDefaultSound
                Save-FahhhConfig
                Write-Host "[fahhh] Sound reset to default: $($global:FahhhSound)"
                return
            }
            $resolved = Resolve-Path $Arg -ErrorAction SilentlyContinue
            if (-not $resolved) {
                Write-Host "[fahhh] File not found: $Arg"
                return
            }
            $ext = [System.IO.Path]::GetExtension($resolved.Path).ToLower()
            $supported = @(".mp3", ".wav", ".ogg", ".flac", ".m4a", ".aac", ".wma")
            if ($ext -notin $supported) {
                Write-Host "[fahhh] Warning: '$ext' may not be a supported audio format."
                Write-Host "[fahhh] Supported: mp3, wav, ogg, flac, m4a, aac"
                $confirm = Read-Host "[fahhh] Use anyway? [y/N]"
                if ($confirm -ne "y" -and $confirm -ne "Y") {
                    Write-Host "[fahhh] Cancelled."
                    return
                }
            }
            $destName = "custom_" + (Split-Path $resolved.Path -Leaf)
            Copy-Item $resolved.Path (Join-Path $global:FahhhSoundsDir $destName) -Force
            $global:FahhhSound = Join-Path $global:FahhhSoundsDir $destName
            Save-FahhhConfig
            Write-Host "[fahhh] Sound set to: $($global:FahhhSound)"
            Write-Host "[fahhh] Run 'fahhh test' to preview."
        }
        "status" {
            Write-Host "[fahhh] Sound: $($global:FahhhSound)"
            Write-Host "[fahhh] Player: .NET MediaPlayer (built-in)"
            if (Test-Path $global:FahhhSound) {
                Write-Host "[fahhh] Sound file: found"
            } else {
                Write-Host "[fahhh] Sound file: NOT FOUND"
            }
        }
        default {
            if ($Command) {
                Write-Host "[fahhh] Unknown command: $Command"
            }
            Write-Host "[fahhh] Run 'fahhh help' for usage."
        }
    }
}

$global:FahhhOriginalPrompt = $function:prompt

function prompt {
    # Detect errors: cmdlet errors increase $Error.Count,
    # native command failures set $LASTEXITCODE to non-zero
    $currentErrorCount = $Error.Count
    $nativeExitFailed = ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0)
    $newErrorOccurred = ($currentErrorCount -gt $global:FahhhLastErrorCount)

    if (($newErrorOccurred -or $nativeExitFailed) -and (Test-Path $global:FahhhSound)) {
        try {
            $global:FahhhPlayer = New-Object System.Windows.Media.MediaPlayer
            $global:FahhhPlayer.Open([Uri](Resolve-Path $global:FahhhSound).Path)
            $global:FahhhPlayer.Play()
        } catch { }
    }

    $global:FahhhLastErrorCount = $currentErrorCount
    $exitCode = $LASTEXITCODE
    if ($global:FahhhOriginalPrompt) {
        & $global:FahhhOriginalPrompt
    } else {
        "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
    }
    $global:LASTEXITCODE = $exitCode
}
