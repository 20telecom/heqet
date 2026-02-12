#!/bin/bash
#
# ISO Testing and Validation Script
# Tests the custom Debian 12 ISO in QEMU
#
# Usage: ./test-iso.sh [path-to-iso]
#
# Requirements:
#   - qemu-system-x86_64
#   - At least 2GB RAM allocated to VM
#   - VNC client (optional, for GUI monitoring)

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
WORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${WORK_DIR}/logs"
VM_NAME="debian-freepbx-test"
VM_DISK="${WORK_DIR}/build/${VM_NAME}.qcow2"
VM_MEMORY="2048"
VM_CORES="2"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

# Check if QEMU is installed
check_qemu() {
    if ! command -v qemu-system-x86_64 &> /dev/null; then
        log_error "qemu-system-x86_64 not found. Please install QEMU."
        log_info "On Debian/Ubuntu: sudo apt-get install qemu-system-x86"
        exit 1
    fi
    log "QEMU is installed."
}

# Check if ISO file exists
check_iso() {
    local iso_file="$1"
    
    if [[ ! -f "$iso_file" ]]; then
        log_error "ISO file not found: $iso_file"
        exit 1
    fi
    
    log "ISO file found: $iso_file"
}

# Create virtual disk
create_disk() {
    log "Creating virtual disk (20GB)..."
    
    if [[ -f "$VM_DISK" ]]; then
        log_warn "Virtual disk already exists. Removing..."
        rm -f "$VM_DISK"
    fi
    
    qemu-img create -f qcow2 "$VM_DISK" 20G > /dev/null 2>&1
    
    log "Virtual disk created: $VM_DISK"
}

# Start VM with ISO
start_vm() {
    local iso_file="$1"
    local vnc_port=":1"
    
    log "Starting VM with ISO..."
    log_info "VM Name: $VM_NAME"
    log_info "Memory: ${VM_MEMORY}MB"
    log_info "CPU Cores: $VM_CORES"
    log_info "VNC Display: $vnc_port (localhost:5901)"
    log_info "Serial console log: ${LOG_DIR}/vm-serial.log"
    
    mkdir -p "$LOG_DIR"
    
    # Start QEMU in background
    nohup qemu-system-x86_64 \
        -name "$VM_NAME" \
        -m "$VM_MEMORY" \
        -smp "$VM_CORES" \
        -drive file="$VM_DISK",format=qcow2 \
        -cdrom "$iso_file" \
        -boot d \
        -vnc "$vnc_port" \
        -serial file:"${LOG_DIR}/vm-serial.log" \
        -net nic,model=virtio \
        -net user,hostfwd=tcp::8080-:80,hostfwd=tcp::2222-:22 \
        > "${LOG_DIR}/qemu.log" 2>&1 &
    
    local qemu_pid=$!
    echo "$qemu_pid" > "${LOG_DIR}/qemu.pid"
    
    log "VM started with PID: $qemu_pid"
    log_info "Web forwarding: localhost:8080 -> VM:80 (FreePBX GUI)"
    log_info "SSH forwarding: localhost:2222 -> VM:22"
    echo ""
    log "${YELLOW}Monitor installation:${NC}"
    echo "  1. VNC: Connect to localhost:5901 with a VNC client"
    echo "  2. Serial: tail -f ${LOG_DIR}/vm-serial.log"
    echo "  3. QEMU log: tail -f ${LOG_DIR}/qemu.log"
    echo ""
    log_info "To stop VM: kill $qemu_pid or run: kill \$(cat ${LOG_DIR}/qemu.pid)"
    echo ""
    log "${GREEN}Installation is automated and will take 15-30 minutes.${NC}"
    log_info "After reboot, IN1CLICK will run automatically."
    log_info "Access FreePBX at: http://localhost:8080 (after installation completes)"
}

# Monitor installation progress
monitor_install() {
    log "Monitoring installation progress..."
    log_info "Press Ctrl+C to stop monitoring (VM will continue running)"
    echo ""
    
    sleep 5
    
    # Follow serial log
    if [[ -f "${LOG_DIR}/vm-serial.log" ]]; then
        tail -f "${LOG_DIR}/vm-serial.log" || true
    else
        log_warn "Serial log not available yet. VM is starting..."
        sleep 10
        if [[ -f "${LOG_DIR}/vm-serial.log" ]]; then
            tail -f "${LOG_DIR}/vm-serial.log" || true
        fi
    fi
}

# Print usage
usage() {
    echo "Usage: $0 [OPTIONS] [ISO_FILE]"
    echo ""
    echo "Test Debian 12 custom ISO in QEMU VM"
    echo ""
    echo "Options:"
    echo "  -h, --help       Show this help message"
    echo "  -m, --monitor    Start VM and monitor installation"
    echo "  -s, --stop       Stop running VM"
    echo ""
    echo "Examples:"
    echo "  $0 output/debian-12-freepbx-auto-20260115.iso"
    echo "  $0 -m output/debian-12-freepbx-auto-20260115.iso"
    echo "  $0 -s"
    echo ""
}

# Stop VM
stop_vm() {
    if [[ -f "${LOG_DIR}/qemu.pid" ]]; then
        local pid
        pid=$(cat "${LOG_DIR}/qemu.pid")
        
        if ps -p "$pid" > /dev/null 2>&1; then
            log "Stopping VM (PID: $pid)..."
            kill "$pid"
            sleep 2
            
            if ps -p "$pid" > /dev/null 2>&1; then
                log_warn "VM still running, forcing shutdown..."
                kill -9 "$pid"
            fi
            
            rm -f "${LOG_DIR}/qemu.pid"
            log "VM stopped."
        else
            log_warn "VM is not running (PID $pid not found)"
            rm -f "${LOG_DIR}/qemu.pid"
        fi
    else
        log_warn "No PID file found. VM may not be running."
    fi
}

# Main
main() {
    local iso_file=""
    local monitor=false
    local should_stop=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -m|--monitor)
                monitor=true
                shift
                ;;
            -s|--stop)
                should_stop=true
                shift
                ;;
            *)
                iso_file="$1"
                shift
                ;;
        esac
    done
    
    # Handle stop command
    if [[ "$should_stop" == true ]]; then
        stop_vm
        exit 0
    fi
    
    # Validate ISO file
    if [[ -z "$iso_file" ]]; then
        # Try to find latest ISO in output directory
        iso_file=$(find "${WORK_DIR}/output" -name "*.iso" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | awk '{print $2}')
        
        if [[ -z "$iso_file" ]]; then
            log_error "No ISO file specified and none found in output directory."
            usage
            exit 1
        fi
        
        log_info "Using latest ISO: $iso_file"
    fi
    
    check_qemu
    check_iso "$iso_file"
    create_disk
    start_vm "$iso_file"
    
    if [[ "$monitor" == true ]]; then
        monitor_install
    fi
}

main "$@"
