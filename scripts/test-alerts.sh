#!/bin/bash
# =============================================================================
# test-alerts.sh — Generate test security alerts for Wazuh validation
# Run on an AGENT machine to trigger alerts visible in the dashboard.
# =============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_section() { echo -e "\n${YELLOW}>>> $1${NC}"; }

# ── Test 1: SSH Brute Force ────────────────────────────────────────────────
log_section "Test 1: SSH Brute Force (Rule 5720 — Level 10)"
log_info "Sending 12 failed SSH login attempts..."
for i in {1..12}; do
    ssh -o StrictHostKeyChecking=no \
        -o ConnectTimeout=1 \
        -o PasswordAuthentication=no \
        invaliduser123@localhost 2>/dev/null || true
    sleep 0.3
done
log_info "Done. Watch for rule 5720 in the dashboard."

# ── Test 2: FIM — Create File ─────────────────────────────────────────────
log_section "Test 2: FIM — Create file in /etc (Rule 554)"
TESTFILE="/etc/wazuh-fim-test-$(date +%s).txt"
echo "FIM test — $(date)" | sudo tee "$TESTFILE" > /dev/null
log_info "Created: $TESTFILE — Watch for rule 554."

sleep 2

# ── Test 3: FIM — Modify File ─────────────────────────────────────────────
log_section "Test 3: FIM — Modify file (Rule 550)"
echo "Modified — $(date)" | sudo tee -a "$TESTFILE" > /dev/null
log_info "Modified: $TESTFILE — Watch for rule 550."

sleep 2

# ── Test 4: FIM — Delete File ─────────────────────────────────────────────
log_section "Test 4: FIM — Delete file (Rule 553)"
sudo rm -f "$TESTFILE"
log_info "Deleted: $TESTFILE — Watch for rule 553."

# ── Test 5: New User ──────────────────────────────────────────────────────
log_section "Test 5: New user creation (Rule 5901 — Level 8)"
if ! id "wazuh-test-user" &>/dev/null; then
    sudo useradd -m wazuh-test-user 2>/dev/null || true
    log_info "Created user wazuh-test-user — Watch for rule 5901."
    sleep 2
    sudo userdel -r wazuh-test-user 2>/dev/null || true
    log_info "Cleaned up test user."
fi

echo ""
log_info "All tests complete. Check the Wazuh Dashboard → Security Events."
log_info "Tip: Filter by 'Last 5 minutes' to see your test alerts."
