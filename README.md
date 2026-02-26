# FAHHH - Terminal Failure Sound Hook

A lightweight CLI tool that plays a "FAHHHH" sound every time a command fails in your terminal.

## How It Works

FAHHH hooks into your shell and monitors command exit codes. When a command exits with a non-zero status, it plays the FAHHH sound in the background without blocking your terminal. Works on Linux, macOS, and Windows.

```
$ ls /nonexistent
ls: cannot access '/nonexistent': No such file or directory
*FAHHHH*
```

## Install

### Linux / macOS (bash, zsh)

One-line install:

```bash
curl -sSL https://raw.githubusercontent.com/yasharyas/fail-fahhh/main/install.sh | bash
```

Then restart your terminal or run:

```bash
source ~/.bashrc   # for bash
source ~/.zshrc    # for zsh
```

### Windows (PowerShell)

Run in PowerShell:

```powershell
irm https://raw.githubusercontent.com/yasharyas/fail-fahhh/main/install.ps1 | iex
```

Then restart your terminal or run:

```powershell
. $PROFILE
```

## Requirements

### Linux / macOS

- bash 4+ or zsh 5+
- One of these audio players:
  - macOS: `afplay` (built-in)
  - Linux: `mpg123`, `pw-play`, `paplay`, or `ffplay`
  - If no player is found, the installer auto-installs `mpg123`

### Windows

- PowerShell 5.1+ or PowerShell 7+
- No additional dependencies (uses built-in .NET audio)

## Uninstall

### Linux / macOS

```bash
curl -sSL https://raw.githubusercontent.com/yasharyas/fail-fahhh/main/uninstall.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/yasharyas/fail-fahhh/main/uninstall.ps1 | iex
```

### Manual removal

Linux/macOS:

```bash
rm -rf ~/.fahhh
# Then remove the FAHHH lines from your ~/.bashrc and/or ~/.zshrc
```

Windows:

```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\.fahhh"
# Then remove the FAHHH lines from your PowerShell profile
```

## Configuration

Set a custom sound file:

```bash
export FAHHH_SOUND="/path/to/your/sound.mp3"
```

Override the audio player:

```bash
export FAHHH_PLAYER="mpg123"
```

Add these exports to your shell rc file before the FAHHH source line.

## Project Structure

```
fail-fahhh/
  fahhh.sh        # Core hook logic (bash/zsh)
  fahhh.ps1       # Core hook logic (PowerShell)
  install.sh      # Installer (Linux/macOS)
  install.ps1     # Installer (Windows)
  uninstall.sh    # Uninstaller (Linux/macOS)
  uninstall.ps1   # Uninstaller (Windows)
  sounds/
    fahhh.mp3     # The FAHHH sound
```

## How It Works (Technical)

### Linux / macOS

1. `fahhh.sh` is sourced by your shell rc file on terminal startup
2. It registers `__fahhh_play` as a hook:
   - bash: via `PROMPT_COMMAND`
   - zsh: via `precmd` hook
3. Before each prompt, `__fahhh_play` checks the last exit code (`$?`)
4. If non-zero, it plays the sound in the background using the detected audio player
5. The original exit code is preserved

### Windows

1. `fahhh.ps1` is sourced by your PowerShell profile on startup
2. It wraps the `prompt` function to check `$LASTEXITCODE` and `$?`
3. If a command failed, it plays the sound via .NET MediaPlayer in a background job
4. The original exit code and prompt behavior are preserved

## License

MIT
