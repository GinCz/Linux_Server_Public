# Changelog — Linux Server Public

> All notable changes to this repository are documented here.  
> Format: `YYYY-MM-DD` · `server` · `what changed`  
> = Rooted by VladiMIR | AI =

---

## 2026-04-10

### 🛡 VPN Backup System — Full Setup

**Server:** 222-DE-NetCup (`152.53.182.xxx`)  
**Script:** `VPN/vpn_docker_backup.sh`

#### What was done:

1. **SSH key deployed** to new node SO_38 (`.38`) — last of 8 nodes
   ```bash
   ssh-copy-id -i /root/.ssh/id_ed25519 root@xxx.xxx.xxx.38
   ssh -i /root/.ssh/id_ed25519 -o BatchMode=yes root@xxx.xxx.xxx.38 "echo OK"
   # → OK
   ```

2. **First full backup run** — all 8 VPN nodes:
   - 8/8 nodes OK, 0 errors
   - Total: **227 MB** in **53 seconds**
   - Each archive: ~13 MB @ 47–65 MB/s
   - Note: PILIK_178 (`.178`) — slower at 3.0 MB/s (provider limit)

3. **KEEP changed from 3 → 7** (7 archives per node):
   ```bash
   sed -i 's/^KEEP=3/KEEP=7/' /root/vpn_docker_backup.sh
   # Verified: KEEP=7
   ```

4. **Cron schedule set** — Wednesday + Saturday at **03:30**:
   ```
   30 3 * * 3,6  bash /root/vpn_docker_backup.sh >> /var/log/vpn_backup.log 2>&1
   ```
   - Start time shifted to 03:30 to avoid conflict with `docker_backup.sh` at 03:00
   - Next auto-run: **Wednesday, 2026-04-15 at 03:30**

5. **Documentation added:**
   - `VPN/BACKUP.md` — full backup docs (new file)
   - `VPN/README.md` — updated with file index and node fleet table
   - `CHANGELOG.md` — this entry

#### Current crontab on server 222:
```
*/15 * * * *   php_fpm_watchdog.sh
@reboot        fastpanel_php_ondemand.sh
0 2  * * *     backup_clean.sh
0 3  * * *     docker_backup.sh
0 2  * * 3,6   wp_update_all.sh
* * * * *      crowdsec banned count
30 3 * * 3,6   vpn_docker_backup.sh  ← NEW
```

#### Storage estimate:
```
8 nodes × 7 archives × 13 MB ≈ 730 MB on /BACKUP/vpn/
History depth: ~3.5 weeks per node
```

---

## 2026-03-25

### FastPanel PHP On-Demand
- Script `scripts/fastpanel_php_ondemand_v2026-03-25.sh` added
- Auto-runs at `@reboot` on server 222

---

## Earlier

- VPN node fleet built: 8 nodes (ALEX, 4TON, TATRA, SHAHIN, STOLB, PILIK, ILYA, SO)
- AmneziaWG installed on all nodes
- Samba, Prometheus, AdGuard Home, Kuma deployed on selected nodes
- Backup infrastructure on server 222 (NetCup Germany)
