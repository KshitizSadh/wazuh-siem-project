# ⚙️ 04 — Configuration

> This guide covers the key configuration files in Wazuh and how to tune them for better detection in your lab environment.

---

## Configuration File Overview

| File | Location | Purpose |
|------|----------|---------|
| `ossec.conf` (Manager) | `/var/ossec/etc/ossec.conf` | Main Manager configuration |
| `ossec.conf` (Agent) | `/var/ossec/etc/ossec.conf` | Agent-side configuration |
| `rules/` | `/var/ossec/ruleset/rules/` | Built-in detection rules |
| `local_rules.xml` | `/var/ossec/etc/rules/local_rules.xml` | Your custom rules |
| `decoders/` | `/var/ossec/ruleset/decoders/` | Built-in log decoders |
| `local_decoder.xml` | `/var/ossec/etc/decoders/local_decoder.xml` | Your custom decoders |
| `filebeat.yml` | `/etc/filebeat/filebeat.yml` | Filebeat → Indexer forwarding config |
| `opensearch.yml` | `/etc/wazuh-indexer/opensearch.yml` | Indexer/OpenSearch config |

---

## Manager Configuration (`ossec.conf`)

The Manager's main config file controls nearly every aspect of Wazuh's behavior.

```bash
# Open the config file
sudo nano /var/ossec/etc/ossec.conf
```

### Global Section

```xml
<ossec_config>
  <global>
    <!-- Output alerts in JSON format (required for Filebeat) -->
    <jsonout_output>yes</jsonout_output>

    <!-- Write alerts to the alerts log file -->
    <alerts_log>yes</alerts_log>

    <!-- Set to yes only for deep debugging — generates huge files -->
    <logall>no</logall>
    <logall_json>no</logall_json>

    <!-- Email notifications (disabled in lab) -->
    <email_notification>no</email_notification>

    <!-- Maximum number of agents -->
    <max_agents>10000</max_agents>

    <!-- Hostname or IP of this server -->
    <host_information>yes</host_information>
  </global>
```

---

### Alerts Section

```xml
  <alerts>
    <!-- Minimum level to write to alerts log (1-15) -->
    <!-- Level 3 = informational, Level 10 = high severity -->
    <log_alert_level>3</log_alert_level>

    <!-- Minimum level to send email alerts -->
    <email_alert_level>12</email_alert_level>
  </alerts>
```

**Alert Level Reference:**

| Level | Severity | Examples |
|-------|----------|---------|
| 1–3 | Informational | Successful logins, routine events |
| 4–6 | Low | Multiple login failures, unknown users |
| 7–9 | Medium | Brute force, suspicious activity |
| 10–12 | High | Rootkit detected, integrity violation |
| 13–15 | Critical | Active attack, system compromise |

---

### File Integrity Monitoring (FIM)

FIM is one of Wazuh's most powerful features. It watches critical files and directories for unauthorized changes.

```xml
  <syscheck>
    <!-- How often to run a full FIM scan (seconds) -->
    <!-- 300 = every 5 minutes. In production, 21600 (6 hours) is common -->
    <frequency>300</frequency>

    <!-- Enable real-time monitoring (inotify-based) for these dirs -->
    <!-- Real-time = alerts within seconds of a change -->
    <directories check_all="yes" realtime="yes">/etc</directories>
    <directories check_all="yes" realtime="yes">/usr/bin,/usr/sbin</directories>
    <directories check_all="yes">/bin,/sbin,/boot</directories>

    <!-- Monitor home directories -->
    <directories check_all="yes">/home</directories>

    <!-- Files/dirs to ignore (reduce noise) -->
    <ignore>/etc/mtab</ignore>
    <ignore>/etc/hosts.deny</ignore>
    <ignore>/etc/mail/statistics</ignore>
    <ignore>/etc/random-seed</ignore>
    <ignore>/etc/adjtime</ignore>
    <ignore>/etc/httpd/logs</ignore>
    <ignore type="sregex">.log$|.tmp$|.swp$</ignore>

    <!-- Alert if a new file appears in these dirs -->
    <alert_new_files>yes</alert_new_files>

    <!-- Scan on startup -->
    <scan_on_start>yes</scan_on_start>
  </syscheck>
```

**`check_all="yes"` means FIM will track:**
- File hash (MD5, SHA1, SHA256)
- File permissions (mode)
- File owner and group
- File size
- Last modification time
- Inode number

---

### Log Collection

```xml
  <!-- Collect authentication logs (SSH, sudo, PAM) -->
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/auth.log</location>
  </localfile>

  <!-- Collect system messages -->
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/syslog</location>
  </localfile>

  <!-- Collect kernel messages -->
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/kern.log</location>
  </localfile>

  <!-- Collect dpkg (package install/remove) logs -->
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/dpkg.log</location>
  </localfile>

  <!-- Collect running processes (every 10 minutes) -->
  <localfile>
    <log_format>command</log_format>
    <command>df -P</command>
    <frequency>600</frequency>
  </localfile>

  <!-- Collect netstat output -->
  <localfile>
    <log_format>full_command</log_format>
    <command>netstat -tulpn | sed 's/\([[:alnum:]]\+\)\/.*$/\1/'</command>
    <alias>netstat listening ports</alias>
    <frequency>360</frequency>
  </localfile>
</ossec_config>
```

---

## Agent Configuration

The agent's `ossec.conf` (on the agent machine) controls what the agent monitors locally before sending data to the Manager.

```bash
# On the AGENT machine
sudo nano /var/ossec/etc/ossec.conf
```

```xml
<ossec_config>
  <!-- Connection to Manager -->
  <client>
    <server>
      <address>192.168.x.x</address>  <!-- Your Manager IP -->
      <port>1514</port>
      <protocol>tcp</protocol>
    </server>
    <!-- How often to check in with Manager (seconds) -->
    <notify_time>10</notify_time>
    <time-reconnect>60</time-reconnect>
    <auto_restart>yes</auto_restart>
  </client>

  <!-- Local FIM on the agent -->
  <syscheck>
    <frequency>300</frequency>
    <directories check_all="yes" realtime="yes">/etc,/usr/bin,/usr/sbin</directories>
    <directories check_all="yes">/home,/tmp</directories>
    <ignore>/etc/mtab</ignore>
  </syscheck>

  <!-- Collect local logs -->
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/auth.log</location>
  </localfile>

  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/syslog</location>
  </localfile>
</ossec_config>
```

After editing, restart the agent:

```bash
sudo systemctl restart wazuh-agent
```

---

## Writing Custom Detection Rules

Custom rules go in `/var/ossec/etc/rules/local_rules.xml`. This file is preserved during Wazuh upgrades.

### Rule Structure

```xml
<group name="local,custom,">

  <!-- Rule to detect creation of files in /tmp -->
  <rule id="100001" level="7">
    <if_sid>554</if_sid>         <!-- Parent rule: new file created -->
    <field name="file">/tmp/</field>  <!-- Only if path contains /tmp/ -->
    <description>New file created in /tmp directory</description>
    <group>file_creation,tmp,</group>
    <mitre>
      <id>T1059</id>              <!-- Map to MITRE ATT&CK technique -->
    </mitre>
  </rule>

  <!-- Rule to detect sudo usage by non-admin users -->
  <rule id="100002" level="9">
    <if_sid>5402</if_sid>         <!-- Parent: sudo used -->
    <match>root</match>
    <description>Sudo command used to gain root access</description>
    <group>sudo,privilege_escalation,</group>
    <mitre>
      <id>T1548.003</id>
    </mitre>
  </rule>

</group>
```

**Rule ID convention:** Custom rules must use IDs between **100000–119999** to avoid conflicts with Wazuh built-in rules.

### Apply Changes

```bash
# Test the rules for syntax errors first
sudo /var/ossec/bin/wazuh-logtest

# Restart the manager to apply
sudo systemctl restart wazuh-manager
```

---

## Verify Configuration

```bash
# Check the Manager config for errors
sudo /var/ossec/bin/ossec-logtest

# Validate ossec.conf XML syntax
sudo /var/ossec/bin/verify-agent-conf

# Check active agents
sudo /var/ossec/bin/agent_control -l

# Check which rules are loaded
sudo grep -r "rule id" /var/ossec/ruleset/rules/ | wc -l
```

---

*Previous: [Installation ←](03-installation.md) | Next: [Usage →](05-usage.md)*
