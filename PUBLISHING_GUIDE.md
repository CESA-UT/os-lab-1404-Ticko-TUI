# 📦 Publishing Your Team's Debian Package to GitHub Releases

**[نسخه فارسی](PUBLISHING_GUIDE.fa.md) | English Version**

This guide explains how to build your Debian package locally and publish it to GitHub Releases for submission.

---

## 🛠️ Step 1: Build Your Package Locally

**Note:** Any team member can build the package, but coordinate to ensure you're working with the latest code!

### Install Build Tools (First Time Only)

```bash
sudo apt-get update
sudo apt-get install -y devscripts debhelper build-essential
```

### Build the Package

From your project root directory:

```bash
debuild -us -uc
```

This creates the `.deb` file in the **parent directory**:

```bash
ls ../*.deb
# Output: ../yourproject_1.0-1_all.deb
```

### Test Your Package

```bash
# Install it
sudo dpkg -i ../yourproject_*.deb

# Test it works
yourproject  # Replace with your actual command name

# Check installed files
dpkg -L yourproject

# View man page
man yourproject

# Uninstall when done testing
sudo apt remove yourproject
```

---

## 📤 Step 2: Create a GitHub Release

**Note:** Designate one team member to create the release, or coordinate to avoid creating duplicate releases.

### Option A: Using GitHub Web Interface (Recommended for Beginners)

1. **Push your team's code to GitHub:**

   ```bash
   git add .
   git commit -m "Final version for submission"
   git push origin main
   ```

2. **Go to your repository on GitHub**

3. **Click on "Releases"** (right sidebar)

4. **Click "Create a new release"**

5. **Fill in the release form:**

   - **Tag version:** `v1.0` (or match your version in debian/changelog)
   - **Release title:** `v1.0 - Initial Release`
   - **Description:** Brief summary of what your team's tool does and list team members
   - **Attach files:** Drag and drop your `.deb` file

6. **Click "Publish release"**

### Option B: Using GitHub CLI (Advanced)

```bash
# Install GitHub CLI (first time only)
sudo apt install gh

# Login to GitHub
gh auth login

# Create a release and upload your .deb
gh release create v1.0 \
  --title "v1.0 - Initial Release" \
  --notes "Our team's bash tool packaged as .deb" \
  ../yourproject_*.deb
```

---

## ✅ Step 3: Verify Your Release

1. Go to your repository's Releases page
2. You should see your release with the `.deb` file attached
3. Click the `.deb` file to verify it downloads correctly
4. Have all team members verify the release
5. Copy the release URL and submit it for grading

---

## 🔄 Updating Your Release

If your team needs to make changes:

1. **Update the version** in `debian/changelog`:

   ```bash
   dch -i
   # This opens an editor to add a new changelog entry
   ```

2. **Rebuild the package:**

   ```bash
   debuild -us -uc
   ```

3. **Create a new release** (e.g., `v1.1`) with the new `.deb` file

---

## 📋 Team Checklist Before Submission

- [ ] **Renamed all files from `mytool` to your project name**
- [ ] **Updated all `debian/` files with your project name**
- [ ] Package builds without errors
- [ ] Package installs successfully with `dpkg -i`
- [ ] Your tool works when installed (your command runs, not `mytool`!)
- [ ] Man page is accessible (`man yourproject`, not `man mytool`!)
- [ ] Updated `debian/control` with team name/representative
- [ ] Updated `debian/changelog` with team information
- [ ] All team members have reviewed the code
- [ ] `.deb` file is uploaded to a GitHub Release
- [ ] All team members have verified the release
- [ ] Release URL submitted for grading

---

## 🆘 Troubleshooting

### Build Fails with "Bad signature"

This is normal with `-us -uc` flags (unsigned). These flags skip GPG signing, which is fine for learning.

### "No such file or directory" during build

Check that files listed in `debian/install` actually exist in your project and have the correct names.

### Package installs but command not found

Verify:

1. `debian/install` puts the script in `usr/bin/yourcommand` (no leading `/`)
2. Your script has execute permissions: `chmod +x src/yourproject.sh`
3. Check with a team member if they modified the installation paths

### "Cannot find file" in GitHub Release

Make sure you're uploading the `.deb` from the parent directory (`../`), not from inside your project.

### Merge Conflicts

Coordinate with your team! Use branches and pull requests to avoid conflicts in `debian/` files.

### Still see "mytool" references after renaming

You missed some files! Check:

- `debian/control` (Source and Package fields)
- `debian/changelog` (first line)
- `debian/install` (all paths)
- `debian/manpages` (man page path)
- Man page content (`.TH` line and throughout)
- Config file paths

---

## 🎯 Quick Command Reference

```bash
# Build package
debuild -us -uc

# Install package (replace 'yourproject' with your actual name)
sudo dpkg -i ../yourproject_*.deb

# Test package
yourproject      # Your command
man yourproject  # Your man page

# Remove package
sudo apt remove yourproject

# Create GitHub release (with gh CLI)
gh release create v1.0 --title "Release v1.0" ../yourproject_*.deb
```

---

## 💡 Tips for Success

1. **Test early, test often** - Don't wait until the last minute to build and test your package
2. **Use meaningful commit messages** - This helps track what changed and when
3. **Document your tool** - Good documentation in the man page and README helps users (and graders!)
4. **Coordinate with your team** - Regular communication prevents conflicts and duplicated work
5. **Keep backups** - Make sure your code is pushed to GitHub regularly

---

Good luck with your submission! 🚀
