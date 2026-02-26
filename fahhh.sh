#!/usr/bin/env bash
# fahhh.sh - Terminal Failure Sound Hook
# Plays a sound when a command exits with a non-zero status

FAHHH_DIR="$HOME/.fahhh"
FAHHH_DEFAULT_SOUND="$FAHHH_DIR/sounds/fahhh.mp3"
FAHHH_SOUND="${FAHHH_SOUND:-$FAHHH_DEFAULT_SOUND}"

# Load saved config if it exists (picks up custom sound)
__fahhh_load_config() {
    local config_file="$FAHHH_DIR/config"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    fi
}

# Save config to persist across sessions
__fahhh_save_config() {
    echo "FAHHH_SOUND=\"$FAHHH_SOUND\"" > "$FAHHH_DIR/config"
}

__fahhh_load_config

__fahhh_detect_player() {
    if [[ "$OSTYPE" == darwin* ]]; then
        command -v afplay >/dev/null 2>&1 && echo "afplay" && return
    fi
    # Priority order: reliable MP3 players first
    # NOTE: paplay/aplay removed - they do NOT support MP3
    command -v mpg123 >/dev/null 2>&1 && echo "mpg123" && return
    command -v mpv >/dev/null 2>&1 && echo "mpv" && return
    command -v ffplay >/dev/null 2>&1 && echo "ffplay" && return
    command -v cvlc >/dev/null 2>&1 && echo "cvlc" && return
    command -v play >/dev/null 2>&1 && echo "play" && return      # sox
    command -v mplayer >/dev/null 2>&1 && echo "mplayer" && return
    command -v pw-play >/dev/null 2>&1 && echo "pw-play" && return # unreliable MP3
    echo ""
}

FAHHH_PLAYER="${FAHHH_PLAYER:-$(__fahhh_detect_player)}"

# Play a specific file synchronously (used by test)
__fahhh_play_file() {
    local file="$1"
    case "$FAHHH_PLAYER" in
        afplay)  afplay "$file" ;;
        mpg123)  mpg123 -q "$file" ;;
        mpv)     mpv --no-video --really-quiet "$file" ;;
        ffplay)  ffplay -nodisp -autoexit -loglevel quiet "$file" 2>/dev/null ;;
        cvlc)    cvlc --play-and-exit --quiet "$file" 2>/dev/null ;;
        play)    play -q "$file" ;;
        mplayer) mplayer -really-quiet "$file" ;;
        pw-play) pw-play "$file" ;;
    esac
}

# CLI command
fahhh() {
    local cmd="${1:-}"
    case "$cmd" in
        help|-h|--help)
            echo "fahhh - terminal failure sound hook"
            echo ""
            echo "Commands:"
            echo "  fahhh help              Show this help"
            echo "  fahhh test              Play the current sound"
            echo "  fahhh sound             Show the current sound file"
            echo "  fahhh sound <file>      Set a custom sound file"
            echo "  fahhh sound reset       Reset to the default sound"
            echo "  fahhh status            Show current configuration"
            echo ""
            echo "Examples:"
            echo "  fahhh sound ~/my-sounds/bruh.mp3"
            echo "  fahhh sound reset"
            ;;
        test)
            if [[ ! -f "$FAHHH_SOUND" ]]; then
                echo "[fahhh] Sound file not found: $FAHHH_SOUND"
                return 1
            fi
            if [[ -z "$FAHHH_PLAYER" ]]; then
                echo "[fahhh] No audio player found."
                echo "[fahhh] Install one: sudo apt install mpg123"
                return 1
            fi
            echo "[fahhh] Sound: $FAHHH_SOUND"
            echo "[fahhh] Player: $FAHHH_PLAYER"
            echo "[fahhh] Playing test sound..."
            __fahhh_play_file "$FAHHH_SOUND"
            if [[ $? -eq 0 ]]; then
                echo "[fahhh] Sound played successfully."
            else
                echo "[fahhh] Playback failed. Try: export FAHHH_PLAYER=mpg123"
            fi
            ;;
        sound)
            local arg="${2:-}"
            if [[ -z "$arg" ]]; then
                echo "[fahhh] Current sound: $FAHHH_SOUND"
                if [[ -f "$FAHHH_SOUND" ]]; then
                    echo "[fahhh] Status: found"
                else
                    echo "[fahhh] Status: NOT FOUND"
                fi
                return 0
            fi
            if [[ "$arg" == "reset" ]]; then
                FAHHH_SOUND="$FAHHH_DEFAULT_SOUND"
                __fahhh_save_config
                echo "[fahhh] Sound reset to default: $FAHHH_SOUND"
                return 0
            fi
            # Resolve to absolute path
            local resolved
            if [[ "$arg" == /* ]]; then
                resolved="$arg"
            else
                resolved="$(cd "$(dirname "$arg")" 2>/dev/null && pwd)/$(basename "$arg")"
            fi
            if [[ ! -f "$resolved" ]]; then
                echo "[fahhh] File not found: $resolved"
                return 1
            fi
            # Validate audio extension
            local ext="${resolved##*.}"
            ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
            case "$ext" in
                mp3|wav|ogg|flac|m4a|aac|wma) ;;
                *)
                    echo "[fahhh] Warning: '.$ext' may not be a supported audio format."
                    echo "[fahhh] Supported: mp3, wav, ogg, flac, m4a, aac"
                    printf "[fahhh] Use anyway? [y/N]: "
                    read -r confirm
                    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                        echo "[fahhh] Cancelled."
                        return 1
                    fi
                    ;;
            esac
            # Copy to fahhh sounds directory
            local dest_name="custom_$(basename "$resolved")"
            cp "$resolved" "$FAHHH_DIR/sounds/$dest_name"
            FAHHH_SOUND="$FAHHH_DIR/sounds/$dest_name"
            __fahhh_save_config
            echo "[fahhh] Sound set to: $FAHHH_SOUND"
            echo "[fahhh] Run 'fahhh test' to preview."
            ;;
        status)
            echo "[fahhh] Sound: $FAHHH_SOUND"
            echo "[fahhh] Player: ${FAHHH_PLAYER:-none}"
            if [[ -f "$FAHHH_SOUND" ]]; then
                echo "[fahhh] Sound file: found"
            else
                echo "[fahhh] Sound file: NOT FOUND"
            fi
            if [[ -n "$FAHHH_PLAYER" ]] && command -v "$FAHHH_PLAYER" >/dev/null 2>&1; then
                echo "[fahhh] Player binary: found"
            else
                echo "[fahhh] Player binary: NOT FOUND"
            fi
            ;;
        "")
            echo "[fahhh] Run 'fahhh help' for usage."
            ;;
        *)
            echo "[fahhh] Unknown command: $cmd"
            echo "[fahhh] Run 'fahhh help' for usage."
            return 1
            ;;
    esac
}

__fahhh_play() {
    local last_exit=$?
    if [[ $last_exit -ne 0 && -n "$FAHHH_PLAYER" && -f "$FAHHH_SOUND" ]]; then
        case "$FAHHH_PLAYER" in
            afplay)  afplay "$FAHHH_SOUND" &>/dev/null & ;;
            mpg123)  mpg123 -q "$FAHHH_SOUND" &>/dev/null & ;;
            mpv)     mpv --no-video --really-quiet "$FAHHH_SOUND" &>/dev/null & ;;
            ffplay)  ffplay -nodisp -autoexit -loglevel quiet "$FAHHH_SOUND" &>/dev/null & ;;
            cvlc)    cvlc --play-and-exit --quiet "$FAHHH_SOUND" &>/dev/null & ;;
            play)    play -q "$FAHHH_SOUND" &>/dev/null & ;;
            mplayer) mplayer -really-quiet "$FAHHH_SOUND" &>/dev/null & ;;
            pw-play) pw-play "$FAHHH_SOUND" &>/dev/null & ;;
        esac
        disown 2>/dev/null
    fi
    return $last_exit
}

# Hook into shell
if [[ -n "$ZSH_VERSION" ]]; then
    autoload -Uz add-zsh-hook 2>/dev/null
    if typeset -f add-zsh-hook >/dev/null 2>&1; then
        add-zsh-hook precmd __fahhh_play
    else
        precmd_functions+=(__fahhh_play)
    fi
elif [[ -n "$BASH_VERSION" ]]; then
    if [[ -z "$PROMPT_COMMAND" ]]; then
        PROMPT_COMMAND="__fahhh_play"
    elif [[ "$PROMPT_COMMAND" != *"__fahhh_play"* ]]; then
        PROMPT_COMMAND="__fahhh_play;${PROMPT_COMMAND}"
    fi
fi
