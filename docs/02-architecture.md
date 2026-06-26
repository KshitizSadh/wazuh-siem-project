# 🏗️ 02 — Architecture

## Overview

Wazuh uses a **distributed architecture** with three main server-side components and a lightweight agent that runs on every monitored endpoint. Understanding this architecture is critical — it directly maps to how real enterprise SIEMs are designed.

---

## Component Breakdown

### 1. Wazuh Manager

**What it is:** The brain of the Wazuh deployment.

**What it does:**
- Receives log data from all connected agents
- Runs the **rules engine** — matching incoming data against hundreds of built-in detection rules
- Generates **alerts** when a rule is triggered
- Stores alerts locally and forwards them to the Indexer via Filebeat
- Manages agent enrollment, keys, and configuration

**Where it lives:** `/var/ossec/`

**Key processes:**

| Process | Purpose |
|---------|---------|
| `wazuh-analysisd` | Main analysis daemon — runs the rules engine |
| `wazuh-remoted` | Handles communication with agents |
| `wazuh-authd` | Handles agent enrollment and key management |
| `wazuh-monitord` | Monitors agent and manager health |
| `wazuh-logcollector` | Collects logs from local files |

---

### 2. Wazuh Indexer

**What it is:** The data storage layer, built on **OpenSearch** (an open-source fork of Elasticsearch).

**What it does:**
- Receives forwarded alerts from the Manager via **Filebeat**
- Indexes all alerts for fast search and retrieval
- Powers the search and filtering capabilities in the Dashboard
- Stores data in time-based indices (e.g., `wazuh-alerts-4.x-YYYY.MM.DD`)

**Key port:** `9200` (REST API), `9300` (cluster communication)

**Important note:** The Indexer is the most resource-intensive component. It requires at minimum **4 GB of dedicated RAM** to operate stably.

---

### 3. Wazuh Dashboard

**What it is:** The web-based user interface, built on **OpenSearch Dashboards**.

**What it does:**
- Provides a visual interface for security analysts
- Displays real-time and historical alerts
- Contains specialized modules: Security Events, Integrity Monitoring, Vulnerability Detection, Compliance, Threat Hunting
- Connects to the Indexer via REST API on port 9200

**Key port:** `443` (HTTPS)

---

### 4. Wazuh Agent

**What it is:** A lightweight daemon installed on every endpoint you want to monitor.

**What it does:**
- Collects log data from the local system (auth logs, application logs, Windows Event Logs)
- Monitors file integrity (FIM)
- Scans for vulnerabilities
- Executes active response actions (e.g., blocking an IP)
- Forwards all data to the Manager over **TCP port 1514** (encrypted)

**Enrollment port:** `1515` (used only during initial enrollment)

---

## Network Architecture

```
┌─────────────────────────────────────────────────────┐
│                  MONITORED ENDPOINTS                │
│                                                     │
│  ┌─────────────┐    ┌─────────────┐                │
│  │ Linux Agent │    │Windows Agent│                │
│  │  Ubuntu     │    │  Win 10/11  │                │
│  └──────┬──────┘    └──────┬──────┘                │
│         │                  │                        │
└─────────┼──────────────────┼────────────────────────┘
          │  TCP 1514 (TLS)  │
          ▼                  ▼
┌─────────────────────────────────────────────────────┐
│                  WAZUH SERVER                       │
│                                                     │
│  ┌───────────────────┐                             │
│  │   Wazuh Manager   │  ← Alert Processing        │
│  │   :1514 (agents)  │  ← Rules Engine            │
│  │   :1515 (enroll)  │  ← Agent Management        │
│  └────────┬──────────┘                             │
│           │ Filebeat                               │
│           ▼                                        │
│  ┌───────────────────┐                             │
│  │   Wazuh Indexer   │  ← Data Storage            │
│  │   OpenSearch :9200│  ← Search Engine           │
│  └────────┬──────────┘                             │
│           │ REST API                               │
│           ▼                                        │
│  ┌───────────────────┐                             │
│  │  Wazuh Dashboard  │  ← Web UI                  │
│  │   HTTPS :443      │  ← Visualizations          │
│  └───────────────────┘                             │
│                                                     │
└─────────────────────────────────────────────────────┘
          │
          ▼
    Analyst Browser
    (SOC Workstation)
```

---

## Data Flow: From Event to Alert

Understanding the data flow is fundamental to troubleshooting and detection engineering.

```
1. EVENT OCCURS ON ENDPOINT
   └── e.g., Failed SSH login to Linux server

2. AGENT COLLECTS THE LOG
   └── Reads /var/log/auth.log
   └── "Failed password for invalid user admin from 192.168.1.50"

3. AGENT PRE-PROCESSES
   └── Applies local decoders
   └── Checks ignore lists
   └── Encrypts the event

4. AGENT FORWARDS TO MANAGER
   └── TCP port 1514
   └── Encrypted with agent key

5. MANAGER DECODES
   └── Identifies log format (syslog)
   └── Extracts fields: user, source IP, timestamp

6. RULES ENGINE RUNS
   └── Rule 5710: "sshd: Authentication failed"
   └── Rule 5720: "sshd: Multiple authentication failures" (if >8 in 120s)

7. ALERT GENERATED
   └── Level 5 (single failure) or Level 10 (brute force)
   └── Stored in /var/ossec/logs/alerts/alerts.json

8. FILEBEAT FORWARDS TO INDEXER
   └── Alert JSON sent to OpenSearch on port 9200

9. INDEXED AND SEARCHABLE
   └── Stored in wazuh-alerts-4.x-YYYY.MM.DD index

10. DISPLAYED IN DASHBOARD
    └── Visible in Security Events module within seconds
```

---

## Lab Environment Specifications

This project was implemented in the following environment:

| Component | Specification |
|-----------|--------------|
| **Wazuh Server OS** | Ubuntu Server 22.04 LTS |
| **Server RAM** | 8 GB |
| **Server CPU** | 4 vCPUs |
| **Server Storage** | 80 GB |
| **Linux Agent OS** | Ubuntu 22.04 LTS (separate VM) |
| **Windows Agent OS** | Windows 10 (separate VM) |
| **Hypervisor** | VirtualBox / VMware Workstation |
| **Network** | Host-only / NAT networking |

---

## Port Reference

| Port | Protocol | Component | Purpose |
|------|----------|-----------|---------|
| 443 | TCP/HTTPS | Dashboard | Web UI access |
| 1514 | TCP | Manager | Agent data reception |
| 1515 | TCP | Manager | Agent enrollment |
| 9200 | TCP | Indexer | REST API / data ingestion |
| 9300 | TCP | Indexer | Cluster communication |
| 55000 | TCP | Manager | REST API |

---

## Security of the Architecture

Even in a lab, it is good practice to understand the security properties of what you are running:

- **Agent-to-Manager communication** is encrypted using pre-shared keys generated during enrollment
- **Manager-to-Indexer** communication via Filebeat uses TLS certificates generated during installation
- **Dashboard-to-Indexer** communication is authenticated with credentials
- **Dashboard** is served over HTTPS only (self-signed cert by default in lab)

---

*Previous: [Introduction ←](01-introduction.md) | Next: [Installation →](03-installation.md)*
