# HOW TO UPDATE MOTD (SSH Banner) on server 222-DE-NetCup
# v2026-04-02
# = Rooted by VladiMIR | AI =

## ARCHITECTURE — How it works

The SSH banner (MOTD) on server 222 is built from THREE separate files.
All three must be in sync. Editing only one or two will NOT work.

```
/etc/profile.d/motd_server.sh   ← MASTER FILE — executes on every SSH login
                                   This is what the user actually SEES.
                                   Source of truth for the live banner.

/root/Linux_Server_Public/222/motd_server.sh  ← GitHub copy
                                   Edit this file in GitHub.
                                   Then copy to /etc/profile.d/ manually.

/root/.bashrc                   ← Contains aliases (commands shown in banner)
                                   GitHub path: /root/Linux_Server_Public/222/.bashrc
                                   Loaded via /root/.bash_profile on SSH login.
```

## IMPORTANT: /root/.bashrc vs /root/Linux_Server_Public/222/.bashrc

There are TWO .bashrc files:

1. `/root/.bashrc` — the REAL system file loaded by bash
2. `/root/Linux_Server_Public/222/.bashrc` — the GitHub copy

`/root/.bash_profile` loads the GitHub copy:
```bash
source /root/Linux_Server_Public/222/.bashrc
```

BUT: `/root/.bashrc` also exists and may contain OLD/DUPLICATE aliases
at the bottom that OVERRIDE the correct ones from the GitHub copy.

### DANGER ZONE in /root/.bashrc
Always check the bottom of `/root/.bashrc` for duplicate/old aliases:
```bash
cat /root/.bashrc
```
If you see a block like `# WP Tools v20xx-xx-xx` at the bottom with
old aliases — remove everything from that line to end of file:
```bash
sed -i '/^# WP Tools/,$ d' /root/.bashrc
```

## STEP-BY-STEP: How to update the banner

### Step 1 — Edit in GitHub
Edit the file:
```
/root/Linux_Server_Public/222/motd_server.sh
```
Commit to `main` branch.

### Step 2 — Pull to server
```bash
cd && load
```
This runs `git pull` in `/root/Linux_Server_Public/`.

### Step 3 — Copy to /etc/profile.d/ (THE CRITICAL STEP)
```bash
cp -f /root/Linux_Server_Public/222/motd_server.sh /etc/profile.d/motd_server.sh && chmod +x /etc/profile.d/motd_server.sh
```
⚠️ This step is ALWAYS required. GitHub pull alone does NOT update the live banner.
The file in `/etc/profile.d/` is completely separate from the repo copy.

### Step 4 — Verify immediately (without reconnecting)
```bash
bash /etc/profile.d/motd_server.sh
```
You will see the new banner right away.

### Step 5 — Reconnect SSH to confirm
Close and reopen SSH session. The new banner should appear on login.

## ONE-LINER (Steps 2+3+4 combined)
```bash
cd && load && cp -f /root/Linux_Server_Public/222/motd_server.sh /etc/profile.d/motd_server.sh && chmod +x /etc/profile.d/motd_server.sh && bash /etc/profile.d/motd_server.sh
```

## HOW TO UPDATE ALIASES (.bashrc)

### Step 1 — Edit in GitHub
Edit: `/root/Linux_Server_Public/222/.bashrc`

### Step 2 — Pull and reload
```bash
cd && load && source ~/.bashrc
```

### Step 3 — Check for duplicates at bottom of /root/.bashrc
```bash
tail -20 /root/.bashrc
```
If old aliases exist at the bottom — clean them:
```bash
sed -i '/^# WP Tools/,$ d' /root/.bashrc && source /root/.bashrc
```

## VERIFY everything is consistent
```bash
# Check what is actually running as MOTD
grep -n "sos3\|dbackup\|allinfo" /etc/profile.d/motd_server.sh

# Check aliases loaded in current session
alias | grep -E "sos3|dbackup|allinfo"

# Check /root/.bashrc for old overrides
grep -n "sos3\|dbackup\|f5bot\|f9bot" /root/.bashrc
```

## FILE LOCATIONS SUMMARY

| What | Path | How to update |
|------|------|---------------|
| Live MOTD | `/etc/profile.d/motd_server.sh` | `cp -f` from repo copy |
| MOTD source | `/root/Linux_Server_Public/222/motd_server.sh` | Edit in GitHub, then `load` |
| Aliases source | `/root/Linux_Server_Public/222/.bashrc` | Edit in GitHub, then `load` |
| System bashrc | `/root/.bashrc` | Check for old duplicates at bottom |
| bash_profile | `/root/.bash_profile` | Loads GitHub `.bashrc` on SSH login |

## SAME PROCEDURE FOR SERVER 109
Exact same logic applies to server 109 (212.109.223.109):
- Edit: `/root/Linux_Server_Public/109/motd_server.sh`
- Deploy: `cp -f /root/Linux_Server_Public/109/motd_server.sh /etc/profile.d/motd_server.sh && chmod +x /etc/profile.d/motd_server.sh`
