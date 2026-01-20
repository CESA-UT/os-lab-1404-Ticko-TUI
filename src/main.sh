#!/usr/bin/env bash

#
# ticko.sh — Main entry point for Ticko TODO Manager
#
# A TUI TODO list app with CLI support and Vim keybindings.
#

set -o errexit   # Exit on error
set -o nounset   # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

###########################################
# Application Constants
###########################################
readonly VERSION="1.0.0"
readonly APP_NAME="Ticko"
readonly DEFAULT_CONFIG_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/ticko/ticko.conf"
readonly DEFAULT_DATA_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/ticko/todos.tik"

###########################################
# Determine script directory
###########################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

###########################################
# Source all modules
###########################################
# shellcheck source=utils.sh
source "$SCRIPT_DIR/utils.sh"

# shellcheck source=data.sh
source "$SCRIPT_DIR/data.sh"

# shellcheck source=todo.sh
source "$SCRIPT_DIR/todo.sh"

# shellcheck source=cli.sh
source "$SCRIPT_DIR/cli.sh"

# shellcheck source=help.sh
source "$SCRIPT_DIR/help.sh"

# shellcheck source=keybinds.sh
source "$SCRIPT_DIR/keybinds.sh"

# shellcheck source=tui.sh
source "$SCRIPT_DIR/tui.sh"

###########################################
# Main entry point
###########################################
main() {
    # Load configuration
    load_config "/etc/ticko.conf"
    load_config $DEFAULT_CONFIG_PATH
    
    # Parse command-line arguments
    parse_args "$@"
    
    # Dispatch based on mode
    case "$MODE" in
        tui)
            run_tui
            ;;
        cli_help)
            show_cli_help
            ;;
        cli_version)
            show_version
            ;;
        cli_command)
            run_cli_command
            ;;
        *)
            print_error "Unknown mode: $MODE"
            exit 1
            ;;
    esac
}

# Run main with all arguments
main "$@"
