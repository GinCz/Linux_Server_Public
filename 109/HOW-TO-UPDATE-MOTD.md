# HOW TO UPDATE MOTD (SSH Banner) on server 109-ru-vds
# v2026-04-02
# = Rooted by VladiMIR | AI =

---

## ⚠️ CRITICAL LESSON (learned the hard way)

Editing files in GitHub and doing `load` (git pull) is NOT enough.
The live MOTD file lives in `/etc/profile.d/motd_server.sh` and is
**completely separate** from the repository copy.
You MUST manually copy the repo file to `/etc/profile.d/` every time.

---

## ARCHITECTURE — Three independent layers

```
LAYER 1 — LIVE MOTD (what you SEE on SSH login)
  /etc/profile.d/motd_server.sh
  └─ Executed automatically by bash on every SSH login
  └─ This file is NOT updated by git pull!
  └─ Must be updated MANUALLY with cp -f

LAYER 2 — GITHUB SOURCE (what you EDIT)
  /root/Linux_Server_Public/109/motd_server.sh
  └─ Edit this file in GitHub (or locally)
  └─ Pull with: cd && load
  └─ Then copy to Layer 1 manually

LAYER 3 — ALIASES (commands shown in the banner)
  /root/Linux_Server_Public/109/.bashrc  ← GitHub source
  /root/.bashrc                          ← REAL system file
  └─ /root/.bash_profile loads the GitHub copy on SSH login
  └─ BUT /root/.bashrc may have OLD duplicate aliases at the
    bottom that override the correct ones!
```

---

## THE ONLY CORRECT WAY TO UPDATE MOTD

### Step 1 — Edit in GitHub
Edit this file and commit to `main`:
```
/root/Linux_Server_Public/109/motd_server.sh
```

### Step 2 — Deploy with ONE command on server 109
```bash
cd && load && cp -f /root/Linux_Server_Public/109/motd_server.sh /etc/profile.d/motd_server.sh && chmod +x /etc/profile.d/motd_server.sh && bash /etc/profile.d/motd_server.sh
```

What this does:
- `cd && load` — go to home, git pull latest from GitHub
- `cp -f ... /etc/profile.d/motd_server.sh` — overwrite the LIVE file
- `chmod +x` — make sure it is executable
- `bash /etc/profile.d/motd_server.sh` — show result immediately without reconnecting

---

## THE ONLY CORRECT WAY TO UPDATE ALIASES

### Step 1 — Edit in GitHub
Edit this file and commit to `main`:
```
/root/Linux_Server_Public/109/.bashrc
```

### Step 2 — Pull and reload
```bash
cd && load && source ~/.bashrc
```

### Step 3 — Check for old duplicate aliases
Old aliases appended to `/root/.bashrc` by old scripts will OVERRIDE
the correct aliases from the GitHub copy. Always check:
```bash
tail -30 /root/.bashrc
```
If you see a block of old aliases at the bottom — remove from that line:
```bash
sed -i '/^# WP Tools/,$ d' /root/.bashrc && source /root/.bashrc
```

---

## VERIFY everything is correct
```bash
# 1. Check live MOTD file contains the new content
grep -n "sos3\|dbackup\|allinfo" /etc/profile.d/motd_server.sh

# 2. Check GitHub copy matches
grep -n "sos3\|dbackup\|allinfo" /root/Linux_Server_Public/109/motd_server.sh

# 3. Check no old aliases override in /root/.bashrc
grep -n "sos3\|dbackup\|f5bot\|f9bot" /root/.bashrc

# 4. Find ALL places where motd_server.sh is referenced
grep -rn "motd_server" /root/ /etc/ 2>/dev/null
```

---

## FILE LOCATIONS SUMMARY

| What | Path | Updated by |
|------|------|------------|
| **Live MOTD** | `/etc/profile.d/motd_server.sh` | `cp -f` from repo copy (MANUAL) |
| **MOTD source** | `/root/Linux_Server_Public/109/motd_server.sh` | Edit in GitHub + `load` |
| **Aliases source** | `/root/Linux_Server_Public/109/.bashrc` | Edit in GitHub + `load` |
| **System bashrc** | `/root/.bashrc` | Check bottom for old duplicate aliases |
| **bash_profile** | `/root/.bash_profile` | Loads GitHub `.bashrc` on SSH login |

---

## SAME PROCEDURE FOR SERVER 222
Exact same logic, just different paths:
- Source: `/root/Linux_Server_Public/222/motd_server.sh`
- Deploy:
```bash
cd && load && cp -f /root/Linux_Server_Public/222/motd_server.sh /etc/profile.d/motd_server.sh && chmod +x /etc/profile.d/motd_server.sh && bash /etc/profile.d/motd_server.sh
```
See also: `222/HOW-TO-UPDATE-MOTD.md`
