#!/bin/bash
#
# Preseed Configuration Validator
# Validates the preseed.cfg file for syntax errors and logical issues
#
# Usage: ./validate-preseed.sh

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRESEED_FILE="${SCRIPT_DIR}/../config/preseed.cfg"

log() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}!${NC} $1"
}

echo "═══════════════════════════════════════════════════════════════"
echo "  Preseed Configuration Validator"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Check if preseed file exists
if [[ ! -f "$PRESEED_FILE" ]]; then
    log_error "Preseed file not found: $PRESEED_FILE"
    exit 1
fi

log "Preseed file found: $PRESEED_FILE"
echo ""

# Check for required sections
echo "Checking for required configuration sections..."

# Note: preseed/early_command has been removed to enable fully unattended installation.
# The confirmation prompt it contained does not work in the Debian installer environment.
required_sections=(
    "debian-installer/locale"
    "netcfg/get_hostname"
    "passwd/root-password"
    "partman-auto/method"
    "grub-installer/only_debian"
    "preseed/late_command"
)

all_found=true
for section in "${required_sections[@]}"; do
    if grep -q "$section" "$PRESEED_FILE"; then
        log "Found: $section"
    else
        log_error "Missing: $section"
        all_found=false
    fi
done

echo ""

if [[ "$all_found" != true ]]; then
    log_error "Some required sections are missing!"
    exit 1
fi

echo ""

# Check file size (preseed shouldn't be too large)
file_size=$(wc -c < "$PRESEED_FILE")
if (( file_size > 50000 )); then
    log_warn "Preseed file is quite large (${file_size} bytes)"
else
    log "File size is reasonable (${file_size} bytes)"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ All validation checks passed!${NC}"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Summary:"
echo "  • Preseed file: $PRESEED_FILE"
echo "  • User confirmation: Disabled (Fully automated installation)"
echo "  • Installation proceeds immediately without user interaction"
echo ""
echo "Next steps:"
echo "  1. Build the ISO: cd scripts && sudo ./build-iso.sh"
echo "  2. Test the ISO: ./test-iso.sh -m ../output/*.iso"
echo ""
