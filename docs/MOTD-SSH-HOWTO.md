# MOTD — Emoji and SSH Banner: Complete Guide

> **This file was created specifically to avoid wasting 2 hours next time.**
> Everything is here: why it broke, how to fix it, which code works.

---

## ⚡ QUICK ANSWER (if everything is already broken)

### Remove “Using username” and “Last login” on SSH login

```bash
sed -i 's/^#\?PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config
sed -i 's/^#\?PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config
systemctl reload ssh
```

### Icons for MOTD (already tested, work in terminal)

```bash
# TYPE 1 — VPN servers (4Ton and others)
echo -e "  \U0001F511  Server_Name"   # 🔑

# TYPE 2 — Server 222-DE-NetCup (152.53.182.222)
echo -e "  \U0001F310  Server_Name"   # 🌐

# TYPE 3 — Server 109 (212.109.223.109)
echo -e "  \U0001F310  Server_Name"   # 🌐
```

---

## PROBLEM 1 — SSH banner on login

### Symptom

When connecting via SSH (PuTTY, MobaXterm, any client), extra lines appear **before** our custom MOTD:

```
Using username "root".
Last login: Wed Jun 10 00:21:50 2026 from 185.100.197.16
```

### Where this comes from

| Line | Source | Controlled by |
|---|---|---|
| `Using username "root".` | SSH **client** (PuTTY/MobaXterm) — not the server | Client settings, cannot be removed from server side |
| `Last login: ...` | SSH **server**, parameter `PrintLastLog` | `/etc/ssh/sshd_config` → `PrintLastLog no` |
| System `/etc/motd` | PAM module `pam_motd` | `/etc/ssh/sshd_config` → `PrintMotd no` |

> **Note:** The `Using username` line comes from the client (PuTTY shows it itself).
> It can only be removed in the client settings. Cannot be removed from the server side.

### Solution

```bash
# On any server (222, 109, VPN — all the same):
sed -i 's/^#\?PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config
grep -q '^PrintLastLog' /etc/ssh/sshd_config || echo 'PrintLastLog no' >> /etc/ssh/sshd_config

sed -i 's/^#\?PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config
grep -q '^PrintMotd' /etc/ssh/sshd_config || echo 'PrintMotd no' >> /etc/ssh/sshd_config

systemctl reload ssh
# Or if reload doesn't work:
systemctl reload sshd
```

### Verification

```bash
grep -E 'PrintLastLog|PrintMotd' /etc/ssh/sshd_config
# Expected output:
# PrintLastLog no
# PrintMotd no
```

After this **reconnect** — the lines will disappear.

### In new_server_install.sh script

This block is already added to **STEP 1** of the script — it is applied automatically when installing a new server.

---

## PROBLEM 2 — Emoji breaks line alignment in terminal

### Symptom

The icon takes up **one and a half cells** instead of two (or instead of one) in the terminal, causing the entire MOTD line to shift:

```
# Broken — 🖥 is not rendered as a full wide character:
  🖥  222-DE-NetCup  152.53.182.222  ...
     ^^^--- space shifted, line is uneven
```

### Why this happens

Not all emojis are equal. In Unicode there are two types:

| Type | Range | Width in terminal | Examples |
|---|---|---|---|
| **Miscellaneous Symbols** | U+2600–U+26FF, U+2700–U+27BF | **1.5 cells** — PROBLEMATIC | `🖥` (U+1F5A5), `⚡`, `☁` |
| **Emoji block** (full emojis) | U+1F300–U+1FFFF | **2 cells** — works correctly | `🔑` (U+1F511), `🌐` (U+1F310) |

Terminals (PuTTY, MobaXterm, iTerm2, Windows Terminal) interpret character width **differently**.
Characters from “Miscellaneous Symbols” and “Transport Symbols” are especially unpredictable.

### Which icons to use

**Verified — work everywhere:**

| Emoji | Unicode | Hex escape for bash | Usage |
|---|---|---|---|
| 🔑 | U+1F511 | `\U0001F511` | VPN servers (TYPE 1) |
| 🌐 | U+1F310 | `\U0001F310` | Web servers 222 and 109 (TYPE 2, 3) |

**Problematic — do NOT use:**

| Emoji | Unicode | Problem |
|---|---|---|
| 🖥 | U+1F5A5 | Renders as 1.5 characters — breaks alignment |
| 💻 | U+1F4BB | Unstable across different terminals |
| 🖨 | U+1F5A8 | Same problem |

### How to correctly insert emoji into a bash script

**CORRECT — via Unicode escape:**
```bash
echo -e "  \U0001F511  ${W}${HN}${X}  ..."
echo -e "  \U0001F310  ${W}${HN}${X}  ..."
```

**INCORRECT — direct character insertion:**
```bash
echo "  🔑  ${HN}  ..."    # May break when:
                             # - passed via curl
                             # - heredoc with wrong encoding
                             # - locale is not UTF-8 on server
```

**Why `\U0001F511` is better than direct insertion:**
- Works regardless of server locale (`LANG=C`, `LANG=en_US.UTF-8` — doesn't matter)
- Doesn't break with `curl | bash` or `bash <(...)`
- Doesn't depend on how the editor saved the file
- `echo -e` with `\U` is bash built-in, works in bash 4.0+

---

## PROBLEM 3 — Icon missing in TYPE 2 / TYPE 3

### Symptom

After changes, the icon appeared on the VPN server but not on 222 and 109:
```
# VPN (TYPE 1) — OK:
  🔑  4Ton-237  144.124.228.237  ...

# Web (TYPE 2) — broken:
  222-DE-NetCup  152.53.182.222  ...   ← no icon
```

### Cause

The script has three independent blocks (`TYPE_1`, `TYPE_2`, `TYPE_3`). A change in one block **does not automatically apply** to the others.

### Solution

Always when changing MOTD check **all three blocks** in `new_server_install.sh`:
- `# === TYPE 1 — VPN ===`
- `# === TYPE 2 — Web 222/CF ===`
- `# === TYPE 3 — Web 109 ===`

Each block contains its own MOTD header line. All three must be updated.

---

## CODE — How it is implemented in the script

### File: `scripts/new_server_install.sh`

#### STEP 1 — SSH banner (applied for all types)

```bash
# === SSH: hide "Last login" and system motd ===
SEEKED_SSHD=/etc/ssh/sshd_config
if [ -f "$SEEKED_SSHD" ]; then
  sed -i 's/^#\?PrintLastLog.*/PrintLastLog no/'  "$SEEKED_SSHD"
  grep -q '^PrintLastLog' "$SEEKED_SSHD" || echo 'PrintLastLog no' >> "$SEEKED_SSHD"
  sed -i 's/^#\?PrintMotd.*/PrintMotd no/'        "$SEEKED_SSHD"
  grep -q '^PrintMotd'     "$SEEKED_SSHD" || echo 'PrintMotd no'     >> "$SEEKED_SSHD"
  systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true
fi
```

#### MOTD — header line for each type

```bash
# TYPE 1 — VPN (4Ton and other VPN servers)
echo -e "  \U0001F511  ${W}${HN}${X}  ${Y}${IP}${X}  RAM:${W}${RAM_USED}/${RAM_TOTAL}MB${X}  CPU:${W}${CPU}%${X}  up ${W}${UPTIME}${X}"

# TYPE 2 — 222-DE-NetCup (FastPanel + Cloudflare)
echo -e "  \U0001F310  ${W}${HN}${X}  ${Y}${IP}${X}  RAM:${W}${RAM_USED}/${RAM_TOTAL}MB${X}  CPU:${W}${CPU}%${X}  up ${W}${UPTIME}${X}"

# TYPE 3 — 109 (212.109.223.109)
echo -e "  \U0001F310  ${W}${HN}${X}  ${Y}${IP}${X}  RAM:${W}${RAM_USED}/${RAM_TOTAL}MB${X}  CPU:${W}${CPU}%${X}  up ${W}${UPTIME}${X}"
```

#### Type + CrowdSec line (one line instead of two)

```bash
# Variable with short server type
MOTD_TYPE_SHORT="VPN"        # for TYPE 1
MOTD_TYPE_SHORT="Web-222/CF" # for TYPE 2
MOTD_TYPE_SHORT="Web-109"    # for TYPE 3

# One line instead of two:
CS_LINE="  ${Y}Type:${X} ${MOTD_TYPE_SHORT}   ${Y}CrowdSec:${X} ${G}\u25cf ACTIVE${X} | bans: ${W}${BAN_COUNT}${X}"
```

---

## SERVERS — Applying on 222 and 109

### Server 222-DE-NetCup (152.53.182.222) — TYPE 2

```bash
# Full MOTD reinstall:
cd /root/Linux_Server_Public
git pull
bash scripts/new_server_install.sh
# Select: 2 (Web 222/CF)

# SSH banner only (without reinstall):
sed -i 's/^#\?PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config
sed -i 's/^#\?PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config
systemctl reload ssh
```

### Server 109 (212.109.223.109) — TYPE 3

```bash
# Full MOTD reinstall:
cd /root/Linux_Server_Public
git pull
bash scripts/new_server_install.sh
# Select: 3 (Web 109)

# SSH banner only:
sed -i 's/^#\?PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config
sed -i 's/^#\?PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config
systemctl reload ssh
```

---

## VERIFICATION — Final result

### Expected SSH login on server 222

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🌐  222-DE-NetCup  152.53.182.222  RAM:4544/7935MB  CPU:8%  up 20 hours, 1 minute
  Xray: 1 enabled / 1 total    CrowdSec Engine: ● ACTIVE  Firewall: ● ACTIVE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ...
```

**NO** `Using username` / `Last login` lines before MOTD.

### Expected SSH login on VPN server

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔑  4Ton-237  144.124.228.237  RAM:444/961MB  CPU:9%  up 5 hours, 57 minutes
  Type: VPN   CrowdSec: ● ACTIVE | bans: 4
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## ISSUE HISTORY (2026-06-10)

| Version | Problem | Solution |
|---|---|---|
| before v2026.06.10b | `Last login` on login | `PrintLastLog no` in sshd_config |
| before v2026.06.10b | Type + CrowdSec = 2 lines | Merged into single `CS_LINE` |
| v2026.06.10m | `🖥` (U+1F5A5) broke the line | Replaced with `\U0001F511` / `\U0001F310` |
| v2026.06.10m | Icon missing in TYPE 2/3 | Added to all three blocks |
| v2026.06.10m | Uptime missing in TYPE 2/3 | `UPTIME` variable added everywhere |
| **v2026.06.10n** | **FINAL — everything works** | — |

---

> _= Rooted by VladiMIR + AI | github.com/GinCz/Linux_Server_Public =_
