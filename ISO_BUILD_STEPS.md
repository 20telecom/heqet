# Step-by-Step Guide: Building Custom Debian 12 ISO in GitHub Codespaces (Heqet)

This comprehensive guide walks you through building the custom Debian 12 ISO with integrated FreePBX 17 installation using GitHub Codespaces. Follow these steps for a successful build.

## ⚠️ IMPORTANT SECURITY NOTICE

**This guide uses default test credentials for demonstration purposes only.**

Default credentials included in the preseed configuration:
- Root: Randomized (credentials displayed in Heqet Gate)

**These credentials are for TESTING ONLY and must NEVER be used in production environments.**

Before deploying to production:
1. Edit `iso-build/config/preseed.cfg` to change the root password
2. Rebuild the ISO with secure credentials
3. Follow security best practices in Section 9

---

## Table of Contents

1. [Prerequisites and Codespace Setup](#1-prerequisites-and-codespace-setup)
2. [Install Dependencies](#2-install-dependencies)
3. [Navigate and Prepare Scripts](#3-navigate-and-prepare-scripts)
4. [Build Process - Five Phases](#4-build-process---five-phases)
5. [Troubleshooting Common Issues](#5-troubleshooting-common-issues)
6. [Verify Build Success](#6-verify-build-success)
7. [Cleanup After Build](#7-cleanup-after-build)
8. [Test the ISO](#8-test-the-iso)
9. [Support and Next Steps](#9-support-and-next-steps)

---

## 1. Prerequisites and Codespace Setup

### What is GitHub Codespaces?

GitHub Codespaces provides a complete, cloud-based development environment that runs in your browser. It comes pre-configured with common development tools and provides consistent build environments.

### Setting Up Your Codespace

#### Step 1.1: Access the Repository

1. Navigate to the Heqet repository on GitHub:
   ```
   https://github.com/kierknoby/heqet
   ```

2. Click the green **"Code"** button in the top right

3. Select the **"Codespaces"** tab

#### Step 1.2: Create a New Codespace

1. Click **"Create codespace on main"** (or your desired branch)
   - Alternatively, click the **"+"** icon to create a new codespace

2. Wait for the Codespace to initialize (typically 1-2 minutes)
   - You'll see a VS Code-like interface load in your browser
   - The repository will be automatically cloned

3. Verify you're in the correct directory:
   ```bash
   pwd
   # Should output: /workspaces/Heqet
   ```

#### Step 1.3: Check System Resources

Verify your Codespace has sufficient resources:

```bash
# Check available disk space (need at least 10GB free)
df -h /workspaces

# Check memory (2GB+ recommended)
free -h

# Verify internet connectivity
ping -c 3 8.8.8.8
```

**Expected Output:**
```
Filesystem      Size  Used Avail Use% Mounted on
overlay         32G   5G   27G   16% /workspaces

              total        used        free      shared  buff/cache   available
Mem:           7.7Gi       1.2Gi       5.8Gi       8.0Mi       719Mi       6.2Gi

3 packets transmitted, 3 received, 0% packet loss
```

---

## 2. Install Dependencies

The ISO build process requires several packages. Follow these steps to install them.

### Step 2.1: Update Package Lists

First, ensure your package lists are current:

```bash
sudo apt-get update
```

**Expected Output:**
```
Hit:1 http://archive.ubuntu.com/ubuntu jammy InRelease
Get:2 http://archive.ubuntu.com/ubuntu jammy-updates InRelease [119 kB]
...
Reading package lists... Done
```

**Duration:** ~10-30 seconds

### Step 2.2: Install Required Packages

Install all necessary dependencies for ISO building:

```bash
sudo apt-get install -y xorriso isolinux syslinux-utils genisoimage wget curl
```

**Expected Output:**
```
Reading package lists... Done
Building dependency tree... Done
The following NEW packages will be installed:
  xorriso isolinux syslinux-utils genisoimage wget curl
0 upgraded, 6 newly installed, 0 to remove and 0 not upgraded.
Need to get 2,345 kB of archives.
...
Setting up xorriso (1.5.4-2) ...
Setting up isolinux (3:6.04~git20190206.bf6db5b4+dfsg1-3) ...
...
Processing triggers for man-db (2.10.2-1) ...
```

**Duration:** ~1-2 minutes

### Step 2.3: Verify Installation

Confirm all packages are installed correctly:

```bash
# Check xorriso (ISO creation tool)
xorriso --version | head -n 1

# Check isolinux (boot loader)
isolinux --version 2>&1 | head -n 1

# Check genisoimage
genisoimage --version 2>&1 | head -n 1

# Check curl
curl --version | head -n 1

# Check wget
wget --version | head -n 1
```

**Expected Output:**
```
xorriso 1.5.4 : RockRidge filesystem manipulator, libburnia project.
isolinux: 6.04
genisoimage 1.1.11 (Linux)
curl 7.81.0 (x86_64-pc-linux-gnu)
GNU Wget 1.21.2 built on linux-gnu.
```

✅ **Success Indicator:** All commands return version information without errors.

❌ **Failure Indicator:** "command not found" or "no such file or directory" errors.

---

## 3. Navigate and Prepare Scripts

### Step 3.1: Navigate to Build Scripts Directory

```bash
cd /workspaces/Heqet/iso-build/scripts
pwd
```

**Expected Output:**
```
/workspaces/Heqet/iso-build/scripts
```

### Step 3.2: List Available Scripts

View the scripts available for building and testing:

```bash
ls -lh
```

**Expected Output:**
```
total 32K
-rwxr-xr-x 1 codespace codespace   89 Jan 17 13:17 build-iso.sh
-rwxr-xr-x 1 codespace codespace 6.3K Jan 17 13:17 diagnostics.sh
-rw-r--r-- 1 codespace codespace 5.3K Jan 17 13:17 test-confirmation-logic.sh
-rwxr-xr-x 1 codespace codespace 6.4K Jan 17 13:17 test-iso.sh
-rwxr-xr-x 1 codespace codespace 5.5K Jan 17 13:17 validate-preseed.sh
```

### Step 3.3: Grant Execution Permissions

Ensure all scripts have execution permissions (they should already, but this confirms):

```bash
chmod +x build-iso.sh test-iso.sh diagnostics.sh validate-preseed.sh
```

**Verify Permissions:**
```bash
ls -l *.sh | awk '{print $1, $9}'
```

**Expected Output:**
```
-rwxr-xr-x build-iso.sh
-rwxr-xr-x diagnostics.sh
-rwxr-xr-x test-iso.sh
-rwxr-xr-x validate-preseed.sh
```

✅ **Success Indicator:** All `.sh` files show `-rwxr-xr-x` (executable)

### Step 3.4: Verify Preseed Configuration

Check that the preseed configuration file exists:

```bash
ls -lh ../config/preseed.cfg
```

**Expected Output:**
```
-rw-r--r-- 1 codespace codespace 15K Jan 17 13:17 ../config/preseed.cfg
```

### Step 3.5: Verify IN1CLICK Script

Confirm the IN1CLICK script is available:

```bash
ls -lh ../../IN1CLICK
```

**Expected Output:**
```
-rw-r--r-- 1 codespace codespace 45K Jan 17 13:17 ../../IN1CLICK
```

---

## 4. Build Process - Five Phases

The ISO build process consists of five distinct phases. Each phase is described below with expected outputs and time estimates.

### Overview of Build Phases

| Phase | Description | Duration | Output Location |
|-------|-------------|----------|-----------------|
| 1 | Initialization | ~5 seconds | Terminal output |
| 2 | Download Debian ISO | ~3-8 minutes | `../build/` |
| 3 | Extract ISO | ~30-60 seconds | `../build/iso-extract/` |
| 4 | Customize ISO | ~10-20 seconds | `../build/iso-extract/` |
| 5 | Generate Final ISO | ~2-5 minutes | `../output/` |

### Starting the Build

Run the build script with sudo (required for mounting ISO images):

```bash
sudo ./build-iso.sh
```

---

### Phase 1: Initialization

**Duration:** ~5 seconds

**What Happens:**
- Script checks for root/sudo privileges
- Verifies required packages are installed
- Creates necessary directory structure
- Sets up logging

**Expected Console Output:**
```
╔═══════════════════════════════════════════════════════════════╗
║         Heqet - Debian 12 ISO Build with IN1CLICK             ║
╚═══════════════════════════════════════════════════════════════╝

[2025-01-17 13:20:00] Starting Debian 12 ISO build with IN1CLICK integration...
[2025-01-17 13:20:00] Checking required packages...
[2025-01-17 13:20:01] ✓ xorriso is installed
[2025-01-17 13:20:01] ✓ isolinux is installed
[2025-01-17 13:20:01] ✓ genisoimage is installed
[2025-01-17 13:20:01] ✓ wget is installed
[2025-01-17 13:20:01] ✓ curl is installed
[2025-01-17 13:20:01] All required packages are installed.
[2025-01-17 13:20:01] Setting up build directories...
[2025-01-17 13:20:01] ✓ Build directories created
```

✅ **Success Indicator:** All packages show checkmarks (✓)

❌ **Failure Indicator:** Missing package warnings - see [Troubleshooting](#dependency-errors)

---

### Phase 2: Download Debian ISO

**Duration:** ~3-8 minutes (depends on internet speed)

**What Happens:**
- Downloads official Debian 12 netinst ISO (~400MB)
- Verifies download integrity
- Skips download if ISO already exists

**Expected Console Output:**
```
[2025-01-17 13:20:02] Checking for existing Debian ISO...
[2025-01-17 13:20:02] Debian ISO not found. Downloading...
[2025-01-17 13:20:02] Downloading Debian 12.x AMD64 netinst ISO...
[2025-01-17 13:20:02] Source: https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-XX.X.X-amd64-netinst.iso
[2025-01-17 13:20:02] This may take several minutes depending on your connection...
[2025-01-17 13:20:02] 
[2025-01-17 13:20:02] Note: The exact version number will vary (e.g., 12.8.0, 12.9.0, etc.)

Downloading: debian-12.8.0-amd64-netinst.iso
  % Total    % Received  Time    Time     Time  Current
                         Total   Spent    Left  Speed
  0  400M    0     0    0     0      0      0 --:--:-- --:--:--
  5  400M    5  20M     0     0   3.2M      0  0:02:04  0:00:06
 12  400M   12  48M     0     0   4.1M      0  0:01:37  0:00:11
 25  400M   25  100M    0     0   5.0M      0  0:01:20  0:00:20
...
100  400M  100  400M    0     0   5.8M      0  0:01:09  0:01:09

[2025-01-17 13:25:15] ✓ Debian ISO downloaded successfully
[2025-01-17 13:25:15] ISO saved to: ../build/debian-XX.X.X-amd64-netinst.iso
[2025-01-17 13:25:15] File size: 400 MB
[2025-01-17 13:25:15] 
Note: XX.X.X represents the current Debian 12 point release version (e.g., 12.8.0)
```

**Files Created:**
```
../build/debian-XX.X.X-amd64-netinst.iso  (~400 MB)
```
Note: The exact filename will include the current Debian 12 point release version.

✅ **Success Indicator:** Download reaches 100%, checkmark appears

❌ **Failure Indicator:** Connection timeout, download errors - see [Troubleshooting](#download-failures)

**Note:** If you run the build again, this phase will be skipped:
```
[2025-01-17 13:20:02] ✓ Debian ISO already exists, skipping download
```

---

### Phase 3: Extract ISO

**Duration:** ~30-60 seconds

**What Happens:**
- Mounts the Debian ISO
- Extracts all files to working directory
- Prepares directory structure for customization
- Unmounts the ISO

**Expected Console Output:**
```
[2025-01-17 13:25:16] Extracting Debian ISO contents...
[2025-01-17 13:25:16] Creating extraction directory...
[2025-01-17 13:25:16] Mounting ISO...
[2025-01-17 13:25:16] Copying ISO contents (this may take a minute)...

Copying files: [####################################] 100%

[2025-01-17 13:25:47] Unmounting ISO...
[2025-01-17 13:25:47] ✓ ISO contents extracted successfully
[2025-01-17 13:25:47] Extracted to: ../build/iso-extract/
[2025-01-17 13:25:47] Files extracted: 3,247
[2025-01-17 13:25:47] Total size: 450 MB
```

**Files Created:**
```
../build/iso-extract/
  ├── boot/
  ├── dists/
  ├── install.amd/
  ├── isolinux/
  ├── md5sum.txt
  └── [many other files and directories]
```

✅ **Success Indicator:** Extraction completes with checkmark, all files copied

❌ **Failure Indicator:** Mount errors, permission denied - see [Troubleshooting](#permission-issues)

---

### Phase 4: Customize ISO

**Duration:** ~10-20 seconds

**What Happens:**
- Copies preseed.cfg to ISO root for automated installation
- Copies IN1CLICK script to ISO
- Modifies isolinux (BIOS) boot configuration
- Modifies GRUB (UEFI) boot configuration
- Sets boot timeout and default options

**Expected Console Output:**
```
[2025-01-17 13:25:48] Customizing ISO with preseed and IN1CLICK...
[2025-01-17 13:25:48] 
[2025-01-17 13:25:48] Step 1: Adding preseed configuration...
[2025-01-17 13:25:48] ✓ Preseed file copied to ISO root
[2025-01-17 13:25:48] File: preseed.cfg (15 KB)
[2025-01-17 13:25:49] 
[2025-01-17 13:25:49] Step 2: Adding IN1CLICK script...
[2025-01-17 13:25:49] Creating in1click directory in ISO...
[2025-01-17 13:25:49] ✓ IN1CLICK script copied
[2025-01-17 13:25:49] File: in1click/IN1CLICK (45 KB)
[2025-01-17 13:25:49] 
[2025-01-17 13:25:49] Step 3: Configuring boot loader (BIOS/isolinux)...
[2025-01-17 13:25:49] Backing up original isolinux.cfg...
[2025-01-17 13:25:49] Modifying boot menu...
[2025-01-17 13:25:49] ✓ Isolinux configuration updated
[2025-01-17 13:25:50] - Auto-install option added
[2025-01-17 13:25:50] - Boot timeout: 10 seconds
[2025-01-17 13:25:50] - Default: Automated Installation
[2025-01-17 13:25:50] 
[2025-01-17 13:25:50] Step 4: Configuring boot loader (UEFI/GRUB)...
[2025-01-17 13:25:50] Backing up original grub.cfg...
[2025-01-17 13:25:50] Modifying GRUB menu...
[2025-01-17 13:25:50] ✓ GRUB configuration updated
[2025-01-17 13:25:50] - Auto-install entry added
[2025-01-17 13:25:50] - Preseed parameters configured
[2025-01-17 13:25:51] 
[2025-01-17 13:25:51] ✓ ISO customization completed successfully
```

**Files Modified:**
```
../build/iso-extract/
  ├── preseed.cfg (new file)
  ├── in1click/
   │   └── IN1CLICK (new file)
  ├── isolinux/
  │   ├── isolinux.cfg (modified)
  │   └── isolinux.cfg.backup (created)
  └── boot/grub/
      ├── grub.cfg (modified)
      └── grub.cfg.backup (created)
```

✅ **Success Indicator:** All 4 steps show checkmarks

❌ **Failure Indicator:** File not found errors - verify preseed.cfg and IN1CLICK script exist

---

### Phase 5: Generate Final ISO

**Duration:** ~2-5 minutes

**What Happens:**
- Generates new ISO from customized directory
- Creates hybrid ISO (bootable on BIOS and UEFI)
- Sets boot flags and volume labels
- Calculates SHA256 checksum for verification
- Saves ISO to output directory

**Expected Console Output:**
```
[2025-01-17 13:25:52] Generating custom ISO image...
[2025-01-17 13:25:52] This may take several minutes...
[2025-01-17 13:25:52] 
[2025-01-17 13:25:52] xorriso 1.5.4 : RockRidge filesystem manipulator
[2025-01-17 13:25:52] Drive current: -outdev 'stdio:../output/heqet_0-0-1.iso'
[2025-01-17 13:25:52] Media current: stdio file, overwriteable
[2025-01-17 13:25:52] Media status : is blank
[2025-01-17 13:25:53] Scanning files for content...
[2025-01-17 13:25:55] Writing to '../output/heqet_0-0-1.iso' completed successfully
[2025-01-17 13:25:55] 
[2025-01-17 13:25:55] ISO Image generated: 3,247 files, 450 MB
[2025-01-17 13:25:55] Adding ISO to partition table...
[2025-01-17 13:25:56] Adding MBR partition...
[2025-01-17 13:27:32] ✓ ISO image created successfully
[2025-01-17 13:27:32] 
[2025-01-17 13:27:32] Calculating SHA256 checksum...
[2025-01-17 13:27:45] ✓ Checksum calculated
[2025-01-17 13:27:45] SHA256: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6
[2025-01-17 13:27:45] Checksum saved to: ../output/heqet_0-0-1.iso.sha256
```

**Files Created:**
```
../output/
   ├── heqet_0-0-1.iso (~450 MB)
   └── heqet_0-0-1.iso.sha256 (checksum file)
```

✅ **Success Indicator:** ISO created successfully, checksum generated

❌ **Failure Indicator:** "No space left on device" - see [Troubleshooting](#space-management)

---

### Build Complete

**Expected Final Output:**
```
╔═══════════════════════════════════════════════════════════════╗
║                  ISO BUILD COMPLETED SUCCESSFULLY              ║
╚═══════════════════════════════════════════════════════════════╝

[2025-01-17 13:27:46] Build Summary:
[2025-01-17 13:27:46] ────────────────────────────────────────────
[2025-01-17 13:27:46] Custom ISO: ../output/heqet_0-0-1.iso
[2025-01-17 13:27:46] File size: 450 MB (472,186,880 bytes)
[2025-01-17 13:27:46] Checksum: ../output/heqet_0-0-1.iso.sha256
[2025-01-17 13:27:46] Build logs: ../logs/
[2025-01-17 13:27:46] 
[2025-01-17 13:27:46] Total build time: 7 minutes 46 seconds
[2025-01-17 13:27:46] 
[2025-01-17 13:27:46] Next Steps:
[2025-01-17 13:27:46]   1. Verify build artifacts (see section 6 below)
[2025-01-17 13:27:46]   2. Download ISO from Codespaces (see section 8 below)
[2025-01-17 13:27:46]   3. Test ISO in a VM or write to USB
[2025-01-17 13:27:46]   4. Clean up temporary files (see section 7 below)
[2025-01-17 13:27:46] 
[2025-01-17 13:27:46] Default Credentials (⚠️ CHANGE FOR PRODUCTION):
[2025-01-17 13:27:46]   Root: root / heqet001
[2025-01-17 13:27:46]   User: Random (see /root/heqet-credentials.txt after installation)
╔═══════════════════════════════════════════════════════════════╗
```

**Total Duration:** Typically 10-15 minutes for complete build process

---

## 5. Troubleshooting Common Issues

This section covers common problems you might encounter and their solutions.

### Permission Issues

**Problem:** "Permission denied" or "Operation not permitted" errors

**Symptoms:**
```
Error: mount: only root can do that
Error: Permission denied: cannot create directory
```

**Solution 1: Run with sudo**
```bash
sudo ./build-iso.sh
```

**Solution 2: Check file permissions**
```bash
# Verify you have read access to IN1CLICK script
ls -l ../../IN1CLICK

# Verify preseed.cfg is readable
ls -l ../config/preseed.cfg

# If needed, fix permissions
chmod +r ../../IN1CLICK
chmod +r ../config/preseed.cfg
```

**Solution 3: Verify you're in the correct directory**
```bash
pwd
# Should be: /workspaces/Heqet/iso-build/scripts

# If not, navigate there:
cd /workspaces/Heqet/iso-build/scripts
```

---

### Dependency Errors

**Problem:** Missing packages or commands not found

**Symptoms:**
```
Error: xorriso: command not found
Error: genisoimage: No such file or directory
bash: isolinux: command not found
```

**Solution: Install missing packages**
```bash
# Update package lists
sudo apt-get update

# Install all required dependencies
sudo apt-get install -y xorriso isolinux syslinux-utils genisoimage wget curl

# Verify installation
which xorriso genisoimage wget curl
```

**Expected Output:**
```
/usr/bin/xorriso
/usr/bin/genisoimage
/usr/bin/wget
/usr/bin/curl
```

---

### Download Failures

**Problem:** Cannot download Debian ISO

**Symptoms:**
```
Error: Failed to download Debian ISO
curl: (6) Could not resolve host: cdimage.debian.org
wget: unable to resolve host address
Connection timed out
```

**Solution 1: Check internet connectivity**
```bash
# Test connection to Debian servers
ping -c 3 cdimage.debian.org

# Test DNS resolution
nslookup cdimage.debian.org

# Test with different DNS
ping -c 3 8.8.8.8
```

**Solution 2: Try manual download**
```bash
# Navigate to build directory
cd ../build

# Download ISO manually
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.8.0-amd64-netinst.iso

# Return to scripts directory
cd ../scripts

# Run build again (will skip download)
sudo ./build-iso.sh
```

**Solution 3: Use alternative mirror**

If the main Debian mirror is unavailable, edit the build script to use an alternative:

```bash
# Check for alternative Debian mirrors at:
# https://www.debian.org/mirror/list
```

---

### Space Management

**Problem:** Insufficient disk space

**Symptoms:**
```
Error: No space left on device
df: cannot write: No space left on device
```

**Solution 1: Check available space**
```bash
# Check disk usage
df -h /workspaces

# Check size of build artifacts
du -sh /workspaces/Heqet/iso-build/{build,output,logs}
```

**Solution 2: Clean up previous builds**
```bash
cd /workspaces/Heqet/iso-build

# Remove extracted ISO contents (safe to delete)
sudo rm -rf build/iso-extract/

# Remove old ISOs from build directory (keep only latest)
ls -lh build/*.iso
# Manually delete old ones if needed
rm build/old-debian-*.iso

# Remove old output ISOs (if testing multiple builds)
ls -lh output/
# Keep only the latest build
```

**Solution 3: Estimate space requirements**

Minimum space needed:
- Debian ISO download: ~400 MB
- ISO extraction: ~450 MB  
- Custom ISO output: ~450 MB
- Logs and temporary files: ~50 MB
- **Total: ~1.5 GB minimum, 3 GB recommended**

---

### Build Script Errors

**Problem:** Build script fails or exits unexpectedly

**Symptoms:**
```
Error: Failed to mount ISO
Error: Preseed configuration not found
Error: IN1CLICK script not found
```

**Solution 1: Verify repository integrity**
```bash
# Check if all files are present
cd /workspaces/Heqet

# Check preseed.cfg
test -f iso-build/config/preseed.cfg && echo "✓ Preseed found" || echo "✗ Preseed missing"

# Check IN1CLICK script
test -f IN1CLICK && echo "✓ IN1CLICK found" || echo "✗ IN1CLICK missing"

# Check build script
test -f iso-build/scripts/build-iso.sh && echo "✓ Build script found" || echo "✗ Build script missing"
```

**Solution 2: Re-clone repository**

If files are missing or corrupted:

```bash
# Exit current directory
cd ~

# Remove corrupted repository
rm -rf /workspaces/Heqet

# Clone fresh copy
git clone https://github.com/kierknoby/heqet.git /workspaces/Heqet

# Navigate to scripts
cd /workspaces/Heqet/iso-build/scripts
```

**Solution 3: Check logs**
```bash
# View build logs for details
cd /workspaces/Heqet/iso-build

# Check for log files
ls -lh logs/

# View most recent log
cat logs/xorriso.log

# View last 50 lines if log is long
tail -50 logs/xorriso.log
```

---

### ISO Mount Errors

**Problem:** Cannot mount or unmount ISO

**Symptoms:**
```
Error: mount: /tmp/iso_mount: mount failed: Device or resource busy
Error: umount: target is busy
```

**Solution 1: Force unmount**
```bash
# Find what's using the mount point
sudo lsof /tmp/iso_mount 2>/dev/null

# Force unmount
sudo umount -f /tmp/iso_mount

# If that fails, lazy unmount
sudo umount -l /tmp/iso_mount

# Clean up mount point
sudo rmdir /tmp/iso_mount 2>/dev/null
```

**Solution 2: Kill processes using the mount**
```bash
# Find processes
sudo fuser -m /tmp/iso_mount

# Kill them (replace PID with actual process ID)
sudo kill -9 PID
```

**Solution 3: Restart build**
```bash
# Clean up and try again
sudo ./build-iso.sh
```

---

### Codespace-Specific Issues

**Problem:** Codespace crashes or disconnects during build

**Solution 1: Monitor build in background**
```bash
# Run build in screen session
screen -S iso_build
sudo ./build-iso.sh

# Detach: Press Ctrl+A, then D
# Reattach later: screen -r iso_build
```

**Solution 2: Increase Codespace timeout**
- Go to Codespace settings
- Increase idle timeout
- Keep browser tab active during build

**Solution 3: Check Codespace resources**
```bash
# Monitor resources during build
top
# Press 'q' to quit

# Check for out-of-memory errors
dmesg | grep -i "out of memory"
```

---

## 6. Verify Build Success

After the build completes, verify that all artifacts were created successfully.

### Step 6.1: Check Output Directory

```bash
cd /workspaces/Heqet/iso-build/output
ls -lh
```

**Expected Output:**
```
total 450M
-rw-r--r-- 1 root root 450M Jan 17 13:27 heqet_0-0-1.iso
-rw-r--r-- 1 root root   71 Jan 17 13:27 heqet_0-0-1.iso.sha256
```

✅ **Success Indicators:**
- ISO file exists and is ~450 MB
- SHA256 checksum file exists

### Step 6.2: Verify ISO File Integrity

```bash
# Check file type
file heqet_0-0-1.iso
```

**Expected Output:**
```
heqet_0-0-1.iso: ISO 9660 CD-ROM filesystem data 'Debian 12.8.0 amd64 n' (bootable)
```

### Step 6.3: Verify Checksum

```bash
# Display checksum
cat heqet_0-0-1.iso.sha256
```

**Expected Output:**
```
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6  heqet_0-0-1.iso
```

### Step 6.4: Validate Checksum

```bash
# Verify ISO integrity
sha256sum -c heqet_0-0-1.iso.sha256
```

**Expected Output:**
```
heqet_0-0-1.iso: OK
```

✅ **Success Indicator:** Output shows "OK"

❌ **Failure Indicator:** "FAILED" indicates corrupted ISO - rebuild required

### Step 6.5: Check Build Logs

```bash
cd /workspaces/Heqet/iso-build/logs
ls -lh
```

**Expected Output:**
```
total 24K
-rw-r--r-- 1 root root 22K Jan 17 13:27 xorriso.log
```

### Step 6.6: Review Log for Errors

```bash
# Check for any errors in the build log
grep -i error logs/xorriso.log
grep -i failed logs/xorriso.log
```

**Expected Output:**
```
(no output means no errors)
```

### Step 6.7: Summary Verification Checklist

Run this comprehensive check:

```bash
cd /workspaces/Heqet/iso-build

echo "═══════════════════════════════════════════════"
echo "Build Verification Checklist"
echo "═══════════════════════════════════════════════"

# Check ISO exists
if [ -f output/heqet_0-0-1.iso ]; then
    echo "✓ ISO file exists"
   ls -lh output/heqet_0-0-1.iso
else
    echo "✗ ISO file missing"
fi

# Check checksum exists
if [ -f output/heqet_0-0-1.iso.sha256 ]; then
    echo "✓ Checksum file exists"
else
    echo "✗ Checksum file missing"
fi

# Verify ISO is bootable
if file output/atum_0-0-1.iso | grep -q "bootable"; then
    echo "✓ ISO is bootable"
else
    echo "✗ ISO is not bootable"
fi

# Check ISO size (should be ~450MB)
ISO_SIZE=$(stat -c%s output/atum_0-0-1.iso 2>/dev/null)
if [ "$ISO_SIZE" -gt 400000000 ] && [ "$ISO_SIZE" -lt 500000000 ]; then
    echo "✓ ISO size is reasonable (~450MB)"
else
    echo "⚠ ISO size is unusual: $ISO_SIZE bytes"
fi

echo "═══════════════════════════════════════════════"
```

**Expected Output:**
```
═══════════════════════════════════════════════
Build Verification Checklist
═══════════════════════════════════════════════
✓ ISO file exists
-rw-r--r-- 1 root root 450M Jan 17 13:27 output/atum_0-0-1.iso
✓ Checksum file exists
✓ ISO is bootable
✓ ISO size is reasonable (~450MB)
═══════════════════════════════════════════════
```

🎉 **Build successful!** All checks passed. Proceed to downloading and testing your ISO.

---

## 7. Cleanup After Build

After successfully building the ISO, clean up temporary files to free disk space.

### Step 7.1: Understand What Can Be Cleaned

**Safe to delete:**
- `build/iso-extract/` - Extracted ISO contents (~450 MB)
- `build/debian-*.iso` - Original Debian ISO (~400 MB) - only if you don't plan to rebuild

**Keep these files:**
- `output/atum_0-0-1.iso` - Your custom ISO (needed for deployment)
- `output/atum_0-0-1.iso.sha256` - Checksum file (needed for verification)
- `logs/` - Build logs (useful for troubleshooting)

### Step 7.2: Basic Cleanup (Recommended)

Remove extracted ISO contents but keep the downloaded base ISO:

```bash
cd /workspaces/Atum/iso-build

# Remove extracted ISO directory (saves ~450 MB)
sudo rm -rf build/iso-extract/

# Verify cleanup
du -sh build/
```

**Expected Output:**
```
400M    build/
```

**Space Saved:** ~450 MB

### Step 7.3: Full Cleanup (Maximum Space Savings)

Remove all temporary files including the downloaded Debian ISO:

```bash
cd /workspaces/Atum/iso-build

# Remove entire build directory (saves ~850 MB)
sudo rm -rf build/*

# Keep the .gitkeep file
touch build/.gitkeep

# Verify cleanup
du -sh build/
```

**Expected Output:**
```
4.0K    build/
```

**Space Saved:** ~850 MB

⚠️ **Note:** If you delete the Debian ISO, it will need to be re-downloaded for future builds.

### Step 7.4: Cleanup Old ISOs (Optional)

If you've built multiple ISOs during testing:

```bash
cd /workspaces/Atum/iso-build/output

# List all ISOs
ls -lh *.iso

# Remove old ISOs (example - adjust filename as needed)
rm atum_old_version.iso atum_old_version.iso.sha256

# Keep only the latest
ls -lh
```

### Step 7.5: Clean Build Logs (Optional)

If logs are large or contain sensitive information:

```bash
cd /workspaces/Atum/iso-build

# Check log size
du -sh logs/

# Remove logs (can be regenerated)
rm -rf logs/*
touch logs/.gitkeep
```

### Step 7.6: Verify Disk Space After Cleanup

```bash
# Check available space
df -h /workspaces

# Check Atum directory size
du -sh /workspaces/Atum
du -sh /workspaces/Atum/iso-build/*
```

**Expected Output After Full Cleanup:**
```
Filesystem      Size  Used Avail Use% Mounted on
overlay         32G   6G   26G   19% /workspaces

450M    /workspaces/Atum/iso-build/output
4.0K    /workspaces/Atum/iso-build/build
24K     /workspaces/Atum/iso-build/logs
```

### Step 7.7: Cleanup Summary

| Action | Space Saved | Impact on Rebuild |
|--------|-------------|-------------------|
| Remove iso-extract/ | ~450 MB | None - safe to delete |
| Remove Debian ISO | ~400 MB | Must re-download for rebuild |
| Remove logs | ~1-5 MB | Logs regenerated on rebuild |
| Remove old output ISOs | ~450 MB each | None - these are final products |

**Recommended:** Basic cleanup (Step 7.2) balances space savings with rebuild convenience.

---

## 8. Test the ISO

After building the ISO, test it to ensure it works correctly before deploying to production.

### Overview of Testing Methods

| Method | Best For | Requirements | Setup Time |
|--------|----------|--------------|------------|
| Download & VirtualBox | Local testing, GUI access | VirtualBox installed | 5-10 min |
| Download & QEMU | Local testing, command line | QEMU installed | 5-10 min |
| Download & VMware | Professional testing | VMware Workstation/Fusion | 5-10 min |
| USB Boot | Hardware testing | USB drive (4GB+) | 10-15 min |

---

### Step 8.1: Download ISO from Codespaces

#### Option A: Download via VS Code Interface

1. **Navigate to the ISO file:**
   - Open the VS Code Explorer (left sidebar)
   - Navigate to: `iso-build/output/`
   - Right-click on `atum_0-0-1.iso`

2. **Download the file:**
   - Select **"Download..."** from the context menu
   - Choose save location on your local machine
   - Wait for download to complete (~450 MB)

3. **Verify download:**
   - Check file size: Should be approximately 450 MB
   - Download should complete without errors

#### Option B: Download via Command Line

If the VS Code interface is unavailable:

```bash
# Create a publicly accessible link (expires after a short time)
cd /workspaces/Atum/iso-build/output

# Display the file for download
cat atum_0-0-1.iso | base64
# Note: This is not practical for large files

# Better: Use the Codespaces port forwarding feature
# (Requires setting up a temporary HTTP server)
python3 -m http.server 8000
```

Then access via: `https://[your-codespace-url]-8000.githubpreview.dev/`

⚠️ **Note:** For large files like ISOs, the VS Code interface (Option A) is most reliable.

#### Step 8.1.1: Also Download Checksum

```bash
# Right-click and download:
# iso-build/output/atum_0-0-1.iso.sha256
```

---

### Step 8.2: Verify Downloaded ISO

After downloading to your local machine:

#### On Linux/macOS:

```bash
# Navigate to download location
cd ~/Downloads

# Verify checksum
sha256sum -c atum_0-0-1.iso.sha256
```

**Expected Output:**
```
atum_0-0-1.iso: OK
```

#### On Windows (PowerShell):

```powershell
# Navigate to download location
cd $HOME\Downloads

# Calculate checksum
Get-FileHash atum_0-0-1.iso -Algorithm SHA256

# Compare with checksum file content
Get-Content atum_0-0-1.iso.sha256
```

Compare the hash values - they should match exactly.

✅ **Success:** Checksums match - ISO downloaded correctly

❌ **Failure:** Checksums don't match - re-download ISO

---

### Step 8.3: Test with VirtualBox

VirtualBox is free and works on Windows, macOS, and Linux.

#### Step 8.3.1: Install VirtualBox

If not already installed:
- Download from: https://www.virtualbox.org/wiki/Downloads
- Install for your operating system
- Restart your computer if prompted

#### Step 8.3.2: Create New Virtual Machine

1. **Open VirtualBox** and click **"New"**

2. **Configure VM settings:**
   ```
   Name: Atum-FreePBX-Test
   Type: Linux
   Version: Debian (64-bit)
   Memory: 2048 MB (minimum, 4096 MB recommended)
   Hard disk: Create a virtual hard disk now
   ```

3. **Create Virtual Hard Disk:**
   ```
   File size: 20 GB (minimum)
   Hard disk file type: VDI (VirtualBox Disk Image)
   Storage: Dynamically allocated
   ```

4. **Click "Create"**

#### Step 8.3.3: Configure VM Settings

1. **Select the VM** and click **"Settings"**

2. **System Settings:**
   - **Processor:** 2 CPUs (minimum)
   - **Boot Order:** Optical, Hard Disk
   - **Enable EFI:** Optional (test both BIOS and UEFI)

3. **Storage Settings:**
   - Click on **"Empty"** under Controller: IDE
   - Click the disk icon next to "Optical Drive"
   - Select **"Choose a disk file..."**
   - Navigate to and select `atum_0-0-1.iso`

4. **Network Settings:**
   - **Adapter 1:** Enable Network Adapter
   - **Attached to:** NAT or Bridged Adapter
   - **Bridged** gives VM direct network access (easier for testing)

5. **Click "OK"** to save settings

#### Step 8.3.4: Start Installation

1. **Start the VM** - Click **"Start"**

2. **Watch boot process:**
   - You'll see the Atum boot menu
   - Wait 10 seconds for auto-start, or press Enter
   - Automated installation begins

3. **Monitor installation progress:**
   - Disk partitioning (automatic)
   - Base system installation
   - Package installation
   - IN1CLICK setup
   - First reboot

4. **After first reboot:**
   - Remove ISO from virtual CD drive (optional)
   - VM reboots into new Debian installation
   - IN1CLICK begins FreePBX installation automatically
   - Wait for completion (~20-25 minutes)

#### Step 8.3.5: Expected Installation Timeline

| Time | Event | What You'll See |
|------|-------|-----------------|
| 0:00 | Boot from ISO | Atum boot menu appears |
| 0:10 | Auto-start | "Automated Installation" starts |
| 0:15 | Partitioning | Disk is partitioned and formatted |
| 1:00 | Base install | Debian core system installed |
| 3:00 | Packages | Additional packages installed |
| 5:00 | First reboot | System restarts (remove ISO here) |
| 5:30 | IN1CLICK starts | FreePBX installation begins |
| 25:00 | Completion | System ready, final reboot |

**Total: ~25-30 minutes**

#### Step 8.3.6: Verify Installation Success

After installation completes:

1. **Log in:**
   ```
   Username: root
   Password: atum001
   ```

2. **Check services:**
   ```bash
   systemctl status apache2
   systemctl status asterisk
   systemctl status mariadb
   ```

3. **Check IN1CLICK log:**
   ```bash
   cat /var/log/in1click/install.log
   ```

4. **Access FreePBX Web GUI:**
   - Get VM IP address: `ip addr show`
   - Open browser: `http://[VM-IP-Address]`
   - You should see FreePBX administration page

✅ **Success Indicators:**
- All services are running (active)
- FreePBX web interface is accessible
- No errors in IN1CLICK log

---

### Step 8.4: Test with QEMU (Command Line)

For command-line testing on Linux or macOS:

#### Step 8.4.1: Install QEMU

**On Linux:**
```bash
sudo apt-get install -y qemu-system-x86 qemu-utils
```

**On macOS:**
```bash
brew install qemu
```

#### Step 8.4.2: Create Virtual Disk

```bash
# Navigate to ISO location
cd ~/Downloads

# Create 20GB virtual disk
qemu-img create -f qcow2 freepbx-test.qcow2 20G
```

#### Step 8.4.3: Start VM

```bash
qemu-system-x86_64 \
  -m 2048 \
  -smp 2 \
  -hda freepbx-test.qcow2 \
  -cdrom atum_0-0-1.iso \
  -boot d \
  -net nic -net user,hostfwd=tcp::8080-:80,hostfwd=tcp::2222-:22 \
  -enable-kvm
```

**Parameters explained:**
- `-m 2048`: 2GB RAM
- `-smp 2`: 2 CPU cores
- `-hda`: Virtual hard disk
- `-cdrom`: ISO image
- `-boot d`: Boot from CD-ROM first
- `-net`: Network with port forwarding
- `-enable-kvm`: Use KVM acceleration (Linux only)

#### Step 8.4.4: Monitor Installation

Watch the installation progress in the QEMU window. Follow the same timeline as VirtualBox.

#### Step 8.4.5: Access After Installation

After installation completes:

**SSH Access:**
```bash
ssh -p 2222 root@localhost
# Password: atum001
```

**Web GUI Access:**
```
http://localhost:8080
```

---

### Step 8.5: Test with VMware

For VMware Workstation (Windows/Linux) or VMware Fusion (macOS):

#### Step 8.5.1: Create New VM

1. **Open VMware** and select **"Create a New Virtual Machine"**

2. **Choose installer:**
   - Select **"Installer disc image file (iso)"**
   - Browse to `atum_0-0-1.iso`

3. **Guest OS:**
   ```
   Guest operating system: Linux
   Version: Debian 12.x 64-bit
   ```

4. **VM Configuration:**
   ```
   Name: Atum-FreePBX-Test
   Memory: 2048 MB (minimum)
   Processors: 2
   Hard Disk: 20 GB (minimum)
   Network: NAT or Bridged
   ```

5. **Click "Finish"**

#### Step 8.5.2: Start and Monitor

1. **Power on the VM**
2. Monitor installation (same as VirtualBox timeline)
3. Wait for completion (~25-30 minutes)

#### Step 8.5.3: Verify Success

Same verification steps as VirtualBox (Section 8.3.6)

---

### Step 8.6: Test on Physical Hardware (USB Boot)

For testing on actual hardware:

⚠️ **WARNING:** This will erase the target computer's hard drive. Use only test hardware!

#### Step 8.6.1: Write ISO to USB Drive

**On Linux:**

```bash
# Find USB device
lsblk

# Write ISO (replace /dev/sdX with your USB device)
sudo dd if=atum_0-0-1.iso of=/dev/sdX bs=4M status=progress
sudo sync
```

**On macOS:**

```bash
# Find USB device
diskutil list

# Unmount the drive
diskutil unmountDisk /dev/diskX

# Write ISO
sudo dd if=atum_0-0-1.iso of=/dev/rdiskX bs=4m
```

**On Windows:**

Use a tool like:
- **Rufus** (https://rufus.ie/)
- **Etcher** (https://www.balena.io/etcher/)

Settings for Rufus:
- Boot selection: Select `atum_0-0-1.iso`
- Partition scheme: MBR
- Target system: BIOS or UEFI
- File system: FAT32
- Click "START"

#### Step 8.6.2: Boot from USB

1. **Insert USB** into target computer
2. **Restart computer**
3. **Enter boot menu:**
   - Common keys: F12, F11, F2, ESC, DEL
   - Select USB drive from boot menu
4. **Installation begins** automatically
5. **Monitor progress** on the screen
6. **Wait for completion** (~25-30 minutes)

#### Step 8.6.3: Post-Installation Testing

After installation:

1. **Remove USB drive**
2. **Reboot computer**
3. **Log in with default credentials**
4. **Verify services** (same as VM testing)
5. **Access FreePBX GUI** from another computer on the same network

---

### Step 8.7: Validation Checklist

After testing in any environment, verify these items:

```
Installation Checklist:
□ System boots successfully from ISO
□ Automated installation completes without errors
□ System reboots after Debian installation
□ IN1CLICK runs automatically on first boot
□ FreePBX installation completes successfully
□ Apache2 service is running
□ MariaDB service is running
□ Asterisk service is running
□ FreePBX web GUI is accessible
□ Can log in via SSH with default credentials
□ Network connectivity works (DHCP or static)
□ No critical errors in /var/log/syslog
□ IN1CLICK log shows successful completion
```

✅ **All items checked:** ISO is working correctly!

❌ **Some items failed:** See [Troubleshooting](#5-troubleshooting-common-issues) or check build logs.

---

## 9. Support and Next Steps

### Next Steps After Successful Build

1. **Production Use:**
   - Edit `preseed.cfg` to change default passwords
   - Rebuild ISO with production credentials
   - Test thoroughly before deployment

2. **Mass Deployment:**
   - Copy ISO to multiple USB drives
   - Deploy to multiple systems
   - Consider PXE boot for network deployment

3. **Customization:**
   - Modify preseed.cfg for different network settings
   - Add custom packages to preseed
   - Adjust partitioning scheme for specific needs

4. **Documentation:**
   - Document your specific deployment process
   - Create runbooks for your environment
   - Train staff on ISO usage

### Getting Support

If you encounter issues not covered in this guide:

1. **Check Existing Documentation:**
   - [ISO_BUILD.md](ISO_BUILD.md) - Comprehensive technical documentation
   - [README.md](README.md) - Repository overview
   - [IN1CLICK_README.md](IN1CLICK_README.md) - IN1CLICK documentation

2. **Review Logs:**
   - Build logs: `iso-build/logs/`
   - Installation logs: `/var/log/in1click/install.log` (on installed system)
   - System logs: `/var/log/syslog` (on installed system)

3. **Run Diagnostics:**
   ```bash
   # On installed system
   sudo /opt/diagnostics.sh
   ```

4. **Contact Support:**
   - **GitHub Issues (Primary):** https://github.com/kierknoby/heqet/issues
   - **Email:** support@20tele.com
   - **Support Portal:** https://support.20tele.com

When requesting support, include:
- ISO build date and version
- Build logs
- Error messages or unexpected behavior
- Screenshots of errors
- Steps to reproduce the issue
- Diagnostics output (if available)

### Additional Resources

- **Debian Preseed Documentation:** https://www.debian.org/releases/stable/amd64/apb.html
- **FreePBX Documentation:** https://wiki.freepbx.org/
- **Asterisk Documentation:** https://wiki.asterisk.org/

### Security Reminders

⚠️ **Before Production Deployment:**

1. **Change all default passwords** in `preseed.cfg`
2. **Review network settings** (use static IP for servers)
3. **Configure firewall rules** after installation
4. **Enable HTTPS** for FreePBX web interface
5. **Disable root SSH login** and use key-based authentication
6. **Set up regular backups** of FreePBX configuration
7. **Enable automatic security updates**

### Contributing

Found a bug or want to improve this guide?

1. Fork the repository
2. Make your changes
3. Test thoroughly
4. Submit a pull request

We appreciate contributions that:
- Fix errors or clarify instructions
- Add troubleshooting solutions for new issues
- Improve the build process
- Enhance documentation

---

## Appendix: Quick Reference

### Essential Commands Summary

```bash
# Setup
cd /workspaces/Atum/iso-build/scripts
sudo apt-get update
sudo apt-get install -y xorriso isolinux syslinux-utils genisoimage wget curl

# Build
sudo ./build-iso.sh

# Verify
cd ../output
ls -lh
sha256sum -c atum_0-0-1.iso.sha256

# Cleanup
cd ..
sudo rm -rf build/iso-extract/

# Test (VirtualBox)
# Download ISO and use VirtualBox GUI

# Test (QEMU)
qemu-img create -f qcow2 test.qcow2 20G
qemu-system-x86_64 -m 2048 -smp 2 -hda test.qcow2 -cdrom atum_0-0-1.iso -boot d
```

### Default Credentials

```
Root:  root / atum001
User:  Randomized (see /root/atum-credentials.txt after installation)
```

⚠️ **Change these in production!**

### Directory Structure Quick Reference

```
Atum/
├── IN1CLICK          # IN1CLICK script
├── ISO_BUILD_STEPS.md             # This guide
├── ISO_BUILD.md                   # Technical documentation
└── iso-build/
    ├── config/
    │   └── preseed.cfg            # Installation configuration
    ├── scripts/
    │   └── build-iso.sh           # Build script
    ├── build/                      # Temporary files
    ├── output/                     # Final ISO
    └── logs/                       # Build logs
```

### Troubleshooting Quick Reference

| Problem | Quick Solution |
|---------|---------------|
| Permission denied | Run with `sudo` |
| Command not found | Install dependencies: `sudo apt-get install -y xorriso isolinux syslinux-utils genisoimage wget curl` |
| Download fails | Check internet: `ping 8.8.8.8` |
| No space left | Clean up: `sudo rm -rf build/iso-extract/` |
| Build fails | Check logs: `cat logs/xorriso.log` |
| ISO corrupted | Verify checksum: `sha256sum -c *.sha256` |

### Build Time Estimates

- **Initialization:** ~5 seconds
- **Download ISO:** ~3-8 minutes
- **Extract ISO:** ~30-60 seconds
- **Customize:** ~10-20 seconds
- **Generate ISO:** ~2-5 minutes
- **Total:** ~10-15 minutes

### Installation Time Estimates

- **Debian installation:** ~5 minutes
- **First reboot:** ~30 seconds
- **IN1CLICK/FreePBX:** ~20-25 minutes
- **Total:** ~25-30 minutes

---

**Document Version:** 1.0  
**Last Updated:** January 2025  
**Compatible With:** Atum ISO Builder v1.0, Debian 12 (Bookworm)  
**Author:** Atum Project Contributors

---

**End of Guide**

Thank you for using Atum! For the latest updates and improvements, visit:
https://github.com/kierknoby/heqet
