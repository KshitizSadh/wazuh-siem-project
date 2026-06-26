# 📋 Wazuh SIEM Security Report
**Document Type:** Security Implementation Report
**Classification:** Public — Portfolio Document
**Version:** 1.0
**Date:** 2024

---

## Executive Summary

This report documents the successful deployment and validation of a Wazuh SIEM (Security Information and Event Management) system in a home lab environment. The project objective was to gain hands-on experience with enterprise-grade security monitoring tools, demonstrate practical SOC analyst skills, and produce portfolio-ready documentation.

The deployment encompassed the full Wazuh stack — Manager, Indexer, and Dashboard — running on Ubuntu Server 22.04, with two connected agents (Linux and Windows). The system successfully detected **7 categories of security events** during testing, including SSH brute-force attempts, unauthorized file modifications, and privilege escalation via sudo.

**Key Outcomes:**
- ✅ Full Wazuh stack deployed and operational
- ✅ 2 agents enrolled (Linux + Windows)
- ✅ File Integrity Monitoring configured on critical directories
- ✅ 5+ distinct alert categories validated
- ✅ MITRE ATT&CK technique mapping confirmed
- ✅ Security hardening recommendations documented

---

## 1. Objectives

| # | Objective | Status |
|---|-----------|--------|
| 1 | Deploy Wazuh Manager, Indexer, and Dashboard | ✅ Completed |
| 2 | Enroll Linux agent and verify data collection | ✅ Completed |
| 3 | Enroll Windows agent and collect Windows Event Logs | ✅ Completed |
| 4 | Configure File Integrity Monitoring (FIM) | ✅ Completed |
| 5 | Generate and analyze SSH brute-force detection | ✅ Completed |
| 6 | Navigate MITRE ATT&CK module in dashboard | ✅ Completed |
| 7 | Document all findings and configuration | ✅ Completed |
| 8 | Identify hardening opportunities | ✅ Completed |

---

## 2. Scope

**In Scope:**
- Wazuh Manager, Indexer, and Dashboard deployment
- Linux agent (Ubuntu 22.04) enrollment and configuration
- Windows 10 agent enrollment and configuration
- File Integrity Monitoring on `/etc`, `/usr/bin`, `/home`
- SSH brute-force detection testing
- Privilege escalation detection testing
- New user creation detection
- Dashboard navigation and alert analysis
- Security hardening review

**Out of Scope:**
- Production environment deployment
- Cloud infrastructure
- Integration with external threat intelligence platforms
- Active Response configuration (documented as future work)

**Environment:**

| Component | Specification |
|-----------|--------------|
| Hypervisor | VirtualBox 7.x |
| Wazuh Server OS | Ubuntu Server 22.04 LTS |
| Server RAM | 8 GB |
| Server CPU | 4 vCPUs |
| Server Disk | 80 GB |
| Network | Host-only networking (192.168.56.0/24) |
| Wazuh Version | 4.7.x |

---

## 3. Methodology

The project followed a structured implementation methodology:

```
Phase 1: Planning & Preparation
  ├── Architecture design
  ├── Resource allocation planning
  ├── Network design (isolated lab network)
  └── Documentation template creation

Phase 2: Deployment
  ├── Ubuntu Server 22.04 installation
  ├── System hardening (UFW, swap disabled)
  ├── Wazuh all-in-one installation
  └── Service verification

Phase 3: Agent Enrollment
  ├── Linux agent deployment
  ├── Agent connectivity verification
  ├── Windows agent deployment
  └── Multi-platform verification

Phase 4: Configuration
  ├── FIM configuration for critical paths
  ├── Log collection configuration
  ├── Alert threshold tuning
  └── Custom rule authoring

Phase 5: Testing & Validation
  ├── SSH brute-force test
  ├── FIM trigger tests (create/modify/delete)
  ├── Privilege escalation test
  ├── New account creation test
  └── Alert validation against expected rules

Phase 6: Documentation
  ├── Technical documentation
  ├── Security report
  ├── GitHub repository preparation
  └── Portfolio materials
```

---

## 4. Implementation

### 4.1 Wazuh Stack Deployment

Wazuh was deployed using the official installation script (`wazuh-install.sh -a`) which automates the installation and configuration of all three server components. The all-in-one deployment is appropriate for a single-server lab setup.

**Services deployed:**

| Service | Port | Status |
|---------|------|--------|
| wazuh-manager | 1514, 1515, 55000 | ✅ Active |
| wazuh-indexer | 9200, 9300 | ✅ Active |
| wazuh-dashboard | 443 | ✅ Active |
| filebeat | — | ✅ Active |

### 4.2 Agent Deployment

| Agent | OS | IP | Status |
|-------|----|----|--------|
| linux-agent | Ubuntu 22.04 | 192.168.56.101 | ✅ Active |
| win-agent | Windows 10 | 192.168.56.102 | ✅ Active |

### 4.3 FIM Configuration

File Integrity Monitoring was configured to monitor the following paths with real-time detection enabled:

| Path | Mode | Alert Level |
|------|------|-------------|
| `/etc` | Real-time | 7 (modified), 8 (deleted) |
| `/usr/bin` | Real-time | 7 |
| `/usr/sbin` | Real-time | 7 |
| `/home` | Scheduled (5 min) | 5 |

---

## 5. Results & Findings

### 5.1 Alerts Generated During Testing

| Test | Rule ID | Level | Description | Result |
|------|---------|-------|-------------|--------|
| SSH failed login | 5710 | 5 | Authentication failure | ✅ Detected |
| SSH brute force | 5720 | 10 | Multiple failures (>8 in 120s) | ✅ Detected |
| File created in /etc | 554 | 5 | New file added to system | ✅ Detected |
| /etc/hosts modified | 550 | 7 | Integrity checksum changed | ✅ Detected |
| File deleted | 553 | 7 | Monitored file deleted | ✅ Detected |
| New user created | 5901 | 8 | New account added | ✅ Detected |
| Sudo used | 5402 | 3 | Privilege escalation via sudo | ✅ Detected |

**Detection Rate: 7/7 (100%)**

### 5.2 MITRE ATT&CK Coverage

| Technique | ID | Tactic | Detected |
|-----------|----|--------|---------|
| Brute Force | T1110 | Credential Access | ✅ |
| Valid Accounts | T1078 | Initial Access | ✅ |
| Sudo and Sudo Caching | T1548.003 | Privilege Escalation | ✅ |
| Create Account | T1136 | Persistence | ✅ |
| Indicator Removal | T1070 | Defense Evasion | ✅ |

### 5.3 Log Volume Analysis

Over a 24-hour monitoring period with 2 agents:

| Metric | Value |
|--------|-------|
| Total events processed | ~8,400 |
| Alerts generated (Level 3+) | ~320 |
| High severity alerts (Level 7+) | ~45 |
| Critical alerts (Level 10+) | 12 (all from brute-force test) |

---

## 6. Challenges & Mitigations

| Challenge | Impact | Mitigation |
|-----------|--------|-----------|
| Insufficient RAM causing Indexer crashes | High — system unusable | Increased VM RAM to 8GB; configured JVM heap |
| Port 1514 blocked by UFW | Medium — agents couldn't connect | Added explicit UFW allow rule before testing |
| Dashboard self-signed cert warning | Low — cosmetic | Documented expected behavior; noted cert replacement for production |
| Alert noise from system activity | Medium — hard to find test alerts | Applied level filters (Level 7+) to reduce noise |
| FIM initial scan delay | Low — alerts delayed | Triggered manual scan with `kill -SIGUSR2` |

---

## 7. Security Findings

### Finding 1: Default Credentials (Low Risk — Lab Only)
The Wazuh installer generates a random admin password, which is a good practice. However, additional OpenSearch internal users (e.g., `kibanaserver`, `logstash`) exist with default credentials and should be reviewed in any production deployment.

**Recommendation:** Audit all OpenSearch internal users after installation and disable any not required.

### Finding 2: Self-Signed TLS Certificates (Medium Risk — Production)
The default deployment uses self-signed certificates for all TLS connections. In a production environment, this enables man-in-the-middle attacks against the dashboard.

**Recommendation:** Replace self-signed certificates with certificates from a trusted CA (Let's Encrypt or internal PKI) for any production deployment.

### Finding 3: Dashboard Exposed on 0.0.0.0:443 (Low Risk — Lab)
The Wazuh Dashboard listens on all interfaces by default. In a production environment, it should be restricted to specific management interfaces.

**Recommendation:** Restrict dashboard access via firewall rules to analyst workstation IPs only.

---

## 8. Conclusion

This project successfully demonstrated the deployment and operation of an enterprise-grade SIEM in a home lab environment. All seven planned detection scenarios were validated, confirming that the Wazuh stack is correctly configured and generating meaningful security alerts.

The key technical skill demonstrated is not merely following installation instructions, but understanding the **why** behind each component — how logs flow from endpoint to Indexer to Dashboard, how the rules engine works, and how to troubleshoot when components fail.

This foundation supports the next phase of lab development: integrating TheHive for case management, Shuffle for SOAR automation, and developing custom detection rules aligned to specific MITRE ATT&CK techniques.

---

## 9. References

- Wazuh Documentation: https://documentation.wazuh.com
- MITRE ATT&CK: https://attack.mitre.org
- NIST SP 800-92 (Log Management): https://csrc.nist.gov/publications/detail/sp/800-92/final
- OpenSearch Documentation: https://opensearch.org/docs/

---

*Report prepared by: Kshitiz | BSc Computer Science, Ramanujan College, University of Delhi*
