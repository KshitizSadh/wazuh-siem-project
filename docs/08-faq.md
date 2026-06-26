# ❓ 08 — FAQ

**Q: How many agents can Wazuh handle?**
A: A single Wazuh Manager can handle up to 10,000 agents. For larger deployments, you can use a cluster configuration with multiple Managers behind a load balancer.

**Q: Is Wazuh really free?**
A: Yes. Wazuh is fully open-source under the GPL v2 license. There are no licensing costs. Wazuh also offers a commercial cloud service (Wazuh Cloud) with support, but the self-hosted version is completely free.

**Q: What is the difference between Wazuh and Splunk/QRadar?**
A: Splunk and IBM QRadar are commercial, enterprise SIEMs that cost tens of thousands of dollars per year. Wazuh is open-source and free. Functionally, Wazuh covers the core SIEM capabilities (log collection, rule-based detection, dashboards) and adds features like FIM and vulnerability detection that some commercial tools charge extra for.

**Q: How does Wazuh compare to the ELK stack?**
A: The ELK stack (Elasticsearch, Logstash, Kibana) is a log management platform. Wazuh uses OpenSearch (a fork of Elasticsearch) as its backend but adds a security-specific rules engine, agent management, FIM, compliance modules, and MITRE ATT&CK mapping on top. Wazuh = ELK + security features + agents.

**Q: Can Wazuh detect malware?**
A: Wazuh can detect indicators of malware (new executables, suspicious processes, rootkit signatures, integrity violations) but it is not a traditional antivirus. For malware-specific detection, integrate it with a tool like ClamAV or a commercial EDR.

**Q: Why does the dashboard show a security warning about the SSL certificate?**
A: The Wazuh installer generates a self-signed TLS certificate for the dashboard. Browsers warn about self-signed certs because they are not issued by a trusted Certificate Authority (CA). In a production environment, you would replace this with a certificate from Let's Encrypt or your organization's internal CA. In a lab, you can safely click past the warning.

**Q: How do I update Wazuh?**
A: `sudo apt-get update && sudo apt-get upgrade wazuh-manager wazuh-indexer wazuh-dashboard wazuh-agent`

**Q: Can I run Wazuh on a Raspberry Pi?**
A: The agent can run on ARM devices including Raspberry Pi. The server components (Manager, Indexer, Dashboard) are resource-intensive and are not recommended for Pi deployment.

**Q: What is the data retention period?**
A: By default, Wazuh Indexer does not automatically delete old data. You should configure Index Lifecycle Management (ILM) policies to delete indices older than your retention target (e.g., 90 days).

**Q: Does Wazuh have active response capabilities?**
A: Yes. Wazuh Active Response can automatically execute scripts when specific alerts fire — for example, blocking an IP with iptables when a brute-force alert is triggered. Configure this in the `<active-response>` section of `ossec.conf`.
