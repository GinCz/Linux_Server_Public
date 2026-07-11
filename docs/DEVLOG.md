# DEVLOG — Development Journal

## Session 2026-06-10 (VladiMIR + AI)

> Work done jointly: VladiMIR Bulantsev (GinCz) + Perplexity AI
> Repository: https://github.com/GinCz/Linux_Server_Public
> Files affected: `scripts/new_server_install.sh`, `scripts/upd.sh`, `scripts/night_update.sh`, `scripts/motd_vpn.sh`, `scripts/motd_222.sh`, `scripts/motd_109.sh`

---

### 1. `upd.sh` — refactoring + nightly auto-update

**Problem:** the `upd` alias for `apt upgrade` ran updates directly without control — no logs, no service checks after reboot.

**What was done:**

- Added **startup menu**: `1) Run now` / `2) Install scheduler`
- `Install scheduler` mode:
  - deploys `night_update.sh` to `/usr/local/bin/`
  - sets up cron: update at **3:00 AM**, plus `@reboot` hook
  - after install prints a readable schedule summary

- Reboot delay changed from `sleep 3` → `sleep 30` (to allow time to read output)

**Commits:**
- [`71932cd`](https://github.com/GinCz/Linux_Server_Public/commit/71932cdf4e8e4390d002f9443a46bdf8293f4c4b) — full logic rework — run vs install menu
- [`e5b9bf5`](https://github.com/GinCz/Linux_Server_Public/commit/e5b9bf5b115a8957d9ab47ce4cedf69c7bf4ba18) — deploy night_update.sh + @reboot cron in install mode
- [`7bbff97`](https://github.com/GinCz/Linux_Server_Public/commit/7bbff97bf4c73c0c8372839638c3f288ba347331) — show readable crontab summary after install
- [`5ced82e`](https://github.com/GinCz/Linux_Server_Public/commit/5ced82eea591c9a4680fe4ed021608f2525de31f) — sleep 3→30 before reboot

---

### 2. `night_update.sh` — new nightly update script

**What it does:**
- Runs automatically at 3:00 via cron
- Executes `apt update && apt upgrade -y && autoremove`
- Writes log to `/var/log/night_update.log`
- Checks if reboot is required (`/var/run/reboot-required`)
- If required — reboots
- After `@reboot` waits 90 seconds then runs `sos 1h` — post-reboot audit
- Checks for failed services (`systemctl --failed`), filters lines with `●`

**Commits:**
- [`d31c89a`](https://github.com/GinCz/Linux_Server_Public/commit/d31c89ad58227e32422b7eecd817fd04e3ae04bb) — add to repo, fix sleep 30→90 in post-reboot audit
- [`5ced82e`](https://github.com/GinCz/Linux_Server_Public/commit/5ced82eea591c9a4680fe4ed021608f2525de31f) — fix systemctl failed units parsing (skip ● bullet)

---

### 3. MOTD — merge Type + CrowdSec into one line

**Problem:** VPN server MOTD showed two separate lines:
```
  Type: VPN / XRay / AmneziaWG / AdGuard / Semaphore
  CrowdSec: ● ACTIVE | bans: 4
```
This wasted space and was redundant.

**Solution:** merged into single `CS_LINE`:
```
  Type: VPN   CrowdSec: ● ACTIVE | bans: 4
```

For servers 222 and 109 similarly: Xray + CrowdSec Engine + Firewall lines merged into `CS_LINE`.

**Commits:**
- [`c8a971c`](https://github.com/GinCz/Linux_Server_Public/commit/c8a971c4c3971d14e996ea6a5a35f837c6f734ba) — motd_vpn.sh: merge AWG/Type and CrowdSec into one line
- [`bad2f9d`](https://github.com/GinCz/Linux_Server_Public/commit/bad2f9d3fc69bc187b22c0a6c8df477fe696d760) — MOTD types 2&3: merge Xray+CrowdSec into single CS_LINE

---

### 4. MOTD — separate cheatsheets for 222 and 109

**Problem:** servers 222 (Cloudflare) and 109 (no Cloudflare) showed the same cheatsheet, even though their alias sets differ. Test aliases `aws-test` were also present.

**Solution:** split cheatsheets in MOTD — each type shows only its own commands. Removed `aws-test` from all types.

**Commit:**
- [`d7dbe52`](https://github.com/GinCz/Linux_Server_Public/commit/d7dbe520a77f2b160b3e23488bcdcaea7b3b328f) — separate MOTD cheatsheets for 222/109, remove aws-test everywhere

---

### 5. MOTD — 🖥 icon replaced with `[S]` ASCII

**Problem:** emoji `🖥` (U+1F5A5, computer) renders as double-width in most SSH terminals, breaking `printf` alignment. Attempts to compensate with extra spaces and `echo -n` were unstable.

**Solution:** replaced with ASCII string `[S]` in all three MOTD types — width is always predictable.

**Commits (iterations):**
- [`dcb96df`](https://github.com/GinCz/Linux_Server_Public/commit/dcb96dff85697c45c64ddcc1421e37eb0714b938) — replace broken lock emoji with computer icon (U+1F5A5)
- [`96e759e`](https://github.com/GinCz/Linux_Server_Public/commit/96e759ede814346240627dc16e30ad2fb4db2307) — add extra space after emoji
- [`8dc26b2`](https://github.com/GinCz/Linux_Server_Public/commit/8dc26b275fe29314b9e0c9cb70e8a52039490614) — print emoji separately via echo -n
- [`e140ba8`](https://github.com/GinCz/Linux_Server_Public/commit/e140ba87e84fdef37d08097e8b688a3f55b9acff) — emoji inside printf like VPN/motd_server.sh
- [`737dce7`](https://github.com/GinCz/Linux_Server_Public/commit/737dce759ab2964795b006a6cc4468be69dcc7fe) — globe for 222/109, key for VPN
- [`345cc99`](https://github.com/GinCz/Linux_Server_Public/commit/345cc99685ac117754028daac36950443728c608) — **final fix: replace 🖥 with [S] ASCII in all MOTD types**

---

### 6. `sos` — new OPEN PORTS section (section 27)

**Problem:** the open ports section in `sos` produced 20+ duplicate lines for `named:53` — one per IPv6 interface address.

**What was done:**
- Deduplication by `port+procname` pair via `awk match()` with proper parsing of `users:((\"name\",pid=N,fd=N))` format
- Addresses shown in cyan, process name in green with quotes
- Sorted by port number
- IPv6 addresses grouped (no duplicates)
- Added Key Ports table: 22, 25, 53, 80, 443, 445, 3000, 8080, 51820
- Separate `ports.sh` removed — logic moved inside `sos`

**Commits:**
- [`7ef799a`](https://github.com/GinCz/Linux_Server_Public/commit/7ef799a4fb28d1f233a86fde1ec7ef52b0cf2afd) — add full ports section (dedup, key ports table)
- [`911c0f7`](https://github.com/GinCz/Linux_Server_Public/commit/911c0f70c1407e1e9554718539bd261793f7a89c) — proper dedup + colored output
- [`ce85a69`](https://github.com/GinCz/Linux_Server_Public/commit/ce85a69194a3108396afa0b1ef8d5ba1889f31df) — dedup named/fe80, IPv6 grouping, removed separate ports.sh

---

### 7. `new_server_install.sh` STEP 1 — remove SSH banner

**Problem:** on every SSH login, system lines were displayed:
```
Using username "root".
Last login: Wed Jun 10 00:21:50 2026 from 185.100.197.16
```
These lines cannot be removed from MOTD — they are generated by the SSH daemon and PAM before any scripts run.

**Solution:** added to STEP 1 of the installer:
```bash
sed -i 's/^#\?PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config
grep -q '^PrintLastLog' /etc/ssh/sshd_config || echo 'PrintLastLog no' >> /etc/ssh/sshd_config
sed -i 's/^#\?PrintMotd.*/PrintMotd no/'  /etc/ssh/sshd_config
grep -q '^PrintMotd'    /etc/ssh/sshd_config || echo 'PrintMotd no' >> /etc/ssh/sshd_config
systemctl reload ssh
```

- `PrintLastLog no` — removes the `Last login: ...` line
- `PrintMotd no` — disables PAM output of `/etc/motd` (prevents duplication of our custom MOTD)

Included in `new_server_install.sh` starting from `v2026.06.10k`.

---

### 8. Blacklist — updates

Automatic and manual updates of blacklist files:
- [`c808cbb`](https://github.com/GinCz/Linux_Server_Public/commit/c808cbbe2d1278d455cd3a261b6b8ce2fc059ef3) — 27 IPs from 222-DE-NetCup
- [`f6f2728`](https://github.com/GinCz/Linux_Server_Public/commit/f6f27289dcb3d3ab7b26cb8522d82d83105837d6) — all-nodes update, 109 unique IPs

---

## Applying to existing server (without reinstalling)

```bash
# 1. Pull everything from the repository
load

# 2. Remove SSH banner "Last login" and "Using username"
sed -i 's/^#\?PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config
grep -q '^PrintLastLog' /etc/ssh/sshd_config || echo 'PrintLastLog no' >> /etc/ssh/sshd_config
sed -i 's/^#\?PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config
grep -q '^PrintMotd' /etc/ssh/sshd_config || echo 'PrintMotd no' >> /etc/ssh/sshd_config
systemctl reload ssh && echo "OK: SSH banner disabled"

# 3. Update MOTD (for VPN server)
cp /root/Linux_Server_Public/scripts/motd_vpn.sh /etc/profile.d/motd_server.sh
chmod +x /etc/profile.d/motd_server.sh
echo "OK: MOTD updated"

# 4. Check MOTD right now (without reconnecting)
bash /etc/profile.d/motd_server.sh
```

> After this, on the next SSH connection the `Using username` and `Last login` lines will disappear, and MOTD will show the merged line `Type: VPN | CrowdSec: ● ACTIVE | bans: N`.

---

*Log started: 2026-06-10 | = Rooted by VladiMIR + AI | github.com/GinCz =*
