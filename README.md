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
- One of these audio players (MP3-capable):
  - macOS: `afplay` (built-in)
  - Linux: `mpg123`, `mpv`, `ffplay`, `cvlc`, `play` (sox), `mplayer`, or `pw-play`
  - If no player is found, the installer will prompt you to install `mpg123`

Many Linux systems do not have an MP3-capable player pre-installed. The installer detects your package manager and shows the exact command to run. You can also install manually:

```bash
sudo apt install mpg123      # Debian/Ubuntu
sudo dnf install mpg123      # Fedora
sudo pacman -S mpg123        # Arch
sudo zypper install mpg123   # openSUSE
brew install mpg123          # macOS (if afplay is missing)
```

### Windows

- PowerShell 5.1+ or PowerShell 7+
- No additional dependencies (uses built-in .NET audio)

## Usage

### Commands

```
fahhh help              Show help and available commands
fahhh test              Play the current sound
fahhh sound             Show the current sound file
fahhh sound <file>      Set a custom sound file
fahhh sound reset       Reset to the default FAHHH sound
fahhh status            Show current configuration
```

### Custom Sound

Set any audio file as your failure sound:

```bash
fahhh sound ~/my-sounds/bruh.mp3
fahhh test
fahhh sound reset
```

The custom sound file is copied into `~/.fahhh/sounds/` and persists across terminal sessions.

Supported formats: mp3, wav, ogg, flac, m4a, aac

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

### Environment Variables

Set these in your shell rc file before the FAHHH source line:

```bash
export FAHHH_SOUND="/path/to/your/sound.mp3"
export FAHHH_PLAYER="mpg123"
```

Or use the `fahhh sound` command which persists automatically.

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
    fahhh.mp3     # The default FAHHH sound
```

## How It Works (Technical)

### Linux / macOS

1. `fahhh.sh` is sourced by your shell rc file on terminal startup
2. It loads any saved config from `~/.fahhh/config`
3. It registers `__fahhh_play` as a hook:
   - bash: via `PROMPT_COMMAND`
   - zsh: via `precmd` hook
4. Before each prompt, `__fahhh_play` checks the last exit code (`$?`)
5. If non-zero, it plays the sound in the background using the detected audio player
6. The original exit code is preserved
7. The `fahhh` function provides the CLI for help, test, sound, and status

### Windows

1. `fahhh.ps1` is sourced by your PowerShell profile on startup
2. It loads any saved config from `~/.fahhh/config.ps1`
3. It wraps the `prompt` function to check `$LASTEXITCODE` and `$?`
4. If a command failed, it plays the sound via .NET MediaPlayer on the main thread
5. The original exit code and prompt behavior are preserved
6. The `fahhh` function provides the CLI for help, test, sound, and status

## License

MIT
