# FAHHH - Terminal Failure Sound Hook

A lightweight CLI tool that plays a "FAHHHH" sound every time a command fails in your terminal.

## How It Works

FAHHH hooks into your shell (bash/zsh) and monitors command exit codes. When a command exits with a non-zero status, it plays the FAHHH sound in the background without blocking your terminal.

```
$ ls /nonexistent
ls: cannot access '/nonexistent': No such file or directory
*FAHHHH*
```

## Install

One-line install:

```bash
curl -sSL https://raw.githubusercontent.com/yasharyas/fail-fahhh/main/install.sh | bash
```

Then restart your terminal or run:

```bash
source ~/.bashrc   # for bash
source ~/.zshrc    # for zsh
```

## Requirements

- bash 4+ or zsh 5+
- One of these audio players:
  - macOS: `afplay` (built-in)
  - Linux: `mpg123`, `pw-play`, `paplay`, or `ffplay`

Install mpg123 on Ubuntu/Debian:

```bash
sudo apt install mpg123
```

## Uninstall

```bash
curl -sSL https://raw.githubusercontent.com/yasharyas/fail-fahhh/main/uninstall.sh | bash
```

Or manually:

```bash
rm -rf ~/.fahhh
# Then remove the FAHHH lines from your ~/.bashrc and/or ~/.zshrc
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
  fahhh.sh        # Core hook logic
  install.sh      # Installer script
  uninstall.sh    # Uninstaller script
  sounds/
    fahhh.mp3     # The FAHHH sound
```

## How It Works (Technical)

1. `fahhh.sh` is sourced by your shell rc file on terminal startup
2. It registers `__fahhh_play` as a hook:
   - bash: via `PROMPT_COMMAND`
   - zsh: via `precmd` hook
3. Before each prompt, `__fahhh_play` checks the last exit code (`$?`)
4. If non-zero, it plays the sound in the background using the detected audio player
5. The original exit code is preserved

## License

MIT
