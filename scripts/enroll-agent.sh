#!/bin/bash
# =============================================================================
# enroll-agent.sh — Wazuh Linux Agent Enrollment Script
# Usage: sudo bash enroll-agent.sh <MANAGER_IP>
# Run this on the AGENT machine, not the manager.
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

MANAGER_IP="${1:-}"

if [[ -z "$MANAGER_IP" ]]; then
    log_error "Usage: sudo bash enroll-agent.sh <MANAGER_IP>"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    log_error "Run as root: sudo bash $0 $MANAGER_IP"
    exit 1
fi

# Test connectivity
log_info "Testing connectivity to Manager at $MANAGER_IP:1514..."
if ! nc -zv "$MANAGER_IP" 1514 2>/dev/null; then
    log_error "Cannot reach $MANAGER_IP on port 1514."
    log_error "Ensure the Manager firewall allows port 1514/TCP."
    exit 1
fi
log_info "Connectivity OK ✓"

# Add Wazuh repository
log_info "Adding Wazuh repository..."
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | \
    gpg --no-default-keyring \
    --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg \
    --import
chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] \
    https://packages.wazuh.com/4.x/apt/ stable main" | \
    tee /etc/apt/sources.list.d/wazuh.list > /dev/null

apt-get update -qq

# Install agent
log_info "Installing Wazuh agent (Manager: $MANAGER_IP)..."
WAZUH_MANAGER="$MANAGER_IP" apt-get install wazuh-agent -y

# Start agent
log_info "Starting Wazuh agent..."
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

sleep 3

if systemctl is-active --quiet wazuh-agent; then
    log_info "Wazuh agent is Active ✓"
    log_info "Check the Manager dashboard to confirm enrollment."
    log_info "Manager command: sudo /var/ossec/bin/agent_control -l"
else
    log_error "Agent failed to start. Check: sudo journalctl -u wazuh-agent -n 50"
fi
