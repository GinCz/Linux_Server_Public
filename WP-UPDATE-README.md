# WP Update All — Session Log & Documentation

> Date: 2026-05-21 (session ~22:00 – 01:30 CEST)
> Servers: 222-EU-NetCup (152.53.182.222) | 109-RU-FastVDS (212.109.223.109)
> Author: VladiMIR + AI (Perplexity / Grok)
> Repo: https://github.com/GinCz/Linux_Server_Public

---

## Goal

Create a single bash script `wp_update_all.sh` that:
- Updates ALL WordPress sites on both FastPanel servers automatically
- Runs as the **site owner** (not root) via `sudo -u USER` to avoid permission errors
- Updates: translations (core/plugins/themes), plugins, themes
- Checks WP core version (info only, no auto-update)
- Runs every night via systemd timer
- Is documented in GitHub so any new server can be set up in 2 minutes

---

## Final File Structure in Repo

```
222/
  wp_update_all.sh          ← main script (alias: wpupd)
  systemd/
    wp-update.service       ← systemd service
    wp-update.timer         ← runs EVERY NIGHT at 02:00

109/
  wp_update_all.sh          ← main script (alias: wpupd)
  systemd/
    wp-update.service       ← systemd service
    wp-update.timer         ← runs EVERY NIGHT at 03:00
```

---

## Quick Install on Any New Server

### Server 222 (EU-NetCup)
```bash
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/222/wp_update_all.sh \
     -o /root/wp_update_all.sh && chmod +x /root/wp_update_all.sh

echo "alias wpupd='bash /root/wp_update_all.sh'" >> ~/.bashrc && source ~/.bashrc

curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/222/systemd/wp-update.service \
     -o /etc/systemd/system/wp-update.service
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/222/systemd/wp-update.timer \
     -o /etc/systemd/system/wp-update.timer

systemctl daemon-reload
systemctl enable --now wp-update.timer
systemctl list-timers wp-update.timer
```

### Server 109 (RU-FastVDS)
```bash
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/109/wp_update_all.sh \
     -o /root/wp_update_all.sh && chmod +x /root/wp_update_all.sh

echo "alias wpupd='bash /root/wp_update_all.sh'" >> ~/.bashrc && source ~/.bashrc

curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/109/systemd/wp-update.service \
     -o /etc/systemd/system/wp-update.service
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/109/systemd/wp-update.timer \
     -o /etc/systemd/system/wp-update.timer

systemctl daemon-reload
systemctl enable --now wp-update.timer
systemctl list-timers wp-update.timer
```

---

## Check & Logs

```bash
# Timer status
systemctl list-timers wp-update.timer
systemctl status wp-update.timer

# Last 50 lines of log
tail -50 /var/log/wp_update.log

# Live log
tail -f /var/log/wp_update.log

# journald
journalctl -u wp-update.service -n 50
```

---

## ⚠️ Errors Encountered During This Session

### ERROR 1 — wp-cli runs as root → permission denied on wp-content/

**Problem:**  
Running `wp plugin update --all --path=/var/www/USER/data/www/DOMAIN/` as root  
causes wp-cli to write files as `root`, making them unreadable by the PHP/nginx  
process running as site owner. Also throws:
```
Warning: file_put_contents(...wp-content/languages/...): Failed to open stream: Permission denied
```

**Fix (Grok helped to finalize this):**  
Run wp-cli **as the site owner** using:
```bash
sudo -u "$SITE_USER" /usr/local/bin/wp plugin update --all --path="$DOMAIN_DIR" --no-color
```
This way all file writes happen as the correct user.

**Key point:** FastPanel creates each site under its own Linux user.  
Structure: `/var/www/USERNAME/data/www/DOMAIN/`

---

### ERROR 2 — nano editor opened after script ran

**Problem:**  
After running the setup script, `nano` editor opened unexpectedly.  
The script was using `crontab -e` somewhere (opens editor) instead of  
`crontab -l | ... | crontab -` (non-interactive add).

**Fix:**  
Replaced `crontab -e` with non-interactive one-liner:
```bash
(crontab -l 2>/dev/null; echo "0 2 * * * bash /root/wp_update_all.sh >> /var/log/wp_update.log 2>&1") | crontab -
```
Later switched entirely to **systemd timer** (no cron needed).

---

### ERROR 3 — MOTD menu loaded twice on login

**Problem:**  
After running setup script and re-logging in, the custom MOTD/menu  
(the `modd` alias / interactive menu) appeared **twice** in the terminal.

**Root cause:**  
The setup script appended lines to `~/.bashrc` which were already there,  
causing the menu to be triggered twice (once from `.bash_profile` sourcing  
`.bashrc`, once from `.bashrc` itself running on interactive shell).

**Fix:**  
Check before appending to avoid duplicates:
```bash
grep -qF 'alias wpupd' ~/.bashrc || echo "alias wpupd='bash /root/wp_update_all.sh'" >> ~/.bashrc
```
Or manually check:
```bash
grep 'wpupd\|wp_update' ~/.bashrc ~/.bash_profile
```

---

### ERROR 4 — Timer was set to Wed+Sat instead of daily

**Problem:**  
Initial systemd timer used `OnCalendar=Wed,Sat *-*-* 02:00:00`  
(twice a week) instead of every night.

**Fix:**  
Changed to daily:
```ini
[Timer]
OnCalendar=*-*-* 02:00:00   # server 222
OnCalendar=*-*-* 03:00:00   # server 109
Persistent=true
```

**Update timer without reinstall:**
```bash
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/222/systemd/wp-update.timer \
     -o /etc/systemd/system/wp-update.timer
systemctl daemon-reload
systemctl restart wp-update.timer
systemctl list-timers wp-update.timer
```

---

### ERROR 5 — Old duplicate scripts left on servers

**Problem:**  
Old scripts `wp_update_all_222.sh` and `wp_update_all_109.sh` were left  
on both servers alongside the new `wp_update_all.sh`. Caused confusion.

**Fix (executed):**
```bash
# On 222:
rm -f /root/wp_update_all_222.sh

# On 109:
rm -f /root/wp_update_all_109.sh
```

---

## What Perplexity AI Could Not Do / Grok Did Instead

| Task | Status | Who fixed |
|------|--------|----------|
| Logic to run wp-cli as site owner (`sudo -u USER`) | ⚠️ First versions ran as root | **Grok** finalized the correct `sudo -u` approach |
| Fixing nano opening during setup | ⚠️ Perplexity generated `crontab -e` | Fixed to non-interactive after user reported the issue |
| MOTD loading twice | ⚠️ Perplexity missed duplicate append check | Fixed after user reported |
| Timer schedule (daily vs twice/week) | ❌ Wrong schedule in first version | Fixed after user pointed out |

**Lesson learned:**  
When writing scripts that modify `~/.bashrc` or `crontab`, ALWAYS:
1. Use `grep -qF 'pattern' file || echo '...' >> file` to prevent duplicates
2. Use non-interactive crontab editing (pipe to `crontab -`)
3. Test with fresh shell session after every setup script run

---

## FastPanel-Specific Notes

- User directories: `/var/www/USERNAME/`
- Sites: `/var/www/USERNAME/data/www/DOMAIN/`
- `wp-config.php` presence = WordPress site
- System users to skip: `fastuser`, `lost+found`
- Always run wp-cli as site owner, NOT root
- wp-cli path: `/usr/local/bin/wp`

---

## Current Status (2026-05-21 01:30 CEST)

| | Server 222 (EU-NetCup) | Server 109 (RU-FastVDS) |
|---|---|---|
| Script | `/root/wp_update_all.sh` ✅ | `/root/wp_update_all.sh` ✅ |
| Alias | `wpupd` ✅ | `wpupd` ✅ |
| systemd timer | `02:00 daily` ⚠️ update needed | `03:00 daily` ✅ |
| Log | `/var/log/wp_update.log` | `/var/log/wp_update.log` |
| Old duplicates | deleted ✅ | deleted ✅ |

---

*= Rooted by VladiMIR + AI | v.2026.05.21 | github.com/GinCz =*
