# fahhh.ps1 - Terminal Failure Sound Hook for PowerShell
# Plays a sound when a command exits with a non-zero status

$global:FahhhSound = if ($env:FAHHH_SOUND) {
    $env:FAHHH_SOUND
} else {
    Join-Path $env:USERPROFILE ".fahhh\sounds\fahhh.mp3"
}

# Load WPF assembly once at startup
Add-Type -AssemblyName presentationCore -ErrorAction SilentlyContinue

# Track error count to detect failures between prompts
$global:FahhhLastErrorCount = $Error.Count

# Diagnostic command: run "fahhh test" to check setup
function fahhh {
    param([string]$Command)
    switch ($Command) {
        "test" {
            Write-Host "[fahhh] Sound file: $global:FahhhSound"
            if (Test-Path $global:FahhhSound) {
                Write-Host "[fahhh] Sound file: found"
            } else {
                Write-Host "[fahhh] Sound file: MISSING"
                return
            }
            Write-Host "[fahhh] Playing test sound..."
            try {
                $player = New-Object System.Windows.Media.MediaPlayer
                $player.Open([Uri](Resolve-Path $global:FahhhSound).Path)
                $player.Play()
                Start-Sleep -Milliseconds 3000
                $player.Close()
                Write-Host "[fahhh] Sound played successfully."
            } catch {
                Write-Host "[fahhh] ERROR: Playback failed: $_"
            }
        }
        default {
            Write-Host "Usage: fahhh test"
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
        # Play on the main thread (STA) — MediaPlayer.Play() is async and
        # returns immediately, but needs the WPF dispatcher which only the
        # main thread has.  Store in $global: to prevent garbage-collection.
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
