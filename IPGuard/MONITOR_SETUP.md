# IPGuard Monitor — Setup Guide

> = Rooted by VladiMIR + AI | v.2026.07.04 | github.com/GinCz =

## What is monitor-ipguard.sh

A daily health check script that runs **on server 222 only** and checks all 11 nodes via SSH.

Checks per node:
- CrowdSec service status + active ban count
- `ipset vladblacklist` loaded + IP count (warns if < 100)
- `iptables` DROP rule active
- `deploy-blacklist` cron job present
- `collect-from-vpn` cron job (master node 222 only)

Sends a **silent Telegram notification** daily at 10:00.
- Green report if all OK
- Red alert listing specific failures per node

## Installation (server 222 only)

```bash
# 1. Download template
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/monitor-ipguard.sh \
  -o /root/monitor-ipguard.sh

# 2. Fill in your Telegram credentials
nano /root/monitor-ipguard.sh
# Set: TG_TOKEN and TG_CHAT

# 3. Make executable
chmod +x /root/monitor-ipguard.sh

# 4. Add to crontab
(crontab -l 2>/dev/null; echo "0 10 * * * /root/monitor-ipguard.sh >> /var/log/monitor-ipguard.log 2>&1") | crontab -

# 5. Test immediately
bash /root/monitor-ipguard.sh
tail -20 /var/log/monitor-ipguard.log
```

## Full Cron Schedule on Server 222

```
0  */3 * * *  collect-from-vpn.sh    — collect CrowdSec bans from all nodes → push GitHub
30 */3 * * *  deploy-blacklist.sh    — pull blacklist from GitHub → apply ipset locally
0  10  * * *  monitor-ipguard.sh     — daily health check → silent Telegram report
```

## Node List (11 servers)

| Name | IP | Role |
|---|---|---|
| 222-DE-NetCup | 152.53.182.222 | Master (collector) |
| 109-RU-FastVDS | 212.109.223.109 | Web + VPN |
| IONOS-38 | 82.223.116.38 | VPN |
| ALEX-47 | 212.34.148.51 | VPN |
| 4TON-237 | 144.124.228.237 | VPN |
| TATRA-9 | 144.124.232.9 | VPN + Kuma |
| SHAHIN-227 | 144.124.228.227 | VPN |
| STOLB-24 | 144.124.239.24 | VPN + AdGuard |
| PILIK-33 | 195.63.138.33 | VPN |
| ILYA-176 | 146.103.110.176 | VPN |
| SO-38 | 144.124.233.38 | VPN |

## Telegram Report Format

```
✅ IPGuard OK — all 11 servers protected
📅 04.07.2026 10:00

🟢 109-RU-FastVDS  212.109.223.109
   bans: 81 | ipset: 8547 IP
🟢 222-DE-NetCup   152.53.182.222
   bans: 12 | ipset: 8547 IP
...

📊 GitHub blacklist: 8547 IP | updated: 3 hours ago
✔ OK: 11/11
```

## Log File

```bash
tail -50 /var/log/monitor-ipguard.log
```

## Credentials

Telegram token and chat ID are stored in **Secret_Privat** repository.
Never commit credentials to this public repository.
