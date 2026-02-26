#!/usr/bin/env bash
# fahhh.sh - Terminal Failure Sound Hook
# Plays a sound when a command exits with a non-zero status

FAHHH_SOUND="${FAHHH_SOUND:-$HOME/.fahhh/sounds/fahhh.mp3}"

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

# Diagnostic command: run "fahhh test" to check setup
fahhh() {
    case "${1:-}" in
        test)
            echo "[fahhh] Sound file: $FAHHH_SOUND"
            if [[ -f "$FAHHH_SOUND" ]]; then
                echo "[fahhh] Sound file: found"
            else
                echo "[fahhh] Sound file: MISSING"
                return 1
            fi
            echo "[fahhh] Player: ${FAHHH_PLAYER:-none}"
            if [[ -z "$FAHHH_PLAYER" ]]; then
                echo "[fahhh] ERROR: No audio player detected."
                echo "[fahhh] Install mpg123: sudo apt install mpg123"
                return 1
            fi
            echo "[fahhh] Playing test sound..."
            case "$FAHHH_PLAYER" in
                afplay)  afplay "$FAHHH_SOUND" ;;
                mpg123)  mpg123 -q "$FAHHH_SOUND" ;;
                mpv)     mpv --no-video --really-quiet "$FAHHH_SOUND" ;;
                ffplay)  ffplay -nodisp -autoexit -loglevel quiet "$FAHHH_SOUND" ;;
                cvlc)    cvlc --play-and-exit --quiet "$FAHHH_SOUND" 2>/dev/null ;;
                play)    play -q "$FAHHH_SOUND" ;;
                mplayer) mplayer -really-quiet "$FAHHH_SOUND" ;;
                pw-play) pw-play "$FAHHH_SOUND" ;;
            esac
            if [[ $? -eq 0 ]]; then
                echo "[fahhh] Sound played successfully."
            else
                echo "[fahhh] ERROR: Player failed. Try a different player:"
                echo "[fahhh]   export FAHHH_PLAYER=mpg123"
            fi
            ;;
        *)
            echo "Usage: fahhh test"
            ;;
    esac
}

__fahhh_play() {
    local last_exit=$?
    if [[ $last_exit -ne 0 && -n "$FAHHH_PLAYER" && -f "$FAHHH_SOUND" ]]; then
        case "$FAHHH_PLAYER" in
            afplay)
                afplay "$FAHHH_SOUND" &>/dev/null &
                ;;
            mpg123)
                mpg123 -q "$FAHHH_SOUND" &>/dev/null &
                ;;
            mpv)
                mpv --no-video --really-quiet "$FAHHH_SOUND" &>/dev/null &
                ;;
            ffplay)
                ffplay -nodisp -autoexit -loglevel quiet "$FAHHH_SOUND" &>/dev/null &
                ;;
            cvlc)
                cvlc --play-and-exit --quiet "$FAHHH_SOUND" &>/dev/null &
                ;;
            play)
                play -q "$FAHHH_SOUND" &>/dev/null &
                ;;
            mplayer)
                mplayer -really-quiet "$FAHHH_SOUND" &>/dev/null &
                ;;
            pw-play)
                pw-play "$FAHHH_SOUND" &>/dev/null &
                ;;
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
