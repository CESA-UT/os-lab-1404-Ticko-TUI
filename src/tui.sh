#!/usr/bin/env bash

#
# tui.sh — Terminal User Interface for Ticko
#
# Full-screen TUI with scrolling, colors, and Vim keybinds.
#

# TUI State
TUI_SELECTED=0          # Currently selected index (in visible list)
TUI_SCROLL_OFFSET=0     # First visible item index
TUI_RUNNING=1           # Main loop control
TUI_SEARCH_QUERY=""     # Current search query
TUI_SEARCH_RESULTS=()   # IDs matching search
TUI_SEARCH_IDX=0        # Current search result index
TUI_MESSAGE=""          # Status message to show
TUI_MESSAGE_TYPE=""     # info/success/error/warning

# Terminal dimensions
TERM_ROWS=24
TERM_COLS=80

# Layout constants
HEADER_LINES=3
FOOTER_LINES=2
STATUS_LINES=1

# Colors for TUI
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_ITALIC="\033[3m"
C_UNDERLINE="\033[4m"
C_BLINK="\033[5m"
C_REVERSE="\033[7m"
C_STRIKETHROUGH="\033[9m"

C_BLACK="\033[30m"
C_RED="\033[31m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_BLUE="\033[34m"
C_MAGENTA="\033[35m"
C_CYAN="\033[36m"
C_WHITE="\033[37m"

C_BG_BLACK="\033[40m"
C_BG_RED="\033[41m"
C_BG_GREEN="\033[42m"
C_BG_YELLOW="\033[43m"
C_BG_BLUE="\033[44m"
C_BG_MAGENTA="\033[45m"
C_BG_CYAN="\033[46m"
C_BG_WHITE="\033[47m"

###########################################
# Get terminal dimensions
###########################################
_get_term_size() {
    if command -v tput &>/dev/null; then
        TERM_ROWS=$(tput lines 2>/dev/null || echo 24)
        TERM_COLS=$(tput cols 2>/dev/null || echo 80)
    elif [[ -n "$LINES" && -n "$COLUMNS" ]]; then
        TERM_ROWS="$LINES"
        TERM_COLS="$COLUMNS"
    fi
}

###########################################
# Calculate visible lines for todo list
###########################################
_visible_lines() {
    echo $(( TERM_ROWS - HEADER_LINES - FOOTER_LINES - STATUS_LINES - 1 ))
}

###########################################
# Move cursor to position
###########################################
_cursor_to() {
    local row="$1"
    local col="$2"
    echo -ne "\033[${row};${col}H"
}

###########################################
# Clear screen
###########################################
_clear_screen() {
    echo -ne "\033[2J\033[H"
}

###########################################
# Hide/show cursor
###########################################
_hide_cursor() {
    echo -ne "\033[?25l"
}

_show_cursor() {
    echo -ne "\033[?25h"
}

###########################################
# Enter/exit alternate screen buffer
###########################################
_enter_alt_screen() {
    echo -ne "\033[?1049h"
}

_exit_alt_screen() {
    echo -ne "\033[?1049l"
}

###########################################
# Draw horizontal line
###########################################
_draw_hline() {
    local width="$1"
    local char="${2:-─}"
    local i
    for (( i=0; i<width; i++ )); do
        echo -n "$char"
    done
}

###########################################
# Draw centered text
###########################################
_draw_centered() {
    local text="$1"
    local width="$2"
    local len=${#text}
    local pad=$(( (width - len) / 2 ))

    local additional_space=""
    if (( $len % 2 == 0 )); then
        additional_space=" "
    fi
    
    printf "%*s%s%*s$additional_space" "$pad" "" "$text" "$pad" ""
}

###########################################
# Draw header
###########################################
_draw_header() {
    local count
    count=$(get_todo_count)
    
    _cursor_to 1 1
    
    # Top line
    echo -ne "${C_CYAN}${C_BOLD}"
    echo -n "╭"
    _draw_hline $(( TERM_COLS - 2 )) "─"
    echo -n "╮"
    echo -ne "${C_RESET}"
    
    # Title line
    _cursor_to 2 1
    echo -ne "${C_CYAN}${C_BOLD}│${C_RESET}"
    
    local title=" ✓ TICKO - TODO Manager "
    local info="[$count items]"
    local title_len=${#title}
    local info_len=${#info}
    local space=$(( TERM_COLS - 2 - title_len - info_len ))
    
    echo -ne "${C_BOLD}${C_YELLOW}$title${C_RESET}"
    printf "%*s" "$space" ""
    echo -ne "${C_DIM}$info${C_RESET}"
    echo -ne "${C_CYAN}${C_BOLD}│${C_RESET}"
    
    # Bottom line
    _cursor_to 3 1
    echo -ne "${C_CYAN}${C_BOLD}"
    echo -n "├"
    _draw_hline $(( TERM_COLS - 2 )) "─"
    echo -n "┤"
    echo -ne "${C_RESET}"
}

###########################################
# Draw footer
###########################################
_draw_footer() {
    local footer_row=$(( TERM_ROWS - FOOTER_LINES ))
    
    # Separator line
    _cursor_to "$footer_row" 1
    echo -ne "${C_CYAN}${C_BOLD}"
    echo -n "├"
    _draw_hline $(( TERM_COLS - 2 )) "─"
    echo -n "┤"
    echo -ne "${C_RESET}"
    
    # Help hints
    _cursor_to $(( footer_row + 1 )) 1
    echo -ne "${C_CYAN}${C_BOLD}│${C_RESET}"
    
    local hints=" j/k:Move  a:Add  x:Done  e:Edit  s:Save  ?:Help  q:Quit "
    local hints_len=${#hints}
    local pad=$(( TERM_COLS - 2 - hints_len ))
    
    echo -ne "${C_DIM}$hints${C_RESET}"
    printf "%*s" "$pad" ""
    echo -ne "${C_CYAN}${C_BOLD}│${C_RESET}"
    
    # Bottom border
    _cursor_to $(( footer_row + 2 )) 1
    echo -ne "${C_CYAN}${C_BOLD}"
    echo -n "╰"
    _draw_hline $(( TERM_COLS - 2 )) "─"
    echo -n "╯"
    echo -ne "${C_RESET}"
}

###########################################
# Draw status bar
###########################################
_draw_status() {
    local status_row=$(( TERM_ROWS - FOOTER_LINES - STATUS_LINES ))
    
    _cursor_to "$status_row" 1
    echo -ne "${C_CYAN}${C_BOLD}│${C_RESET}"
    
    # Status message
    local msg=""
    local color="$C_RESET"
    
    if [[ -n "$TUI_MESSAGE" ]]; then
        msg="$TUI_MESSAGE"
        case "$TUI_MESSAGE_TYPE" in
            success) color="${C_GREEN}" ;;
            error)   color="${C_RED}" ;;
            warning) color="${C_YELLOW}" ;;
            info)    color="${C_BLUE}" ;;
        esac
    elif [[ -n "$TUI_SEARCH_QUERY" ]]; then
        local temp="Search:  [${TUI_SEARCH_IDX}/${#TUI_SEARCH_RESULTS[@]}]"
        local max_query_length=$(( TERM_COLS - ${#temp} - 2 ))
        local query_text="$TUI_SEARCH_QUERY"
        if [[ "${#query_text}" -gt max_query_length ]]; then
            local size=$(( (max_query_length - 1) / 2 ))
            query_text="${query_text:0:size}…${query_text:$(( ${#query_text} - size )):size}"
        fi
        msg="Search: $query_text [${TUI_SEARCH_IDX}/${#TUI_SEARCH_RESULTS[@]}]"
        color="${C_MAGENTA}"
    elif (( DATA_MODIFIED )); then
        msg="[Modified - press 's' to save]"
        color="${C_YELLOW}"
    fi
    
    local msg_len=${#msg}
    if (( msg_len > TERM_COLS - 2 )); then
        local size=$(( (TERM_COLS - 3) / 2 ))
        msg="${msg:0:size}…${msg:$(( ${#msg} - size )):size}"
        msg_len=${#msg}
    fi
    local pad=$(( TERM_COLS - 2 - msg_len ))
    
    echo -ne "${color}${msg}${C_RESET}"
    (( pad > 0 )) && printf "%*s" "$pad" ""
    echo -ne "${C_CYAN}${C_BOLD}│${C_RESET}"
    
    # Clear message after showing
    TUI_MESSAGE=""
    TUI_MESSAGE_TYPE=""
}

###########################################
# Draw a single TODO item
###########################################
_draw_todo_item() {
    local idx="$1"       # Position in display
    local id="$2"        # TODO ID
    local is_selected="$3"
    
    local title desc due completed
    local item
    item=$(get_todo "$id")
    IFS='|' read -r title desc due completed <<< "$item"
    
    local row=$(( HEADER_LINES + idx + 1 ))
    _cursor_to "$row" 1
    
    # Left border
    echo -ne "${C_CYAN}${C_BOLD}│${C_RESET}"
    
    # Selection indicator + checkbox
    if [[ "$is_selected" == "1" ]]; then
        echo -ne "${C_REVERSE}"
    fi
    
    # Checkbox
    if [[ "$completed" == "1" ]]; then
        echo -ne "${C_GREEN}[✓]${C_RESET}"
    else
        echo -ne "${C_WHITE}[ ]${C_RESET}"
    fi
    
    if [[ "$is_selected" == "1" ]]; then
        echo -ne "${C_REVERSE}"
    fi
    
    # ID
    printf " ${C_DIM}#%-3s${C_RESET}" "$id"
    
    if [[ "$is_selected" == "1" ]]; then
        echo -ne "${C_REVERSE}"
    fi

    # Calculate available space
    local show_desc=$(( TERM_COLS > 80 && ${#desc} > 0 ))
    local prefix_len=10  # "│[✓] #123 "
    local due_len=${#due}
    local suffix_len=$(( $due_len + 2 ))
    local title_max=$(( show_desc?20:(TERM_COLS - prefix_len - suffix_len) ))
    
    # Color based on status
    if [[ "$completed" == "1" ]]; then
        echo -ne "${C_DIM}${C_STRIKETHROUGH}"
    elif is_overdue "$id" 2>/dev/null; then
        echo -ne "${C_RED}${C_BOLD}"
    fi
    
    # Truncate title if needed
    if (( ${#title} > title_max )); then
        title="${title:0:title_max-1}…"
    fi
    
    printf "%-${title_max}s" "$title"
    echo -ne "${C_RESET}"
    
    if [[ "$is_selected" == "1" ]]; then
        echo -ne "${C_REVERSE}"
    fi

    if [[ "$show_desc" == "1" ]]; then
        local desc_max=$(( TERM_COLS - prefix_len - title_max - suffix_len - 2 ))

        # Color based on status
        if [[ "$completed" == "1" ]]; then
            echo -ne "${C_DIM}${C_STRIKETHROUGH}"
        elif is_overdue "$id" 2>/dev/null; then
            echo -ne "${C_RED}${C_BOLD}"
        fi
        
        if (( ${#desc} > desc_max )); then
            title="${desc:0:desc_max-1}…"
        fi
        
        printf "  %-${desc_max}s" "$desc"
        echo -ne "${C_RESET}"
        
        if [[ "$is_selected" == "1" ]]; then
            echo -ne "${C_REVERSE}"
        fi
    fi
    
    # Due date
    if [[ "$due" != "NULL" && -n "$due" ]]; then
        if is_overdue "$id" 2>/dev/null; then
            echo -ne "${C_RED} ${due} ${C_RESET}"
        else
            echo -ne "${C_DIM} ${due} ${C_RESET}"
        fi
    else
        if [[ "$completed" == "1" ]]; then
            echo -ne "${C_DIM}${C_STRIKETHROUGH}"
        elif is_overdue "$id" 2>/dev/null; then
            echo -ne "${C_RED}${C_BOLD}"
        fi
        printf "%5s${C_RESET}"
        if [[ "$is_selected" == "1" ]]; then
            echo -ne "${C_REVERSE}"
        fi
        printf " "
    fi
    
    echo -ne "${C_RESET}"
    
    # Right border
    echo -ne "${C_CYAN}${C_BOLD}│${C_RESET}"
}

###########################################
# Draw empty list message
###########################################
_draw_empty_list() {
    local visible=$(_visible_lines)
    local mid=$(( visible / 2 ))
    
    for (( i=0; i<visible; i++ )); do
        local row=$(( HEADER_LINES + i + 1 ))
        _cursor_to "$row" 1
        echo -ne "${C_CYAN}${C_BOLD}│${C_RESET}"
        
        if (( i == mid - 1 )); then
            local msg="No TODOs yet!"
            _draw_centered "$msg" $(( TERM_COLS - 2 ))
        elif (( i == mid )); then
            local msg="Press 'o' to add your first item"
            echo -ne "${C_DIM}"
            _draw_centered "$msg" $(( TERM_COLS - 2 ))
            echo -ne "${C_RESET}"
        else
            printf "%*s" $(( TERM_COLS - 2 )) ""
        fi
        
        echo -ne "${C_CYAN}${C_BOLD}│${C_RESET}"
    done
}

###########################################
# Draw the TODO list items
###########################################
_draw_list_items() {
    local visible=$1
    local draw_quick=${2:-}

    # Get all IDs
    local ids=()
    while IFS= read -r id_; do
        [[ -n "$id_" ]] && ids+=("$id_")
    done < <(get_all_todo_ids)
    
    # Draw selected, first, last, and draw_quick(if any)
    _draw_todo_item "$(( TUI_SELECTED - TUI_SCROLL_OFFSET ))" "${ids[$TUI_SELECTED]}" "1"
    if [[ -n "$draw_quick" && "$draw_quick" -ne "$TUI_SELECTED" && "$draw_quick" -gt "$TUI_SCROLL_OFFSET" && "$draw_quick" -lt "$(( TUI_SCROLL_OFFSET + visible ))" ]]; then
        _draw_todo_item "$(( draw_quick - TUI_SCROLL_OFFSET ))" "${ids[$draw_quick]}" "0"
    fi
    if [[ "$TUI_SCROLL_OFFSET" -ne "$TUI_SELECTED" ]]; then
        _draw_todo_item "0" "${ids[$TUI_SCROLL_OFFSET]}" "0"
    fi
    local last_id=$(( TUI_SCROLL_OFFSET + visible - 1 ))
    if (( last_id >= count )); then
        last_id=$(( count - 1 ))
    fi
    if [[ "$last_id" -ne "$TUI_SELECTED" && "$last_id" -ne "$TUI_SCROLL_OFFSET" ]]; then
        _draw_todo_item "$(( last_id - TUI_SCROLL_OFFSET ))" "${ids[$last_id]}" "0"
    fi
    
    # Draw visible items
    local i
    for (( i=1; i<visible; i++ )); do
        local list_idx=$(( TUI_SCROLL_OFFSET + i ))
        if (( list_idx == TUI_SELECTED )); then
            continue
        fi
        local row=$(( HEADER_LINES + i + 1 ))
        
        _cursor_to "$row" 1
        
        if (( list_idx < count )); then
            local id="${ids[$list_idx]}"
            _draw_todo_item "$i" "$id" "0"
        else
            # Empty row
            echo -ne "${C_CYAN}${C_BOLD}│${C_RESET}"
            printf "%*s" $(( TERM_COLS - 2 )) ""
            echo -ne "${C_CYAN}${C_BOLD}│${C_RESET}"
        fi
    done

    _DRAW_LIST_PID=
}

_DRAW_LIST_PID=
###########################################
# Draw the TODO list
###########################################
_draw_list() {
    local sync=${1:-}
    local draw_quick=${2:-}

    local count
    count=$(get_todo_count)
    local visible=$(_visible_lines)
    
    if (( count == 0 )); then
        _draw_empty_list
        return
    fi
    
    # Adjust scroll offset
    if (( TUI_SELECTED < TUI_SCROLL_OFFSET )); then
        TUI_SCROLL_OFFSET=$TUI_SELECTED
    elif (( TUI_SELECTED >= TUI_SCROLL_OFFSET + visible )); then
        TUI_SCROLL_OFFSET=$(( TUI_SELECTED - visible + 1 ))
    fi

    # Kill the last _draw_list_items if still running
    if [[ -n "$_DRAW_LIST_PID" ]]; then
        kill "$_DRAW_LIST_PID" 2>/dev/null || true
        _DRAW_LIST_PID=
    fi

    # Run _draw_list_items
    if [[ -n "$sync" ]]; then
        _draw_list_items $visible "$draw_quick"
    else
        _draw_list_items $visible "$draw_quick" &
        _DRAW_LIST_PID="$!"
    fi
}

###########################################
# Full screen redraw
###########################################
_redraw() {
    _get_term_size
    _clear_screen
    _hide_cursor
    if (( TERM_COLS < 60 || TERM_ROWS < 10 )); then
        echo -e "${C_RED}${C_BOLD}Window is too small for TUI!"
        echo -en "${C_RESET}Press any key to update..."
    else
        _draw_header
        _draw_list "1"
        _draw_status
        _draw_footer
    fi
}

###########################################
# Show status message
###########################################
_show_message() {
    local msg="$1"
    local type="${2:-info}"
    
    TUI_MESSAGE="$msg"
    TUI_MESSAGE_TYPE="$type"
}

###########################################
# Get currently selected TODO ID
###########################################
_get_selected_id() {
    local count
    count=$(get_todo_count)
    
    if (( count == 0 || TUI_SELECTED >= count )); then
        return 1
    fi
    
    local ids=()
    while IFS= read -r id_; do
        [[ -n "$id_" ]] && ids+=("$id_")
    done < <(get_all_todo_ids)
    
    echo "${ids[$TUI_SELECTED]}"
}

_input_dialog_result=""
###########################################
# Input dialog (overlay)                  #
# Output Variable: $_input_dialog_result  #
###########################################
_input_dialog() {
    local title="$1"
    local prompt="$2"
    local default="${3:-}"
    
    _get_term_size
    
    local dialog_width=60
    local dialog_height=5
    local start_row=$(( (TERM_ROWS - dialog_height) / 2 ))
    local start_col=$(( (TERM_COLS - dialog_width) / 2 ))
    
    # Draw dialog box
    _cursor_to "$start_row" "$start_col"
    echo -ne "${C_BG_BLUE}${C_WHITE}${C_BOLD}"
    echo -n "╭"
    _draw_hline $(( dialog_width - 2 )) "─"
    echo -n "╮"
    
    _cursor_to $(( start_row + 1 )) "$start_col"
    echo -n "│"
    printf " %-*s" $(( dialog_width - 3 )) "$title"
    echo -n "│"
    
    _cursor_to $(( start_row + 2 )) "$start_col"
    echo -n "├"
    _draw_hline $(( dialog_width - 2 )) "─"
    echo -n "┤"
    
    _cursor_to $(( start_row + 3 )) "$start_col"
    echo -n "│ "
    echo -ne "${C_RESET}${C_BG_BLUE}${C_WHITE}"

    _show_cursor
    
    # Read input
    local input=""
    local cursor=0
    local max_input=$(( dialog_width - 5 ))
    
    input="$default"
    cursor=${#input}
    
    echo -n "$prompt"

    start_pos=0
    end_pos="$max_input"
    visible_input="$input"
    cursor_col=$(( start_col + 2 + ${#prompt} + cursor ))
    if [[ "${#input}" -gt "$max_input" ]]; then
        start_pos="$(( ${#input} - max_input + 1 ))"
        cursor_col=$(( start_col + 2 + ${#prompt} + end_pos ))
        visible_input="…${input:start_pos:end_pos}"
    fi

    echo -n "$visible_input"
    printf "%*s" $(( max_input - ${#visible_input} - ${#prompt} + 2 )) ""
    echo -ne "${C_BOLD}│"

    _cursor_to $(( start_row + 4 )) $(( $start_col ))
    echo -n "╰"
    _draw_hline $(( dialog_width - 2 )) "─"
    echo -n "╯"
    echo -ne "${C_RESET}"
    
    # Position cursor
    _cursor_to $(( start_row + 3 )) "$cursor_col"
    
    local key
    while true; do
        key=$(read_key) || break

        case "$key" in
            "$KEY_ENTER")
                _hide_cursor
                echo -ne "${C_RESET}"
                _input_dialog_result=$input
                break
                ;;
            "$KEY_ESCAPE")
                _hide_cursor
                echo -ne "${C_RESET}" _input_dialog_result=$default
                break
                ;;
            "$KEY_BACKSPACE")
                if (( cursor > 0 )); then
                    input="${input:0:cursor-1}${input:cursor}"
                    cursor=$(( cursor - 1 ))
                fi
                ;;
            "DELETE")
                if (( cursor >= 0 && cursor < ${#input} )); then
                    input="${input:0:cursor}${input:cursor+1}"
                fi
                ;;
            "$KEY_LEFT")
                if [[ "$cursor" -gt "0" ]]; then
                    cursor=$(( cursor - 1 ))
                fi
                ;;
            "$KEY_RIGHT")
                if [[ "$cursor" -lt "${#input}" ]]; then
                    cursor=$(( cursor + 1 ))
                fi
                ;;
            "HOME")
                cursor=0
                ;;
            "END")
                cursor="${#input}"
                ;;
            *)
                # && ${#input} -lt $max_input 
                if [[ ${#key} -eq 1 && "$key" =~ [[:print:]] ]]; then
                    input="${input:0:cursor}${key}${input:cursor}"
                    cursor=$(( $cursor + 1 ))
                fi
                ;;
        esac

        # Redraw input line
        _cursor_to $(( start_row + 3 )) $(( $start_col ))
        echo -ne "${C_BG_BLUE}${C_WHITE}"
        echo -n "│ $prompt"

        start_pos=0
        end_pos="$max_input"
        visible_input="$input"
        cursor_col=$(( start_col + 2 + ${#prompt} + cursor ))
        if [[ "${#input}" -gt "$max_input" ]]; then
            if [[ "$cursor" -gt "$max_input" ]]; then
                start_pos="$(( cursor - max_input + 1 ))"
                cursor_col=$(( start_col + 2 + ${#prompt} + end_pos ))
                if [[ "$cursor" < "${#input}" ]]; then
                    end_pos=$(( $max_input - 1 ))
                    visible_input="…${input:start_pos:end_pos}…"
                else
                    visible_input="…${input:start_pos:end_pos}"
                fi
            else
                start_pos=0
                visible_input="${input:start_pos:end_pos}…"
            fi
        fi

        echo -n "$visible_input"
        printf "%*s" $(( max_input - ${#visible_input} - ${#prompt} + 2 )) ""
        echo -ne "${C_BOLD}│${C_RESET}"
        
        # Position cursor
        _cursor_to $(( start_row + 3 )) "$cursor_col"
    done
    
    _hide_cursor
    echo -ne "${C_RESET}"
}

_confirm_dialog_result=""
############################################
# Confirm dialog (overlay)                 #
# Output Variable: $_confirm_dialog_result #
# Possible results: "Y" "N" "ESC"          #
############################################
_confirm_dialog() {
    local title="$1"
    local prompt="$2"
    local choice="${3:-Y}"

    if [[ "$choice" != "Y" && "$choice" != "N" ]]; then
        choice="Y"
    fi
    
    _get_term_size
    
    local dialog_width=60
    local dialog_height=5
    local start_row=$(( (TERM_ROWS - dialog_height) / 2 ))
    local start_col=$(( (TERM_COLS - dialog_width) / 2 ))
    
    # Draw dialog box
    _cursor_to "$start_row" "$start_col"
    echo -ne "${C_BG_BLUE}${C_WHITE}${C_BOLD}"
    echo -n "╭"
    _draw_hline $(( dialog_width - 2 )) "─"
    echo -n "╮"
    
    _cursor_to $(( start_row + 1 )) "$start_col"
    echo -n "│"
    printf " %-*s" $(( dialog_width - 3 )) "$title"
    echo -n "│"
    
    _cursor_to $(( start_row + 2 )) "$start_col"
    echo -n "├"
    _draw_hline $(( dialog_width - 2 )) "─"
    echo -n "┤"
    
    _cursor_to $(( start_row + 3 )) "$start_col"
    echo -n "│ "
    echo -ne "${C_RESET}${C_BG_BLUE}${C_WHITE}"

    _cursor_to $(( start_row + 3 )) "$start_col"
    echo -n "│"
    printf " %-*s" $(( dialog_width - 3 )) "$prompt"
    echo -n "│"
    
    _cursor_to $(( start_row + 4 )) "$start_col"
    echo -n "├"
    _draw_hline $(( dialog_width - 2 )) "─"
    echo -n "┤"
    
    _cursor_to $(( start_row + 5 )) "$start_col"
    echo -n "│ "
    echo -ne "${C_RESET}${C_BG_BLUE}${C_WHITE}${C_BOLD}"

    local max_input=$(( dialog_width - 5 ))
    
    if [[ "$choice" == "Y" ]]; then
        echo -en "${C_REVERSE} Yes ${C_RESET}${C_BG_BLUE}${C_WHITE}${C_BOLD}"
    else
        echo -n " Yes "
    fi
    printf "%*s" $(( max_input - 7 )) ""
    if [[ "$choice" == "N" ]]; then
        echo -en "${C_REVERSE} No ${C_RESET}${C_BG_BLUE}${C_WHITE}${C_BOLD}"
    else
        echo -n " No "
    fi
    echo -ne "${C_BOLD}│"

    _cursor_to $(( start_row + 6 )) $(( $start_col ))
    echo -n "╰"
    _draw_hline $(( dialog_width - 2 )) "─"
    echo -n "╯"
    echo -ne "${C_RESET}"

    # Position cursor
    _cursor_to $(( start_row + 5 )) $(( start_col + 2 ))
    
    local key
    while true; do
        key=$(read_key) || break

        case "$key" in
            "$KEY_ENTER")
                _confirm_dialog_result=$choice
                break
                ;;
            "$KEY_ESCAPE")
                _confirm_dialog_result="ESC"
                break
                ;;
            "$KEY_LEFT"|"h")
                choice="Y"
                ;;
            "$KEY_RIGHT"|"l")
                choice="N"
                ;;
            "y"|"Y")
                _confirm_dialog_result="Y"
                break
                ;;
            "n"|"N")
                _confirm_dialog_result="N"
                break
                ;;
        esac
        
        # Redraw the buttons
        _cursor_to $(( start_row + 5 )) $(( $start_col ))
        echo -ne "${C_BG_BLUE}${C_WHITE}"
        echo -n "│ "
        if [[ "$choice" == "Y" ]]; then
            echo -en "${C_REVERSE} Yes ${C_RESET}${C_BG_BLUE}${C_WHITE}${C_BOLD}"
        else
            echo -n " Yes "
        fi
        printf "%*s" $(( max_input - 7 )) ""
        if [[ "$choice" == "N" ]]; then
            echo -en "${C_REVERSE} No ${C_RESET}${C_BG_BLUE}${C_WHITE}${C_BOLD}"
        else
            echo -n " No "
        fi
        echo -ne "${C_BOLD}│${C_RESET}"
        
        # Position cursor
        _cursor_to $(( start_row + 5 )) $(( start_col + 2 ))
    done
    
    echo -ne "${C_RESET}"
}


###########################################
# Show help overlay
###########################################
_show_help_overlay() {
    _get_term_size
    
    local help_width=46
    local help_height=22
    local start_row=$(( (TERM_ROWS - help_height) / 2 ))
    local start_col=$(( (TERM_COLS - help_width) / 2 ))
    
    (( start_row < 1 )) && start_row=1
    (( start_col < 1 )) && start_col=1
    
    # Draw help box
    _cursor_to "$start_row" "$start_col"
    echo -ne "${C_BG_BLUE}${C_WHITE}${C_BOLD}"
    echo -n "╭"
    _draw_hline $(( help_width - 2 )) "─"
    echo -n "╮"
    
    local row=$(( start_row + 1 ))
    _cursor_to "$row" "$start_col"
    echo -n "│"
    printf "  %-*s" $(( help_width - 4 )) "TICKO HELP"
    echo -n "│"
    
    (( row++ ))
    _cursor_to "$row" "$start_col"
    echo -n "├"
    _draw_hline $(( help_width - 2 )) "─"
    echo -n "┤"
    
    local -a help_lines=(
        ""
        "  NAVIGATION"
        "    j             Move down"
        "    k             Move up"
        "    g             Go to first item"
        "    G             Go to last item"
        ""
        "  ACTIONS"
        "    a / o         Add new item"
        "    x / Space     Toggle completion"
        "    D             Delete item"
        "    e             Edit description"
        "    t             Edit title"
        "    d             Set due date"
        ""
        "  OTHER"
        "    /             Search"
        "    n / N         Next/Prev result"
        "    s             Save changes"
        "    ?             Show this help"
        "    q             Quit"
        ""
        "          Press any key to close"
    )
    
    for line in "${help_lines[@]}"; do
        (( row++ ))
        _cursor_to "$row" "$start_col"
        echo -n "│"
        printf " %-*s" $(( help_width - 3 )) "$line"
        echo -n "│"
    done
    
    (( row++ ))
    _cursor_to "$row" "$start_col"
    echo -n "╰"
    _draw_hline $(( help_width - 2 )) "─"
    echo -n "╯"
    
    echo -ne "${C_RESET}"
    
    # Wait for key
    read_key >/dev/null 2>&1
}

###########################################
# Action handlers
###########################################

_action_move_down() {
    local count
    count=$(get_todo_count)
    if (( TUI_SELECTED < count - 1 )); then
        TUI_SELECTED=$[ $TUI_SELECTED + 1 ]
    fi
}

_action_move_up() {
    if (( TUI_SELECTED > 0 )); then
        TUI_SELECTED=$[ $TUI_SELECTED - 1 ]
    fi
}

_action_goto_first() {
    TUI_SELECTED=0
    TUI_SCROLL_OFFSET=0
}

_action_goto_last() {
    local count
    count=$(get_todo_count)
    if (( count > 0 )); then
        TUI_SELECTED=$(( count - 1 ))
    fi
}

_action_add() {
    _input_dialog "Add New TODO" "" ""
    if title="$_input_dialog_result"; then
        if [[ -n "$title" ]]; then
            local new_id
            new_id=$NEXT_TODO_ID
            (( NEXT_TODO_ID++ ))
            add_todo "$new_id" "$title" "" "NULL"
            _show_message "Added TODO #$new_id" "success"
            # Select the new item
            local count
            count=$(get_todo_count)
            TUI_SELECTED=$(( count - 1 ))
        fi
    fi
}

_action_toggle_complete() {
    local id
    if id=$(_get_selected_id); then
        toggle_complete "$id"
        if is_completed "$id"; then
            _show_message "Marked #$id as completed" "success"
        else
            _show_message "Marked #$id as pending" "info"
        fi
    fi
}

_action_delete() {
    local id
    if id=$(_get_selected_id); then
        _confirm_dialog "Confirm Delete" "Are you sure you want to remove TODO #$id?" "N"
        if [[ "$_confirm_dialog_result" == "Y" ]]; then
            remove_todo "$id"
            _show_message "Deleted TODO #$id" "warning"
            
            # Adjust selection
            local count
            count=$(get_todo_count)
            if (( TUI_SELECTED >= count && count > 0 )); then
            TUI_SELECTED=$(( count - 1 ))
            fi
        else
            _show_message "Operation cancelled." "info"
        fi
    fi
}

_action_edit_desc() {
    local id
    if id=$(_get_selected_id); then
        local current_desc
        current_desc=$(get_todo_desc "$id")
        local new_desc
        _input_dialog "Edit Description for #$id" "" "$current_desc"
        if new_desc="$_input_dialog_result"; then
            if [[ $new_desc != $current_desc ]]; then
                set_description "$id" "$new_desc"
                _show_message "Updated description for #$id: $new_desc" "success"
            fi
        fi
    fi
}

_action_edit_title() {
    local id
    if id=$(_get_selected_id); then
        local current_title
        current_title=$(get_todo_title "$id")
        local new_title
        _input_dialog "Edit Title for #$id" "" "$current_title"
        if new_title="$_input_dialog_result"; then
            if [[ -n "$new_title" && "$new_title" != "$current_title" ]]; then
                # Direct array update
                local idx
                for (( idx=0; idx<${#TODO_IDS[@]}; idx++ )); do
                    if [[ "${TODO_IDS[$idx]}" == "$id" ]]; then
                        TODO_TITLES[$idx]="$new_title"
                        DATA_MODIFIED=1
                        break
                    fi
                done
                _show_message "Updated title for #$id" "success"
            fi
        fi
    fi
}

_action_set_due() {
    local id
    if id=$(_get_selected_id); then
        local current_due
        current_due=$(get_todo_due "$id")
        [[ "$current_due" == "NULL" ]] && current_due=""
        local new_due
        _input_dialog "Set Due Date (YYYY-MM-DD HH:MM)" "" "$current_due"
        if new_due="$_input_dialog_result"; then
            if [[ -z "$new_due" ]]; then
                if [[ -n "$current_due" && "$current_due" != "NULL" ]]; then
                    set_due_date "$id" "NULL"
                    _show_message "Cleared due date for #$id" "info"
                else
                    _show_message "Due date for #$id is unchanged" "info"
                fi
            elif validate_date "$new_due" 2>/dev/null; then
                if [[ "$current_due" != "$new_due" ]]; then
                    set_due_date "$id" "$new_due"
                    _show_message "Set due date for #$id" "success"
                else
                    _show_message "Due date for #$id is unchanged" "info"
                fi
            else
                _show_message "Invalid date format!" "error"
            fi
        fi
    fi
}

_action_search() {
    local query
    _input_dialog "Search" "/" ""
    if query="$_input_dialog_result"; then
        if [[ -n "$query" ]]; then
            TUI_SEARCH_QUERY="$query"
            TUI_SEARCH_RESULTS=()
            TUI_SEARCH_IDX=0
            
            # Find matching items
            local ids=()
            while IFS= read -r id_; do
                [[ -n "$id_" ]] && ids+=("$id_")
            done < <(get_all_todo_ids)

            for id in "${ids[@]}"; do
                local title
                title=$(get_todo_title "$id")
                if [[ "${title,,}" == *"${query,,}"* ]]; then
                    TUI_SEARCH_RESULTS+=("$id")
                fi
            done

            if (( ${#TUI_SEARCH_RESULTS[@]} > 0 )); then
                # Jump to first result
                _action_search_next
            else
                _show_message "No matches found" "warning"
            fi
        fi
    fi
}

_action_search_next() {
    if (( ${#TUI_SEARCH_RESULTS[@]} == 0 )); then
        return
    fi
    if (( TUI_SEARCH_IDX >= ${#TUI_SEARCH_RESULTS[@]} )); then
        TUI_SEARCH_IDX=0
    fi
    
    # Find index of this ID
    local target_id="${TUI_SEARCH_RESULTS[$TUI_SEARCH_IDX]}"
    local ids=()
    while IFS= read -r id_; do
        [[ -n "$id_" ]] && ids+=("$id_")
    done < <(get_all_todo_ids)

    local i
    for (( i=0; i<${#ids[@]}; i++ )); do
        if [[ "${ids[$i]}" == "$target_id" ]]; then
            TUI_SELECTED=$i
            break
        fi
    done

    # Move to next for subsequent calls
    TUI_SEARCH_IDX=$(( TUI_SEARCH_IDX + 1 ))
}

_action_search_prev() {
    if (( ${#TUI_SEARCH_RESULTS[@]} == 0 )); then
        return
    fi
    
    TUI_SEARCH_IDX=$(( TUI_SEARCH_IDX - 2 ))
    _action_search_next
    if (( TUI_SEARCH_IDX <= 0 )); then
        TUI_SEARCH_IDX=$(( ${#TUI_SEARCH_RESULTS[@]} ))
    fi
}

_action_save() {
    if save_todos; then
        _show_message "Successfully saved to: $CURRENT_DATA_FILE" "success"
    else
        _show_message "Failed to save!" "error"
    fi
}

_action_quit() {
    if (( DATA_MODIFIED )); then
        _confirm_dialog "Unsaved Changes!" "Save before quitting?"
        case "$_confirm_dialog_result" in
            Y)
                save_todos
                TUI_RUNNING=0
                ;;
            N)
                TUI_RUNNING=0
                ;;
            ESC)
                # Cancel - continue
                ;;
        esac
    else
        TUI_RUNNING=0
    fi
}

###########################################
# Handle SIGWINCH (terminal resize)
###########################################
_handle_resize() {
    _redraw
}

###########################################
# Cleanup on exit
###########################################
_cleanup() {
    if [[ -n "$_DRAW_LIST_PID" ]]; then
        kill "$_DRAW_LIST_PID" 2>/dev/null || true
        _DRAW_LIST_PID=
    fi
    _show_cursor
    _exit_alt_screen
    echo -ne "${C_RESET}"
    stty sane 2>/dev/null || true
}

###########################################
# Main TUI loop
###########################################
run_tui() {
    # Setup
    trap _cleanup EXIT
    trap _handle_resize SIGWINCH 2>/dev/null || true
    
    _enter_alt_screen
    _hide_cursor

    # Load data
    local data_file="${CUSTOM_FILE:-$DEFAULT_DATA_PATH}"
    load_todos "$data_file"
    
    TUI_RUNNING=1
    TUI_SELECTED=0
    TUI_SCROLL_OFFSET=0
    
    _redraw
    
    local i=1
    # Main loop
    while (( TUI_RUNNING )); do
        local key action draw_quick
        
        key=$(read_key 0.1) || continue
        action=$(process_key "$key")
        
        case "$action" in
            MOVE_DOWN)
                draw_quick="$TUI_SELECTED"
                _action_move_down
                _draw_list "" "$draw_quick"
                ;;
            MOVE_UP)
                draw_quick="$TUI_SELECTED"
                _action_move_up
                _draw_list "" "$draw_quick"
                ;;
            GOTO_FIRST)
                _action_goto_first
                _draw_list
                ;;
            GOTO_LAST)
                _action_goto_last
                _draw_list
                ;;
            ADD)
                _action_add
                _redraw
                ;;
            TOGGLE_COMPLETE)
                _action_toggle_complete
                _draw_list
                ;;
            DELETE)
                _action_delete
                _redraw
                ;;
            EDIT_DESC)
                _action_edit_desc
                _redraw
                ;;
            EDIT_TITLE)
                _action_edit_title
                _redraw
                ;;
            SET_DUE)
                _action_set_due
                _redraw
                ;;
            SEARCH)
                _action_search
                _redraw
                ;;
            SEARCH_NEXT)
                _action_search_next
                _draw_list
                ;;
            SEARCH_PREV)
                _action_search_prev
                _draw_list
                ;;
            SAVE) _action_save ;;
            HELP)
                _show_help_overlay
                _redraw
                ;;
            QUIT)
                _action_quit
                _redraw
                ;;
            PAGE_UP)
                local visible=$(_visible_lines)
                TUI_SELECTED=$(( TUI_SELECTED - visible ))
                (( TUI_SELECTED < 0 )) && TUI_SELECTED=0
                _draw_list
                ;;
            PAGE_DOWN)
                local visible=$(_visible_lines)
                local count=$(get_todo_count)
                TUI_SELECTED=$(( TUI_SELECTED + visible ))
                (( TUI_SELECTED >= count )) && TUI_SELECTED=$(( count - 1 ))
                (( TUI_SELECTED < 0 )) && TUI_SELECTED=0
                _draw_list
                ;;
            GOTO_FIRST_VISIBLE)
                TUI_SELECTED=$TUI_SCROLL_OFFSET
                (( TUI_SELECTED < 0 )) && TUI_SELECTED=0
                _draw_list
                ;;
            GOTO_LAST_VISIBLE)
                local visible=$(_visible_lines)
                local count=$(get_todo_count)
                TUI_SELECTED=$(( $TUI_SCROLL_OFFSET + visible - 1 ))
                (( TUI_SELECTED >= count )) && TUI_SELECTED=$(( count - 1 ))
                (( TUI_SELECTED < 0 )) && TUI_SELECTED=0
                _draw_list
                ;;
            CANCEL)
                TUI_SEARCH_QUERY=""
                TUI_SEARCH_RESULTS=()
                ;;
            REFRESH) _redraw ;;
        esac

        _draw_status
        _cursor_to $(( TERM_ROWS - FOOTER_LINES - STATUS_LINES )) $TERM_COLS
    done
    
    # Cleanup is handled by trap
}
