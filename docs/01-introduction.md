# 📖 01 — Introduction

## What Is a SIEM?

A **Security Information and Event Management (SIEM)** system is the nerve center of a Security Operations Center (SOC). It does two things:

1. **Security Information Management (SIM)** — Collects, stores, and analyzes log data from across your environment for long-term analysis and compliance.
2. **Security Event Management (SEM)** — Monitors events in real-time, correlates them against known attack patterns, and generates alerts when something suspicious is detected.

Together, they give your SOC a **single pane of glass** — one place to see everything happening across all your endpoints, servers, firewalls, and applications.

---

## Why Wazuh?

Wazuh is a **free and open-source SIEM** platform. It is one of the most widely deployed SIEMs in the world, used by organizations ranging from small startups to large enterprises and government agencies.

### Key Reasons to Learn Wazuh

| Reason | Details |
|--------|---------|
| **Open Source & Free** | No licensing costs — perfect for home labs |
| **Enterprise-Grade** | The same platform used in production SOCs |
| **Active Community** | Thousands of contributors and extensive documentation |
| **Rich Feature Set** | FIM, Vulnerability Detection, Compliance, Threat Intel |
| **MITRE ATT&CK** | Native mapping of alerts to attack techniques |
| **Recruiter Recognition** | Wazuh appears in many SOC analyst job descriptions |

---

## Industry Context

SIEMs are a **mandatory component** of almost every enterprise security program. Regulations like **PCI-DSS**, **HIPAA**, **SOC 2**, and **ISO 27001** require centralized log management and alerting — all things a SIEM provides.

When you can demonstrate Wazuh experience, you are signaling:
- You understand how logs flow through an enterprise
- You can identify anomalous behavior using rules and alerts
- You know how to work in a SOC environment
- You have hands-on experience with a production-grade security tool

---

## What This Project Covers

This project is structured as a **learning journey** — starting from zero and building toward a fully operational SIEM deployment:

```
Phase 1: Installation
  └── Wazuh Manager + Indexer + Dashboard on Ubuntu Server

Phase 2: Agent Enrollment
  ├── Linux agent enrollment and verification
  └── Windows agent enrollment and verification

Phase 3: Detection & Monitoring
  ├── File Integrity Monitoring (FIM)
  ├── Log collection (auth logs, system logs)
  └── First alert generation and analysis

Phase 4: Dashboard Exploration
  ├── Security Events module
  ├── Integrity Monitoring module
  └── Threat Hunting module
```

---

## Project Motivation

This project was built as part of a deliberate effort to develop **practical, demonstrable SOC skills** for the Indian cybersecurity job market. Job descriptions for SOC Analyst and VAPT roles consistently list SIEM experience as a key requirement.

Rather than just reading about SIEM concepts, this project creates **evidence of hands-on capability** — something that can be shown to recruiters and discussed in technical interviews.

---

## How to Use This Documentation

Each document in this repository builds on the previous one. For the best learning experience, follow them in order:

1. **Introduction** ← You are here
2. [Architecture](02-architecture.md) — Understand the system design
3. [Installation](03-installation.md) — Deploy the stack
4. [Configuration](04-configuration.md) — Configure for your environment
5. [Usage](05-usage.md) — Navigate the dashboard
6. [Testing](06-testing.md) — Generate and analyze alerts
7. [Troubleshooting](07-troubleshooting.md) — Fix common problems
8. [FAQ](08-faq.md) — Quick answers
9. [References](09-references.md) — Further reading
10. [Security Notes](10-security-notes.md) — Hardening guidance
11. [Lessons Learned](11-lessons-learned.md) — Key takeaways

---

*Next: [Architecture →](02-architecture.md)*
