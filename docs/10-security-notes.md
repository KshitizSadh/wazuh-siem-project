# 🔒 10 — Security Notes & Hardening

> The default Wazuh installation is designed for ease of setup. These notes document how to harden it for production or a more realistic lab environment.

---

## 1. Change Default Credentials

The installer generates a random password for the `admin` account. However, there are other default accounts in OpenSearch that should be reviewed.

```bash
# List all OpenSearch users
curl -k -u admin:PASSWORD https://localhost:9200/_plugins/_security/api/internalusers

# Change admin password via Wazuh password tool
sudo /usr/share/wazuh-indexer/plugins/opensearch-security/tools/wazuh-passwords-tool.sh \
  -u admin -p NEW_SECURE_PASSWORD
```

---

## 2. Replace Self-Signed Certificates (Production)

For production or realistic lab hardening, replace self-signed certs with Let's Encrypt:

```bash
# Install certbot
sudo apt-get install certbot -y

# Obtain certificate (requires a domain name and port 80 open)
sudo certbot certonly --standalone -d your-wazuh.domain.com

# Update Wazuh Dashboard config to use the new cert
sudo nano /etc/wazuh-dashboard/opensearch_dashboards.yml
# Update:
# server.ssl.certificate: /etc/letsencrypt/live/your-wazuh.domain.com/fullchain.pem
# server.ssl.key: /etc/letsencrypt/live/your-wazuh.domain.com/privkey.pem
```

---

## 3. Restrict Network Access

In production, the Wazuh server should not be publicly accessible. Apply these firewall rules:

```bash
# Only allow dashboard access from your analyst workstation IP
sudo ufw delete allow 443/tcp
sudo ufw allow from ANALYST_IP to any port 443 proto tcp

# Only allow Indexer API from localhost
sudo ufw delete allow 9200/tcp
# (9200 should only be accessible locally — agents do not connect to it)

# Keep 1514 open for agents, but restrict source if agent IPs are known
sudo ufw allow from AGENT_SUBNET to any port 1514 proto tcp
```

---

## 4. Enable Audit Logging

Track who logs into the Wazuh Dashboard and what they do:

```bash
sudo nano /etc/wazuh-indexer/opensearch.yml

# Add:
plugins.security.audit.type: internal_opensearch
plugins.security.audit.config.enabled_rest_categories: AUTHENTICATED,FAILED_LOGIN
plugins.security.audit.config.enabled_transport_categories: []
```

---

## 5. Principle of Least Privilege — Agent Account

The Wazuh agent runs as root by default (required for reading system logs). In high-security environments, consider running specific capabilities with reduced privileges where possible. Always review what the agent is configured to collect — do not monitor more than necessary.

---

## 6. Log Retention Policy

Security logs have legal and compliance implications. Set a retention policy:

```bash
# Create an ISM policy to delete indices older than 90 days
curl -k -u admin:PASSWORD -X PUT https://localhost:9200/_plugins/_ism/policies/wazuh-retention \
  -H 'Content-Type: application/json' \
  -d '{
    "policy": {
      "description": "Delete Wazuh indices older than 90 days",
      "default_state": "hot",
      "states": [{
        "name": "hot",
        "actions": [],
        "transitions": [{"state_name": "delete", "conditions": {"min_index_age": "90d"}}]
      }, {
        "name": "delete",
        "actions": [{"delete": {}}],
        "transitions": []
      }]
    }
  }'
```

---

## 7. Backup Wazuh Configuration

Always back up configuration before making changes:

```bash
# Backup Manager config
sudo cp /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.conf.backup.$(date +%Y%m%d)

# Backup custom rules
sudo cp /var/ossec/etc/rules/local_rules.xml \
  /var/ossec/etc/rules/local_rules.xml.backup.$(date +%Y%m%d)

# Full config backup
sudo tar -czf /tmp/wazuh-config-backup-$(date +%Y%m%d).tar.gz \
  /var/ossec/etc/ /etc/filebeat/ /etc/wazuh-indexer/ /etc/wazuh-dashboard/
```

---

## Security Concepts Applied

| Concept | Implementation in This Project |
|---------|-------------------------------|
| **Defense in Depth** | SIEM is one layer alongside firewall, endpoint controls |
| **Least Privilege** | Agent runs with only necessary permissions |
| **Audit Logging** | All dashboard access and config changes logged |
| **Encryption in Transit** | All agent-to-manager and dashboard communication is TLS |
| **Integrity Verification** | FIM provides cryptographic verification of file state |
| **Separation of Duties** | Analyst role vs admin role in the dashboard |
| **Log Retention** | ISM policy ensures logs are kept per compliance requirements |

---

*Previous: [References ←](09-references.md) | Next: [Lessons Learned →](11-lessons-learned.md)*
