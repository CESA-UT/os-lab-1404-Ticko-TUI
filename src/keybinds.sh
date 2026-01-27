#!/usr/bin/env bash

#
# keybinds.sh — Keyboard handler with Vim bindings for Ticko TUI
#
# Handles raw keyboard input and translates to actions.
#

# Key constants
KEY_UP="UP"
KEY_DOWN="DOWN"
KEY_LEFT="LEFT"
KEY_RIGHT="RIGHT"
KEY_ENTER="ENTER"
KEY_ESCAPE="ESCAPE"
KEY_BACKSPACE="BACKSPACE"
KEY_TAB="TAB"

# Last key pressed (for multi-key sequences)
LAST_KEY=""
LAST_KEY_TIME=0

###########################################
# Read a single key (handles escape seqs)
###########################################
read_key() {
    local timeout="${1:-}"
    local key=""
    local extra=""

    # Read first character
    if [[ -n $timeout ]]; then
        IFS= read -rsn1 -t $timeout key 2>/dev/null || return 1
        local code="$?"
        if [[ "$code" != "0" ]]; then
            return $code
        fi
    else
        IFS= read -rsn1 key 2>/dev/null || return 1
    fi

    # Handle escape sequences
    if [[ "$key" == $'\x1b' ]]; then
        # Check if there's more input (arrow keys, etc.)
        if IFS= read -rsn1 -t 0.01 extra 2>/dev/null; then
            if [[ "$extra" == "[" ]]; then
                IFS= read -rsn1 extra 2>/dev/null
                case "$extra" in
                    A) echo "$KEY_UP"; return 0 ;;
                    B) echo "$KEY_DOWN"; return 0 ;;
                    C) echo "$KEY_RIGHT"; return 0 ;;
                    D) echo "$KEY_LEFT"; return 0 ;;
                    H) echo "HOME"; return 0 ;;
                    F) echo "END"; return 0 ;;
                    3)
                        IFS= read -rsn1 _ 2>/dev/null  # consume ~
                        echo "DELETE"
                        return 0
                        ;;
                    5)
                        IFS= read -rsn1 _ 2>/dev/null  # consume ~
                        echo "PAGEUP"
                        return 0
                        ;;
                    6)
                        IFS= read -rsn1 _ 2>/dev/null  # consume ~
                        echo "PAGEDOWN"
                        return 0
                        ;;
                esac
            elif [[ "$extra" == "O" ]]; then
                IFS= read -rsn1 extra 2>/dev/null
                case "$extra" in
                    H) echo "HOME"; return 0 ;;
                    F) echo "END"; return 0 ;;
                esac
            fi
        fi
        # Plain escape
        echo "$KEY_ESCAPE"
        return 0
    fi

    # Handle special keys
    case "$key" in
        $'\n'|$'\r'|'')
            echo "$KEY_ENTER"
            return 0
            ;;
        $'\x7f'|$'\b')
            echo "$KEY_BACKSPACE"
            return 0
            ;;
        $'\t')
            echo "$KEY_TAB"
            return 0
            ;;
    esac

    # Regular character
    echo "$key"
    return 0
}

###########################################
# Process key and return action
###########################################
process_key() {
    local key="$1"
    local current_time
    current_time=$(date +%s)

    # Check for multi-key timeout (500ms approximation)
    if (( current_time - LAST_KEY_TIME > 1 )); then
        LAST_KEY=""
    fi

    local action=""

    # Navigation keys
    case "$key" in
        j|"$KEY_DOWN")
            action="MOVE_DOWN"
            LAST_KEY=""
            ;;
        k|"$KEY_UP")
            action="MOVE_UP"
            LAST_KEY=""
            ;;
        g)
            action="GOTO_FIRST"
            LAST_KEY=""
            ;;
        G)
            action="GOTO_LAST"
            LAST_KEY=""
            ;;

        # Actions
        a|o)
            action="ADD"
            LAST_KEY=""
            ;;
        x|" ")
            action="TOGGLE_COMPLETE"
            LAST_KEY=""
            ;;
        D)
            action="DELETE"
            LAST_KEY=""
            ;;
        e)
            action="EDIT_DESC"
            LAST_KEY=""
            ;;
        d)
            action="SET_DUE"
            LAST_KEY=""
            ;;
        t)
            action="EDIT_TITLE"
            LAST_KEY=""
            ;;

        # Search
        /)
            action="SEARCH"
            LAST_KEY=""
            ;;
        n)
            action="SEARCH_NEXT"
            LAST_KEY=""
            ;;
        N)
            action="SEARCH_PREV"
            LAST_KEY=""
            ;;

        # General
        s)
            action="SAVE"
            LAST_KEY=""
            ;;
        \?)
            action="HELP"
            LAST_KEY=""
            ;;
        q)
            action="QUIT"
            LAST_KEY=""
            ;;
        "$KEY_ENTER")
            action="SELECT"
            LAST_KEY=""
            ;;
        "$KEY_ESCAPE")
            action="CANCEL"
            LAST_KEY=""
            ;;

        # Page navigation
        PAGEUP)
            action="PAGE_UP"
            LAST_KEY=""
            ;;
        PAGEDOWN)
            action="PAGE_DOWN"
            LAST_KEY=""
            ;;
        HOME)
            action="GOTO_FIRST"
            LAST_KEY=""
            ;;
        END)
            action="GOTO_LAST"
            LAST_KEY=""
            ;;
        H)
            action="GOTO_FIRST_VISIBLE"
            LAST_KEY=""
            ;;
        L)
            action="GOTO_LAST_VISIBLE"
            LAST_KEY=""
            ;;

        r)
            action="REFRESH"
            LAST_KEY=""
            ;;

        *)
            # Unknown key
            action="NONE"
            LAST_KEY=""
            ;;
    esac

    LAST_KEY="$key"
    LAST_KEY_TIME="$current_time"

    echo "$action"
}

###########################################
# Read a line of text input with editing
###########################################
read_input_line() {
    local prompt="$1"
    local default="${2:-}"
    local max_len="${3:-100}"

    local input="$default"
    local cursor=${#input}
    local key

    # Show prompt
    echo -n "$prompt"
    echo -n "$input"

    while true; do
        key=$(read_key) || break

        case "$key" in
            "$KEY_ENTER")
                echo
                echo "$input"
                return 0
                ;;
            "$KEY_ESCAPE")
                echo
                return 1
                ;;
            "$KEY_BACKSPACE")
                if (( cursor > 0 )); then
                    input="${input:0:cursor-1}${input:cursor}"
                    (( cursor-- ))
                    # Redraw
                    echo -ne "\r\033[K$prompt$input"
                    # Position cursor
                    local back=$(( ${#input} - cursor ))
                    (( back > 0 )) && echo -ne "\033[${back}D"
                fi
                ;;
            "$KEY_LEFT")
                if (( cursor > 0 )); then
                    (( cursor-- ))
                    echo -ne "\033[D"
                fi
                ;;
            "$KEY_RIGHT")
                if (( cursor < ${#input} )); then
                    (( cursor++ ))
                    echo -ne "\033[C"
                fi
                ;;
            HOME)
                echo -ne "\r\033[K$prompt$input"
                echo -ne "\033[${#input}D"
                cursor=0
                ;;
            END)
                echo -ne "\r\033[K$prompt$input"
                cursor=${#input}
                ;;
            DELETE)
                if (( cursor < ${#input} )); then
                    input="${input:0:cursor}${input:cursor+1}"
                    echo -ne "\r\033[K$prompt$input"
                    local back=$(( ${#input} - cursor ))
                    (( back > 0 )) && echo -ne "\033[${back}D"
                fi
                ;;
            *)
                # Regular character - insert at cursor
                if [[ ${#key} -eq 1 && ${#input} -lt $max_len ]]; then
                    # Printable character
                    if [[ "$key" =~ [[:print:]] ]]; then
                        input="${input:0:cursor}${key}${input:cursor}"
                        (( cursor++ ))
                        echo -ne "\r\033[K$prompt$input"
                        local back=$(( ${#input} - cursor ))
                        (( back > 0 )) && echo -ne "\033[${back}D"
                    fi
                fi
                ;;
        esac
    done

    return 1
}
