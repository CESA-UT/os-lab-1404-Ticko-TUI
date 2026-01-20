#!/usr/bin/env bash

#
# utils.sh — Common utility functions for Ticko
#

############################
# Colors & Text Styles
############################

if [[ -t 1 ]]; then
    RED="\033[31m"
    GREEN="\033[32m"
    YELLOW="\033[33m"
    BLUE="\033[34m"
    BOLD="\033[1m"
    RESET="\033[0m"
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    RESET=""
fi

############################
# Print Helpers
############################

print_error() {
    echo -e "${RED}$*${RESET}" >&2
}

print_success() {
    echo -e "${GREEN}$*${RESET}"
}

print_warning() {
    echo -e "${YELLOW}$*${RESET}"
}

print_info() {
    echo -e "${BLUE}$*${RESET}"
}

############################
# Date Utilities
############################

# validate format: YYYY-MM-DD HH:MM
validate_date() {
    local input="$1"

    # format check
    if [[ ! "$input" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}$ ]]; then
        return 1
    fi

    # let date command judge if it's real
    if ! date -d "$input" >/dev/null 2>&1; then
        return 1
    fi

    return 0
}

# return unix timestamp from date string
parse_date() {
    local input="$1"

    if ! validate_date "$input"; then
        echo "INVALID"
        return 1
    fi

    date -d "$input" +"%s"
}

# format timestamp -> readable
format_date() {
    local ts="$1"
    if [[ -z "$ts" ]]; then
        echo "N/A"
        return
    fi

    date -d "@$ts" +"%Y-%m-%d %H:%M"
}

############################
# String Utilities
############################

# truncate with …
truncate_string() {
    local str="$1"
    local max="$2"

    local len=${#str}

    if (( len <= max )); then
        echo "$str"
    else
        echo "${str:0:max-1}…"
    fi
}

# center string inside width
center_string() {
    local str="$1"
    local width="$2"

    local len=${#str}

    if (( len >= width )); then
        echo "$str"
        return
    fi

    local pad=$(( (width - len) / 2 ))
    printf "%*s%s%*s\n" "$pad" "" "$str" "$pad" ""
}
