#!/usr/bin/env bash

#
# help.sh — Help & version system for Ticko
#

# relies on:
#  - print_info, print_warning, print_error (from utils.sh)
#  - VERSION, APP_NAME constants (from ticko.sh)


###########################################
# Show version
###########################################
show_version() {
    echo "${APP_NAME:-Ticko} ${VERSION:-0.0.0}"
}


###########################################
# CLI Help Text
###########################################
show_cli_help() {
    cat <<'EOF'
Ticko — A terminal TODO manager with both CLI and TUI modes

Usage:
  ticko                      Launch TUI interface (default)
  ticko [OPTIONS]            Run with options
  ticko COMMAND [...]        Run a specific CLI command

Options:
  -h, --help                 Show this help message and exit
  -v, --version              Show version information
  -f, --file <path>          Use custom TODO data file

CLI Commands:
  list                       List all TODOs
  list --completed           List only completed items
  list --pending             List only pending items

  add "Title"                Add new TODO with title only
  add "Title" -d "Desc"      Add with description
  add "Title" -t "YYYY-MM-DD HH:MM"
                             Add with due date

  done <ID>                  Mark TODO as completed
  undone <ID>                Mark TODO as not completed
  remove <ID>                Remove TODO permanently

  edit <ID> -d "New desc"    Edit description
  edit <ID> -t "YYYY-MM-DD HH:MM"
                             Edit due date

Examples:
  ticko
  ticko list
  ticko add "Study OS"
  ticko add "Exam" -d "chapter 1–3" -t "2026-01-10 18:00"
  ticko done 3
  ticko remove 2

Notes:
  - If no command is given, Ticko launches in TUI mode
  - IDs are numeric and stable (not reused after deletion)
  - Data is stored in your user directory by default
EOF
}


###########################################
# TUI quick help overlay text (for '?')
###########################################
show_tui_help_overlay() {
    cat <<'EOF'
TUI HELP — Ticko Keybindings

Navigation:
  j                Move down
  k                Move up
  g                Go to first item
  G                Go to last item

Actions:
  a / o            Add new item
  x / Space        Toggle completion
  D                Delete current item
  e                Edit description
  d                Set due date
  Enter            Show TODO details

Search:
  /                Search
  n / N            Next/Previous result

General:
  s                Save changes
  ?                Show this help
  q                Quit

Press any key to exit help...
EOF
}
