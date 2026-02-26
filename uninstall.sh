#!/usr/bin/env bash
# uninstall.sh - FAHHH uninstaller
# Removes FAHHH hook from shell rc files and deletes ~/.fahhh

set -e

FAHHH_DIR="$HOME/.fahhh"
HOOK_MARKER="# FAHHH - Terminal Failure Sound Hook"

info() { echo "[fahhh] $1"; }
error() { echo "[fahhh] ERROR: $1" >&2; }

if [[ ! -d "$FAHHH_DIR" ]]; then
    info "FAHHH is not installed (no $FAHHH_DIR directory found)."
    exit 0
fi

info "Uninstalling FAHHH..."

# Remove hook from rc files
remove_hook() {
    local rc_file="$1"
    local shell_name="$2"

    if [[ ! -f "$rc_file" ]]; then
        return 0
    fi

    if grep -q "$HOOK_MARKER" "$rc_file" 2>/dev/null; then
        # Remove the marker line and the source line after it
        sed -i "/$HOOK_MARKER/d" "$rc_file"
        sed -i '/\[ -f "\$HOME\/.fahhh\/fahhh\.sh" \] && source "\$HOME\/.fahhh\/fahhh\.sh"/d' "$rc_file"
        info "Hook removed from $rc_file"
    fi

    # Clean up backup file from install
    if [[ -f "${rc_file}.fahhh.bak" ]]; then
        rm -f "${rc_file}.fahhh.bak"
        info "Removed backup ${rc_file}.fahhh.bak"
    fi
}

# Remove from both shells
remove_hook "$HOME/.bashrc" "bash"
remove_hook "$HOME/.zshrc" "zsh"

# Remove the .fahhh directory
rm -rf "$FAHHH_DIR"
info "Removed $FAHHH_DIR"

echo ""
info "FAHHH has been uninstalled."
info "Restart your terminal to complete the process."
echo ""
