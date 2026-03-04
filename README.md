# Heqet ISO

# Debian 12 + FreePBX 17 + Asterisk 22 + MariaDB 10

**Version:** 1.2.0
**Last Updated:** 4th March 2026
**Status:** Active Development

# Version Update

From 1.0.0 to 1.2.0 on 4th March 2026 by kierknoby

Skipped 1.1.0 to keep Heqet versioning aligned with IN1CLICK 1.2.0.

Major update adding USB-safe disk detection, locale/keymap application from the gate, plymouth-quit ordering for firstboot, and GRUB parameter alignment with isolinux. Build script updated to v1.2.0 with DEBCONF_DEBUG removed and GRUB nosplash added. See changelog below.

---

## Overview

**Heqet** is a zero-touch installer for FreePBX 17 on Debian 12, built and maintained by 20tele.com. Boot the ISO, confirm the Heqet gate, and walk away. The system installs Debian, applies your locale and root password, then runs IN1CLICK to deploy FreePBX 17 automatically.

**WARNING:** The Heqet ISO is not currently suitable for use in production.

**IMPORTANT:** Not currently suitable for USB boot. Tested on Vultr, Proxmox, and VirtualBox.

Download a beta version at https://heqet.in1.click/beta/freepbx17.iso

---

## What You Get

✅ Debian 12 (Bookworm) — Latest stable release
✅ FreePBX 17 — Latest version
✅ Asterisk 22 — Telephony engine
✅ MariaDB — Database server
✅ Apache2 + PHP — Web server and runtime
✅ All dependencies — Fully configured

---

## Using the Pre-Built ISO

1. Download the ISO from https://heqet.in1.click/beta/freepbx17.iso
2. Attach it to a VM or write it to a disk (USB not currently supported)
3. Boot from the ISO
4. The Heqet gate displays a random root password and a 10-second wipe warning
5. Note the password, select a locale (en_US or en_GB) to confirm, or press Enter/0 to abort
6. The installation runs unattended from this point
7. After reboot, IN1CLICK installs FreePBX 17 automatically on tty1

Total install time is approximately 25-30 minutes depending on hardware and mirror speed.

---

## Requirements

**Pre-Built ISO Install:**
- 64-bit (x86_64) hardware or VM
- 1GB+ RAM (2GB+ recommended)
- 10GB+ disk space
- Internet connection

**ISO Build:**
- Debian/Ubuntu build host or GitHub Codespaces
- 10GB+ free disk space
- Root/sudo access
- Internet connection

---

## Documentation

- [IN1CLICK Manual](IN1CLICK_README.md) — The installer script that runs inside Heqet
- [ISO Build Quick Start](iso-build/ISO_BUILD_QUICKSTART.md) — Minimal build steps
- [ISO Build Guide](ISO_BUILD.md) — Full technical guide for building the ISO
- [ISO Build Steps (Codespaces)](ISO_BUILD_STEPS.md) — Codespaces quickstart for building the ISO
- [AI Disclosure](AI_DISCLOSURE.md)
- [Current Issues](CURRENT_ISSUES.md)
- [Requirements](requirements.md)

**Which doc should I read?**
- Installing from the pre-built ISO? Read this README.
- Building a new ISO? Start with [ISO Build Quick Start](iso-build/ISO_BUILD_QUICKSTART.md).
- Need full build details, testing, or troubleshooting? See [ISO_BUILD.md](ISO_BUILD.md).
- Building in GitHub Codespaces? Start with [ISO_BUILD_STEPS.md](ISO_BUILD_STEPS.md).

---

## Repository Structure

```
heqet/
├── IN1CLICK                         # IN1CLICK installer script
├── IN1CLICK_README.md               # IN1CLICK documentation
├── README.md                        # This document
├── ISO_BUILD.md                     # ISO build guide
├── ISO_BUILD_STEPS.md               # Codespaces quickstart
├── requirements.md                  # Project requirements
└── iso-build/                       # ISO build system
    ├── config/
    │   ├── preseed.cfg              # Debian preseed configuration
    │   ├── heqet-gate.sh            # Heqet installation gate script
    │   ├── isolinux.cfg             # Custom BIOS boot menu
    │   └── splash.png               # Boot splash screen
    ├── scripts/
    │   ├── build-iso.sh             # Main ISO build script
    │   ├── test-iso.sh              # QEMU testing script
    │   └── diagnostics.sh           # System diagnostics tool
    ├── build/                       # (created during build)
    ├── output/                      # (created during build)
    └── logs/                        # (created during build)
```

---

## Security & Upgrade Safety

**Root Password (Heqet Gate):**
- The gate generates a random 16-character alphanumeric password at install time using /dev/urandom.
- The password cycles through 7 ANSI colours on tty1 so it is not missed.
- No disks are touched until you confirm the gate. The countdown is a safety pause.
- There are no default or hardcoded credentials in the ISO.

**APT Source Auto-Fix:**
- 'stable' is replaced with 'bookworm' automatically.
- 'trixie' lines are commented out.
- All sources are checked again after `apt update`.
- Warnings are printed if changes are made.

**Upgrade Blocking:**
- IN1CLICK will not allow upgrades to Debian 13 (Trixie).
- Only Bookworm sources are supported.

**Mirror Gate:**
- 3 consecutive successful checks via mirrors.in1.click are required before proceeding.
- Both module mirror status and deb.freepbx.org status must pass.

---

## Architecture

**Heqet Gate (heqet-gate.sh):** Runs before any disks are touched. Detects existing installs, generates the root password, collects locale/keymap selection, and writes values to temp files for the preseed to consume.

**Preseed (preseed.cfg):** Automates Debian installation. Includes USB-safe disk detection in early_command, runtime disk override via partman/early_command, and a late_command that applies the gate password, locale, and keymap, deploys IN1CLICK, and creates systemd firstboot/cleanup services.

**IN1CLICK:** Bash script that runs on first boot via systemd. Performs all pre-checks, installs FreePBX 17 using the official Sangoma installer, upgrades modules, and verifies the installation. Marks completion and triggers cleanup.

**Cleanup Service:** Disables the firstboot and cleanup services, unmasks and restarts getty@tty1, and removes both unit files from disk.

---

## Changelog

### 1.2.0 (4th March 2026)

**Heqet Gate (heqet-gate.sh)**
- Version bump from 1.0.1 to 1.2.0 in banner.
- Password display now cycles through 7 ANSI colours before settling.
- Changed prompt wording from "select a region" to "select a locale".
- Locale and keymap values written to /tmp/heqet-locale and /tmp/heqet-keymap for late_command.
- Debconf block wrapped in a subshell with </dev/null stdin redirection, fixing the hang after region selection.
- Debconf tool priority flipped: debconf-set tried first, debconf-set-selections as fallback.
- Removed DEBIAN_FRONTEND and DEBCONF_NONINTERACTIVE_SEEN exports.
- Fallback error message updated to reflect temp-file recovery path.

**Preseed (preseed.cfg)**
- USB-safe disk detection in early_command to identify and skip the boot device.
- Added partman/early_command to override partman-auto/disk at runtime.
- Late_command now applies locale and keymap from the gate via /tmp/heqet-locale and /tmp/heqet-keymap.
- Added plymouth-quit.service to firstboot unit ordering.
- Updated late_command description to reflect current functionality.
- Removed inline comments and normalised indentation to spaces.

**Build Script (build-iso.sh)**
- Version bump to 1.2.0.
- Updated GRUB menuentry to include DEBIAN_FRONTEND=text, debian-installer/framebuffer=false, and nosplash.

**Boot Configuration (isolinux.cfg)**
- Removed DEBCONF_DEBUG=5 from boot parameters for production builds.

### 1.0.0 (12th February 2026)

- Initial release.

---

## Support

- Email: support@20tele.com
- Portal: https://support.20tele.com
- Issues: [GitHub Issues](https://github.com/20telecom/heqet/issues)

---

## Credits

- Heqet ISO and IN1CLICK: Developed by 20tele.com
- FreePBX: Sangoma Technologies
- Debian: Debian Project
- Mirror Monitoring: mirrors.in1.click by 20tele.com

---

## Contributing

Contributions are welcome! Please:
1. Test thoroughly in a controlled environment
2. Follow code style
3. Document changes
4. Submit pull requests with details

---

## Disclaimer

This software is provided as-is without warranty of any kind, express or implied. You may modify, distribute, and use this software; 20tele.com accepts no responsibility for any damage or issues arising from its use. Please test thoroughly in a controlled environment before deploying.

---

## License

GNU General Public License v3.0

See [LICENSE](LICENSE) for full details.

---
