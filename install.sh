#!/usr/bin/env bash
# install.sh - FAHHH installer
# One-line install: curl -sSL https://raw.githubusercontent.com/yasharyas/fail-fahhh/main/install.sh | bash

set -e

FAHHH_DIR="$HOME/.fahhh"
REPO_BASE="https://raw.githubusercontent.com/yasharyas/fail-fahhh/main"
HOOK_MARKER="# FAHHH - Terminal Failure Sound Hook"

info() { echo "[fahhh] $1"; }
error() { echo "[fahhh] ERROR: $1" >&2; }

# Check for curl
if ! command -v curl >/dev/null 2>&1; then
    error "curl is required but not found. Install curl and try again."
    exit 1
fi

# Check for an audio player
detect_player() {
    if [[ "$OSTYPE" == darwin* ]]; then
        command -v afplay >/dev/null 2>&1 && return 0
    fi
    command -v mpg123 >/dev/null 2>&1 && return 0
    command -v pw-play >/dev/null 2>&1 && return 0
    command -v paplay >/dev/null 2>&1 && return 0
    command -v ffplay >/dev/null 2>&1 && return 0
    return 1
}

# Auto-install mpg123 if no player found
install_player() {
    info "No audio player found. Installing mpg123..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y mpg123 >/dev/null 2>&1
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y mpg123 >/dev/null 2>&1
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm mpg123 >/dev/null 2>&1
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y mpg123 >/dev/null 2>&1
    elif command -v brew >/dev/null 2>&1; then
        brew install mpg123 >/dev/null 2>&1
    else
        error "Could not detect package manager."
        error "Manually install mpg123 and rerun this script."
        exit 1
    fi

    if command -v mpg123 >/dev/null 2>&1; then
        info "mpg123 installed successfully."
    else
        error "Failed to install mpg123."
        error "Manually install mpg123 and rerun this script."
        exit 1
    fi
}

if ! detect_player; then
    install_player
fi

# Prevent duplicate installs
if [[ -d "$FAHHH_DIR" ]]; then
    info "FAHHH is already installed at $FAHHH_DIR"
    info "To reinstall, run: rm -rf $FAHHH_DIR && rerun this script"
    exit 0
fi

info "Installing FAHHH..."

# Create directory structure
mkdir -p "$FAHHH_DIR/sounds"

# Download files
info "Downloading fahhh.sh..."
curl -sSL "$REPO_BASE/fahhh.sh" -o "$FAHHH_DIR/fahhh.sh"
chmod +x "$FAHHH_DIR/fahhh.sh"

info "Downloading sound file..."
curl -sSL "$REPO_BASE/sounds/fahhh.mp3" -o "$FAHHH_DIR/sounds/fahhh.mp3"

# Detect shell and inject hook
inject_hook() {
    local rc_file="$1"
    local shell_name="$2"

    if [[ ! -f "$rc_file" ]]; then
        touch "$rc_file"
    fi

    # Check if already injected
    if grep -q "$HOOK_MARKER" "$rc_file" 2>/dev/null; then
        info "Hook already present in $rc_file, skipping."
        return 0
    fi

    # Backup rc file
    cp "$rc_file" "${rc_file}.fahhh.bak"

    # Append hook
    {
        echo ""
        echo "$HOOK_MARKER"
        echo "[ -f \"\$HOME/.fahhh/fahhh.sh\" ] && source \"\$HOME/.fahhh/fahhh.sh\""
    } >> "$rc_file"

    info "Hook added to $rc_file (backup: ${rc_file}.fahhh.bak)"
}

shells_configured=0

# Bash
if [[ -n "$BASH_VERSION" ]] || [[ "$SHELL" == */bash ]] || [[ -f "$HOME/.bashrc" ]]; then
    inject_hook "$HOME/.bashrc" "bash"
    shells_configured=$((shells_configured + 1))
fi

# Zsh
if [[ -n "$ZSH_VERSION" ]] || [[ "$SHELL" == */zsh ]] || [[ -f "$HOME/.zshrc" ]]; then
    inject_hook "$HOME/.zshrc" "zsh"
    shells_configured=$((shells_configured + 1))
fi

if [[ $shells_configured -eq 0 ]]; then
    error "Could not detect bash or zsh configuration files."
    error "Manually add this to your shell rc file:"
    error "  source \"\$HOME/.fahhh/fahhh.sh\""
    exit 1
fi

echo ""
info "FAHHH installed successfully!"
info "Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
info "Try it: ls /nonexistent_path"
echo ""
