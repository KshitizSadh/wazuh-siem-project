# 📊 05 — Usage Guide

> A practical walkthrough of the Wazuh Dashboard — what each module does, where to find alerts, and how to navigate like a SOC analyst.

---

## Accessing the Dashboard

```
URL:      https://<YOUR-SERVER-IP>
Username: admin
Password: <password from installation>
```

Accept the self-signed certificate warning in your browser.

---

## Dashboard Overview

When you first log in, you see the **Wazuh Home** screen. The left sidebar contains all modules. Here is what each one does:

```
☰ MENU
│
├── 🏠 Home                   ← Overview of all agents and alert counts
│
├── 📊 Security Events         ← ⭐ Your main alert feed (use this most)
│
├── 🔒 Integrity Monitoring    ← File Integrity Monitoring (FIM) alerts
│
├── 🛡️ MITRE ATT&CK           ← Alerts mapped to ATT&CK techniques
│
├── 🔍 Vulnerability Detection ← CVE findings from installed packages
│
├── 📋 Compliance              ← PCI-DSS, HIPAA, GDPR, NIST checks
│
├── 🤖 Agents                 ← Manage and view all connected agents
│
├── 🔎 Threat Hunting          ← Advanced search and investigation
│
└── ⚙️  Management             ← Rules, decoders, groups, config
```

---

## Module 1: Security Events

**What it is:** The primary alert dashboard. Every security event that triggers a Wazuh rule appears here.

**How to use it:**

1. Click **Security Events** in the left menu
2. Select an **agent** from the top dropdown (or "All agents")
3. Set the **time range** (top right — try "Last 24 hours")
4. The dashboard loads with:
   - **Alert count over time** (bar chart)
   - **Top 5 rules** triggered
   - **Top 5 agents** generating alerts
   - **Alert severity distribution**

**Drill into an alert:**

1. Scroll down to the **Alerts** table
2. Click the **▶** arrow on any alert to expand it
3. You will see:
   - `rule.id` — The rule that fired
   - `rule.description` — What happened
   - `rule.level` — Severity (1–15)
   - `agent.name` — Which machine it came from
   - `data.srcip` — Source IP (for network events)
   - `full_log` — The raw log line that triggered the alert

**Filter alerts:**

- Click any value in the expanded alert to create a filter
- Example: Click on `rule.level: 7` to show only level 7 alerts
- Use the **KQL search bar** at the top for advanced queries:

```
# Show all SSH failures
rule.groups: "authentication_failed"

# Show all alerts from a specific agent
agent.name: "linux-agent"

# Show high-severity alerts only
rule.level >= 10

# Show FIM alerts
rule.groups: "syscheck"
```

---

## Module 2: Integrity Monitoring

**What it is:** Shows all File Integrity Monitoring (FIM) events — files that were added, modified, or deleted on monitored endpoints.

**How to use it:**

1. Click **Integrity Monitoring**
2. Select your agent
3. The dashboard shows:
   - **Events over time**
   - **Top modified files**
   - **Events by type** (added / modified / deleted)

**Investigating a FIM alert:**

Click any FIM event to see:

```json
{
  "syscheck.path": "/etc/passwd",
  "syscheck.event": "modified",
  "syscheck.size_before": "1832",
  "syscheck.size_after": "1856",
  "syscheck.sha256_before": "abc123...",
  "syscheck.sha256_after": "def456...",
  "syscheck.mtime_after": "2024-01-15T10:23:45",
  "syscheck.uname_after": "root",
  "rule.description": "File modified."
}
```

This tells you exactly what changed, when, and what the file looked like before and after.

---

## Module 3: MITRE ATT&CK

**What it is:** Visualizes your alerts mapped to the MITRE ATT&CK framework tactics and techniques.

**Why it matters:** ATT&CK is the industry-standard taxonomy for describing attacker behavior. Being able to map alerts to ATT&CK shows security maturity.

**How to use it:**

1. Click **MITRE ATT&CK**
2. You will see a heat map of ATT&CK tactics (columns) vs techniques (rows)
3. Red/orange squares = techniques observed in your environment
4. Click any square to see the alerts that correspond to that technique

**Common techniques you will see in a lab:**

| ATT&CK ID | Technique | Common Trigger |
|-----------|-----------|----------------|
| T1110 | Brute Force | Failed SSH logins |
| T1078 | Valid Accounts | Successful logins |
| T1548 | Abuse Elevation Control | Sudo usage |
| T1070 | Indicator Removal | Log cleared |
| T1543 | Create/Modify System Process | New service created |

---

## Module 4: Agents

**What it is:** Shows all enrolled agents and their status.

**How to use it:**

1. Click **Agents**
2. You see a table with all agents: ID, name, IP, OS, version, status, last keepalive
3. Click any agent to open its **individual dashboard**
4. From an agent's dashboard, you can explore:
   - Its security events
   - Its FIM history
   - Its vulnerability scan results
   - Its configuration

**Agent status meanings:**

| Status | Meaning |
|--------|---------|
| 🟢 Active | Connected and sending data |
| 🔴 Disconnected | Lost connection to Manager |
| ⚫ Never Connected | Enrolled but never checked in |
| ⏸️ Pending | Enrolled, awaiting first connection |

---

## Module 5: Threat Hunting

**What it is:** A raw search interface for exploring all indexed data — not just alerts. This is where advanced analysts go to investigate.

**Basic Threat Hunting queries:**

```
# Find all events involving a specific IP
data.srcip: 192.168.1.50

# Find events in a specific time range with high severity
rule.level: [10 TO 15] AND @timestamp: [2024-01-01 TO 2024-01-02]

# Find all sudo events
data.audit.command: sudo

# Find new processes
rule.groups: process_monitor

# Find outbound connections to unusual ports
data.protocol: tcp AND data.dstport: [4444 TO 4445]
```

---

## Saving and Exporting

### Save a Search

1. Run a query in Threat Hunting or Security Events
2. Click **Save** (top right)
3. Give it a name (e.g., "SSH Brute Force - Last 7 Days")
4. It appears in your Saved Searches

### Export Alerts to CSV

1. In the Alerts table, click the **Share** icon
2. Select **CSV Reports**
3. The file downloads to your browser

### Create a Custom Dashboard

1. Click **☰ → Dashboard**
2. Click **Create new dashboard**
3. Add **Visualizations** (bar charts, pie charts, tables)
4. Save it for reuse

---

## Tips for SOC Analysts

> These are the habits that distinguish experienced analysts from beginners.

1. **Start with the highest severity** — Filter `rule.level >= 10` first
2. **Pivot on IPs** — When you see a suspicious IP in one alert, search for it everywhere
3. **Check the full log** — Always read the `full_log` field, not just the alert description
4. **Use time correlation** — Look for multiple alert types from the same source in a short window
5. **Document your investigation** — Add notes, create tickets in TheHive
6. **Trust but verify** — Even legitimate-looking activity can be malicious in context

---

*Previous: [Configuration ←](04-configuration.md) | Next: [Testing →](06-testing.md)*
