# Ticko - Project Plan

**Project:** Ticko - A TUI TODO List App  
**Language:** Bash  
**Deadline:** January 9, 2026 (19 Dey 1404) - 23:59

---

## Team Members & Task Assignments

| Member                         | Role                             |
| ------------------------------ | -------------------------------- |
| **Mehrad Pooryoussof**         | Core TUI Engine + Vim Keybinds   |
| **AmirHossein Nasrollahi**     | TODO Data Management (CRUD)      |
| **MohammadHossein MaarefVand** | CLI Interface + Help System      |
| **Abolfazl Tavakolian**        | Documentation & Debian Packaging |

---

## File Ownership (To Avoid Merge Conflicts)

```
src/
├── ticko.sh              → Mehrad (main entry point - minimal, just sources others)
├── tui.sh                → Mehrad (TUI rendering engine)
├── keybinds.sh           → Mehrad (keyboard handling + Vim bindings)
├── data.sh               → AmirHossein (data storage/loading functions)
├── todo.sh               → AmirHossein (TODO item CRUD operations)
├── cli.sh                → MohammadHossein (CLI argument parsing)
├── help.sh               → MohammadHossein (help messages)
└── utils.sh              → MohammadHossein (utility functions)

config/
└── ticko.conf            → AmirHossein

man/
└── ticko.1               → Abolfazl

debian/
├── control               → Abolfazl
├── changelog             → Abolfazl
├── install               → Abolfazl
├── links                 → Abolfazl
├── manpages              → Abolfazl
└── rules                 → Abolfazl

README.md                 → Abolfazl
README.fa.md              → Abolfazl
```

---

## Detailed Task Breakdown

---

### Task 1: Mehrad Pooryoussof — Core TUI Engine + Vim Keybinds

**Files to Create/Edit:** `src/ticko.sh`, `src/tui.sh`, `src/keybinds.sh`

#### Subtasks:

1. **Main Entry Point** (`src/ticko.sh`)

   - Source all other modules
   - Initialize the application
   - Handle mode switching (TUI vs CLI)

2. **TUI Rendering Engine** (`src/tui.sh`)

   - Implement full-screen terminal UI using ANSI escape codes
   - Create todo list view with scrolling support
   - Implement status bar and header
   - Handle terminal resize events (`trap SIGWINCH`)
   - Create input dialogs for:
     - Adding new TODO
     - Editing description
     - Setting due date/time
   - Implement visual selection/highlighting of current item
   - Color coding for:
     - Completed items (green/strikethrough)
     - Overdue items (red)
     - Normal items (default)
   - Hide cursor, alternate screen buffer (`tput smcup/rmcup`)
   - Implement TUI help overlay (shown with `?` key)
     - Display keybinds and navigation help
     - Well-formatted overlay with box drawing characters
     - Dismissible with any key press

3. **Keyboard Handler + Vim Bindings** (`src/keybinds.sh`)
   - Raw input reading using `read -rsn1`
   - Handle escape sequences for arrow keys
   - Implement keybinds:
     - `j` / `↓` — Move down
     - `k` / `↑` — Move up
     - `g` — Go to first item
     - `G` — Go to last item
     - `D` — Delete current item
     - `o` — Add new item below
     - `O` — Add new item above
     - `x` — Toggle completion
     - `e` — Edit description
     - `d` — Set due date
     - `/` — Search
     - `s` — Save changes
     - `n` / `N` — Next/Previous search result
     - `q` — Quit
     - `?` — Show help overlay
   - Implement timeout for partial sequences

#### Interfaces to Use (from other team members):

```bash
# From data.sh (AmirHossein)
load_todos "$filepath"        # Load todos from file
save_todos "$filepath"        # Save todos to file

# From todo.sh (AmirHossein)
add_todo "$title" "$desc" "$due"  # Returns: new todo ID
remove_todo "$id"
toggle_complete "$id"
set_description "$id" "$desc"
set_due_date "$id" "$date"
get_todo "$id"                # Returns: title|desc|due|completed
get_todo_count
get_all_todo_ids               # Returns: array of all TODO IDs
```

---

### Task 2: AmirHossein Nasrollahi — TODO Data Management

**Files to Create/Edit:** `src/data.sh`, `src/todo.sh`, `config/ticko.conf`

#### Subtasks:

1. **Data Storage Layer** (`src/data.sh`)

   - Define TODO data format (recommend: simple delimited text file)
   - File format example:
     ```
     # Ticko TODO File v1.0
     # Format: ID|STATUS|TITLE|DESCRIPTION|DUE_DATE|CREATED_DATE
     1|0|Buy groceries|Milk, eggs, bread|NULL|2026-01-06 10:00
     2|1|Finish homework|Math assignment|2026-01-08 23:59|2026-01-05 14:30
     3|0|Finish project|Math assignment|2026-01-10 18:00|2026-01-09 17:12
     ```
   - Each TODO item has a unique auto-generated integer ID
   - IDs are never reused, even after deletion
   - Track next available ID in file header or metadata
   - Implement `load_todos "$filepath"` — Load from file into arrays
   - Implement `save_todos "$filepath"` — Save arrays to file
   - Handle file not found (create new)
   - Handle corrupted files gracefully
   - Implement file locking to prevent concurrent writes
   - Support custom file paths from:
     - CLI argument
     - Config file
     - Default: `~/.local/share/ticko/todos.txt`

2. **TODO CRUD Operations** (`src/todo.sh`)

   - Maintain in-memory arrays:
     ```bash
     TODO_IDS=()        # Unique integer IDs
     TODO_TITLES=()
     TODO_DESCS=()
     TODO_DUES=()
     TODO_COMPLETED=()
     TODO_CREATED=()
     NEXT_TODO_ID=1     # Track next available ID
     ```
   - Implement functions:
     - `add_todo "$title" "$description" "$due_date"` — Add new item, returns new ID
     - `remove_todo "$id"` — Remove by ID
     - `toggle_complete "$id"` — Toggle completion status
     - `set_description "$id" "$desc"` — Update description
     - `set_due_date "$id" "$date"` — Update due date
     - `get_todo "$id"` — Get item as pipe-delimited string
     - `get_todo_count` — Return number of items
     - `is_overdue "$id"` — Check if item is past due
     - `get_all_todo_ids` — Return array of all TODO IDs
     - `sort_todos "$method"` — Sort by date/status/title
     - `generate_next_id` — Generate and return next unique ID
   - Date validation (format: `YYYY-MM-DD HH:MM`)
   - Input sanitization (escape pipe characters)

3. **Configuration** (`config/ticko.conf`)

   - Define config format and parser
   - Config options:

     ```bash
     # Default TODO file path
     DEFAULT_FILE=~/.local/share/ticko/todos.txt

     # Date format
     DATE_FORMAT="%Y-%m-%d %H:%M"

     # Colors (true/false)
     ENABLE_COLORS=true

     # Auto-save on changes
     AUTO_SAVE=true
     ```

   - Implement `load_config` function
   - Support XDG config path: `~/.config/ticko/ticko.conf`

#### Interfaces to Provide:

```bash
# data.sh exports
load_todos "$filepath"
save_todos "$filepath"
load_config

# todo.sh exports
add_todo "$title" "$desc" "$due"  # Returns new ID
remove_todo "$id"
toggle_complete "$id"
set_description "$id" "$desc"
set_due_date "$id" "$date"
get_todo "$id"
get_todo_count
is_overdue "$id"
get_all_todo_ids
generate_next_id
```

---

### Task 3: MohammadHossein MaarefVand — CLI Interface + Help System

**Files to Create/Edit:** `src/cli.sh`, `src/help.sh`, `src/utils.sh`

#### Subtasks:

1. **CLI Argument Parser** (`src/cli.sh`)

   - Parse command-line arguments using `getopts` or manual parsing
   - Implement commands:

     ```bash
     ticko                      # Launch TUI (default)
     ticko -h, --help           # Show help
     ticko -v, --version        # Show version
     ticko -f, --file FILE      # Use custom file path

     ticko list                 # List all todos (CLI mode)
     ticko list --completed     # List only completed
     ticko list --pending       # List only pending

     ticko add "Title"          # Add todo (quick add, shows new ID)
     ticko add "Title" -d "Description" -t "2026-01-10 18:00"

     ticko done ID              # Mark as completed
     ticko undone ID            # Mark as not completed
     ticko remove ID            # Remove todo

     ticko edit ID -d "New desc"       # Edit description
     ticko edit ID -t "2026-01-15"     # Edit due date
     ```

   - Return proper exit codes
   - Validate arguments and show errors

2. **Help System** (`src/help.sh`)

   - Implement `show_cli_help` — Full CLI usage help
   - Implement `show_version` — Version info
   - Help text should be:
     - Well-formatted with colors
     - Show examples
     - List all commands and options

3. **Utility Functions** (`src/utils.sh`)
   - Color output functions:
     ```bash
     print_error "message"
     print_success "message"
     print_warning "message"
     print_info "message"
     ```
   - Date utilities:
     ```bash
     format_date "$timestamp"
     parse_date "$datestring"
     validate_date "$datestring"
     ```
   - String utilities:
     ```bash
     truncate_string "$str" "$maxlen"
     center_string "$str" "$width"
     ```

#### Interfaces to Provide:

```bash
# cli.sh exports
parse_args "$@"              # Returns mode and parsed options

# help.sh exports
show_cli_help
show_version

# utils.sh exports
print_error, print_success, print_warning, print_info
format_date, validate_date
truncate_string, center_string
```

---

### Task 4: Abolfazl Tavakolian — Documentation & Debian Packaging

**Files to Create/Edit:** `man/ticko.1`, `debian/*`, `README.md`, `README.fa.md`

#### Subtasks:

1. **Man Page** (`man/ticko.1`)

   - Write comprehensive man page following standard format
   - Sections to include:
     - NAME — Tool name and brief description
     - SYNOPSIS — Command syntax
     - DESCRIPTION — Detailed description
     - OPTIONS — All CLI options with descriptions
     - COMMANDS — All CLI commands
     - KEYBINDINGS — TUI keybinds table
     - FILES — Config file locations
     - EXAMPLES — Usage examples
     - AUTHORS — Team member names
     - SEE ALSO — Related tools
   - Use proper man page macros (`.TH`, `.SH`, `.TP`, `.B`, etc.)
   - Test with `man ./ticko.1`

2. **Debian Package Files** (`debian/*`)

   - Update `debian/control`:
     - Proper description
     - Correct dependencies (`bash`, etc.)
     - Team info in Maintainer
   - Update `debian/changelog`:
     - Proper version entries
     - Change descriptions
   - Update `debian/install`:
     - All source files
     - Config file path
   - Update `debian/links`:
     - Symlinks if needed
   - Verify `debian/rules` is correct
   - Test package build with `debuild -us -uc`

3. **README Files**
   - Update `README.md`:
     - Project description
     - Features list
     - Installation instructions
     - Usage examples (CLI and TUI)
     - Screenshots/demos (ASCII art)
     - Team member credits
   - Update `README.fa.md`:
     - Persian translation of README.md

#### Dependencies on Other Tasks:

- Wait for CLI commands to be finalized (MohammadHossein) before documenting
- Wait for TUI keybinds to be finalized (Mehrad) before documenting
- Can start with structure while waiting

---

## Timeline & Milestones

| Day   | Date  | Milestone                                  |
| ----- | ----- | ------------------------------------------ |
| Day 1 | Jan 6 | Set up individual files, define interfaces |
| Day 2 | Jan 7 | Core implementation complete               |
| Day 3 | Jan 8 | Integration & Testing                      |
| Day 4 | Jan 9 | Bug fixes, Documentation, Final packaging  |

---

## Integration Points

### Shared Constants (define in `ticko.sh`):

```bash
VERSION="1.0.0"
APP_NAME="Ticko"
DEFAULT_CONFIG_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/ticko/ticko.conf"
DEFAULT_DATA_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/ticko/todos.txt"
```

### Main Script Structure (`ticko.sh`):

```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Source all modules
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/data.sh"
source "$SCRIPT_DIR/todo.sh"
source "$SCRIPT_DIR/cli.sh"
source "$SCRIPT_DIR/help.sh"
source "$SCRIPT_DIR/keybinds.sh"
source "$SCRIPT_DIR/tui.sh"

# Load config
load_config

# Parse CLI args
parse_args "$@"

# Either run TUI or handle CLI command
if [[ "$MODE" == "tui" ]]; then
    run_tui
else
    run_cli_command
fi
```

---

## Definition of Done

- [ ] All commands work as documented
- [ ] TUI is fully functional with all keybinds
- [ ] Keybinds work correctly
- [ ] Data persists between sessions
- [ ] Custom file paths work
- [ ] Help is available in CLI (`--help`) and TUI (`?`)
- [ ] Man page is complete and correct
- [ ] Debian package builds without errors
- [ ] Package installs and uninstalls cleanly
- [ ] README is updated with usage instructions

---

## Testing Checklist

```bash
# Build package
debuild -us -uc

# Install
sudo dpkg -i ../ticko_1.0-1_all.deb

# Test CLI
ticko --help
ticko --version
ticko add "Test item"  # Note the returned ID
ticko list             # Shows IDs of all items
ticko done <ID>        # Use ID from list
ticko remove <ID>      # Use ID from list

# Test TUI
ticko  # Should launch TUI
# Test all keybinds

# Test man page
man ticko

# Uninstall
sudo apt remove ticko
```

---

## Communication

- **Merge to master:** Only after testing locally
- **Branch naming:** `feature/member-name-feature`
- **Commit messages:** Clear and descriptive
- **Questions:** Use GitHub Issues or group chat

---

Good luck, team!
