# Project Topics

**[نسخه فارسی](PROJECT_TOPICS.fa.md) | English Version**

Choose one of the 21 topics below for your team's CLI tool project. Each tool must be implemented in Bash and packaged as a Debian package.

---

## Section 1: File & Disk Utilities

### 1. Disk Usage Analyzer
A tool similar to `du` that optimizes output to display the most readable and resource-intensive directories.

**Suggested Commands:** `du`, `sort`, `head`, `awk`

**Features to implement:**
- Analyze directory sizes recursively
- Sort and display top space-consuming directories
- Human-readable output format
- Optional depth limit

---

### 2. Smart Log Cleaner
A script to clean or archive old log files based on size, date, or count.

**Suggested Commands:** `find`, `du`, `rm`, `tar`, `gzip`

**Features to implement:**
- Find logs older than specified days
- Archive logs before deletion
- Set size thresholds for cleanup
- Preserve recent logs

---

### 3. Backup Lite
A simple backup tool that backs up a specified directory, names it with timestamp, and removes old versions.

**Suggested Commands:** `tar`, `rsync`, `date`, `find`

**Features to implement:**
- Create timestamped backups
- Incremental or full backup options
- Automatic old backup rotation
- Compression support

---

### 4. File Change Watcher
Monitors a directory for any changes (create, delete, edit files) and reports them.

**Suggested Commands:** `inotifywait` (from inotify-tools) or `find` and `stat` in a loop

**Features to implement:**
- Real-time file system monitoring
- Event type detection (create, modify, delete)
- Log changes to file or stdout
- Filter by file types

---

### 5. Versioned Archive Manager
Creates numbered archives (like project-v1.tar.gz) from a project or directory and provides the ability to restore old versions.

**Suggested Commands:** `tar`, `ls`, `sed`

**Features to implement:**
- Auto-increment version numbers
- List available versions
- Restore specific versions
- Version comparison

---

### 6. Regex-based File Searcher
A more powerful tool than simple `grep` that searches files by name and content matching regex patterns.

**Suggested Commands:** `find`, `grep` (with `-E` option), `sed`

**Features to implement:**
- Search by filename pattern
- Search by file content
- Combine multiple search criteria
- Display context around matches

---

### 7. Dotfile Sync & Manager
A tool for managing dotfiles (like .bashrc, .vimrc) by creating symlinks from a central repository to home directory.

**Suggested Commands:** `ln -s`, `git`, `find`

**Features to implement:**
- Initialize dotfile repository
- Install/uninstall dotfiles
- Backup existing dotfiles
- Sync across multiple machines

---

## Section 2: System & Process Monitoring

### 8. CPU & RAM Monitor
Live and simple display of CPU, RAM, and Swap usage in the terminal.

**Suggested Commands:** `top`, `free`, `vmstat`, `awk`, `watch`

**Features to implement:**
- Real-time CPU usage per core
- Memory usage breakdown
- Swap usage monitoring
- Configurable refresh rate

---

### 9. User Activity Reporter
Report on system users' activity including last login time, online duration, and active process count.

**Suggested Commands:** `who`, `last`, `w`, `ps`

**Features to implement:**
- List currently logged-in users
- Show login history
- Display user process statistics
- Calculate session durations

---

### 10. Process Management Tool
Display, filter, and send signals (like KILL, TERM, HUP) to processes based on name, user, or resource consumption.

**Suggested Commands:** `ps`, `pgrep`, `pkill`, `kill`

**Features to implement:**
- List processes with filters
- Send signals to processes
- Sort by CPU/memory usage
- Interactive process selection

---

### 11. System Health Checker
A text dashboard showing overall system status (Load Average, Disk Space, Memory, Uptime).

**Suggested Commands:** `uptime`, `df`, `free`, `iostat`

**Features to implement:**
- System load overview
- Disk space warnings
- Memory pressure detection
- Service status checks

---

### 12. Log Analyzer & Summary
Reads system log files (like syslog or auth.log) and extracts important statistics such as error counts, failed login attempts, etc.

**Suggested Commands:** `grep`, `awk`, `sort`, `uniq -c`

**Features to implement:**
- Parse common log formats
- Extract error patterns
- Count event types
- Generate summary reports

---

### 13. System Log Visualizer
Similar to the previous project, but displays statistics as text-based charts (ASCII bar charts) in the terminal.

**Suggested Commands:** `grep`, `awk`, `sort`, `uniq`, and Bash logic for chart generation

**Features to implement:**
- ASCII bar charts
- Time-based graphs
- Trend visualization
- Customizable chart types

---

### 14. Configuration Drift Detector
Maintains a "golden" version of configuration files and reports if original files change.

**Suggested Commands:** `diff`, `md5sum` or `sha256sum`

**Features to implement:**
- Baseline configuration storage
- Change detection
- Diff report generation
- Restore original configs

---

## Section 3: Automation & Networking

### 15. Simple Port Scanner
Using system tools, scans and reports open ports on a specific host.

**Suggested Commands:** `netcat (nc)`, `nmap` (wrapper), or `/dev/tcp/`

**Features to implement:**
- Scan single or range of ports
- TCP/UDP scanning
- Service detection
- Output formatting

---

### 16. URL & Service Status Monitor
Periodically checks a list of URLs or IP:Port and alerts if unavailable.

**Suggested Commands:** `curl`, `wget`, `ping`, `nc`

**Features to implement:**
- Monitor multiple endpoints
- HTTP status code checking
- Response time tracking
- Alert on failures

---

### 17. Log Rotation & Cleanup Manager
A tool that periodically (using cron) checks system log files or a specified path, compresses or deletes old/large logs, and records operation reports.

**Suggested Commands:** `find`, `du`, `gzip`, `date`, `awk`, `cron`

**Features to implement:**
- Scheduled log rotation
- Size-based and age-based cleanup
- Log compression before deletion
- Operation logging
- Configurable retention policies

---

### 18. Automated Backup Scheduler
An automated backup tool that uses cron to back up a specified path, compresses it, and saves it to a standard system location.

**Suggested Commands:** `tar`, `rsync`, `find`, `date`, `cron`

**Features to implement:**
- Automated scheduled backups
- Incremental and full backup modes
- Compression and storage management
- Old backup cleanup
- Backup verification

---

### 19. CLI TODO / Note Manager
A simple tool for adding, removing, and listing tasks (TODOs) or short notes stored in a text file.

**Suggested Commands:** `echo`, `grep`, `sed`

**Features to implement:**
- Add/remove/list tasks
- Mark tasks as done
- Priority levels
- Search functionality

---

### 20. Cache & Temp Cleaner
Identifies and cleans system temporary files and application caches (e.g., apt or dnf) and reports freed space.

**Suggested Commands:** `find`, `rm`, `du`

**Features to implement:**
- Safe cache detection
- Dry-run mode
- Space calculation
- User confirmation

---

### 21. Network Availability Checker
A tool that reports connection status to various servers on a network using a combination of ping and port checking.

**Suggested Commands:** `ping`, `fping`, `nc`, `traceroute`

**Features to implement:**
- Multiple host checking
- ICMP and TCP testing
- Latency measurement
- Connectivity reports

---

## Selection Guidelines

1. **Choose based on interest:** Pick a topic that matches your team's interests and skill level
2. **Consider complexity:** Some topics are more challenging than others
3. **Unique implementation:** Each team should choose a different topic (coordinate with other teams)
4. **Feature completeness:** Implement all core features before adding extras
5. **User experience:** Focus on making the tool useful and easy to use

---

## Need Help?

- Review the [Main README](README.md) for setup instructions
- Check [Debian Packaging Guide](DEBIAN_PACKAGING.md) for packaging help
- See [Publishing Guide](PUBLISHING_GUIDE.md) for submission instructions
- Ask your instructor or TAs for clarification
