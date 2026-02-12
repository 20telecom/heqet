# Debian 12 ISO Build Guide (Build Hosts Only)

## Overview

This guide documents how to generate a custom Debian 12 (Bookworm) ISO. If you want to install from the pre-built ISO, use the main README.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Build Environment Setup](#build-environment-setup)
4. [Building the ISO](#building-the-iso)
5. [Testing the ISO](#testing-the-iso)
6. [Deployment](#deployment)
7. [Troubleshooting](#troubleshooting)
8. [Technical Details](#technical-details)
9. [Security Considerations](#security-considerations)

## Architecture Overview

The automated installation system consists of several integrated components:

```
┌─────────────────────────────────────────────────────────────┐
│                    Custom Debian 12 ISO                      │
├─────────────────────────────────────────────────────────────┤
│  1. Base Debian 12 netinst ISO                              │
│  2. Preseed configuration (preseed.cfg)                     │
│  3. IN1CLICK script (IN1CLICK)                 │
│  4. Modified boot configuration (isolinux/GRUB)             │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│              Automated Installation Flow                     │
├─────────────────────────────────────────────────────────────┤
│  1. Boot from ISO → Auto-install option (10s timeout)       │
│  2. Debian installer reads preseed.cfg                      │
│  3. Automated partitioning (entire disk, ext4)              │
│  4. Base system installation with required packages         │
│  5. IN1CLICK script copied to /opt/in1click/                │
│  6. First-boot hook configured via rc.local                 │
│  7. System reboot                                            │
│  8. IN1CLICK executes automatically on first boot           │
│  9. FreePBX 17 fully installed and configured               │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

### Build System Requirements

The ISO build process requires a Debian-based Linux system (Debian 10+, Ubuntu 20.04+) with:

- **Root or sudo access** - Required for ISO manipulation and mounting
- **10GB+ free disk space** - For ISO extraction, customization, and output
- **2GB+ RAM** - For build process
- **Internet connection** - To download base Debian ISO and packages

### Required Packages

The build script will automatically install these if missing:

- `xorriso` - ISO creation and manipulation
- `isolinux` - Boot loader for BIOS systems
- `syslinux-utils` - Additional boot utilities
- `genisoimage` - ISO image creation
- `cpio` - initrd unpack/repack support
- `openssl` - Hashing support for installer password gate
- `wget` - Download utilities
- `curl` - HTTP client for validation

Manual installation:
```bash
sudo apt-get update
sudo apt-get install -y xorriso isolinux syslinux-utils genisoimage cpio openssl wget curl
```

### Testing Requirements (Optional)

For testing the ISO in a virtual environment:

- **QEMU/KVM** - Full system emulation
- **VirtualBox** - Alternative VM platform
- **VMware** - Alternative VM platform
- **VNC Client** - For graphical monitoring (optional)

Install QEMU:
```bash
sudo apt-get install -y qemu-system-x86 qemu-utils
```

## Build Environment Setup

### 1. Clone the Repository

```bash
git clone https://github.com/kierknoby/heqet.git
cd Atum
```

### 2. Directory Structure

The ISO build system is organized as follows:

```
Atum/
├── IN1CLICK          # IN1CLICK script (source)
├── IN1CLICK_README.md
├── requirements.md
└── iso-build/                      # ISO build system
    ├── config/
    │   └── preseed.cfg            # Debian preseed configuration
    ├── scripts/
    │   ├── build-iso.sh           # Main ISO build script
    │   ├── test-iso.sh            # QEMU testing script
    │   └── diagnostics.sh         # System diagnostics tool
    ├── build/                      # (created during build)
    │   ├── debian-*.iso           # Downloaded base ISO
    │   └── *.qcow2                # VM disk images
    ├── output/                     # (created during build)
    │   └── debian-12-freepbx-auto-*.iso  # Final custom ISO
    └── logs/                       # (created during build)
        └── *.log                  # Build and test logs
```

### 3. Verify IN1CLICK Script

Ensure the IN1CLICK script is present and unchanged:

```bash
ls -lh IN1CLICK
# Should show: -rw-r--r-- ... IN1CLICK
```

The build process uses this script as-is without modifications.

## Building the ISO

### Quick Start

Navigate to the ISO build directory and run the build script:

```bash
cd iso-build/scripts
sudo ./build-iso.sh
```

The script will:
1. Check and install required packages
2. Download Debian 12 netinst ISO (~400MB)
3. Extract and customize the ISO
4. Add preseed configuration and IN1CLICK script
5. Generate the custom ISO
6. Calculate checksums

**Expected Duration:** 10-20 minutes (depending on download speed)

### Build Process Details

#### Step 1: Preparation
```bash
sudo ./build-iso.sh
```

Output:
```
[2026-01-15 15:30:00] Starting Debian 12 ISO build with IN1CLICK integration...
[2026-01-15 15:30:01] Checking required packages...
[2026-01-15 15:30:02] All required packages are installed.
[2026-01-15 15:30:02] Setting up build directories...
```

#### Step 2: ISO Download
```
[2026-01-15 15:30:03] Downloading Debian 12 netinst ISO...
[2026-01-15 15:30:03] This may take several minutes depending on your connection...
```

The script downloads the official Debian 12.8.0 AMD64 netinst ISO (~400MB). If the ISO already exists in `build/`, this step is skipped.

#### Step 3: ISO Extraction
```
[2026-01-15 15:35:42] Extracting Debian ISO...
[2026-01-15 15:36:15] ISO contents extracted successfully.
```

The base ISO is mounted and its contents copied to a working directory for customization.

#### Step 4: Customization
```
[2026-01-15 15:36:15] Customizing ISO with preseed and IN1CLICK...
[2026-01-15 15:36:16] Preseed file added to ISO.
[2026-01-15 15:36:16] IN1CLICK script added to ISO.
[2026-01-15 15:36:17] Isolinux configuration updated for automated boot.
[2026-01-15 15:36:17] GRUB configuration updated for automated boot.
[2026-01-15 15:36:17] ISO customization completed.
```

This phase:
- Copies `preseed.cfg` to the ISO root
- Copies IN1CLICK script to `/in1click/` directory
- Modifies boot configuration for automatic installation
- Sets 10-second timeout before auto-install starts

#### Step 5: ISO Generation
```
[2026-01-15 15:36:18] Generating custom ISO...
[2026-01-15 15:38:45] Custom ISO generated successfully: output/debian-12-freepbx-auto-20260115.iso
[2026-01-15 15:38:50] SHA256 checksum: a1b2c3d4...
[2026-01-15 15:38:50] Checksum saved to: output/debian-12-freepbx-auto-20260115.iso.sha256
```

The custom ISO is created with hybrid boot support (BIOS and UEFI).

#### Step 6: Completion
```
═══════════════════════════════════════════════════════════════
[2026-01-15 15:38:51] ISO BUILD COMPLETED SUCCESSFULLY
═══════════════════════════════════════════════════════════════

[2026-01-15 15:38:51] Custom ISO: output/debian-12-freepbx-auto-20260115.iso
[2026-01-15 15:38:51] Checksum file: output/debian-12-freepbx-auto-20260115.iso.sha256
[2026-01-15 15:38:51] Build logs: logs/

Next steps:
  1. Test the ISO in a VM (VirtualBox, QEMU, etc.)
  2. Boot from the ISO - installation will start automatically
  3. After first reboot, IN1CLICK will run automatically
  4. Check /var/log/in1click/install.log for installation status

Default credentials:
  Root: root / atum001
  User: Randomized (see /root/atum-credentials.txt after installation)
```

### Build Artifacts

After successful build:

```
iso-build/
├── output/
│   ├── debian-12-freepbx-auto-20260115.iso        # Custom ISO (~450MB)
│   └── debian-12-freepbx-auto-20260115.iso.sha256 # Checksum file
└── logs/
    └── xorriso.log                                 # ISO generation log
```

## Testing the ISO

### Quick Test with QEMU

The included test script provides automated VM testing:

```bash
cd iso-build/scripts
./test-iso.sh ../output/debian-12-freepbx-auto-*.iso
```

This starts a QEMU VM with:
- 2GB RAM
- 2 CPU cores
- 20GB virtual disk
- Port forwarding: localhost:8080 → VM:80 (FreePBX GUI)
- Port forwarding: localhost:2222 → VM:22 (SSH)
- VNC display on localhost:5901

### Monitoring Installation

#### Option 1: VNC (Graphical)

Connect with a VNC client:
```bash
# Install VNC viewer if needed
sudo apt-get install tigervnc-viewer

# Connect
vncviewer localhost:5901
```

#### Option 2: Serial Console (Text)

Monitor serial console output:
```bash
tail -f iso-build/logs/vm-serial.log
```

#### Option 3: QEMU Log

Check QEMU output:
```bash
tail -f iso-build/logs/qemu.log
```

### Expected Installation Timeline

| Time | Stage | Description |
|------|-------|-------------|
| 0:00 | Boot | System boots from ISO |
| 0:10 | Auto-start | Automated install begins (10s timeout) |
| 0:15 | Partitioning | Disk is partitioned (ext4, entire disk) |
| 1:00 | Base Install | Core Debian system installed |
| 3:00 | Packages | Additional packages installed |
| 5:00 | Finalization | IN1CLICK setup, cleanup |
| 5:30 | Reboot | System reboots into new installation |
| 6:00 | IN1CLICK Start | IN1CLICK begins FreePBX installation |
| 20:00 | FreePBX Install | Asterisk, MariaDB, Apache configured |
| 25:00 | Completion | System ready, final reboot |

**Total Duration:** ~25-30 minutes (varies by hardware)

### Testing in Other Platforms

#### VirtualBox

1. Create new VM:
   - Type: Linux
   - Version: Debian (64-bit)
   - Memory: 2048MB minimum
   - Disk: 20GB minimum

2. Attach ISO:
   - Settings → Storage → Controller: IDE → Add Optical Drive
   - Select custom ISO file

3. Start VM and monitor installation

#### VMware

1. Create new VM:
   - Guest OS: Linux → Debian 12.x 64-bit
   - Memory: 2048MB minimum
   - Disk: 20GB minimum

2. Attach ISO:
   - Edit VM Settings → CD/DVD → Use ISO image file
   - Select custom ISO file

3. Power on VM

#### Physical Hardware

For testing on physical hardware:

1. Write ISO to USB drive:
```bash
sudo dd if=output/debian-12-freepbx-auto-*.iso of=/dev/sdX bs=4M status=progress
sync
```

**⚠️ WARNING:** Replace `/dev/sdX` with your actual USB device. This will **erase all data** on the USB drive.

2. Boot from USB drive
3. Installation proceeds automatically

### Validation Checklist

After installation completes:

- [ ] System boots successfully
- [ ] Network connectivity works (DHCP or static)
- [ ] Apache is running (`systemctl status apache2`)
- [ ] MariaDB is running (`systemctl status mariadb`)
- [ ] Asterisk is running (`systemctl status asterisk`)
- [ ] FreePBX GUI accessible at http://[VM-IP]
- [ ] IN1CLICK log exists: `/var/log/in1click/install.log`
- [ ] No critical errors in `/var/log/syslog`

Run diagnostics:
```bash
# On the installed system
sudo /opt/diagnostics.sh
```

## Deployment

### Production Use

For production deployments:

1. **Change Default Passwords**

   Edit `iso-build/config/preseed.cfg` before building:
   ```
   d-i passwd/root-password password YOUR_SECURE_PASSWORD
   d-i passwd/root-password-again password YOUR_SECURE_PASSWORD
   ```
   
   Note: User credentials are randomized automatically during installation and saved to `/root/atum-credentials.txt`

2. **Customize Network Settings**

   For static IP instead of DHCP, modify preseed.cfg:
   ```
   d-i netcfg/disable_autoconfig boolean true
   d-i netcfg/get_ipaddress string 192.168.1.100
   d-i netcfg/get_netmask string 255.255.255.0
   d-i netcfg/get_gateway string 192.168.1.1
   d-i netcfg/get_nameservers string 8.8.8.8 8.8.4.4
   ```

3. **Adjust Partitioning**

   For LVM instead of simple ext4:
   ```
   d-i partman-auto/method string lvm
   d-i partman-auto-lvm/guided_size string max
   ```

4. **Rebuild ISO**
   ```bash
   cd iso-build/scripts
   sudo ./build-iso.sh
   ```

### Mass Deployment

For deploying to multiple systems:

1. **PXE Boot Setup**
   - Extract kernel and initrd from ISO
   - Configure TFTP server
   - Provide preseed.cfg via HTTP/NFS

2. **USB Flash Distribution**
   - Write ISO to multiple USB drives
   - Use USB duplicators for scale

3. **Cloud Images**
   - Convert installed system to cloud format (qcow2, VMDK)
   - Upload to cloud provider
   - Use as template for new instances

## Troubleshooting

### Build Issues

#### Problem: Missing packages error
```
E: Unable to locate package xorriso
```
**Solution:**
```bash
sudo apt-get update
sudo apt-get install -y xorriso isolinux syslinux-utils genisoimage
```

#### Problem: Permission denied
```
mount: only root can do that
```
**Solution:** Run build script with sudo:
```bash
sudo ./build-iso.sh
```

#### Problem: Insufficient disk space
```
ERROR: No space left on device
```
**Solution:** Free up space or use different partition:
```bash
df -h  # Check disk usage
# Clean up build artifacts:
rm -rf iso-build/build/*
```

### Installation Issues

#### Problem: Installation hangs at partitioning
**Symptoms:** Installer stops at disk partition selection

**Solutions:**
1. Check VM disk size (minimum 10GB)
2. Ensure no existing partitions on disk
3. Try manual installation to diagnose disk issues

#### Problem: Network configuration fails
**Symptoms:** Installer can't download packages

**Solutions:**
1. Check network connectivity in VM settings
2. Verify DNS resolution
3. Check firewall settings on host
4. Try different network mode (NAT vs Bridged)

#### Problem: IN1CLICK doesn't run after reboot
**Symptoms:** System boots but FreePBX not installed

**Solutions:**
1. Check if IN1CLICK script exists:
   ```bash
   ls -l /opt/in1click/IN1CLICK
   ```
2. Check rc.local exists and is executable:
   ```bash
   ls -l /etc/rc.local
   ```
3. Check IN1CLICK log:
   ```bash
   cat /var/log/in1click/install.log
   ```
4. Manually run IN1CLICK:
   ```bash
   sudo /opt/in1click/IN1CLICK
   ```

#### Problem: FreePBX installation fails
**Symptoms:** IN1CLICK runs but FreePBX install fails

**Solutions:**
1. Check IN1CLICK log:
   ```bash
   sudo tail -100 /var/log/in1click/install.log
   ```
2. Check FreePBX logs:
   ```bash
   sudo ls -l /var/log/pbx/
   sudo cat /var/log/pbx/freepbx-*.log
   ```
3. Verify system requirements (IN1CLICK performs these checks)
4. Check internet connectivity
5. Verify FreePBX mirrors are accessible

### Testing Issues

#### Problem: QEMU won't start
```
ERROR: qemu-system-x86_64 not found
```
**Solution:**
```bash
sudo apt-get install -y qemu-system-x86 qemu-utils
```

#### Problem: Can't connect via VNC
**Solution:**
1. Check if VM is running:
   ```bash
   ps aux | grep qemu
   ```
2. Try connecting to correct display:
   ```bash
   vncviewer localhost:5901
   ```
3. Check firewall isn't blocking VNC port

#### Problem: Can't access FreePBX GUI
**Symptoms:** localhost:8080 doesn't respond

**Solutions:**
1. Wait for installation to complete (~25-30 min)
2. Check if Apache is running in VM:
   ```bash
   ssh -p 2222 root@localhost "systemctl status apache2"
   ```
3. Verify port forwarding in QEMU
4. Check VM's actual IP and access directly via VNC

## Technical Details

### Preseed Configuration

The preseed file (`config/preseed.cfg`) automates all installation decisions:

**Key Settings:**
- **Locale:** en_US.UTF-8
- **Timezone:** UTC
- **Keyboard:** US
- **Network:** DHCP (auto-configure)
- **Partitioning:** Entire disk, ext4, atomic recipe
- **Accounts:** root and admin user created
- **Packages:** Base system + SSH + IN1CLICK dependencies
- **Boot loader:** GRUB to default device

**Late Commands:**
The preseed's `late_command` section:
1. Creates `/opt/in1click/` directory
2. Copies IN1CLICK script from ISO
3. Makes script executable
4. Creates `/var/log/in1click/` for logs
5. Configures `/etc/rc.local` for first-boot execution
6. Enables rc-local service

### Boot Configuration

#### BIOS Boot (isolinux)
- Default: Automated installation
- Timeout: 10 seconds
- Fallback: Manual installation option

#### UEFI Boot (GRUB)
- Default: Automated installation entry added
- Preseed parameters included in boot options
- Quiet mode for cleaner output

### IN1CLICK Integration

The IN1CLICK script is integrated without modification:

1. **Pre-Installation:**
   - Script embedded in ISO at `/in1click/IN1CLICK`
   - All dependencies pre-installed via preseed package list

2. **First Boot:**
   - rc.local executes IN1CLICK
   - Output redirected to `/var/log/in1click/install.log`
   - rc.local removes itself after execution

3. **IN1CLICK Execution:**
   - Runs all standard checks
   - Installs FreePBX 17
   - Configures system
   - Self-deletes (IN1CLICK behavior)
   - System reboots

### Package Dependencies

Pre-installed packages for IN1CLICK:
- curl, wget - Download utilities
- gnupg2, ca-certificates - Security and certificates
- lsb-release - OS information
- apt-transport-https - HTTPS repository support
- software-properties-common - Repository management
- build-essential - Compilation tools
- git - Version control
- sudo - Privilege elevation
- iptables - Firewall
- net-tools - Network utilities
- dnsutils - DNS tools (host, dig)

These are installed during Debian setup, so IN1CLICK finds everything it needs.

### Logging and Diagnostics

**Build Logs:**
- `logs/xorriso.log` - ISO creation details
- `logs/qemu.log` - VM execution log
- `logs/vm-serial.log` - VM serial console output

**Installation Logs:**
- `/var/log/in1click/install.log` - Complete IN1CLICK output
- `/var/log/in1click/diagnostics-*.log` - System diagnostics
- `/var/log/syslog` - System log
- `/var/log/daemon.log` - Service logs
- `/var/log/pbx/freepbx-*.log` - FreePBX installation logs

**Diagnostic Script:**
The diagnostics.sh script collects:
- System information (OS, kernel, hardware)
- Network configuration and connectivity
- Service status (Apache, Asterisk, MariaDB)
- IN1CLICK and FreePBX status
- Recent logs and errors
- Quick issue detection

Run it on installed system:
```bash
sudo /opt/diagnostics.sh
# Or if script was included in ISO:
sudo /opt/in1click/diagnostics.sh
```

## Security Considerations

### Default Credentials

**⚠️ CRITICAL:** The default preseed configuration includes default passwords:

- Root: `atum001`
- Admin user: Randomized (credentials saved to `/root/atum-credentials.txt` after installation)

**For production use:**
1. Change root password in `preseed.cfg` before building
2. Or change immediately after installation
3. Or remove password from preseed and configure manually

### Network Security

The preseed configuration:
- Installs iptables but doesn't configure rules
- Enables SSH server by default
- Uses DHCP (potentially insecure in untrusted networks)

**Recommendations:**
1. Configure firewall rules post-installation
2. Use SSH key authentication instead of passwords
3. Disable SSH password authentication
4. Use static IP for production systems

### FreePBX Security

IN1CLICK installs FreePBX with:
- Default web GUI (no authentication initially)
- Asterisk manager interface enabled
- MariaDB with default FreePBX user

**Post-Installation Steps:**
1. Complete FreePBX initial setup wizard
2. Set strong admin password
3. Configure firewall rules for SIP/RTP ports
4. Enable HTTPS for web GUI
5. Review Asterisk security settings

### ISO Security

The custom ISO contains:
- IN1CLICK script (readable)
- Preseed with passwords (readable)

**For distribution:**
1. Don't include sensitive credentials in ISO
2. Use separate preseed file via HTTP/network
3. Or prompt for passwords during installation

### Update Policy

- Debian security updates: Enabled by default
- FreePBX updates: Managed by FreePBX
- IN1CLICK: Run once, then self-deletes

**Recommendations:**
1. Enable automatic security updates
2. Regularly update FreePBX modules
3. Monitor security advisories

## Advanced Customization

### Adding Additional Packages

Edit `preseed.cfg`:
```
d-i pkgsel/include string curl wget ... your-package-here
```

### Custom Partitioning Schemes

For complex partitioning, modify preseed.cfg:
```
d-i partman-auto/expert_recipe string \
    boot-root :: \
        512 512 512 ext4 \
            $primary{ } $bootable{ } \
            method{ format } format{ } \
            use_filesystem{ } filesystem{ ext4 } \
            mountpoint{ /boot } \
        . \
        10240 10240 -1 ext4 \
            method{ format } format{ } \
            use_filesystem{ } filesystem{ ext4 } \
            mountpoint{ / } \
        .
```

### Multiple Preseed Profiles

Create multiple preseed files for different scenarios:
- `preseed-dhcp.cfg` - DHCP networking
- `preseed-static.cfg` - Static IP
- `preseed-minimal.cfg` - Minimal installation
- `preseed-full.cfg` - Full installation

Modify build script to include all profiles and adjust boot menu accordingly.

### Post-Installation Scripts

Add additional scripts to run after IN1CLICK:

1. Create script in `iso-build/scripts/post-install.sh`
2. Copy to ISO during customization
3. Add to rc.local or create systemd service

### Branding and Customization

Customize boot splash and installer appearance:
1. Replace isolinux/splash.png
2. Modify GRUB theme
3. Add custom messages to preseed

## Maintenance

### Updating Base ISO

When new Debian 12 point release is available:

1. Update `DEBIAN_ISO_URL` in `build-iso.sh`
2. Update `DEBIAN_ISO_NAME` accordingly
3. Remove old ISO: `rm build/debian-*.iso`
4. Rebuild: `sudo ./build-iso.sh`

### Updating IN1CLICK

When IN1CLICK is updated in the repository:

1. Pull latest changes: `git pull`
2. Verify script: `ls -l IN1CLICK`
3. Rebuild ISO: `sudo ./build-iso.sh`

The build script always uses the current version of IN1CLICK.

### Testing After Updates

Always test after updating:
```bash
cd iso-build/scripts
sudo ./build-iso.sh
./test-iso.sh -m
```

Monitor complete installation cycle to ensure changes work correctly.

## Support and Contributions

### Getting Help

1. Check troubleshooting section above
2. Review logs in `/var/log/in1click/`
3. Run diagnostics: `sudo /opt/diagnostics.sh`
4. Contact support: support@20tele.com
5. Open ticket: https://support.20tele.com

### Reporting Issues

When reporting issues, include:
- ISO build version and date
- Error messages or unexpected behavior
- Relevant log files
- Diagnostics output
- Steps to reproduce

### Contributing

Contributions welcome:
1. Fork repository
2. Create feature branch
3. Test thoroughly
4. Submit pull request with clear description

## License

This ISO build system is provided under the same license as the Atum repository.

IN1CLICK script: GNU General Public License v3.0

Debian: Debian Free Software Guidelines (DFSG)

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-15  
**Maintained By:** Atum Project Contributors
