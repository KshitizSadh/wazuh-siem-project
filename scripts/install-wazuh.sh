#!/bin/bash
# =============================================================================
# install-wazuh.sh — Automated Wazuh All-in-One Installation Script
# Author: Kshitiz
# Description: Downloads and runs the official Wazuh installation script
#              with pre-flight checks for system requirements.
# Usage: sudo bash install-wazuh.sh
# =============================================================================

set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Logging ---
log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================

log_section "Pre-flight Checks"

# Check root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root. Use: sudo bash $0"
   exit 1
fi
log_info "Running as root ✓"

# Check OS
if ! grep -q "Ubuntu 22.04" /etc/os-release 2>/dev/null; then
    log_warn "This script is tested on Ubuntu 22.04 LTS. Your OS may differ."
fi

# Check RAM
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
if [ "$TOTAL_RAM" -lt 3800 ]; then
    log_error "Insufficient RAM: ${TOTAL_RAM}MB detected. Wazuh requires at least 4GB."
    log_error "The Wazuh Indexer (OpenSearch) will crash with less than 4GB RAM."
    exit 1
fi
log_info "RAM: ${TOTAL_RAM}MB ✓"

# Check disk space
FREE_DISK=$(df -BG / | awk 'NR==2{print $4}' | tr -d 'G')
if [ "$FREE_DISK" -lt 20 ]; then
    log_error "Insufficient disk space: ${FREE_DISK}GB free. Need at least 20GB."
    exit 1
fi
log_info "Disk space: ${FREE_DISK}GB free ✓"

# Check internet
if ! curl -s --connect-timeout 5 https://packages.wazuh.com > /dev/null; then
    log_error "Cannot reach packages.wazuh.com. Check your internet connection."
    exit 1
fi
log_info "Internet connectivity ✓"

# =============================================================================
# SYSTEM PREPARATION
# =============================================================================

log_section "System Preparation"

log_info "Updating package lists..."
apt-get update -qq

log_info "Disabling swap (required for Wazuh Indexer)..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
log_info "Swap disabled ✓"

log_info "Configuring firewall..."
ufw --force enable
ufw allow ssh
ufw allow 443/tcp
ufw allow 1514/tcp
ufw allow 1515/tcp
ufw allow 9200/tcp
ufw reload
log_info "Firewall configured ✓"

# =============================================================================
# WAZUH INSTALLATION
# =============================================================================

log_section "Wazuh Installation"

log_info "Downloading Wazuh installation script..."
curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh
chmod +x wazuh-install.sh
log_info "Download complete ✓"

log_info "Starting Wazuh all-in-one installation..."
log_info "This will take 10-20 minutes. Please wait..."
bash wazuh-install.sh -a 2>&1 | tee /tmp/wazuh-install.log

# =============================================================================
# POST-INSTALLATION VERIFICATION
# =============================================================================

log_section "Post-Installation Verification"

sleep 10  # Wait for services to stabilize

SERVICES=("wazuh-manager" "wazuh-indexer" "wazuh-dashboard")
ALL_OK=true

for SERVICE in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$SERVICE"; then
        log_info "$SERVICE: Active ✓"
    else
        log_error "$SERVICE: FAILED ✗"
        ALL_OK=false
    fi
done

if [ "$ALL_OK" = true ]; then
    SERVER_IP=$(hostname -I | awk '{print $1}')
    log_section "Installation Complete!"
    log_info "Dashboard URL: https://${SERVER_IP}"
    log_info "Username:      admin"
    log_info "Password:      (see above — save it now!)"
    log_info ""
    log_info "Next step: Enroll agents using enroll-agent.sh"
else
    log_error "One or more services failed. Check /tmp/wazuh-install.log"
    log_error "Common fix: Ensure at least 4GB RAM is available"
fi
