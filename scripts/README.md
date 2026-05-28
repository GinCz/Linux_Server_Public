# scripts/

> Universal shell scripts for managing all 10 servers in the GinCz infrastructure.
> Deployed and executed remotely from the main server **222-DE-NetCup** (`152.53.182.222`) via SSH.
>
> = Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz =

---

## Server Fleet

| Hostname | IP | Role |
|---|---|---|
| 222-EU-NetCup | 152.53.182.222 | Main server — DE, FastPanel, Cloudflare, Docker, CryptoBot |
| 109-RU-FastVDS | 212.109.223.109 | RU server — FastPanel, Samba, XRAY VPN |
| VPN-EU-ALEX-47 | 109.234.38.47 | VPN node — XRAY + Samba |
| VPN-EU-4TON-237 | 144.124.228.237 | VPN node — XRAY + Samba |
| VPN-EU-TATRA-9 | 144.124.232.9 | VPN node — XRAY + Samba + Uptime Kuma |
| VPN-EU-SHAHIN-227 | 144.124.228.227 | VPN node — AmneziaWG + Samba |
| VPN-EU-STOLB-24 | 144.124.239.24 | VPN node — XRAY + Samba + AdGuard Home |
| VPN-EU-PILIK-178 | 91.84.118.178 | VPN node — AmneziaWG + Samba |
| VPN-EU-ILYA-176 | 146.103.110.176 | VPN node — AmneziaWG + Samba |
| VPN-EU-SO-38 | 144.124.233.38 | VPN node — XRAY + Samba |

---

## Scripts

### `fix_crowdsec_global.sh`
**Version:** v2026.05.28  
**Run on:** All 10 servers (from server 222 via SSH loop)

Universal CrowdSec + Samba configuration fix. Resolves 4 known issues present across all servers:

| Step | Fix | Issue |
|---|---|---|
| 1/5 | `sshd.yaml` | Remove journalctl duplicate, fix `type: ssh` → `type: syslog` |
| 2/5 | `setup.smb.yaml` | Replace glob `log.*` / `*.log` with single `log.smbd` |
| 3/5 | `smb.conf` | Set `log level = 1`, unified `log.smbd`, remove `full_audit` |
| 4/5 | Samba per-IP logs | Delete stale `log.<IP>` files older than 1 day |
| 5/5 | fwupd | Stop and mask — firmware daemon useless on VPS, wastes ~26MB RAM |

**Deploy to all servers from 222:**
```bash
SSH_OPTS="-o ConnectTimeout=10 -o StrictHostKeyChecking=no -o BatchMode=yes -o LogLevel=ERROR"
SCRIPT_URL="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/fix_crowdsec_global.sh"

for IP in 152.53.182.222 212.109.223.109 109.234.38.47 144.124.228.237 \
           144.124.232.9 144.124.228.227 144.124.239.24 \
           91.84.118.178 146.103.110.176 144.124.233.38; do
  ssh $SSH_OPTS root@$IP "bash <(curl -fsSL $SCRIPT_URL)"
done
```

---

### `sos.sh`
**Version:** v2026.05.25  
**Run on:** All servers (installed as alias `sos`, `sos1`, `sos3`, `sos24`, `sos120`)

Server health dashboard — shows CrowdSec bans, Nginx errors, Samba activity, disk and RAM usage for a given time window.

| Alias | Period |
|---|---|
| `sos` | 24h (default) |
| `sos1` | 1h |
| `sos3` | 3h |
| `sos24` | 24h |
| `sos120` | 120h |
| `sos 30m` | any custom period |

---

### `all_servers_info.sh`
**Version:** v2026.05.21  
**Run on:** Server 222 (alias `allinfo`)

Ping + SSH uptime check for all known servers. Quick status overview from main server.

---

### `install_sos.sh`
**Version:** v2026.05.28  
**Run on:** Any new server

Universal installer — deploys `sos.sh` and all aliases to a fresh server.

---

### `setup_aliases_modded_mc.sh`
**Version:** v2026.05.25  
**Run on:** Any server

Sets up all admin aliases in `.bashrc` and `/etc/bash.bashrc`. Includes auto-repair of broken bashrc blocks.

---

### `shared_aliases.sh`
**Version:** v2026.05.26  
**Run on:** All VPN nodes

Shared alias file sourced by `.bashrc` on VPN nodes. Fixes `.bashrc` line 79 parse error on PILIK-178 and ILYA-176.

---

## Deployment Pattern

All scripts are deployed from **server 222** to all other servers via SSH:

```bash
SSH_OPTS="-o ConnectTimeout=10 -o StrictHostKeyChecking=no -o BatchMode=yes -o LogLevel=ERROR"

for IP in <server_list>; do
  ssh $SSH_OPTS root@$IP "bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/<script>.sh)"
done
```

---

*= Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz =*
