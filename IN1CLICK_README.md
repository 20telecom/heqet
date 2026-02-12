# IN1CLICK — FreePBX 17 on Debian 12 [1.1.0]

## Version Update

From 1.0.2 to 1.1.0 on 11th February 2026 by kierknoby

- Further improvements to mirror logic and user prompts.
- Documentation and output clarified.

---

## Overview

**IN1CLICK** is a streamlined, automated installer script for setting up FreePBX 17 on Debian 12. Developed by 20tele.com, the script simplifies the process by automating all necessary checks, system preparation, package installation, and post-install tasks. It leaves a clean system ready for FreePBX use.

---

## Disclaimer

The bash script was first published to install FreePBX 17 on 5th August 2025. Contents are provided as-is without warranty of any kind, express or implied. You may modify, distribute, and use this script; 20tele.com accepts no responsibility for any damage or issues arising from its use.

Please test it thoroughly in a controlled environment before deploying.

---

## Features

- Fast and reliable installation of FreePBX 17 on Debian 12.
- Automated pre-checks: OS version, memory, swap, architecture, hostname, disk space, existing services.
- Validates IP assignment (static or DHCP).
- Verifies and installs required packages including curl, iptables, and others.
- Runs the FreePBX Mirror Status CLI and prompts user if mirrors are unstable.
- Confirms availability of FreePBX APT repository and installer before continuing.
- OS version re-check to ensure Debian did not upgrade from 12 (bookworm) to 13 (trixie).
- Detects desktop environments and warns users to use a minimal server install.
- Uses the official FreePBX install script from Sangoma.
- Automatically upgrades modules and reloads FreePBX.
- Cleans up Asterisk logs and system mail.
- Clears bash history and removes itself from disk after installation.
- Reboots system automatically after notifying the user.

---

## Requirements

- Debian 12 (bookworm), 64-bit (x86_64)
- Root access
- Internet connectivity
- No existing installation of FreePBX, Asterisk, or MariaDB
- Minimal server install (no desktop environment)

---

## FreePBX Mirror Status Check

IN1CLICK runs the FreePBX Mirror Status CLI from in1.click after verifying curl. This check evaluates DNS, TCP, SSL, and XML responses for the FreePBX mirrors and prints a final recommendation.

### Outcomes

- **Stable**: The script prints "Mirrors are stable. OK to proceed." and continues automatically.
- **Degraded/Unstable**: IN1CLICK pauses and asks what to do:
	1) Check mirrors again
	2) Abort installation
	3) Carry on anyway

If you abort, IN1CLICK stops and prints a restart command along with support contact details.

---

## One-Click Installation

Run this command on a clean Debian 12 system as root:

```bash
wget https://raw.githubusercontent.com/20telecom/IN1CLICK/main/IN1CLICK -O /tmp/IN1CLICK && chmod +x /tmp/IN1CLICK && /tmp/IN1CLICK
```

---

## Sample Output

```
Hello. Thanks for using IN1CLICK for FreePBX 17 on Debian 12 [1.1.0] by 20tele.com

Checking if this is Debian 12...
Debian 12 confirmed. OK to proceed.

Checking available disk space...
Disk space available: 16.47 GB. OK to proceed.

Checking available memory and swap...
Memory: 954 MB, Swap: 2399 MB. OK to proceed.

Checking system architecture...
Architecture is 64-bit. OK to proceed.

Checking hostname label format...
Hostname label appears valid. OK to proceed.

Checking for desktop environment...
No desktop environment detected. OK to proceed.

Checking /tmp permissions...
/tmp is writable and executable. OK to proceed.

Checking for existing FreePBX installation...
No existing FreePBX found. OK to proceed.

Checking for existing Asterisk installation...
No existing Asterisk found. OK to proceed.

Checking for existing MariaDB installation...
No existing MariaDB found. OK to proceed.

Checking for existing Node.js installation...
No existing Node.js installation found. OK to proceed.

Checking APT sources and update availability...
APT sources appear to be valid. OK to proceed.

Checking and fixing forbidden APT sources (stable/trixie)...
APT sources do not contain forbidden entries. OK to proceed.

Updating package lists...
All package lists updated. OK to proceed.

Verifying and fixing no Debian 13 (trixie) references after update...
No 'trixie' references found after update. OK to proceed.

Upgrading packages... Please be patient.
Packages upgraded successfully. OK to proceed.

Checking this is still Debian 12...
Debian 12 confirmed. OK to proceed.

Checking IP assignment type...
Static IP detected. OK to proceed.

Checking for iptables...
iptables is already installed. OK to proceed.

Checking for active iptables rules...
No active DROP/REJECT iptables rules detected. OK to proceed.

Checking for port 80 conflicts...
No port 80 conflicts detected. OK to proceed.

Checking DNS resolution...
DNS resolution working. OK to proceed.

Checking for curl...
curl is installed. OK to proceed.

Checking FreePBX mirrors (mirrors.in1.click)...
Mirrors are stable. OK to proceed.

Checking for FreePBX GitHub installer at raw.githubusercontent.com...
FreePBX GitHub installer is reachable. OK to proceed.

Checking FreePBX installation repository (deb.freepbx.org)...
FreePBX APT repository is reachable. OK to proceed.

Checking outbound internet connectivity (public IP)...
Outbound internet connectivity confirmed. Your Public IP is 203.0.113.45. OK to proceed.

Installing FreePBX 17...
Modules upgraded and system reloaded. OK to proceed.

Checking if Apache is running...
Apache is running. OK to proceed.

Checking access to the FreePBX GUI...
Port 80 is open on 192.168.1.100. OK to proceed.

Cleaning Asterisk logs...
Full, fail2ban, and root mail cleared. OK to proceed.

Clearing bash history...
Bash history cleared. OK to proceed.

IN1CLICK completed in 14 min 30 sec.

Goodbye.
```

---

## Support

If something goes wrong during install, check the logs:

- `/var/log/pbx/freepbx-*.log`
- `/var/log/asterisk/full`
- `systemctl status asterisk`
- `fwconsole restart`

If you need help, email support@20tele.com or open a ticket at https://support.20tele.com

---

## License

GNU General Public License v3.0

---
