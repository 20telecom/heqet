
# Heqet ISO
# Debian 12 + FreePBX 17 + Asterisk 22 + MariaDB 10

**Version**: 1.0.0
**Last Updated**: 12th February 2026
**Status**: Active Development

Designed for Zero-Touch Install of FreePBX® 17 using the pre-built ISO.

WARNING: The Heqet ISO is not currently suitable for use in production.
Download a beta version at https://heqet.in1.click/beta/freepbx17.iso

IMPORTANT *** NOT CURRENTLY SUITABLE FOR USB - TESTED ON VULTR, PROXMOX, VIRTUALBOX ***

## Using The Pre-Built ISO

1. Download the ISO from https://heqet.in1.click/beta/freepbx17.iso
2. Write it to a USB drive or attach it to a VM
3. Boot from the ISO and follow the on-screen Heqet gate

## What You Get

✅ Debian 12 (Bookworm) — Latest stable release
✅ FreePBX 17 — Latest version
✅ Asterisk 22 — Telephony engine
✅ MariaDB — Database server
✅ Apache2 + PHP — Web server and runtime
✅ All dependencies — Fully configured

## Repository Structure

```
heqet/
├── IN1CLICK            # IN1CLICK installer script
├── IN1CLICK_README.md  # IN1CLICK documentation
├── requirements.md                  # Project requirements
├── ISO_BUILD.md                     # ISO build documentation
└── iso-build/                       # ISO build system
    ├── ISO_BUILD_QUICKSTART.md      # ISO build quick start
    ├── config/                      # Preseed configurations
    ├── scripts/                     # Build and test scripts
    └── output/                      # Generated ISOs
```

## Documentation
- [AI Disclosure](AI_DISCLOSURE.md)
- [Current Issues](CURRENT_ISSUES.md)
- [IN1CLICK Manual](IN1CLICK_README.md)
- [ISO Build Quick Start](iso-build/ISO_BUILD_QUICKSTART.md)
- [ISO Build Guide](ISO_BUILD.md)
- [ISO Build Steps](ISO_BUILD_STEPS.md)
- [Requirements](requirements.md)

**Which doc should I read?**
- If you are installing from the pre-built ISO, read this README.
- If you want to generate a new ISO, start with [iso-build/ISO_BUILD_QUICKSTART.md](iso-build/ISO_BUILD_QUICKSTART.md) for the minimal build steps, then [ISO_BUILD.md](ISO_BUILD.md) for full details.

## System Requirements

**Pre-Built ISO Install:**
- Debian 12 (Bookworm) 64-bit
- 1GB+ RAM (2GB+ recommended)
- 10GB+ disk space
- Internet connection
- Root access

**ISO Build:**
- Debian/Ubuntu build host
- 10GB+ free disk space
- Root/sudo access
- Internet connection
- Required packages: xorriso, isolinux, syslinux-utils, genisoimage, cpio, openssl, wget, curl

## Security & Upgrade Safety

**Root Password (Heqet Gate):**
- During install, the Heqet gate generates a random root password and displays it on screen.
- A short 10-second countdown runs before password generation.
- No disks are touched until you confirm the gate; the countdown is a safety pause.
- Choose a locale (en_US or en_GB) to continue; press Enter or 0 to abort.

**APT Source Auto-Fix:**
- 'stable' → 'bookworm' automatically
- 'trixie' lines are commented out
- All sources checked after `apt update`
- Warnings printed if changes made

**Upgrade Blocking:**
- Installer will not allow upgrades to Debian 13 (Trixie)
- Only Bookworm sources supported

## Support

- Email: support@20tele.com
- Portal: https://support.20tele.com
- Issues: [GitHub Issues](https://github.com/kierknoby/heqet/issues)

## Developer Info

Heqet is designed for reliability, reproducibility, and ease of use in both lab and production environments.

**Project Purpose:**
- Automate FreePBX deployment
- Support mass deployment
- Facilitate testing and development

**Architecture:**
- ISO Builder: Generates custom ISOs with preseed automation and IN1CLICK embedded
- IN1CLICK Installer: Bash script automates all checks, installs, and setup
- Preseed Automation: Unattended OS install, dynamic root password

**Extending Heqet:**
- Fork and clone the repo
- Review and modify scripts/configs
- Add modules, checks, or post-install actions
- Document changes and submit PRs

## License

GNU General Public License v3.0

See [LICENSE](LICENSE) for full details.

## Credits

- IN1CLICK Script: Developed by 20tele.com
- FreePBX: Sangoma Technologies
- Debian: Debian Project

## Contributing

Contributions are welcome! Please:
1. Test thoroughly in a controlled environment
2. Follow code style
3. Document changes
4. Submit pull requests with details

## Disclaimer

This software is provided as-is without warranty of any kind. Test thoroughly before production use. The authors accept no responsibility for any damage or issues arising from the use of this software.
