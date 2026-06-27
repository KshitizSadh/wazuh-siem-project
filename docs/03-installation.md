# 💾 03 — Installation Guide

> **Target Reader:** This guide assumes you are comfortable with the Linux command line but have never installed Wazuh before. Every command is explained.

---

## Pre-Installation Checklist

Before you begin, verify the following:

- [ ] Ubuntu Server 22.04 LTS is installed and updated
- [ ] You have root or sudo access
- [ ] The server has at least 4 GB RAM (8 GB recommended)
- [ ] Internet connection is active
- [ ] You know the server's IP address (`ip a`)
- [ ] Port 443, 1514, 1515, 9200 are not blocked by a firewall

---
<img width="1917" height="1122" alt="image" src="https://github.com/user-attachments/assets/2114bc5c-31c3-4eec-87ff-be4810e1efee" />

## Step 1: System Preparation

### 1.1 Update the System

**Purpose:** Ensure all system packages are current to avoid dependency conflicts.

```bash
sudo apt-get update && sudo apt-get upgrade -y
```

**Expected output:** A list of packages being updated, ending with "0 upgraded, 0 newly installed..." or similar.

**Why this matters:** Running outdated packages can cause the Wazuh installer to fail when it tries to install its own dependencies.
<img width="1151" height="733" alt="image" src="https://github.com/user-attachments/assets/50c864c7-ce9d-4d7f-ad8b-d8bb7cfe8e0f" />

---

### 1.2 Set the Hostname

**Purpose:** A descriptive hostname makes it easier to identify the server in logs and the dashboard.

```bash
sudo hostnamectl set-hostname wazuh-server
```

Verify the change:

```bash
hostnamectl
```

**Expected output:**
<img width="785" height="390" alt="image" src="https://github.com/user-attachments/assets/5fbd49af-bc9a-49d4-86e6-14b10dc2863c" />


---

### 1.3 Disable Swap (Recommended for Wazuh Indexer)

**Purpose:** OpenSearch (which powers the Wazuh Indexer) performs better with swap disabled. When OpenSearch is allowed to swap to disk, query performance degrades significantly and the JVM can behave unpredictably.

```bash
# Disable swap immediately (until reboot)
sudo swapoff -a

# Disable swap permanently (survives reboots)
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

Verify:

```bash
free -h
```

**Expected output:** The `Swap:` line should show `0B`.

<img width="1096" height="161" alt="image" src="https://github.com/user-attachments/assets/6184d35d-66fd-43e0-9fc1-4c81c5a0f307" />


---

### 1.4 Configure the Firewall (UFW)

**Purpose:** Ensure the ports Wazuh needs are open.

```bash
# Allow SSH (so you don't lock yourself out!)
sudo ufw allow ssh

# Allow Wazuh Dashboard
sudo ufw allow 443/tcp

# Allow agent enrollment
sudo ufw allow 1515/tcp

# Allow agent data
sudo ufw allow 1514/tcp

# Allow Indexer API
sudo ufw allow 9200/tcp

# Enable the firewall
sudo ufw enable

# Verify
sudo ufw status
```

**Expected output:**

<img width="682" height="362" alt="image" src="https://github.com/user-attachments/assets/b7a5caac-2612-4995-99c3-7c53c62a201c" />



> ⚠️ **Common Mistake:** Forgetting to allow port 1514 before starting the agents. This is the #1 cause of agents failing to connect.

---

## Step 2: Install Wazuh (All-in-One)

Wazuh provides an official installation script that handles everything automatically — installing and configuring the Manager, Indexer, and Dashboard in a single run.

### 2.1 Download the Installation Script

```bash
curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh
```

**What this does:** Downloads the official Wazuh installation assistant to your current directory.

**Verify the download:**

```bash
ls -lh wazuh-install.sh
```

---

### 2.2 Make It Executable

```bash
chmod +x wazuh-install.sh
```

---

### 2.3 Run the Installation

```bash
sudo bash wazuh-install.sh -a
```

**Flags explained:**

| Flag | Meaning |
|------|---------|
| `-a` | All-in-one installation (Manager + Indexer + Dashboard on same host) |
| `-v` | Verbose output (optional, add for debugging) |
| `-d` | Download only, do not install (optional) |

**What happens during installation:**

1. Checks system requirements
2. Generates SSL/TLS certificates for component communication
3. Installs and configures Wazuh Indexer (OpenSearch)
4. Installs and configures Wazuh Manager
5. Configures Filebeat to forward alerts to the Indexer
6. Installs and configures Wazuh Dashboard
7. Generates a random admin password

**Expected duration:** 10–20 minutes depending on internet speed.

**Expected output at the end:**

```
INFO: --- Summary ---
INFO: You can access the web interface https://192.168.x.x
   User: admin
   Password: <RANDOM_PASSWORD>


INFO: Installation finished.
```

> 🔴 **CRITICAL:** Save the admin password immediately. It is only shown once. If you miss it, you can retrieve or reset it, but it is easier to save it now.

---

### 2.4 Verify All Services Are Running

```bash
# Check Wazuh Manager
sudo systemctl status wazuh-manager

# Check Wazuh Indexer
sudo systemctl status wazuh-indexer

# Check Wazuh Dashboard
sudo systemctl status wazuh-dashboard
```

**Expected output for each:**

```
● wazuh-manager.service - Wazuh manager
   Loaded: loaded (/lib/systemd/system/wazuh-manager.service; enabled)
   Active: active (running) since ...
```

If any service shows `failed` or `inactive`, see [Troubleshooting](07-troubleshooting.md).

---

## Step 3: First Dashboard Login

### 3.1 Access the Dashboard

Open a web browser and navigate to:

```
https://<YOUR-SERVER-IP>
```

> Note: The dashboard uses a **self-signed SSL certificate** by default. Your browser will show a security warning — this is expected in a lab environment. Click "Advanced" and "Proceed anyway" (the exact wording varies by browser).

### 3.2 Log In

- **Username:** `admin`
- **Password:** The password shown at the end of the installation

You should see the Wazuh dashboard welcome screen.

---

## Step 4: Enroll a Linux Agent

This step installs the Wazuh agent on a second Linux machine (or VM) and connects it to the Manager.

> **Run all commands in this section ON THE AGENT MACHINE, not the server.**

### 4.1 Add the Wazuh Repository

```bash
# Import the GPG key
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring \
  --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import

# Set correct permissions on the keyring
chmod 644 /usr/share/keyrings/wazuh.gpg

# Add the Wazuh apt repository
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | \
  sudo tee /etc/apt/sources.list.d/wazuh.list

# Update package lists
sudo apt-get update
```

---

### 4.2 Install the Agent

Replace `<WAZUH-MANAGER-IP>` with the actual IP address of your Wazuh server.

```bash
sudo WAZUH_MANAGER="<WAZUH-MANAGER-IP>" apt-get install wazuh-agent -y
```

**What happens:** The agent installs and registers itself with the Manager using the IP you provided as an environment variable.

---

### 4.3 Start the Agent

```bash
# Reload systemd daemon
sudo systemctl daemon-reload

# Enable the agent to start on boot
sudo systemctl enable wazuh-agent

# Start the agent
sudo systemctl start wazuh-agent
```

---

### 4.4 Verify Agent is Connected

**On the agent machine:**

```bash
sudo systemctl status wazuh-agent
```

**Expected output:**

```
● wazuh-agent.service - Wazuh agent
   Active: active (running) since ...
```

**On the Wazuh Manager server:**

```bash
sudo /var/ossec/bin/agent_control -l
```

**Expected output:**

```
Wazuh agent_control. List of available agents:
   ID: 000, Name: wazuh-server (server), IP: 127.0.0.1, Active/Local
   ID: 001, Name: linux-agent, IP: 192.168.x.x, Active
```

The agent should show as **Active**.

---

## Step 5: Enroll a Windows Agent

### 5.1 Download the Windows Agent Installer

From the **Wazuh Dashboard:**

1. Go to **☰ Menu → Agents → Deploy new agent**
2. Select **Windows** as the operating system
3. Enter your Manager's IP address
4. Copy the generated PowerShell command

Or download directly from:
```
https://packages.wazuh.com/4.x/windows/wazuh-agent-4.7.x-1.msi
```

### 5.2 Install via PowerShell (Run as Administrator)

```powershell
# Download the installer
Invoke-WebRequest -Uri https://packages.wazuh.com/4.x/windows/wazuh-agent-4.7.x-1.msi `
  -OutFile wazuh-agent.msi

# Install with Manager IP
.\wazuh-agent.msi /q WAZUH_MANAGER="<MANAGER-IP>"

# Start the Wazuh service
NET START WazuhSvc
```

### 5.3 Verify on the Manager

```bash
sudo /var/ossec/bin/agent_control -l
```

**Expected output:**

```
   ID: 000, Name: wazuh-server (server), IP: 127.0.0.1, Active/Local
   ID: 001, Name: linux-agent, IP: 192.168.x.x, Active
   ID: 002, Name: DESKTOP-XXXXX, IP: 192.168.x.x, Active
```

---

## Installation Complete ✅

You now have:
- Wazuh Manager, Indexer, and Dashboard running on your server
- A Linux agent connected and sending logs
- A Windows agent connected and sending logs
- The dashboard accessible at `https://<YOUR-IP>`

**Next Step:** Configure the system for better detection coverage → [Configuration](04-configuration.md)

---

## Quick Reference: Service Management

```bash
# Start all Wazuh services
sudo systemctl start wazuh-manager wazuh-indexer wazuh-dashboard

# Stop all services
sudo systemctl stop wazuh-manager wazuh-indexer wazuh-dashboard

# Restart all services
sudo systemctl restart wazuh-manager wazuh-indexer wazuh-dashboard

# Check status of all services
sudo systemctl status wazuh-manager wazuh-indexer wazuh-dashboard

# View Manager logs in real-time
sudo tail -f /var/ossec/logs/ossec.log

# View alerts in real-time
sudo tail -f /var/ossec/logs/alerts/alerts.json | python3 -m json.tool
```

---

*Previous: [Architecture ←](02-architecture.md) | Next: [Configuration →](04-configuration.md)*
