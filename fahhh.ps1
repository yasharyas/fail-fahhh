# fahhh.ps1 - Terminal Failure Sound Hook for PowerShell
# Plays a sound when a command exits with a non-zero status

$script:FahhhSound = if ($env:FAHHH_SOUND) {
    $env:FAHHH_SOUND
} else {
    Join-Path $env:USERPROFILE ".fahhh\sounds\fahhh.mp3"
}

# Diagnostic command: run "fahhh test" to check setup
function fahhh {
    param([string]$Command)
    switch ($Command) {
        "test" {
            Write-Host "[fahhh] Sound file: $script:FahhhSound"
            if (Test-Path $script:FahhhSound) {
                Write-Host "[fahhh] Sound file: found"
            } else {
                Write-Host "[fahhh] Sound file: MISSING"
                return
            }
            Write-Host "[fahhh] Playing test sound..."
            try {
                Add-Type -AssemblyName presentationCore
                $player = New-Object System.Windows.Media.MediaPlayer
                $player.Open([Uri](Resolve-Path $script:FahhhSound).Path)
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

$script:FahhhOriginalPrompt = $function:prompt

function prompt {
    $exitCode = $LASTEXITCODE
    $cmdFailed = -not $?

    if (($cmdFailed -or ($null -ne $exitCode -and $exitCode -ne 0)) -and (Test-Path $script:FahhhSound)) {
        Start-Job -ScriptBlock {
            param($soundPath)
            Add-Type -AssemblyName presentationCore
            $player = New-Object System.Windows.Media.MediaPlayer
            $player.Open([Uri]$soundPath)
            $player.Play()
            Start-Sleep -Milliseconds 3000
        } -ArgumentList $script:FahhhSound | Out-Null
    }

    $global:LASTEXITCODE = $exitCode
    if ($script:FahhhOriginalPrompt) {
        & $script:FahhhOriginalPrompt
    } else {
        "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
    }
}
