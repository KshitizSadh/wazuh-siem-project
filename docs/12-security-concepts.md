# 🔐 Security Concepts — Deep Dive

> Every security concept encountered in this project, explained clearly.

---

## 1. CIA Triad

The **CIA Triad** is the foundational model of information security. Every security control exists to protect one or more of these three properties.

| Property | Definition | How Wazuh Protects It |
|----------|-----------|----------------------|
| **Confidentiality** | Only authorized parties can access information | Detects unauthorized access attempts (SSH failures, privilege escalation) |
| **Integrity** | Information is accurate and unmodified | FIM detects unauthorized file modifications |
| **Availability** | Systems are accessible when needed | Monitors system health; alerts on service failures |

**Example in this project:** When Wazuh detected a modification to `/etc/passwd`, that was a threat to **Integrity** — an attacker may have added a backdoor account.

---

## 2. Defense in Depth

**Definition:** Layering multiple security controls so that if one fails, others still protect the system.

**The layers in a real SOC:**

```
Layer 1: Perimeter (Firewall, IPS)
Layer 2: Network (VLAN segmentation, IDS)
Layer 3: Endpoint (Antivirus, EDR, Patch Management)
Layer 4: Application (WAF, Secure Code)
Layer 5: Data (Encryption, DLP)
Layer 6: Identity (MFA, PAM)
Layer 7: Monitoring (SIEM ← This is where Wazuh lives)
```

**Why it matters:** Wazuh is a **detective control** — it does not prevent attacks but detects them after they happen. It only has value when combined with preventive controls.

---

## 3. Least Privilege

**Definition:** Every user, process, and system component should have only the minimum permissions required to perform its function.

**Applied in this project:**
- The Wazuh agent needs root access to read system logs — this is unavoidable
- However, the agent process does not have network listening privileges beyond its designated ports
- The `admin` dashboard account should be used for administration, not daily monitoring

**Real-world implication:** If an attacker compromises the Wazuh agent, they should not be able to pivot to other systems. Network segmentation + least privilege limits the blast radius.

---

## 4. MITRE ATT&CK Framework

**Definition:** A globally-accessible knowledge base of adversary tactics, techniques, and procedures (TTPs) based on real-world observations.

**Structure:**

```
TACTICS (the "why" — 14 columns)
  └── TECHNIQUES (the "how" — ~200 techniques)
        └── SUB-TECHNIQUES (specific variations)
              └── PROCEDURES (specific tool/malware usage)
```

**Key Tactics:**

| Tactic | What Attackers Do | Example Technique |
|--------|------------------|------------------|
| Reconnaissance | Gather info before attacking | T1595: Active Scanning |
| Initial Access | Get into the network | T1078: Valid Accounts |
| Execution | Run malicious code | T1059: Command Interpreter |
| Persistence | Maintain access | T1136: Create Account |
| Privilege Escalation | Gain higher permissions | T1548: Abuse Elevation |
| Defense Evasion | Avoid detection | T1070: Indicator Removal |
| Credential Access | Steal passwords | T1110: Brute Force |
| Discovery | Learn about the environment | T1018: Remote System Discovery |
| Lateral Movement | Move to other systems | T1021: Remote Services |
| Collection | Gather target data | T1560: Archive Collected Data |
| Exfiltration | Steal the data | T1048: Exfil Over Alt Protocol |
| Impact | Disrupt/destroy/ransom | T1486: Data Encrypted for Impact |

**How Wazuh uses it:** Every alert can be tagged with a MITRE technique ID. The dashboard's MITRE ATT&CK module shows a heat map of which techniques are most active in your environment.

---

## 5. Logging & Log Management

**Definition:** The practice of capturing, storing, analyzing, and retaining records of system and application activity.

**Log types collected in this project:**

| Log Type | Source | What It Shows |
|----------|--------|--------------|
| Auth logs | `/var/log/auth.log` | Logins, sudo, SSH |
| Syslog | `/var/log/syslog` | General system events |
| Kernel logs | `/var/log/kern.log` | Hardware, driver events |
| Windows Event Logs | Windows Event Viewer | Windows security, system, application |
| Audit logs | `/var/log/audit/audit.log` | Syscall-level auditing |

**NIST SP 800-92** is the authoritative guide on log management. Key principles:
- Logs should be centralized (a SIEM does this)
- Logs should be protected from tampering
- Log retention periods should match compliance requirements

---

## 6. Intrusion Detection

**Types:**

| Type | Method | Example |
|------|--------|---------|
| **Signature-based** | Match known attack patterns | Wazuh rule matching specific log strings |
| **Anomaly-based** | Detect deviations from baseline | Unusual login times, high data transfer |
| **Behavioral** | Watch for suspicious sequences | Recon → Exploitation → Persistence chain |

**Wazuh uses signature-based detection** via its rules engine. Rule 5720 fires when more than 8 SSH failures occur within 120 seconds — this is a signature for brute-force behavior.

**False Positives vs. False Negatives:**

| | Alert Fired | Alert Not Fired |
|---|-------------|----------------|
| **Attack Occurred** | True Positive ✅ | False Negative ❌ |
| **No Attack** | False Positive ⚠️ | True Negative ✅ |

A good SIEM is tuned to minimize both false positives (alert fatigue) and false negatives (missed attacks).

---

## 7. Incident Response

**The NIST IR Lifecycle:**

```
1. PREPARATION
   └── Deploy SIEM, write runbooks, train team

2. DETECTION & ANALYSIS
   └── SIEM fires alert → Analyst investigates
   └── Determine: Is this a real incident?

3. CONTAINMENT
   └── Isolate affected systems
   └── Block attacker's IP/account

4. ERADICATION
   └── Remove malware, close vulnerabilities
   └── Remove attacker's persistence mechanisms

5. RECOVERY
   └── Restore systems to normal operation
   └── Monitor for re-infection

6. POST-INCIDENT ACTIVITY
   └── Write incident report
   └── Update detection rules
   └── Apply lessons learned
```

**Wazuh's role:** Wazuh is the primary tool for **Detection & Analysis**. The alert it generates is the starting point of every investigation.

---

## 8. Zero Trust

**Definition:** "Never trust, always verify." The model that assumes no user, device, or network segment is inherently trusted — even inside the perimeter.

**Key principles:**
1. Verify explicitly (authenticate and authorize every request)
2. Use least privilege access
3. Assume breach (monitor everything, including internal traffic)

**How Wazuh supports Zero Trust:** By monitoring internal systems and user behavior, Wazuh supports the "assume breach" principle. Even if an attacker gets inside the network, Wazuh can detect lateral movement, privilege escalation, and data exfiltration.

---

## 9. Threat Hunting

**Definition:** Proactive searching through networks and endpoints to detect advanced threats that evade automated detection.

**Reactive (SIEM alerting):**
```
Alert fires → Analyst investigates → Confirmed or dismissed
```

**Proactive (Threat Hunting):**
```
Analyst forms hypothesis → Searches logs/endpoints → Finds evidence → Creates new detection rule
```

**Using Wazuh for hunting:** The Threat Hunting module in Wazuh Dashboard provides a raw search interface. A hunter might search for:
- Processes that spawned unusual child processes
- Outbound connections to newly registered domains
- Admin tools used outside business hours
- Large amounts of data moving to an unusual destination

---

## 10. Encryption

**In the context of this project:**

| Connection | Encryption | Mechanism |
|------------|-----------|----------|
| Agent → Manager | ✅ Encrypted | Pre-shared keys generated at enrollment |
| Manager → Indexer (Filebeat) | ✅ TLS | Certificates generated by installer |
| Dashboard → Indexer | ✅ TLS | Certificates generated by installer |
| Browser → Dashboard | ✅ HTTPS | Self-signed cert (lab) |

**Key types:**
- **Symmetric encryption** (AES) — Same key encrypts and decrypts. Fast. Used for bulk data.
- **Asymmetric encryption** (RSA) — Public key encrypts, private key decrypts. Used for key exchange and TLS.
- **TLS** — Transport Layer Security. The protocol that makes HTTPS work. Wazuh uses TLS 1.2+ everywhere.

---

## 11. Risk Management

**Formula:**
```
Risk = Threat × Vulnerability × Impact
```

| Term | In This Project |
|------|----------------|
| **Threat** | SSH brute force attack |
| **Vulnerability** | SSH exposed to network, weak passwords |
| **Impact** | Unauthorized access, data breach |
| **Control** | Wazuh detects brute force (detective) + fail2ban blocks IP (preventive) |

**Risk treatment options:**
- **Mitigate** — Reduce the risk (add MFA)
- **Accept** — Acknowledge and monitor
- **Transfer** — Cyber insurance
- **Avoid** — Disable the service entirely

---

## 12. Network Segmentation

**Definition:** Dividing a network into isolated segments to limit the spread of attacks.

**In a real SOC environment:**

```
Internet
   ↓
DMZ (Web servers, email)
   ↓ (Firewall)
Internal Network
   ├── User Segment (workstations)
   ├── Server Segment (internal servers)
   ├── Security Segment (SIEM, SOC tools) ← Wazuh lives here
   └── Management Segment (firewalls, switches)
```

**Why the SIEM needs its own segment:** If an attacker compromises a workstation and the SIEM is on the same network, they can attack the SIEM itself — deleting logs, disabling alerts. Isolation protects the monitoring infrastructure.

In this lab, all components ran on an isolated host-only network (`192.168.56.0/24`) — a simple form of segmentation.
