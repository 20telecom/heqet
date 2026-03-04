#!/bin/bash

################################################################################
# Heqet - Debian 12 ISO Build Script with IN1CLICK Integration
# 
# This script builds a custom Debian 12 ISO with:
# - Automated installation via preseed
# - Integrated FreePBX 17 IN1CLICK installer
# - Modified boot configurations for unattended deployment
#
# Version: 1.2.0
# Last Updated: 2026-03-02
################################################################################

set -euo pipefail  # Fail fast on errors and unset vars

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISO_BUILD_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$ISO_BUILD_DIR/build"
OUTPUT_DIR="$ISO_BUILD_DIR/output"
LOGS_DIR="$ISO_BUILD_DIR/logs"
CONFIG_DIR="$ISO_BUILD_DIR/config"
REPO_ROOT="$(dirname "$ISO_BUILD_DIR")"


# ISO configuration
if [ -n "${1:-}" ]; then
    ISO_VERSION="$1"
else
    ISO_VERSION="0-0-17"
fi
OUTPUT_NAME="heqet_${ISO_VERSION}.iso"
ISO_LABEL="Heqet Debian 12"
# DEBIAN_VERSION will be detected automatically
DEBIAN_VERSION=""
DEBIAN_ISO_NAME=""
DEBIAN_ISO_URL=""

# Directories
ISO_EXTRACT_DIR="$BUILD_DIR/iso-extract"
ISO_MOUNT_DIR="$BUILD_DIR/iso-mount"

# Files
PRESEED_FILE="$CONFIG_DIR/preseed.cfg"
GATE_SCRIPT="$CONFIG_DIR/heqet-gate.sh"
CUSTOM_ISOLINUX_CFG="$CONFIG_DIR/isolinux.cfg"
SPLASH_FILE="$CONFIG_DIR/splash.png"
IN1CLICK_SCRIPT="$REPO_ROOT/IN1CLICK"
DIAGNOSTICS_SCRIPT="$SCRIPT_DIR/diagnostics.sh"

################################################################################
# Helper Functions
################################################################################

log_info() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

print_header() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║         Heqet - Debian 12 ISO Build with IN1CLICK             ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
}

print_success() {
    local msg
    local width
    local len
    local pad_left
    local pad_right

    msg="You can download and use $OUTPUT_NAME"
    width=61
    len=${#msg}
    if [ "$len" -lt "$width" ]; then
        pad_left=$(( (width - len) / 2 ))
        pad_right=$(( width - len - pad_left ))
    else
        pad_left=0
        pad_right=0
    fi

    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    printf "║ %*s%s%*s ║\n" "$pad_left" "" "$msg" "$pad_right" ""
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
}

detect_latest_debian_iso() {
    log_info "Using static Debian 12.8.0 ISO (Bookworm, EOL)"
    DEBIAN_VERSION="12.8.0"
    DEBIAN_ISO_NAME="debian-12.8.0-amd64-netinst.iso"
    DEBIAN_ISO_URL="https://cdimage.debian.org/cdimage/archive/12.8.0/amd64/iso-cd/debian-12.8.0-amd64-netinst.iso"
    log_info "Will use: $DEBIAN_ISO_NAME"
}

check_dependencies() {
    log_info "Checking required packages..."

    log_info "Ensuring required packages are installed..."
    apt-get update -qq
    apt-get install -y -qq xorriso isolinux syslinux-utils genisoimage wget curl cpio openssl
    log_info "✓ Required packages are installed"
}

verify_match() {
    local src="$1"
    local dst="$2"
    local label="$3"

    if [ ! -f "$src" ] || [ ! -f "$dst" ]; then
        log_error "Validation failed: missing $label file ($src or $dst)"
        exit 1
    fi

    if ! cmp -s "$src" "$dst"; then
        log_error "Validation failed: $label does not match source"
        exit 1
    fi
}

setup_directories() {
    log_info "Setting up build directories..."
    
    mkdir -p "$BUILD_DIR"
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$LOGS_DIR"
    
    log_info "✓ Build directories created"
}

cleanup_previous_build() {
    log_info "Cleaning up previous build artifacts..."
    
    # Unmount if still mounted
    if mountpoint -q "$ISO_MOUNT_DIR" 2>/dev/null; then
        umount "$ISO_MOUNT_DIR" 2>/dev/null || true
    fi
    
    # Remove old extraction directory
    if [ -d "$ISO_EXTRACT_DIR" ]; then
        rm -rf "$ISO_EXTRACT_DIR"
    fi
    
    # Remove old mount directory
    if [ -d "$ISO_MOUNT_DIR" ]; then
        rmdir "$ISO_MOUNT_DIR" 2>/dev/null || true
    fi
    
    log_info "✓ Cleanup completed"
}

################################################################################
# Phase 1: Download Debian ISO
################################################################################

download_debian_iso() {
    log_info "Checking for existing Debian ISO..."
    
    local iso_path="$BUILD_DIR/$DEBIAN_ISO_NAME"
    
    # Check if specific version exists and is valid (size > 100MB)
    if [ -f "$iso_path" ] && [ $(stat -c%s "$iso_path") -gt 100000000 ]; then
        log_info "✓ Debian ISO already exists, skipping download"
        return 0
    fi
    # Use detected ISO variables
    log_info "Will use: $DEBIAN_ISO_NAME"
    log_info "Debian ISO not found. Downloading..."
    log_info "Downloading Debian ${DEBIAN_VERSION} AMD64 netinst ISO..."
    log_info "Source: $DEBIAN_ISO_URL"
    log_info "This may take several minutes depending on your connection..."
    echo ""
    # Download with progress
    wget --progress=bar:force \
         --output-document="$iso_path" \
         "$DEBIAN_ISO_URL" || {
        log_error "Failed to download Debian ISO"
        exit 1
    }
    echo ""
    log_info "✓ Debian ISO downloaded successfully"
    log_info "ISO saved to: $iso_path"
    log_info "File size: $(du -h "$iso_path" | cut -f1)"
}

################################################################################
# Phase 2: Extract ISO Contents
################################################################################

extract_iso() {
    log_info "Extracting Debian ISO contents..."
    
    local iso_path="$BUILD_DIR/$DEBIAN_ISO_NAME"
    
    # Create directories
    mkdir -p "$ISO_EXTRACT_DIR"
    
    log_info "Creating extraction directory..."
    
    # Try to extract using bsdtar (works in containers without loop device support)
    if command -v bsdtar &> /dev/null; then
        log_info "Extracting ISO contents using bsdtar (this may take a minute)..."
        bsdtar -xf "$iso_path" -C "$ISO_EXTRACT_DIR" || {
            log_error "Failed to extract ISO contents with bsdtar"
            exit 1
        }
    elif command -v 7z &> /dev/null; then
        log_info "Extracting ISO contents using 7z (this may take a minute)..."
        7z x "$iso_path" -o"$ISO_EXTRACT_DIR" -y > /dev/null || {
            log_error "Failed to extract ISO contents with 7z"
            exit 1
        }
    else
        # Fallback to traditional mount method
        log_info "Mounting ISO..."
        mkdir -p "$ISO_MOUNT_DIR"
        
        # Mount ISO
        mount -o loop "$iso_path" "$ISO_MOUNT_DIR" || {
            log_error "Failed to mount ISO"
            log_error "Try installing bsdtar or 7z for container-friendly extraction"
            exit 1
        }
        
        log_info "Copying ISO contents (this may take a minute)..."
        
        # Copy all contents
        rsync -a --info=progress2 "$ISO_MOUNT_DIR/" "$ISO_EXTRACT_DIR/" || {
            umount "$ISO_MOUNT_DIR"
            log_error "Failed to copy ISO contents"
            exit 1
        }
        
        # Unmount
        log_info "Unmounting ISO..."
        umount "$ISO_MOUNT_DIR"
        rmdir "$ISO_MOUNT_DIR"
    fi
    
    # Make extracted content writable
    chmod -R u+w "$ISO_EXTRACT_DIR"
    
    log_info "✓ ISO contents extracted successfully"
    log_info "Extracted to: $ISO_EXTRACT_DIR"
}

################################################################################
# Phase 3: Customize ISO
################################################################################

customize_iso() {
    log_info "Customizing ISO with preseed and IN1CLICK..."
    echo ""
    
    # Step 1: Copy preseed configuration
    log_info "Step 1: Adding preseed configuration..."
    if [ ! -f "$PRESEED_FILE" ]; then
        log_error "Preseed file not found: $PRESEED_FILE"
        exit 1
    fi
    
    cp "$PRESEED_FILE" "$ISO_EXTRACT_DIR/preseed.cfg"
    log_info "✓ Preseed file copied to ISO root"
    log_info "File: preseed.cfg ($(du -h "$PRESEED_FILE" | cut -f1))"
    verify_match "$PRESEED_FILE" "$ISO_EXTRACT_DIR/preseed.cfg" "preseed.cfg"
    echo ""
    
    # Step 2: Copy Heqet gate script
    log_info "Step 2: Adding Heqet gate script..."
    if [ ! -f "$GATE_SCRIPT" ]; then
        log_error "Heqet gate script not found: $GATE_SCRIPT"
        exit 1
    fi

    cp "$GATE_SCRIPT" "$ISO_EXTRACT_DIR/heqet-gate.sh"
    chmod +x "$ISO_EXTRACT_DIR/heqet-gate.sh"
    log_info "✓ Heqet gate script copied"
    verify_match "$GATE_SCRIPT" "$ISO_EXTRACT_DIR/heqet-gate.sh" "heqet-gate.sh"
    echo ""

    # Step 3: Copy IN1CLICK script
    log_info "Step 3: Adding IN1CLICK script..."
    if [ ! -f "$IN1CLICK_SCRIPT" ]; then
        log_error "IN1CLICK script not found: $IN1CLICK_SCRIPT"
        exit 1
    fi
    
    mkdir -p "$ISO_EXTRACT_DIR/in1click"
    cp "$IN1CLICK_SCRIPT" "$ISO_EXTRACT_DIR/in1click/IN1CLICK"
    
    # Copy diagnostics script if available
    if [ -f "$DIAGNOSTICS_SCRIPT" ]; then
        cp "$DIAGNOSTICS_SCRIPT" "$ISO_EXTRACT_DIR/in1click/diagnostics.sh"
    fi
    
    log_info "✓ IN1CLICK script copied"
    log_info "File: in1click/IN1CLICK ($(du -h "$IN1CLICK_SCRIPT" | cut -f1))"
    echo ""
    
    # Step 4: Configure BIOS boot (isolinux)
    log_info "Step 4: Configuring boot loader (BIOS/isolinux)..."
    configure_isolinux
    if [ -f "$CUSTOM_ISOLINUX_CFG" ] && [ -f "$ISO_EXTRACT_DIR/isolinux/isolinux.cfg" ]; then
        verify_match "$CUSTOM_ISOLINUX_CFG" "$ISO_EXTRACT_DIR/isolinux/isolinux.cfg" "isolinux.cfg"
    fi
    echo ""
    
    # Step 5: Configuring boot loader (UEFI/GRUB)
    log_info "Step 5: Configuring boot loader (UEFI/GRUB)..."
    configure_grub
    echo ""
    
    log_info "✓ ISO customization completed successfully"
}

validate_iso_contents() {
    local iso_path="$OUTPUT_DIR/$OUTPUT_NAME"
    local tmp_dir

    if ! command -v bsdtar >/dev/null 2>&1; then
        log_warn "bsdtar not found; skipping ISO content validation"
        return 0
    fi

    tmp_dir="$(mktemp -d)"
    bsdtar -xOf "$iso_path" heqet-gate.sh > "$tmp_dir/heqet-gate.sh" || true
    bsdtar -xOf "$iso_path" preseed.cfg > "$tmp_dir/preseed.cfg" || true
    bsdtar -xOf "$iso_path" isolinux/isolinux.cfg > "$tmp_dir/isolinux.cfg" || true

    verify_match "$GATE_SCRIPT" "$tmp_dir/heqet-gate.sh" "heqet-gate.sh (ISO)"
    verify_match "$PRESEED_FILE" "$tmp_dir/preseed.cfg" "preseed.cfg (ISO)"
    if [ -f "$CUSTOM_ISOLINUX_CFG" ]; then
        verify_match "$CUSTOM_ISOLINUX_CFG" "$tmp_dir/isolinux.cfg" "isolinux.cfg (ISO)"
    fi

    rm -rf "$tmp_dir"
    log_info "✓ ISO content validation passed"
}

configure_isolinux() {
    local isolinux_cfg="$ISO_EXTRACT_DIR/isolinux/isolinux.cfg"
    local custom_cfg="$CUSTOM_ISOLINUX_CFG"
    
    if [ ! -f "$isolinux_cfg" ]; then
        log_warn "isolinux.cfg not found, skipping BIOS boot configuration"
        return 0
    fi
    
    log_info "Backing up original isolinux.cfg..."
    cp "$isolinux_cfg" "${isolinux_cfg}.backup"

    if [ -f "$custom_cfg" ]; then
        log_info "Applying custom isolinux.cfg..."
        cp "$custom_cfg" "$isolinux_cfg"
        log_info "✓ Custom isolinux configuration applied"
    else
        log_warn "Custom isolinux.cfg not found at $custom_cfg; keeping default"
    fi
}

configure_grub() {
    local grub_cfg="$ISO_EXTRACT_DIR/boot/grub/grub.cfg"
    
    if [ ! -f "$grub_cfg" ]; then
        log_warn "grub.cfg not found, skipping UEFI boot configuration"
        return 0
    fi
    
    log_info "Backing up original grub.cfg..."
    cp "$grub_cfg" "${grub_cfg}.backup"
    
    log_info "Modifying GRUB menu..."
    
    # Add automated installation entry at the beginning
    cat > "${grub_cfg}.new" << 'EOF'
set timeout=-1
set default=0

menuentry 'Automated Installation (Heqet)' {
    set background_color=black
    linux    /install.amd/vmlinuz auto=true priority=critical preseed/file=/cdrom/preseed.cfg file=/cdrom/preseed.cfg console=tty1 DEBIAN_FRONTEND=text debian-installer/framebuffer=false nosplash
    initrd   /install.amd/initrd.gz
}

EOF
    
    # Append original content (skip first few lines if they set timeout/default)
    sed '/^set timeout=/d; /^set default=/d' "$grub_cfg" >> "${grub_cfg}.new"
    
    mv "${grub_cfg}.new" "$grub_cfg"
    
    log_info "✓ GRUB configuration updated"
    log_info "- Auto-install entry added"
    log_info "- Preseed parameters configured"
}

################################################################################
# Phase 4: Generate Final ISO
################################################################################

generate_iso() {
    log_info "Generating custom ISO image..."
    log_info "This may take several minutes..."
    echo ""
    
    local output_iso="$OUTPUT_DIR/$OUTPUT_NAME"
    local xorriso_log="$LOGS_DIR/xorriso.log"
    
    # Generate MD5 sums for the ISO
    log_info "Updating MD5 checksums..."
    cd "$ISO_EXTRACT_DIR"
    find . -type f -not -path './isolinux/*' -not -path './md5sum.txt' -print0 | xargs -0 md5sum > md5sum.txt 2>/dev/null || true
    cd "$SCRIPT_DIR"
    
    # Create ISO using xorriso
    xorriso -as mkisofs \
        -r -V "$ISO_LABEL" \
        -o "$output_iso" \
        -J -joliet-long \
        -cache-inodes \
        -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -boot-load-size 4 \
        -boot-info-table \
        -no-emul-boot \
        -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        -isohybrid-apm-hfsplus \
        "$ISO_EXTRACT_DIR" \
        > "$xorriso_log" 2>&1 || {
        log_error "Failed to create ISO image"
        log_error "Check log file: $xorriso_log"
        exit 1
    }
    
    log_info "✓ ISO image created successfully"
    echo ""
    
    # Generate checksums
    log_info "Calculating SHA256 and MD5 checksums..."
    cd "$OUTPUT_DIR"
    sha256sum "$OUTPUT_NAME" > "${OUTPUT_NAME}.sha256"
    md5sum "$OUTPUT_NAME" > "${OUTPUT_NAME}.md5"
    local checksum_sha256=$(cut -d' ' -f1 "${OUTPUT_NAME}.sha256")
    local checksum_md5=$(cut -d' ' -f1 "${OUTPUT_NAME}.md5")
    log_info "✓ Checksums calculated"
    log_info "SHA256: $checksum_sha256"
    log_info "MD5:    $checksum_md5"
    log_info "SHA256 file: $OUTPUT_DIR/${OUTPUT_NAME}.sha256"
    log_info "MD5 file:    $OUTPUT_DIR/${OUTPUT_NAME}.md5"
}

################################################################################
# Main Build Process
################################################################################

main() {
    local start_time=$(date +%s)
    
    print_header
    
    log_info "Starting Debian 12 ISO build with IN1CLICK integration..."
    
    # Prerequisites
    check_root
    check_dependencies
    setup_directories
    cleanup_previous_build
    
    # Detect latest Debian ISO version
    detect_latest_debian_iso
    
    # Phase 1: Download
    download_debian_iso
    
    # Phase 2: Extract
    extract_iso
    
    # Phase 3: Customize
    customize_iso
    
    # Phase 4: Generate
    generate_iso

    # Validate ISO contents match sources
    validate_iso_contents

    # Remove extraction directory to avoid stale build copies
    log_info "Cleaning extraction directory..."
    rm -rf "$ISO_EXTRACT_DIR"
    log_info "✓ Extraction directory removed"
    
    # Calculate build time
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    # Success message
    print_success
    
    log_info "Build Summary:"
    log_info "────────────────────────────────────────────"
    log_info "Custom ISO: $OUTPUT_DIR/$OUTPUT_NAME"
    log_info "File size: $(du -h "$OUTPUT_DIR/$OUTPUT_NAME" | cut -f1)"
    log_info "Checksum: $OUTPUT_DIR/${OUTPUT_NAME}.sha256"
    log_info "Build logs: $LOGS_DIR/"
    echo ""
    log_info "Total build time: ${minutes} minutes ${seconds} seconds"
    echo ""
    log_info "Next Steps:"
    log_info "  1. Verify build artifacts (check file size and checksum)"
    log_info "  2. Download ISO from Codespaces or test locally"
    log_info "  3. Test ISO in a VM or write to USB"
    log_info "  4. Clean up temporary files if needed"
    echo ""
    log_info "Root password: generated at install time by Heqet gate"
    log_info "SHA256 file: $OUTPUT_DIR/${OUTPUT_NAME}.sha256"
    
    print_success
}

# Run main function
main "$@"
