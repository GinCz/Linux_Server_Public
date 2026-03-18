# SSH Login: Clean MOTD + Color Prompt

**Version:** v2026-03-18  
**Applies to:** 222-DE-NetCup, 109-RU-FastVDS, VPN nodes

---

## Why `~/.bashrc` Does NOT Work on FastPanel Servers

On regular Linux servers (AWS, VPN nodes), adding `PS1` to `~/.bashrc` works permanently.

On **FastPanel servers (222, 109)** it silently breaks because:

1. SSH login loads scripts in this order:
   - `/etc/profile` → `/etc/profile.d/*.sh` → `~/.bashrc`
2. FastPanel installs `/etc/profile.d/motd.sh` which **sets its own PS1 after** `~/.bashrc` runs
3. Result: your `~/.bashrc` PS1 is set, then immediately **overwritten** by FastPanel
4. On `Ctrl+D` reconnect the cycle repeats — color is always lost

**Solution:** Put `PS1` inside FastPanel's own `/etc/profile.d/motd.sh` — at the end of the file.  
This way PS1 is set last and never overwritten.

---

## Server Color Scheme

| Server | Color | Code |
|---|---|---|
| 222-DE-NetCup | Bright Yellow | `\e[1;93m` |
| 109-RU-FastVDS | Bright Red | `\e[1;31m` |
| VPN nodes | Bright Cyan | `\e[1;36m` |
| AWS nodes | Bright Orange | `\e[1;33m` |

---

## Setup: 222-DE-NetCup (Bright Yellow)

```bash
# Step 1: Disable FastPanel's verbose MOTD and Ubuntu helpers
chmod -x /etc/update-motd.d/00-header 2>/dev/null
chmod -x /etc/update-motd.d/10-help-text 2>/dev/null
chmod -x /etc/update-motd.d/50-motd-news 2>/dev/null
> /etc/motd

# Step 2: Replace /etc/profile.d/motd.sh with minimal version + PS1
cat > /etc/profile.d/motd.sh << 'EOF'
#!/bin/bash
echo ""
echo "  FastPanel | Ubuntu 24 | 152.53.182.222 | $(uptime -p) | load: $(cut -d' ' -f1-3 /proc/loadavg)"
echo ""
export PS1='\[\e[1;93m\]\u@\h:\w\$\[\e[m\] '
EOF
chmod +x /etc/profile.d/motd.sh

# Step 3: Disable Last login line
sed -i 's/^#*PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config
systemctl reload sshd
```

**Result on login:**
```
  FastPanel | Ubuntu 24 | 152.53.182.222 | up 3 days, 13 hours | load: 2.84 3.41 3.57

root@222-DE-NetCup:~#   <- bright yellow, permanent
```

---

## Setup: 109-RU-FastVDS (Bright Red)

```bash
# Step 1: Disable FastPanel MOTD and Ubuntu helpers
chmod -x /etc/update-motd.d/00-header 2>/dev/null
chmod -x /etc/update-motd.d/10-help-text 2>/dev/null
chmod -x /etc/update-motd.d/50-motd-news 2>/dev/null
> /etc/motd

# Step 2: Replace /etc/profile.d/motd.sh with minimal version + PS1
cat > /etc/profile.d/motd.sh << 'EOF'
#!/bin/bash
echo ""
echo "  FastPanel | Ubuntu 24 | 212.109.223.109 | $(uptime -p) | load: $(cut -d' ' -f1-3 /proc/loadavg)"
echo ""
export PS1='\[\e[1;31m\]\u@\h:\w\$\[\e[m\] '
EOF
chmod +x /etc/profile.d/motd.sh

# Step 3: Disable Last login line
sed -i 's/^#*PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config
systemctl reload sshd
```

**Result on login:**
```
  FastPanel | Ubuntu 24 | 212.109.223.109 | up 13 days | load: 1.58 1.02 0.75

root@109-ru-vds:~#   <- bright red, permanent
```

---

## Setup: VPN nodes (Bright Cyan)

On VPN nodes FastPanel is NOT installed, so `~/.bashrc` works fine:

```bash
echo "export PS1='\\[\\e[1;36m\\]\\u@\\h:\\w\\$\\[\\e[m\\] '" >> /root/.bashrc
source /root/.bashrc
```

---

## Setup: AWS nodes (Bright Orange)

```bash
echo "export PS1='\\[\\e[1;33m\\]\\u@\\h:\\w\\$\\[\\e[m\\] '" >> /root/.bashrc
source /root/.bashrc
```

---

## Key Difference: FastPanel vs Standard Servers

| | Standard (VPN/AWS) | FastPanel (222/109) |
|---|---|---|
| PS1 set in | `~/.bashrc` | `/etc/profile.d/motd.sh` |
| MOTD source | `/etc/update-motd.d/` | `/etc/profile.d/motd.sh` |
| Color survives reconnect | ✅ Yes | ✅ Yes (after fix) |
| Ubuntu hint lines | `/etc/update-motd.d/10-help-text` | same |
| Fix complexity | Simple | Must override FastPanel file |
