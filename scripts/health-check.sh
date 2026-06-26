#!/bin/bash
# =============================================================================
# health-check.sh — Verify all Wazuh components are healthy
# Run on the MANAGER machine.
# =============================================================================

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
PASS="${GREEN}[PASS]${NC}"; FAIL="${RED}[FAIL]${NC}"; WARN="${YELLOW}[WARN]${NC}"

echo "============================================"
echo "  Wazuh Health Check — $(date)"
echo "============================================"

# Services
echo -e "\n--- Services ---"
for SVC in wazuh-manager wazuh-indexer wazuh-dashboard filebeat; do
    if systemctl is-active --quiet "$SVC" 2>/dev/null; then
        echo -e "$PASS $SVC"
    else
        echo -e "$FAIL $SVC (not running)"
    fi
done

# Agents
echo -e "\n--- Agents ---"
if command -v /var/ossec/bin/agent_control &>/dev/null; then
    ACTIVE=$(sudo /var/ossec/bin/agent_control -l 2>/dev/null | grep -c "Active" || echo 0)
    TOTAL=$(sudo /var/ossec/bin/agent_control -l 2>/dev/null | grep -c "ID:" || echo 0)
    echo -e "$PASS Agents: $ACTIVE/$TOTAL Active"
fi

# Indexer health
echo -e "\n--- Indexer ---"
HEALTH=$(curl -s -k -u admin:$(grep "password" /etc/filebeat/filebeat.yml 2>/dev/null | head -1 | awk '{print $2}') \
    https://localhost:9200/_cluster/health 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','unknown'))" 2>/dev/null || echo "unreachable")
if [ "$HEALTH" = "green" ]; then
    echo -e "$PASS Indexer cluster: green"
elif [ "$HEALTH" = "yellow" ]; then
    echo -e "$WARN Indexer cluster: yellow (single-node is normal)"
else
    echo -e "$FAIL Indexer cluster: $HEALTH"
fi

# Disk space
echo -e "\n--- Disk ---"
DISK=$(df -h /var/lib/wazuh-indexer 2>/dev/null | awk 'NR==2{print $5}' | tr -d '%')
if [ -n "$DISK" ] && [ "$DISK" -lt 80 ]; then
    echo -e "$PASS Indexer disk usage: ${DISK}%"
elif [ -n "$DISK" ]; then
    echo -e "$WARN Indexer disk usage: ${DISK}% (consider cleanup)"
fi

# RAM
echo -e "\n--- Memory ---"
AVAIL=$(free -m | awk '/^Mem:/{print $7}')
echo -e "$PASS Available RAM: ${AVAIL}MB"

# Recent alerts
echo -e "\n--- Recent Alerts (last 5) ---"
sudo tail -5 /var/ossec/logs/alerts/alerts.json 2>/dev/null | \
    python3 -c "
import sys, json
for line in sys.stdin:
    try:
        a = json.loads(line)
        print(f\"  [{a['rule']['level']:>2}] {a['rule']['description'][:60]}\")
    except: pass
" 2>/dev/null || echo "  (no recent alerts or alerts.json not found)"

echo ""
echo "============================================"
echo "  Server IP: $(hostname -I | awk '{print $1}')"
echo "  Dashboard:  https://$(hostname -I | awk '{print $1}')"
echo "============================================"
