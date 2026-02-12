#!/bin/bash
#
# Preseed validation tests - Confirms automated installation configuration
# Tests that the preseed.cfg is configured for fully unattended installation
#
# Usage: ./test-confirmation-logic.sh

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

test_count=0
pass_count=0
fail_count=0

log_test() {
    test_count=$((test_count + 1))
    echo -e "${BLUE}[TEST ${test_count}]${NC} $1"
}

log_pass() {
    echo -e "  ${GREEN}✓ PASS${NC} $1"
    pass_count=$((pass_count + 1))
}

log_fail() {
    echo -e "  ${RED}✗ FAIL${NC} $1"
    fail_count=$((fail_count + 1))
}

echo "═══════════════════════════════════════════════════════════════"
echo "  Preseed Automation Tests"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Test 1: No user confirmation required
log_test "Checking that user confirmation is disabled"
if ! grep -q "preseed/early_command" ../config/preseed.cfg; then
    log_pass "No early_command section found - fully automated"
else
    log_fail "early_command section still present - should be removed"
fi
echo ""

# Test 2: No confirmation prompts
log_test "Checking that no confirmation prompts exist"
if ! grep -q "Type 'Heqet' to continue" ../config/preseed.cfg; then
    log_pass "No confirmation prompts found"
else
    log_fail "Confirmation prompts still present"
fi
echo ""

# Test 3: No read commands for user input
log_test "Checking that no user input is requested"
if ! grep -q "read -t" ../config/preseed.cfg; then
    log_pass "No user input commands found"
else
    log_fail "User input commands still present"
fi
echo ""

# Test 4: No abort logic
log_test "Checking that no abort logic exists"
if ! grep -q "INSTALLATION ABORTED" ../config/preseed.cfg; then
    log_pass "No abort logic found"
else
    log_fail "Abort logic still present"
fi
echo ""

# Test 5: Starts with localization
log_test "Checking that preseed starts with localization"
if grep -q "### Localization" ../config/preseed.cfg && grep -q "d-i debian-installer/locale string" ../config/preseed.cfg; then
    log_pass "Preseed configuration includes localization settings"
else
    log_fail "Localization section not found"
fi
echo ""

# Test 6: Required sections present
log_test "Checking for required preseed sections"
required_sections=(
    "debian-installer/locale"
    "netcfg/get_hostname"
    "passwd/root-password"
    "partman-auto/method"
    "grub-installer/only_debian"
    "preseed/late_command"
)

all_sections_found=true
for section in "${required_sections[@]}"; do
    if grep -q "$section" ../config/preseed.cfg; then
        : # Section found, continue
    else
        log_fail "Missing required section: $section"
        all_sections_found=false
        fail_count=$((fail_count + 1))
    fi
done

if [ "$all_sections_found" = true ]; then
    log_pass "All required sections are present"
fi
echo ""

# Summary
echo "═══════════════════════════════════════════════════════════════"
echo -e "  Test Results"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  Total tests:  $test_count"
echo -e "  ${GREEN}Passed:       $pass_count${NC}"
if [ $fail_count -gt 0 ]; then
    echo -e "  ${RED}Failed:       $fail_count${NC}"
else
    echo -e "  Failed:       $fail_count"
fi
echo ""

if [ $fail_count -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo "The preseed configuration is set up for fully automated installation."
    echo "Installation will proceed without any user confirmation."
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some tests failed!${NC}"
    echo ""
    exit 1
fi
