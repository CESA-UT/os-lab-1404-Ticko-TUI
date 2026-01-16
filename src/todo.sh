#!/usr/bin/env bash

#
# todo.sh — TODO CRUD operations for Ticko
#
# Provides functions to manipulate TODO items in memory.
# Data arrays are defined in data.sh.
#

###########################################
# Find array index by TODO ID
###########################################
_find_index_by_id() {
    local target_id="$1"
    local i
    for (( i=0; i<${#TODO_IDS[@]}; i++ )); do
        if [[ "${TODO_IDS[$i]}" == "$target_id" ]]; then
            echo "$i"
            return 0
        fi
    done
    return 1
}

###########################################
# Add a new TODO item
# Returns: the new ID
###########################################
add_todo() {
    local id="$1"
    local title="$2"
    local desc="${3:-}"
    local due="${4:-NULL}"

    local created
    created=$(date "+%Y-%m-%d %H:%M")

    TODO_IDS+=("$id")
    TODO_TITLES+=("$title")
    TODO_DESCS+=("$desc")
    TODO_DUES+=("$due")
    TODO_COMPLETED+=("0")
    TODO_CREATED+=("$created")

    DATA_MODIFIED=1
}

###########################################
# Remove TODO by ID
###########################################
remove_todo() {
    local id="$1"
    local idx
    
    if ! idx=$(_find_index_by_id "$id"); then
        return 1
    fi
    
    # Remove from all arrays
    unset 'TODO_IDS[idx]'
    unset 'TODO_TITLES[idx]'
    unset 'TODO_DESCS[idx]'
    unset 'TODO_DUES[idx]'
    unset 'TODO_COMPLETED[idx]'
    unset 'TODO_CREATED[idx]'
    
    # Re-index arrays
    TODO_IDS=("${TODO_IDS[@]}")
    TODO_TITLES=("${TODO_TITLES[@]}")
    TODO_DESCS=("${TODO_DESCS[@]}")
    TODO_DUES=("${TODO_DUES[@]}")
    TODO_COMPLETED=("${TODO_COMPLETED[@]}")
    TODO_CREATED=("${TODO_CREATED[@]}")
    
    DATA_MODIFIED=1
    
    return 0
}

###########################################
# Toggle completion status
###########################################
toggle_complete() {
    local id="$1"
    local idx
    
    if ! idx=$(_find_index_by_id "$id"); then
        return 1
    fi
    
    if [[ "${TODO_COMPLETED[$idx]}" == "1" ]]; then
        TODO_COMPLETED[$idx]="0"
    else
        TODO_COMPLETED[$idx]="1"
    fi
    
    DATA_MODIFIED=1
    
    return 0
}

###########################################
# Set description
###########################################
set_description() {
    local id="$1"
    local desc="$2"
    local idx
    
    if ! idx=$(_find_index_by_id "$id"); then
        return 1
    fi
    
    TODO_DESCS[$idx]="$desc"
    DATA_MODIFIED=1
    
    return 0
}

###########################################
# Set due date
###########################################
set_due_date() {
    local id="$1"
    local due="$2"
    local idx
    
    if ! idx=$(_find_index_by_id "$id"); then
        return 1
    fi
    
    TODO_DUES[$idx]="$due"
    DATA_MODIFIED=1
    
    return 0
}

###########################################
# Get TODO as pipe-delimited string
# Returns: title|desc|due|completed
###########################################
get_todo() {
    local id="$1"
    local idx
    
    if ! idx=$(_find_index_by_id "$id"); then
        return 1
    fi
    
    echo "${TODO_TITLES[$idx]}|${TODO_DESCS[$idx]}|${TODO_DUES[$idx]}|${TODO_COMPLETED[$idx]}"
}

###########################################
# Get total count of TODOs
###########################################
get_todo_count() {
    echo "${#TODO_IDS[@]}"
}

###########################################
# Check if TODO is overdue
###########################################
is_overdue() {
    local id="$1"
    local idx
    
    if ! idx=$(_find_index_by_id "$id"); then
        return 1
    fi
    
    local due="${TODO_DUES[$idx]}"
    
    # NULL or empty means no due date
    if [[ "$due" == "NULL" || -z "$due" ]]; then
        return 1
    fi
    
    # Compare with current time
    local due_ts now_ts
    due_ts=$(date -d "$due" +%s 2>/dev/null) || return 1
    now_ts=$(date +%s)
    
    if (( due_ts < now_ts )); then
        return 0  # overdue
    fi
    
    return 1  # not overdue
}

###########################################
# Get all TODO IDs (one per line)
###########################################
get_all_todo_ids() {
    local id
    for id in "${TODO_IDS[@]}"; do
        echo "$id"
    done
}

###########################################
# Get TODO title by ID
###########################################
get_todo_title() {
    local id="$1"
    local idx
    
    if ! idx=$(_find_index_by_id "$id"); then
        return 1
    fi
    
    echo "${TODO_TITLES[$idx]}"
}

###########################################
# Get TODO description by ID
###########################################
get_todo_desc() {
    local id="$1"
    local idx
    
    if ! idx=$(_find_index_by_id "$id"); then
        return 1
    fi
    
    echo "${TODO_DESCS[$idx]}"
}

###########################################
# Get TODO due date by ID
###########################################
get_todo_due() {
    local id="$1"
    local idx
    
    if ! idx=$(_find_index_by_id "$id"); then
        return 1
    fi
    
    echo "${TODO_DUES[$idx]}"
}

###########################################
# Check if TODO is completed
###########################################
is_completed() {
    local id="$1"
    local idx
    
    if ! idx=$(_find_index_by_id "$id"); then
        return 1
    fi
    
    [[ "${TODO_COMPLETED[$idx]}" == "1" ]]
}
