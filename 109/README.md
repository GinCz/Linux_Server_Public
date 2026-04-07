# 🖥 Server 109-RU-FastVDS — 212.109.223.109

> FastVDS.ru, Russia | Ubuntu 24 / FASTPANEL / No Cloudflare  
> 4 vCore AMD EPYC 7763 / 8GB RAM / 80GB NVMe | 13 €/mo

---

## 📁 Structure of this folder

```
109/
├── README.md          ← this file — documentation & how-to
├── motd_server.sh     ← MOTD banner shown on every SSH login
└── .bashrc            ← aliases (aw, save, fight, banblock, etc.)
```

---

## 🖥 MOTD Banner — `motd_server.sh`

**What it shows:**
- Hostname, IP, RAM, CPU usage
- `AmneziaWG: X online / Y total peers` — from Docker container `amnezia-awg`
- `CrowdSec Engine: ● ACTIVE/INACTIVE` — via `systemctl is-active crowdsec`
- `Firewall Bouncer: ● ACTIVE/INACTIVE` — via `systemctl is-active crowdsec-firewall-bouncer`
- Full alias menu in 2 sections: SCAN & SECURITY / SERVER / WORDPRESS + GIT / TOOLS
- Footer: uptime, load average

**Install / Update:**
```bash
cd /root/Linux_Server_Public && git pull
cp 109/motd_server.sh /etc/profile.d/motd_server.sh
chmod +x /etc/profile.d/motd_server.sh
```

**Test without re-login:**
```bash
bash /etc/profile.d/motd_server.sh
```

### ✏️ How to edit the alias menu in MOTD

```bash
nano /etc/profile.d/motd_server.sh
```
- **Add/remove alias row** → find `# Row 1` or `# Row 2` block
- Each line format: `echo -e "  ${G}aliasname${X}(description) ..."`
- Column spacing: use spaces to align 3 columns (26 chars per column)
- After editing → test: `bash /etc/profile.d/motd_server.sh`
- Save to repo: `cd /root/Linux_Server_Public && cp /etc/profile.d/motd_server.sh 109/motd_server.sh && save`

---

## ⌨️ Aliases — `.bashrc`

**Location on server:** `/root/.bashrc`  
**Location in repo:** `109/.bashrc`

**Install / Update:**
```bash
cd /root/Linux_Server_Public && git pull
cp 109/.bashrc /root/.bashrc
source /root/.bashrc
```

### ✏️ How to add/edit an alias

```bash
nano /root/.bashrc
```
Format:
```bash
alias myalias='command here'
```
After editing:
```bash
source /root/.bashrc
# Save to repo:
cp /root/.bashrc /root/Linux_Server_Public/109/.bashrc && cd /root/Linux_Server_Public && save
```
> ⚠️ Also add the alias to the MOTD menu (`motd_server.sh`) so it appears in the banner!

---

## 🔒 CrowdSec — Fix if Engine goes INACTIVE

Symptom: `CrowdSec Engine: ● INACTIVE` in MOTD banner

```bash
# Step 1: restore hub index (if missing)
mkdir -p /etc/crowdsec/hub
cscli hub update

# Step 2: upgrade all components
cscli hub upgrade

# Step 3: restart
systemctl restart crowdsec
systemctl status crowdsec --no-pager | head -5
```

---

## 🐳 AmneziaWG Docker container

**Container name:** `amnezia-awg`  
**Interface:** `wg0`

```bash
# Check peers
docker exec amnezia-awg wg show wg0

# Check container status
docker ps | grep amnezia

# Restart container
docker restart amnezia-awg
```

---

## 🔄 Typical update workflow

```bash
# On server — pull latest from repo and install:
cd /root/Linux_Server_Public && git pull
cp 109/motd_server.sh /etc/profile.d/motd_server.sh
cp 109/.bashrc /root/.bashrc
source /root/.bashrc
bash /etc/profile.d/motd_server.sh

# After editing on server — push back to repo:
cd /root/Linux_Server_Public
cp /etc/profile.d/motd_server.sh 109/motd_server.sh
cp /root/.bashrc 109/.bashrc
save
```
