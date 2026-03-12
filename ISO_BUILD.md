# Heqet ISO Build Guide (Build Hosts Only)

## Overview

This guide documents how to generate the Heqet custom Debian 12 (Bookworm) ISO with integrated IN1CLICK for FreePBX 17. If you want to install from the pre-built ISO, use the main README.

---

## Building in GitHub Codespaces?

Start with [ISO_BUILD_STEPS.md](ISO_BUILD_STEPS.md) for the Codespaces quickstart.

---

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
│                    Heqet Custom ISO                          │
├─────────────────────────────────────────────────────────────┤
│  1. Base Debian 12.13.0 netinst ISO                         │
│  2. Heqet gate script (heqet-gate.sh)                       │
│  3. Preseed configuration (preseed.cfg)                     │
│  4. IN1CLICK installer script                               │
│  5. Modified boot configuration (isolinux/GRUB)             │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              Automated Installation Flow                     │
├─────────────────────────────────────────────────────────────┤
│  1. Boot from ISO, select Heqet entry (waits indefinitely)  │
│  2. Heqet gate runs (early_command):                        │
│     a. Checks for existing install (reboot or reinstall)    │
│     b. Generates random root password, displays on tty1     │
│     c. User selects locale (en_US / en_GB) to confirm       │
│     d. Writes password, locale, keymap to /tmp files        │
│     e. Sets debconf values in isolated subshell              │
│  3. USB-safe disk detection skips the boot device            │
│  4. partman/early_command overrides target disk at runtime  │
│  5. Debian installer reads preseed.cfg, installs base       │
│  6. late_command:                                            │
│     a. Applies root password from gate via openssl hash     │
│     b. Applies locale and keymap from gate selections       │
│     c. Copies IN1CLICK and diagnostics to /opt/in1click/    │
│     d. Masks getty@tty1 for clean first-boot output         │
│     e. Creates in1click-firstboot.service (runs IN1CLICK)   │
│     f. Creates in1click-cleanup.service (restores getty)    │
│  7. System reboots into installed OS                         │
│  8. in1click-firstboot.service runs IN1CLICK on tty1        │
│  9. in1click-cleanup.service disables itself, restores tty1 │
│ 10. FreePBX 17 fully installed and configured               │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

### Build System Requirements

The ISO build process requires a Debian-based Linux system (Debian 10+, Ubuntu 20.04+) with:

- **Root or sudo access** for ISO manipulation
- **10GB+ free disk space** for ISO extraction, customisation, and output
- **2GB+ RAM** for the build process
- **Internet connection** to download the base Debian ISO

### Required Packages

The build script will automatically install these if missing:

- `xorriso` for ISO creation and manipulation
- `isolinux` for BIOS boot loader
- `syslinux-utils` for additional boot utilities
- `genisoimage` for ISO image creation
- `cpio` for initrd support
- `openssl` for hashing support
- `wget` and `curl` for downloads and validation

Manual installation:
```bash
sudo apt-get update
sudo apt-get install -y xorriso isolinux syslinux-utils genisoimage cpio openssl wget curl
```

### Testing Requirements (Optional)

For testing the ISO in a virtual environment:

- **QEMU/KVM**, **VirtualBox**, or **VMware** for VM testing
- **VNC Client** for graphical monitoring (optional)

Install QEMU:
```bash
sudo apt-get install -y qemu-system-x86 qemu-utils
```

## Build Environment Setup

### 1. Clone the Repository

```bash
git clone https://github.com/20telecom/heqet.git
cd heqet
```

### 2. Directory Structure

```
heqet/
├── IN1CLICK                         # IN1CLICK installer script (source)
├── IN1CLICK_README.md               # IN1CLICK documentation
├── README.md                        # Main project README
├── ISO_BUILD.md                     # This document
├── requirements.md                  # Project requirements
└── iso-build/                       # ISO build system
    ├── ISO_BUILD_QUICKSTART.md      # Quick start guide
    ├── config/
    │   ├── preseed.cfg              # Debian preseed configuration
    │   ├── heqet-gate.sh            # Heqet installation gate script
    │   └── isolinux.cfg             # Custom BIOS boot menu
    ├── scripts/
    │   ├── build-iso.sh             # Main ISO build script
    │   ├── test-iso.sh              # QEMU testing script
    │   └── diagnostics.sh           # System diagnostics tool
    ├── build/                       # (created during build)
    │   └── debian-12.13.0-*.iso     # Downloaded base ISO
    ├── output/                      # (created during build)
    │   ├── heqet_*.iso              # Final custom ISO
    │   ├── heqet_*.iso.sha256       # SHA256 checksum
    │   └── heqet_*.iso.md5          # MD5 checksum
    └── logs/                        # (created during build)
        └── xorriso.log              # ISO generation log
```

### 3. Verify IN1CLICK Script

Ensure the IN1CLICK script is present at the repository root:

```bash
ls -lh IN1CLICK
```

The build script copies this into the ISO without modification.

## Building the ISO

### Quick Start

From the repository root:

```bash
sudo bash iso-build/scripts/build-iso.sh
```

The output filename is always `heqet_1-3-0.iso`, derived from the version hardcoded in the build script.

### Build Process

The script runs through four phases:

**Phase 1: Download.** Downloads the Debian 12.13.0 AMD64 netinst ISO (~631MB) if not already cached in `build/`.

**Phase 2: Extract.** Extracts the base ISO using bsdtar, 7z, or mount+rsync (whichever is available). Extraction is made writable for customisation.

**Phase 3: Customise.** Copies preseed.cfg, heqet-gate.sh, IN1CLICK, and diagnostics.sh into the extracted ISO. Applies the custom isolinux.cfg for BIOS boot. Generates a GRUB entry for UEFI boot with matching parameters. Each file is verified against its source after copying.

**Phase 4: Generate.** Creates the hybrid ISO (BIOS + UEFI) using xorriso, generates SHA256 and MD5 checksums, then validates the final ISO contents against source files using bsdtar extraction.

The extraction directory is cleaned up after a successful build.

**Expected Duration:** Under 1 minute if the Debian ISO is cached, or around 1-2 minutes including the download.

### Build Artifacts

```
iso-build/output/
├── heqet_1-3-0.iso          # Custom ISO (~632MB)
├── heqet_1-3-0.iso.sha256   # SHA256 checksum
└── heqet_1-3-0.iso.md5      # MD5 checksum
```

## Testing the ISO

### Quick Test with QEMU

```bash
cd iso-build/scripts
./test-iso.sh ../output/heqet_*.iso
```

This starts a QEMU VM with 2GB RAM, 2 CPU cores, 20GB virtual disk, port forwarding (8080 to 80, 2222 to 22), and VNC on localhost:5901.

### Monitoring Installation

Connect via VNC:
```bash
vncviewer localhost:5901
```

Or monitor serial console:
```bash
tail -f iso-build/logs/vm-serial.log
```

### Testing on Other Platforms

**VirtualBox or VMware:** Create a VM with at least 2GB RAM and 20GB disk. Attach the ISO as a CD/DVD. Boot and follow the Heqet gate on screen.

**Physical Hardware (not currently supported for USB boot):**
```bash
sudo dd if=output/heqet_*.iso of=/dev/sdX bs=4M status=progress
sync
```

**Warning:** Replace `/dev/sdX` with your actual device. This will erase all data on the target.

Note: USB boot is not currently supported. The ISO is designed for VM and bare metal installs where the boot device is not the install target. USB-safe disk detection exists in the preseed but the fallback behaviour has not been fully tested for USB scenarios.

### Expected Installation Timeline

| Time | Stage |
|------|-------|
| 0:00 | Boot from ISO, Heqet gate displayed |
| 0:30 | User confirms gate (password noted, locale selected) |
| 1:00 | Partitioning and base system installation |
| 5:00 | Packages installed, late_command runs |
| 5:30 | First reboot into installed system |
| 6:00 | in1click-firstboot.service starts IN1CLICK |
| 20:00 | FreePBX 17 installed and configured |
| 25:00 | Cleanup service runs, getty restored, system ready |

Total duration: approximately 25-30 minutes depending on hardware and mirror speed.

### Validation Checklist

After installation completes:

- [ ] System boots successfully after ISO removal
- [ ] Root login works with the password from the Heqet gate
- [ ] Network connectivity works
- [ ] Apache is running: `systemctl status apache2`
- [ ] MariaDB is running: `systemctl status mariadb`
- [ ] Asterisk is running: `systemctl status asterisk`
- [ ] FreePBX GUI accessible at http://[server-ip]
- [ ] getty@tty1 is restored: `systemctl status getty@tty1`
- [ ] Firstboot and cleanup services are removed from /etc/systemd/system/
- [ ] /opt/in1click/.installed marker file exists
- [ ] Locale and keyboard match the gate selection

## Deployment

### Production Use

1. **Root Password:** The Heqet gate generates a random 16-character password at install time and displays it on tty1. There are no default credentials in the ISO. Note the password during installation.

2. **Network:** The preseed uses DHCP by default. For static IP, modify preseed.cfg before building:
   ```
   d-i netcfg/disable_autoconfig boolean true
   d-i netcfg/get_ipaddress string 192.168.1.100
   d-i netcfg/get_netmask string 255.255.255.0
   d-i netcfg/get_gateway string 192.168.1.1
   d-i netcfg/get_nameservers string 8.8.8.8 8.8.4.4
   ```

3. **Partitioning:** Default is regular ext4 on the entire disk using the atomic recipe. For LVM:
   ```
   d-i partman-auto/method string lvm
   d-i partman-auto-lvm/guided_size string max
   ```

4. **Rebuild** after any config changes:
   ```bash
   sudo bash iso-build/scripts/build-iso.sh
   ```

### Mass Deployment

- **PXE Boot:** Extract kernel and initrd from the ISO, configure TFTP, serve preseed.cfg via HTTP.
- **Cloud Images:** Install in a VM, convert the disk to qcow2/VMDK, upload as a template.

## Troubleshooting

### Build Issues

**Missing packages:**
```bash
sudo apt-get update
sudo apt-get install -y xorriso isolinux syslinux-utils genisoimage cpio openssl wget curl
```

**Permission denied:** Run the build script with sudo.

**Insufficient disk space:** Clean previous builds with `rm -rf iso-build/build/iso-extract`.

**Validation failed:** The build script verifies each file after copying and again after ISO generation. If validation fails, check that source files in `config/` have not been modified during the build.

### Installation Issues

**Gate hangs after locale selection:** This was a known bug where debconf-set-selections consumed stdin from the read command. Fixed in gate v1.2.0 by wrapping the debconf block in a subshell with `</dev/null`.

**Installation targets the wrong disk:** The preseed includes USB-safe disk detection that skips the boot device. If detection fails, it falls back to /dev/sda. Check /tmp/heqet-target-disk in the installer environment.

**IN1CLICK does not run after reboot:** Check that the firstboot service was created:
```bash
systemctl status in1click-firstboot.service
ls -l /opt/in1click/IN1CLICK
```

**FreePBX installation fails:** Check IN1CLICK output on tty1, or review logs:
```bash
cat /var/log/in1click/install.log
ls /var/log/pbx/freepbx-*.log
```

**getty@tty1 not restored:** The cleanup service should unmask and restart it. If it did not run:
```bash
systemctl unmask getty@tty1.service
systemctl enable getty@tty1.service
systemctl start getty@tty1.service
```

## Technical Details

### Heqet Gate (heqet-gate.sh)

The gate runs as a preseed early_command before any disks are touched. It:

1. Checks common disk paths for an existing /opt/in1click/.installed marker. If found, offers a 10-second window to reinstall or reboots to the installed system.
2. Pins output to tty1 and clears the screen.
3. Displays the Heqet/Egyptian Eyes banner and a 10-second wipe warning countdown.
4. Generates a 16-character alphanumeric root password using /dev/urandom.
5. Cycles the password through 7 ANSI colours so it is not missed on the console.
6. Prompts for locale selection (en_US, en_GB, or abort).
7. Writes the password, locale, and keymap to /tmp files for late_command.
8. Attempts to set debconf values in an isolated subshell with `</dev/null` to avoid consuming stdin.

### Preseed Configuration (preseed.cfg)

**early_command:** Runs the Heqet gate, then performs USB-safe disk detection. Parses /proc/cmdline and /cdrom mount to identify the boot device, iterates candidate disks skipping the boot device, and writes the target to /tmp/heqet-target-disk.

**partman/early_command:** Reads /tmp/heqet-target-disk and overrides partman-auto/disk via debconf-set at runtime. The static disk list in the preseed serves as a fallback default.

**Key settings:**
- Locale: en_US.UTF-8 (overridden by gate selection)
- Timezone: UTC
- Keyboard: us (overridden by gate selection)
- Network: DHCP, hostname freepbx.sangoma.local, domain localdomain
- Partitioning: entire disk, ext4, atomic recipe
- Root password: placeholder hash (overridden by gate password)
- No non-root user created
- Packages: curl, wget, gnupg2, ca-certificates, lsb-release, apt-transport-https, software-properties-common, build-essential, git, sudo, iptables, net-tools, dnsutils, plymouth, plymouth-themes, cloud-init

**late_command:** Hashes and applies the gate password. Copies and applies locale/keymap selections. Copies IN1CLICK and diagnostics to /opt/in1click/. Masks getty@tty1. Creates two systemd services:

- **in1click-firstboot.service:** Runs IN1CLICK on tty1 after network-online.target, local-fs.target, and plymouth-quit.service. Type=oneshot with RemainAfterExit. ConditionPathExists checks for /opt/in1click/IN1CLICK.
- **in1click-cleanup.service:** Requires and runs after in1click-firstboot.service. ConditionPathExists checks for /opt/in1click/IN1CLICK. Disables both services, unmasks, enables, and restarts getty@tty1, then removes both unit files from disk.

### Boot Configuration

**BIOS (isolinux):** Custom isolinux.cfg with TIMEOUT 0 (waits indefinitely for user selection), PROMPT 1, single Heqet entry with preseed parameters including console=tty1 and DEBIAN_FRONTEND=text.

**UEFI (GRUB):** Auto-generated entry with timeout -1 (waits indefinitely), matching parameters including DEBIAN_FRONTEND=text, debian-installer/framebuffer=false, and nosplash.

Both boot paths pass identical preseed and console parameters to ensure consistent behaviour.

### Post-Installation

After IN1CLICK completes:

- FreePBX 17, Asterisk 22, MariaDB, Apache2, and PHP are installed and running.
- The firstboot service is disabled and its unit file removed.
- The cleanup service is disabled and its unit file removed.
- getty@tty1 is unmasked, enabled, and restarted.
- /opt/in1click/.installed marker exists.
- The system is ready for FreePBX initial setup via the web GUI.

## Security Considerations

### Root Password

The Heqet gate generates a random 16-character alphanumeric password at install time using /dev/urandom. It is displayed on tty1 during the gate. There are no default or hardcoded credentials. The preseed contains a placeholder password hash that is overwritten by late_command using the gate-generated password.

The password is visible in plaintext on tty1 during installation. This is inherent to the pre-boot installer environment where no encrypted channels are available.

### Network Security

The preseed installs iptables but does not configure rules. SSH is enabled by default. DHCP is used unless modified.

**Post-installation recommendations:**
1. Configure firewall rules for SIP/RTP ports
2. Use SSH key authentication
3. Disable SSH password authentication
4. Use static IP for production systems
5. Enable HTTPS for the FreePBX web GUI

### ISO Contents

The ISO contains readable copies of preseed.cfg, heqet-gate.sh, and IN1CLICK. The preseed password hash is a placeholder and does not represent the actual root password (which is generated at install time). No sensitive credentials are embedded in the ISO.

### APT Source Safety

IN1CLICK includes Debian 13 prevention that blocks stable and trixie references in APT sources before and after updates. It also disables unattended-upgrades during installation to prevent APT lock conflicts.

---

## Credits

- Heqet ISO and IN1CLICK: Developed by 20tele.com
- FreePBX: Sangoma Technologies
- Debian: Debian Project
- Mirror Monitoring: mirrors.in1.click by 20tele.com

## Contributing

Contributions are welcome! Please:
1. Test thoroughly in a controlled environment
2. Follow code style
3. Document changes
4. Submit pull requests with details

## License

GNU General Public License v3.0

## Disclaimer

This software is provided as-is without warranty of any kind, express or implied. You may modify, distribute, and use this software; 20tele.com accepts no responsibility for any damage or issues arising from its use. Please test thoroughly in a controlled environment before deploying.

---

**Version:** 1.3.0
**Last Updated:** 11th March 2026
**Status:** Active Development
