# 🔧 07 — Troubleshooting

> Systematic fixes for every common Wazuh problem. Start with the diagnosis commands, then apply the fix.

---

## General Diagnostic Commands

Run these first to understand what is happening:

```bash
# Check all Wazuh service statuses at once
sudo systemctl status wazuh-manager wazuh-indexer wazuh-dashboard

# Check Manager logs for errors
sudo tail -100 /var/ossec/logs/ossec.log | grep -i "error\|warning\|critical"

# Check Indexer health
curl -k -u admin:PASSWORD https://localhost:9200/_cluster/health?pretty

# Check Dashboard logs
sudo journalctl -u wazuh-dashboard -n 50

# List all agents and their status
sudo /var/ossec/bin/agent_control -l

# Check available disk space (Indexer fills up fast)
df -h /var/lib/wazuh-indexer

# Check RAM usage
free -h
```

---

## Problem 1: Agent Shows "Never Connected" or "Disconnected"

**Symptoms:**
- Agent appears in the dashboard but shows red status
- `agent_control -l` shows "Disconnected" or "Never Connected"

**Diagnosis:**

```bash
# On the AGENT machine — check agent service status
sudo systemctl status wazuh-agent

# Check the agent log for connection errors
sudo tail -50 /var/ossec/logs/ossec.log

# Test connectivity to Manager on port 1514
nc -zv MANAGER_IP 1514

# Check if firewall is blocking
sudo ufw status
```

**Fix A — Firewall blocking port 1514:**

```bash
# On the MANAGER machine
sudo ufw allow 1514/tcp
sudo ufw reload

# On the AGENT machine — test again
nc -zv MANAGER_IP 1514
# Should output: "Connection to MANAGER_IP 1514 port [tcp/*] succeeded!"
```

**Fix B — Wrong Manager IP in agent config:**

```bash
# On the AGENT machine — check the configured Manager IP
grep -A5 "<server>" /var/ossec/etc/ossec.conf

# If wrong, edit it
sudo nano /var/ossec/etc/ossec.conf
# Change <address>WRONG_IP</address> to <address>CORRECT_IP</address>

# Restart the agent
sudo systemctl restart wazuh-agent
```

**Fix C — Agent key mismatch (corrupted enrollment):**

```bash
# Re-enroll the agent from scratch

# On MANAGER — remove the old agent
sudo /var/ossec/bin/manage_agents
# Press 'r' to remove, enter agent ID

# On AGENT — remove local keys and re-install
sudo systemctl stop wazuh-agent
sudo rm /var/ossec/etc/client.keys
sudo rm /var/ossec/etc/ossec.conf

# Re-install with manager IP
sudo WAZUH_MANAGER="MANAGER_IP" apt-get install --reinstall wazuh-agent
sudo systemctl start wazuh-agent
```

---

## Problem 2: Dashboard Not Loading (HTTPS Timeout)

**Symptoms:**
- Browser shows "Connection timed out" or "Connection refused"
- `https://SERVER_IP` does not load

**Diagnosis:**

```bash
# Check if the dashboard service is running
sudo systemctl status wazuh-dashboard

# Check which port the dashboard is on
sudo ss -tlnp | grep 443

# Check dashboard logs
sudo journalctl -u wazuh-dashboard -n 100
```

**Fix A — Service is stopped:**

```bash
sudo systemctl start wazuh-dashboard
sudo systemctl enable wazuh-dashboard
```

**Fix B — Port 443 blocked by firewall:**

```bash
sudo ufw allow 443/tcp
sudo ufw reload
```

**Fix C — Dashboard config points to wrong Indexer:**

```bash
sudo nano /etc/wazuh-dashboard/opensearch_dashboards.yml

# Verify this line points to your Indexer (usually localhost)
opensearch.hosts: ["https://localhost:9200"]

# Save and restart
sudo systemctl restart wazuh-dashboard
```

---

## Problem 3: Wazuh Indexer Crashing or Not Starting

**Symptoms:**
- No data showing in the Dashboard
- `systemctl status wazuh-indexer` shows `failed`
- Dashboard shows "No results" or "Index not found"

**This is almost always a RAM issue.**

**Diagnosis:**

```bash
# Check current memory usage
free -h

# Check Indexer service logs
sudo journalctl -u wazuh-indexer -n 100 | grep -i "error\|exception\|heap"

# Check if Indexer process exists
ps aux | grep opensearch
```

**Fix A — Not enough RAM (most common cause):**

The Wazuh Indexer requires at least **4 GB of RAM**. If the system has less, the JVM will crash.

```bash
# Check current JVM heap allocation
grep -i "heap" /etc/wazuh-indexer/jvm.options

# Reduce heap size if system RAM is limited (e.g., for a 4GB system)
sudo nano /etc/wazuh-indexer/jvm.options
# Change:
# -Xms2g
# -Xmx2g
# To:
# -Xms1g
# -Xmx1g

sudo systemctl restart wazuh-indexer
```

**Fix B — Disk is full:**

```bash
# Check disk usage
df -h

# Check how much Wazuh Indexer data is using
du -sh /var/lib/wazuh-indexer/

# Delete old indices (dangerous — data loss!)
# Only do this if you understand the implications
curl -k -u admin:PASSWORD -X DELETE \
  "https://localhost:9200/wazuh-alerts-4.x-2024.01.01"
```

---

## Problem 4: No Alerts Appearing in Dashboard

**Symptoms:**
- Agents are connected (Active status)
- But the Security Events dashboard shows no data

**Diagnosis:**

```bash
# Check if alerts are being written to the local file
sudo tail -f /var/ossec/logs/alerts/alerts.json

# Check Filebeat status (it forwards alerts to Indexer)
sudo systemctl status filebeat

# Check Filebeat logs for errors
sudo tail -50 /var/log/filebeat/filebeat

# Check if Indexer has any data
curl -k -u admin:PASSWORD https://localhost:9200/_cat/indices | grep wazuh
```

**Fix A — Filebeat is not running:**

```bash
sudo systemctl start filebeat
sudo systemctl enable filebeat
```

**Fix B — Filebeat cannot reach Indexer:**

```bash
sudo nano /etc/filebeat/filebeat.yml

# Verify the output section:
output.opensearch:
  hosts: ["https://localhost:9200"]
  username: "admin"
  password: "YOUR_PASSWORD"

# Restart Filebeat
sudo systemctl restart filebeat
```

**Fix C — Wait longer:**

After agents connect, there may be a 2–5 minute delay before alerts appear in the Dashboard. If the system was just installed, give it time.

---

## Problem 5: `apt-get install wazuh-agent` Fails with GPG Error

**Symptoms:**

```
W: GPG error: https://packages.wazuh.com ... The following signatures couldn't be verified
E: The repository 'https://packages.wazuh.com ... Release' is not signed
```

**Fix:**

```bash
# Re-import the GPG key
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | \
  gpg --no-default-keyring \
  --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg \
  --import

chmod 644 /usr/share/keyrings/wazuh.gpg

# Update package lists
sudo apt-get update

# Retry installation
sudo WAZUH_MANAGER="MANAGER_IP" apt-get install wazuh-agent -y
```

---

## Problem 6: Wazuh Manager Fails to Start After Config Edit

**Symptoms:**
- Manager was working, you edited `ossec.conf`, now it fails to start

**Diagnosis:**

```bash
# Check the Manager log for config errors
sudo tail -50 /var/ossec/logs/ossec.log

# Validate your configuration syntax
sudo /var/ossec/bin/verify-agent-conf

# Test rules for syntax errors
sudo /var/ossec/bin/wazuh-logtest
```

**Fix:**

The error message in `ossec.log` will point to the exact line number in `ossec.conf` that has a problem. Common issues:

- Unclosed XML tags (`<directories>` without `</directories>`)
- Invalid characters in rule descriptions
- Referencing a non-existent file path in `<localfile>`

```bash
# Restore a backup if you have one
sudo cp /var/ossec/etc/ossec.conf.backup /var/ossec/etc/ossec.conf
sudo systemctl restart wazuh-manager
```

---

## Log File Reference

| Log File | What It Contains |
|----------|-----------------|
| `/var/ossec/logs/ossec.log` | Manager operational logs, errors |
| `/var/ossec/logs/alerts/alerts.json` | All generated alerts (JSON) |
| `/var/ossec/logs/alerts/alerts.log` | All generated alerts (plain text) |
| `/var/ossec/logs/rootcheck.log` | Rootkit check results |
| `/var/log/filebeat/filebeat` | Filebeat forwarding logs |
| `/var/log/wazuh-indexer/` | Indexer/OpenSearch logs |
| `/var/log/wazuh-dashboard/` | Dashboard logs |

---

*Previous: [Testing ←](06-testing.md) | Next: [FAQ →](08-faq.md)*
