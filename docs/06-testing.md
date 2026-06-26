# 🧪 06 — Testing & Alert Generation

> Generate real security alerts in your lab to validate the SIEM is working and to practice alert analysis.

---

## Why Test?

A SIEM with no alerts is not useful — and you cannot learn alert analysis without alerts to analyze. These tests are safe, controlled ways to generate meaningful security events in your lab.

> ⚠️ **Lab Only:** Perform these tests only in your own lab environment. Never run brute-force or intrusion tests against systems you do not own.

---

## Test 1: SSH Brute Force Detection

**What it tests:** Wazuh's ability to detect repeated authentication failures.

**Rules triggered:** 5710 (SSH auth failure), 5720 (Multiple failures — brute force)

**Expected alert level:** 10 (High)

### Method A: Using hydra (from a separate machine)

```bash
# Install hydra if not present
sudo apt-get install hydra -y

# Run a brute force against your agent's SSH
# Replace TARGET_IP with your agent's IP
hydra -l root -P /usr/share/wordlists/rockyou.txt ssh://TARGET_IP -t 4
```

### Method B: Manual failed logins (no extra tools needed)

```bash
# On the agent machine — intentionally fail SSH logins
# Run this 10 times rapidly to trigger the brute force rule
ssh invaliduser@localhost
# Enter wrong password when prompted
```

### Method C: Script to generate rapid failures

```bash
#!/bin/bash
# test-ssh-brute.sh
TARGET="localhost"
for i in {1..15}; do
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 \
        invaliduser@$TARGET echo "test" 2>/dev/null
    echo "Attempt $i sent"
    sleep 0.5
done
echo "Done — check Wazuh dashboard for rule 5720"
```

### Expected Alerts

| Rule | Level | Description |
|------|-------|-------------|
| 5710 | 5 | sshd: Authentication failed |
| 5711 | 5 | sshd: Failed login attempt |
| 5720 | 10 | sshd: Multiple authentication failures |

---

## Test 2: File Integrity Monitoring (FIM)

**What it tests:** Detection of unauthorized file modifications.

**Rules triggered:** 550 (file modified), 554 (new file), 553 (file deleted)

### 2.1 Create a New File in Monitored Directory

```bash
# Create a file in /etc (which is monitored)
sudo touch /etc/test-wazuh-fim.txt
echo "FIM test file" | sudo tee /etc/test-wazuh-fim.txt
```

**Expected alert:** Rule 554 — "File added to the system"

### 2.2 Modify a Critical File

```bash
# Add a comment to /etc/hosts (non-destructive)
echo "# Wazuh FIM test comment" | sudo tee -a /etc/hosts
```

**Expected alert:** Rule 550 — "Integrity checksum changed"

### 2.3 Simulate a Password File Change

```bash
# Add and remove a dummy entry to /etc/passwd
# WARNING: Be careful with /etc/passwd — only add a comment line
echo "# Wazuh FIM test" | sudo tee -a /etc/passwd
```

**Expected alert:** Rule 550 — Level 7 — "Integrity checksum changed"

### 2.4 Delete a Monitored File

```bash
# Remove the test file we created
sudo rm /etc/test-wazuh-fim.txt
```

**Expected alert:** Rule 553 — "File deleted"

### 2.5 Force an Immediate FIM Scan

```bash
# By default, FIM runs every 5 minutes
# Force an immediate scan:
sudo kill -SIGUSR2 $(pgrep wazuh-syscheckd)

# Alternatively, restart the agent to trigger a scan on startup
sudo systemctl restart wazuh-agent
```

---

## Test 3: Sudo Usage Detection

**What it tests:** Detection of privilege escalation via sudo.

**Rules triggered:** 5402 (sudo success), 5403 (sudo failure)

```bash
# On the agent — run commands with sudo (will generate audit logs)
sudo ls /root
sudo cat /etc/shadow  # This should fail unless you have permissions
sudo su -             # Switch to root
```

**Expected alerts:**

| Rule | Level | Description |
|------|-------|-------------|
| 5402 | 3 | PAM: Login session opened |
| 5403 | 5 | sudo: failed attempt |

---

## Test 4: New User Creation

**What it tests:** Detecting unauthorized account creation — a key indicator of compromise.

**Rules triggered:** 5901 (new user added)

```bash
# Create a test user (then delete it)
sudo useradd -m testuser-wazuh

# Verify the alert appeared in the dashboard, then clean up
sudo userdel -r testuser-wazuh
```

**Expected alert:** Rule 5901 — Level 8 — "New user added to the system"

---

## Test 5: Rootkit Check

**What it tests:** Wazuh's rootkit detection module.

```bash
# Trigger a manual rootkit scan
sudo /var/ossec/bin/wazuh-rootcheck

# View rootcheck results
sudo cat /var/ossec/logs/rootcheck.log
```

---

## Test 6: Port Scan Detection

**What it tests:** Detection of network reconnaissance.

**From a separate machine, run an Nmap scan against the agent:**

```bash
# Install nmap
sudo apt-get install nmap -y

# Run a port scan against the agent
nmap -sS -p 1-1000 TARGET_AGENT_IP

# More aggressive scan
nmap -A TARGET_AGENT_IP
```

> Note: Wazuh alone may not detect port scans without additional configuration. This test works better when combined with a host-based firewall (iptables) that logs dropped packets.

---

## Viewing Results in the Dashboard

After running any test:

1. Open the Wazuh Dashboard: `https://<SERVER-IP>`
2. Go to **Security Events**
3. Select the relevant agent
4. Set time range to **Last 15 minutes**
5. Look for the alert in the feed

**To watch alerts in real-time from the CLI:**

```bash
# Stream all new alerts as JSON
sudo tail -f /var/ossec/logs/alerts/alerts.json | python3 -m json.tool

# Filter for just the rule ID you are testing
sudo tail -f /var/ossec/logs/alerts/alerts.json | grep "5720"

# Pretty print each alert as it arrives
sudo tail -f /var/ossec/logs/alerts/alerts.json | \
  python3 -c "
import sys, json
for line in sys.stdin:
    try:
        alert = json.loads(line)
        print(f\"[{alert['rule']['level']}] {alert['rule']['description']} - {alert.get('agent',{}).get('name','manager')}\")
    except: pass
"
```

---

## Alert Validation Checklist

| Test | Alert Generated | Rule ID | Level | ✓ |
|------|----------------|---------|-------|---|
| SSH failed login (single) | sshd auth failure | 5710 | 5 | ☐ |
| SSH brute force (10+ fails) | Multiple auth failures | 5720 | 10 | ☐ |
| New file in /etc | File added to system | 554 | 5 | ☐ |
| File modified in /etc | Integrity checksum changed | 550 | 7 | ☐ |
| File deleted | File deleted | 553 | 7 | ☐ |
| New user created | New user added | 5901 | 8 | ☐ |
| Sudo used | sudo command used | 5402 | 3 | ☐ |

---

## Clean Up After Testing

```bash
# Remove test files
sudo rm -f /etc/test-wazuh-fim.txt

# Remove test users
sudo userdel -r testuser-wazuh 2>/dev/null

# Clean up /etc/hosts if you modified it
sudo sed -i '/Wazuh FIM test/d' /etc/hosts

# Clean up /etc/passwd if you modified it
sudo sed -i '/Wazuh FIM test/d' /etc/passwd
```

---

*Previous: [Usage ←](05-usage.md) | Next: [Troubleshooting →](07-troubleshooting.md)*
