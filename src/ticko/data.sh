#!/usr/bin/env bash

#
# data.sh — Data storage layer for Ticko
#
# Handles file I/O for TODO items.
# File format:
#   # Ticko TODO File v1.0
#   # NEXT_ID:5
#   # Format: ID|STATUS|TITLE|DESCRIPTION|DUE_DATE|CREATED_DATE
#   1|0|Buy groceries|Milk, eggs|2026-01-10 18:00|2026-01-06 10:00
#

# Global arrays (shared with todo.sh)
TODO_IDS=()
TODO_TITLES=()
TODO_DESCS=()
TODO_DUES=()
TODO_COMPLETED=()
TODO_CREATED=()
NEXT_TODO_ID=1
CURRENT_DATA_FILE=""
DATA_MODIFIED=0
    
###########################################
# Load todos from file
###########################################
load_todos() {
    local filepath="$1"
    
    # Clear existing data
    TODO_IDS=()
    TODO_TITLES=()
    TODO_DESCS=()
    TODO_DUES=()
    TODO_COMPLETED=()
    TODO_CREATED=()
    NEXT_TODO_ID=1
    DATA_MODIFIED=0
    
    CURRENT_DATA_FILE="$filepath"
    
    # Create directory if needed
    local dir
    dir=$(dirname "$filepath")
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" 2>/dev/null || true
    fi
    
    # If file doesn't exist, we're done
    if [[ ! -f "$filepath" ]]; then
        return 0
    fi
    
    # Read file
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines
        [[ -z "$line" ]] && continue
        
        # Parse NEXT_ID header
        if [[ "$line" =~ ^#\ NEXT_ID:([0-9]+) ]]; then
            NEXT_TODO_ID="${BASH_REMATCH[1]}"
            continue
        fi
        
        # Skip other comments
        [[ "$line" =~ ^# ]] && continue
        
        # Parse data line: ID|STATUS|TITLE|DESC|DUE|CREATED
        IFS='|' read -r id status title desc due created <<< "$line"
        
        # Validate ID
        if [[ ! "$id" =~ ^[0-9]+$ ]]; then
            continue
        fi
        
        TODO_IDS+=("$id")
        TODO_COMPLETED+=("$status")
        TODO_TITLES+=("$title")
        TODO_DESCS+=("$desc")
        TODO_DUES+=("$due")
        TODO_CREATED+=("$created")
        
    done < "$filepath"
    
    return 0
}

###########################################
# Save todos to file
###########################################
save_todos() {
    local filepath="${1:-$CURRENT_DATA_FILE}"
    
    [[ -z "$filepath" ]] && return 1
    
    # Create directory if needed
    local dir
    dir=$(dirname "$filepath")
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" 2>/dev/null || return 1
    fi
    
    # Write file
    {
        echo "# Ticko TODO File v1.0"
        echo "# NEXT_ID:$NEXT_TODO_ID"
        echo "# Format: ID|STATUS|TITLE|DESCRIPTION|DUE_DATE|CREATED_DATE"
        
        local i
        for (( i=0; i<${#TODO_IDS[@]}; i++ )); do
            local id="${TODO_IDS[$i]}"
            local status="${TODO_COMPLETED[$i]}"
            local title="${TODO_TITLES[$i]}"
            local desc="${TODO_DESCS[$i]}"
            local due="${TODO_DUES[$i]}"
            local created="${TODO_CREATED[$i]}"
            
            # Escape pipe characters in text fields
            title="${title//|/\\|}"
            desc="${desc//|/\\|}"
            
            echo "${id}|${status}|${title}|${desc}|${due}|${created}"
        done
    } > "$filepath"

    DATA_MODIFIED=0
    CURRENT_DATA_FILE="$filepath"
    
    return 0
}

###########################################
# Load configuration
###########################################
load_config() {
    local config_path="$1"
    
    # Load config if exists
    if [[ -f "$config_path" ]]; then
        # shellcheck disable=SC1090
        source "$config_path" 2>/dev/null || true
        CUSTOM_FILE="${DATA_PATH:-}"
        CURRENT_DATA_FILE="${CUSTOM_FILE}"
    fi
}
