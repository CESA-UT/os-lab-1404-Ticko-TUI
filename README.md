[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/1Hm_uBaj)
# MyTool — Bash Tool Debian Packaging Template

**[نسخه فارسی](README.fa.md) | English Version**

**Operating System Lab - Final Project**  
**First Semester 1404-1405 (2025-2026)**  
**Due Date: January 9, 2026 (19 Dey 1404) - 23:59**

This repository is a template for your team to create a Bash command-line tool and package it into a `.deb` package.

## 📋 Project Topics

Before you start, **choose one topic** from the list of 21 available projects:

**[View All Project Topics](PROJECT_TOPICS.md)** | **[مشاهده موضوعات پروژه](PROJECT_TOPICS.fa.md)**

Each topic has specific requirements and suggested commands. Make sure to coordinate with other teams to avoid duplicates.

## ⚠️ FIRST STEP: Rename Your Project!

**`mytool` is just a placeholder name!** Your team should:

1. **Choose a meaningful name** that represents your project topic
2. **Rename all files:**
   - `src/mytool.sh` → `src/yourproject.sh`
   - `man/mytool.1` → `man/yourproject.1`
   - `config/mytool.conf` → `config/yourproject.conf`
3. **Update `debian/control`** (Source and Package fields)
4. **Update `debian/changelog`** (package name)
5. **Update `debian/install`** (all file paths)
6. **Update `debian/manpages`** (man page path)
7. **Update `debian/links`** (all file paths)

**Examples of good names:** `diskmonitor`, `loganalyzer`, `fileorganizer`, `sysbackup`, `netcheck`

---

## 🧩 Where to put your team's code

- Write your Bash program in **src/mytool.sh** (after renaming it!)
- Update the man page in **man/mytool.1**
- Update configuration in **config/mytool.conf** (optional)

---

## 🛠 Building the .deb Package

### 1. Install required tools (on Ubuntu/Debian)

```bash
sudo apt-get update
sudo apt-get install -y devscripts debhelper build-essential
```

### 2. Build the package

From the project root directory:

```bash
debuild -us -uc
```

If successful, the `.deb` file appears in the **parent directory**:

```bash
ls ../*.deb
# Example output: ../mytool_1.0-1_all.deb
```

### 3. Install and test your package

```bash
# Install the package
sudo dpkg -i ../*.deb

# Test your tool
mytool  # (or whatever you renamed it to!)

# Check installed files
dpkg -L mytool

# View the man page
man mytool

# Uninstall when done testing
sudo apt remove mytool
```

---

## 📝 Customizing your tool

**STEP 1: Rename everything from `mytool` to your project name!**

- Rename all source files, man pages, and config files
- Update `debian/control`, `debian/changelog`, `debian/install`, `debian/links`, and `debian/manpages`
- Change file paths in `debian/install` to match your renamed files
- Change file paths in `debian/links` to match your renamed files
- Update metadata in `debian/control` with your team information
- Update version info in `debian/changelog` when your team submits new versions
- Coordinate with team members to avoid merge conflicts!

---

## 📦 What this template gives you

- A valid Debian packaging structure (`debian/` directory)
- Example code, config, and documentation
- Automatic installation of:
  - `/usr/bin/mytool` (your executable)
  - `/etc/mytool.conf` (configuration file)
  - Man page in `/usr/share/man/man1/mytool.1.gz`

---

## 📚 Documentation

- **[Publishing Guide](PUBLISHING_GUIDE.md)** - How to publish your package to GitHub Releases ([فارسی](PUBLISHING_GUIDE.fa.md))
- **[Debian Packaging Guide](DEBIAN_PACKAGING.md)** - Debian packaging instructions ([فارسی](DEBIAN_PACKAGING.fa.md))

---

## 🎯 File Structure

```
my-bash-tool/
├── src/
│   └── mytool.sh              # Your main script (rename me!)
├── man/
│   └── mytool.1               # Man page documentation (rename me!)
├── config/
│   └── mytool.conf            # Configuration file (rename me!)
├── debian/
│   ├── changelog              # Version history (update me!)
│   ├── control                # Package metadata (update me!)
│   ├── install                # File installation mappings (update me!)
│   ├── links                  # File link mappings (update me!)
│   ├── manpages               # Man page registration (update me!)
│   └── rules                  # Build rules (usually no changes needed)
├── .gitignore                 # Excludes build artifacts
├── DEBIAN_PACKAGING.md        # Debian packaging guide (English)
├── DEBIAN_PACKAGING.fa.md     # Debian packaging guide (Persian)
├── README.md                  # This file (English)
├── README.fa.md               # Persian version
├── PUBLISHING_GUIDE.md        # Publishing instructions (English)
└── PUBLISHING_GUIDE.fa.md     # Publishing instructions (Persian)
```

---

## ⚠️ Important Reminders

1. **Rename everything** - Don't leave any "mytool" references in your final submission!
2. **Test thoroughly** - Install and test your package before publishing
3. **Coordinate with your team** - Use git branches to avoid conflicts
4. **Update all debian files** - Make sure all metadata reflects your actual project
5. **Follow naming rules** - Only lowercase letters (a-z), numbers (0-9), and hyphens (-)

---

## 📊 Grading Information

**Base Score:** 4 points  
**Maximum Score:** 6 points (with bonus features)

**Required Deliverables:**
1. Complete source code in `src/`
2. Man page in `man/`
3. Debian packaging files in `debian/`
4. Built `.deb` package
5. Comprehensive README with team member names
6. Project report explaining implementation and showing screenshots

---

## 🆘 Getting Help

- Check [PUBLISHING_GUIDE.md](PUBLISHING_GUIDE.md) for detailed build and release instructions
- Read [DEBIAN_PACKAGING.md](DEBIAN_PACKAGING.md) for packaging guidance
- Review [PROJECT_TOPICS.md](PROJECT_TOPICS.md) for topic-specific requirements
- Review the Troubleshooting section in the Publishing Guide
- Ask your instructor or teaching assistants for help

---

## 🎉 Happy packaging!

Good luck with your project!
