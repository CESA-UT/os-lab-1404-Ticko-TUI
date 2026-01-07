#!/usr/bin/env bash

#
# cli.sh — Command-line interface for Ticko
#

# Globals that will be set
MODE="tui"           # default
CLI_COMMAND=""       # add/list/done/...
CLI_ARGS=()          # extra args
CUSTOM_FILE=""       # --file
FILTER_MODE=""       # completed/pending


############################################
# Internal: require argument count
############################################
_require_args() {
    local need=$1
    local got=$2
    local usage=$3

    if (( got < need )); then
        print_error "Not enough arguments"
        [[ -n "$usage" ]] && echo "$usage"
        exit 1
    fi
}

############################################
# Helper: ensure ID is integer
############################################
_validate_id() {
    local id="$1"
    if [[ ! "$id" =~ ^[0-9]+$ ]]; then
        print_error "ID must be a number"
        exit 1
    fi
}

############################################
# Entry point: parse all CLI args
############################################
parse_args() {

    # no arguments → TUI mode
    if (( $# == 0 )); then
        MODE="tui"
        return
    fi

    # first pass: handle global flags
    case "$1" in
        -h|--help)
            MODE="cli_help"
            return
            ;;
        -v|--version)
            MODE="cli_version"
            return
            ;;
    esac

    # check global file option before commands
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--file)
                shift
                if [[ -z "$1" ]]; then
                    print_error "--file requires a path"
                    exit 1
                fi
                CUSTOM_FILE="$1"
                ;;
            list|add|remove|done|undone|edit)
                CLI_COMMAND="$1"
                shift
                CLI_ARGS=("$@")
                MODE="cli_command"
                return
                ;;
            *)
                # default: unknown thing means TUI, but warn
                break
                ;;
        esac
        shift
    done

    # fallback → no direct command → TUI
    MODE="tui"
}


############################################
# Dispatch CLI command
############################################
run_cli_command() {

    # load todos first
    if [[ -n "$CUSTOM_FILE" ]]; then
        load_todos "$CUSTOM_FILE"
    else
        load_todos "$DEFAULT_DATA_PATH"
    fi

    case "$CLI_COMMAND" in
        list)
            _cmd_list "${CLI_ARGS[@]}"
            ;;
        add)
            _cmd_add "${CLI_ARGS[@]}"
            ;;
        remove)
            _cmd_remove "${CLI_ARGS[@]}"
            ;;
        done)
            _cmd_done "${CLI_ARGS[@]}"
            ;;
        undone)
            _cmd_undone "${CLI_ARGS[@]}"
            ;;
        edit)
            _cmd_edit "${CLI_ARGS[@]}"
            ;;
        *)
            print_error "Unknown command: $CLI_COMMAND"
            exit 1
            ;;
    esac

    # save after modifications
    if [[ -n "$CUSTOM_FILE" ]]; then
        save_todos "$CUSTOM_FILE"
    else
        save_todos "$DEFAULT_DATA_PATH"
    fi
}

############################################
# Command: list
############################################
_cmd_list() {
    local mode="all"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --completed)
                mode="completed"
                ;;
            --pending)
                mode="pending"
                ;;
            *)
                print_warning "Unknown list option: $1"
                ;;
        esac
        shift
    done

    local ids
    IFS=$'\n' read -r -d '' -a ids < <(get_all_todo_ids && printf '\0')

    if (( ${#ids[@]} == 0 )); then
        print_info "No TODOs yet. Clean life, huh 😌"
        return
    fi

    for id in "${ids[@]}"; do
        local item
        item=$(get_todo "$id")
        IFS='|' read -r title desc due completed <<<"$item"

        case "$mode" in
            completed) [[ "$completed" != "1" ]] && continue ;;
            pending)   [[ "$completed" == "1" ]] && continue ;;
        esac

        if [[ "$completed" == "1" ]]; then
            echo -e "[$id] ✔ $title"
        else
            echo -e "[$id] • $title"
        fi
    done
}

############################################
# Command: add
############################################
_cmd_add() {
    _require_args 1 $# "Usage: ticko add \"Title\" [-d desc] [-t date]"

    local title="$1"
    shift

    local desc=""
    local due=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--description)
                shift
                desc="$1"
                ;;
            -t|--time|--due)
                shift
                due="$1"
                if ! validate_date "$due"; then
                    print_error "Invalid date format. Use: YYYY-MM-DD HH:MM"
                    exit 1
                fi
                ;;
            *)
                print_warning "Unknown option: $1"
                ;;
        esac
        shift
    done

    local id
    id=$(add_todo "$title" "$desc" "$due")
    print_success "Added TODO with ID $id"
}

############################################
# Command: remove
############################################
_cmd_remove() {
    _require_args 1 $# "Usage: ticko remove <ID>"
    _validate_id "$1"

    remove_todo "$1"
    print_success "Removed TODO $1"
}

############################################
# Command: done
############################################
_cmd_done() {
    _require_args 1 $# "Usage: ticko done <ID>"
    _validate_id "$1"

    toggle_complete "$1"
    print_success "Marked TODO $1 as completed"
}

############################################
# Command: undone
############################################
_cmd_undone() {
    _require_args 1 $# "Usage: ticko undone <ID>"
    _validate_id "$1"

    toggle_complete "$1"
    print_success "Marked TODO $1 as not completed"
}

############################################
# Command: edit
############################################
_cmd_edit() {
    _require_args 1 $# "Usage: ticko edit <ID> [options]"
    local id="$1"
    shift
    _validate_id "$id"

    local new_desc=""
    local new_due=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--description)
                shift
                new_desc="$1"
                ;;
            -t|--time|--due)
                shift
                new_due="$1"
                if ! validate_date "$new_due"; then
                    print_error "Invalid date format"
                    exit 1
                fi
                ;;
        esac
        shift
    done

    [[ -n "$new_desc" ]] && set_description "$id" "$new_desc"
    [[ -n "$new_due" ]] && set_due_date "$id" "$new_due"

    print_success "Edited TODO $id"
}
