#!/bin/bash
#
# Diagnostic and Logging Script
# Collects system information and logs for troubleshooting
#
# This script can be included in the ISO or run on the installed system
# to help diagnose issues with the automated installation

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DIAG_DIR="/var/log/in1click"
DIAG_FILE="${DIAG_DIR}/diagnostics-$(date +%Y%m%d-%H%M%S).log"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$DIAG_FILE"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$DIAG_FILE"
}

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "$DIAG_FILE"
}

section() {
    echo "" | tee -a "$DIAG_FILE"
    echo "═══════════════════════════════════════════════════════════════" | tee -a "$DIAG_FILE"
    echo "$1" | tee -a "$DIAG_FILE"
    echo "═══════════════════════════════════════════════════════════════" | tee -a "$DIAG_FILE"
}

# Create diagnostics directory
mkdir -p "$DIAG_DIR"

section "SYSTEM DIAGNOSTICS - $(date)"

# System Information
section "1. System Information"
log_info "Operating System:"
cat /etc/os-release | tee -a "$DIAG_FILE"

log_info "Kernel:"
uname -a | tee -a "$DIAG_FILE"

log_info "Architecture:"
uname -m | tee -a "$DIAG_FILE"

# Hardware Information
section "2. Hardware Information"
log_info "CPU Information:"
lscpu | grep -E "Model name|CPU\(s\):|Thread|Core" | tee -a "$DIAG_FILE"

log_info "Memory:"
free -h | tee -a "$DIAG_FILE"

log_info "Disk Space:"
df -h | tee -a "$DIAG_FILE"

log_info "Disk Partitions:"
lsblk | tee -a "$DIAG_FILE"

# Network Information
section "3. Network Information"
log_info "IP Configuration:"
ip addr show | tee -a "$DIAG_FILE"

log_info "Routing Table:"
ip route | tee -a "$DIAG_FILE"

log_info "DNS Configuration:"
cat /etc/resolv.conf | tee -a "$DIAG_FILE" || echo "No DNS config found" | tee -a "$DIAG_FILE"

log_info "Network Connectivity Test:"
if ping -c 3 8.8.8.8 > /dev/null 2>&1; then
    echo "✓ Internet connectivity: OK" | tee -a "$DIAG_FILE"
else
    echo "✗ Internet connectivity: FAILED" | tee -a "$DIAG_FILE"
fi

if host google.com > /dev/null 2>&1; then
    echo "✓ DNS resolution: OK" | tee -a "$DIAG_FILE"
else
    echo "✗ DNS resolution: FAILED" | tee -a "$DIAG_FILE"
fi

# Service Status
section "4. Service Status"
log_info "Checking critical services:"

for service in asterisk apache2 mariadb mysql; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo "✓ $service: Running" | tee -a "$DIAG_FILE"
    elif systemctl list-unit-files | grep -q "$service"; then
        echo "✗ $service: Installed but not running" | tee -a "$DIAG_FILE"
    else
        echo "○ $service: Not installed" | tee -a "$DIAG_FILE"
    fi
done

# IN1CLICK Status
section "5. IN1CLICK Status"

if [[ -f /opt/in1click/IN1CLICK ]]; then
    log_info "IN1CLICK script: Present"
else
    log_error "IN1CLICK script: NOT FOUND"
fi

if [[ -f /var/log/in1click/install.log ]]; then
    log_info "IN1CLICK install log exists"
    echo "Last 50 lines of install log:" >> "$DIAG_FILE"
    tail -n 50 /var/log/in1click/install.log >> "$DIAG_FILE" 2>&1
else
    log_error "IN1CLICK install log not found"
fi

# FreePBX Status
section "6. FreePBX Status"

if [[ -f /etc/freepbx.conf ]]; then
    log_info "FreePBX configuration: Found"
else
    log_error "FreePBX configuration: NOT FOUND"
fi

if [[ -d /var/www/html/admin ]]; then
    log_info "FreePBX web directory: Found"
else
    log_error "FreePBX web directory: NOT FOUND"
fi

if command -v fwconsole &> /dev/null; then
    log_info "FreePBX console available"
    echo "FreePBX version:" >> "$DIAG_FILE"
    fwconsole version >> "$DIAG_FILE" 2>&1 || echo "Failed to get version" >> "$DIAG_FILE"
else
    log_error "FreePBX console not available"
fi

# Port Status
section "7. Port Status"

log_info "Listening ports:"
ss -tlnp | grep -E ":(80|443|5060|5061|22)" | tee -a "$DIAG_FILE" || echo "No matching ports found" | tee -a "$DIAG_FILE"

# Recent Logs
section "8. Recent System Logs"

log_info "Last 20 syslog entries:"
tail -n 20 /var/log/syslog >> "$DIAG_FILE" 2>&1 || echo "Syslog not available" >> "$DIAG_FILE"

log_info "Last 20 daemon log entries:"
tail -n 20 /var/log/daemon.log >> "$DIAG_FILE" 2>&1 || echo "Daemon log not available" >> "$DIAG_FILE"

# Package Status
section "9. Package Status"

log_info "Checking key packages:"
for pkg in asterisk freepbx apache2 mariadb-server php curl wget; do
    if dpkg -l | grep -q "^ii  $pkg"; then
        echo "✓ $pkg: Installed" | tee -a "$DIAG_FILE"
    else
        echo "✗ $pkg: Not installed" | tee -a "$DIAG_FILE"
    fi
done

# Boot Status
section "10. Boot Information"

log_info "Last boot:"
who -b | tee -a "$DIAG_FILE"

log_info "System uptime:"
uptime | tee -a "$DIAG_FILE"

log_info "Failed services:"
systemctl list-units --failed | tee -a "$DIAG_FILE"

# Summary
section "DIAGNOSTICS COMPLETE"

echo "" | tee -a "$DIAG_FILE"
log "Diagnostics saved to: $DIAG_FILE"
log_info "Share this file with support if you need help."
echo ""

# Check for common issues
echo "Quick Issue Detection:" | tee -a "$DIAG_FILE"
echo "═══════════════════════" | tee -a "$DIAG_FILE"

ISSUES_FOUND=0

# Check disk space
if df / | tail -1 | awk '{print $5}' | sed 's/%//' | awk '$1 > 90 {exit 1}'; then
    true
else
    echo "⚠ WARNING: Disk usage over 90%" | tee -a "$DIAG_FILE"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check memory
if free | awk '/^Mem:/ {if ($3/$2 > 0.95) exit 1}'; then
    true
else
    echo "⚠ WARNING: Memory usage over 95%" | tee -a "$DIAG_FILE"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check services
if systemctl is-active --quiet apache2 2>/dev/null; then
    true
else
    echo "⚠ WARNING: Apache2 is not running" | tee -a "$DIAG_FILE"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

if [[ $ISSUES_FOUND -eq 0 ]]; then
    echo "✓ No immediate issues detected" | tee -a "$DIAG_FILE"
else
    echo "✗ $ISSUES_FOUND potential issue(s) detected" | tee -a "$DIAG_FILE"
fi

echo ""
exit 0
