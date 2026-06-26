# 💡 11 — Lessons Learned

> Honest reflections on what was discovered, what was harder than expected, and what this project taught that textbooks cannot.

---

## Technical Lessons

### 1. Resource Planning Is Not Optional

The biggest surprise was how much RAM the Wazuh Indexer (OpenSearch) consumes. Starting with a 2GB VM caused the Indexer to crash repeatedly. The logs showed Java heap space errors — the JVM was running out of memory. After upgrading to 8GB RAM and properly configuring the JVM heap, everything stabilized.

**Key insight:** Before deploying any Elastic/OpenSearch-based stack, calculate: *available RAM ÷ 2 = max JVM heap*. The Indexer should never get more than half the system's RAM, and it needs at least 2GB of heap to function.

---

### 2. Firewall Is Always the First Suspect

Every time an agent failed to connect, the instinct was to look at the Wazuh configuration. Almost every time, the real problem was simpler — **port 1514 was blocked**. The lesson: when troubleshooting network connectivity in any security tool, check the firewall before anything else.

```bash
# This one command saved hours of debugging:
nc -zv MANAGER_IP 1514
```

---

### 3. Log Volume Is Overwhelming at First

Two agents generating logs created hundreds of events per hour — far more than expected. The first few sessions were spent trying to understand which alerts mattered. This taught the value of:
- **Alert severity levels** — filtering to Level 7+ immediately reduces noise
- **Alert grouping** — understanding parent/child rule relationships
- **Suppression rules** — disabling noisy low-value rules to focus on what matters

In a real SOC with thousands of endpoints, this problem is multiplied enormously. This is why SIEM tuning is a full-time job.

---

### 4. Documentation Is Itself a Security Skill

Writing documentation for this project was not just busywork — it forced a deeper understanding of every component. The act of explaining *why* each configuration choice was made revealed gaps in understanding that simply running commands would have hidden.

In a real security team, documentation is also a **defensive capability**: it establishes baselines, speeds up incident response, and enables knowledge transfer.

---

### 5. The Rules Engine Is Hierarchical

Wazuh's rules are not flat lists — they are **trees**. A Level 5 rule can become a Level 10 rule when triggered multiple times within a time window (a "frequency" rule). Understanding this hierarchy was essential to not misinterpreting alert severity.

Example: A single failed SSH login is Rule 5710, Level 5. Ten failures within 2 minutes triggers Rule 5720, Level 10. Same underlying event — different context, different severity.

---

### 6. JSON Alerts Are Your Best Friend

Wazuh stores alerts as JSON in `/var/ossec/logs/alerts/alerts.json`. Learning to read this file directly — rather than always relying on the dashboard — was a valuable skill. It enabled:
- Faster alert analysis during dashboard downtime
- Shell scripting to filter and count specific alert types
- Understanding the exact data structure that Filebeat sends to the Indexer

---

## What This Project Proves to Employers

This is not just a "I followed a tutorial" project. The documentation demonstrates:

- The ability to **deploy and configure** a complex multi-component security stack
- **Systematic troubleshooting** — diagnosing and resolving real errors
- **Security thinking** — hardening recommendations, not just making it work
- **Communication skills** — explaining technical concepts clearly in writing
- **Lab methodology** — controlled alert generation to test detection coverage

---

## What I Would Do Differently

1. **Start with more RAM** — Would have saved hours of Indexer debugging
2. **Take screenshots throughout** — Many intermediate states are hard to recreate later
3. **Set up Active Response earlier** — It is one of Wazuh's most impressive features
4. **Integrate TheHive from the start** — Having a case management system from day one would create a more realistic SOC simulation
5. **Write custom rules earlier** — The built-in rules are a great starting point, but writing your own is where the real learning happens

---

## Security Concepts Solidified

| Concept | Before | After |
|---------|--------|-------|
| SIEM architecture | Theoretical | Hands-on deployed |
| Log collection | "Logs are collected" | Understood the full pipeline from endpoint to indexer |
| Alert severity | Vague | Understand Wazuh's 1–15 level system and parent rule logic |
| FIM | Knew it existed | Can configure, trigger, and analyze FIM alerts |
| MITRE ATT&CK | Read the framework | Can correlate real alerts to specific techniques |
| Incident Response | Theoretical | Know how to use SIEM as the first step of an IR workflow |

---

## Final Reflection

Setting up a SIEM is not glamorous work. It involves a lot of configuration files, service restarts, and log reading. But that is exactly what makes it valuable — it is the same work that real SOC engineers do every day. This project proved that the tools are learnable, the problems are solvable, and the skills are real.

The next step is to integrate this with TheHive for case management and Shuffle for SOAR automation — building toward a complete, realistic home SOC environment.

---

*Previous: [Security Notes ←](10-security-notes.md)*
