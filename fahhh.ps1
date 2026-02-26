# fahhh.ps1 - Terminal Failure Sound Hook for PowerShell
# Plays a sound when a command exits with a non-zero status

$script:FahhhSound = if ($env:FAHHH_SOUND) {
    $env:FAHHH_SOUND
} else {
    Join-Path $env:USERPROFILE ".fahhh\sounds\fahhh.mp3"
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
