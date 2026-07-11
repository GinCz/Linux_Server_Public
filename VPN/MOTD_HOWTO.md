# MOTD & Aliases — Full Architecture of VPN Servers

> Version: v2026.05.21
> = Rooted by VladiMIR + AI | v.2026.05.21 | github.com/GinCz =

Servers: VPN-EU-Alex-47, VPN-EU-4Ton-237, VPN-EU-Tatra-9, VPN-EU-Pilik-178,
VPN-EU-Shahin-227, VPN-EU-Stolb-24, VPN-EU-Ilya-176, VPN-EU-So-38

---

## ⚡ Quick Reference (read this FIRST)

| What to do | Command |
|---|---|
| Add / remove alias | Edit `VPN/.bashrc` in repo, then run `load` |
| Change MOTD menu text | Edit `VPN/motd_server.sh`, then run `load` |
| Apply changes | `load` (on VPN server) |
| Fresh install | see section "Fresh install" below |
| MOTD shows twice | see section "Common errors" below |
| MOTD not showing at all | see section "Common errors" below |

---

## 📁 Which file does what

```
/root/Linux_Server_Public/
└── VPN/
    ├── motd_server.sh        ← Colored MOTD menu for VPN (cyan color scheme)
    ├── .bashrc               ← PS1 + SOS aliases + VPN aliases + shared_aliases
    ├── deploy_vpn_node.sh    ← Deploy: copies .bashrc to server + installs MOTD
    └── MOTD_HOWTO.md         ← This file

/root/                        ← Files ON THE SERVER (not in repo)
├── .bash_profile             ← Loaded on SSH → source .bashrc
└── .bashrc                   ← COPY from repo VPN/.bashrc

/root/Linux_Server_Public/scripts/
└── shared_aliases.sh         ← Shared aliases: save, aw, ls, mc, 00, la, ll
```

---

## 🔄 How SSH login works (load order)

```
SSH connection
      │
      ├► Ubuntu reads /root/.bash_profile
      │         └► source /root/.bashrc
      │                   ├► [1] PS1='cyan prompt \u@\h'
      │                   ├► [2] HISTCONTROL, shopt settings
      │                   ├► [3] SOS aliases (sos, sos3, sos24, sos120)
      │                   │         → bash /root/Linux_Server_Public/VPN/sos_vpn.sh <hours>
      │                   ├► [4] VPN aliases (audit, infooo, backup, banlog, antivir, load)
      │                   └► [5] source /root/Linux_Server_Public/scripts/shared_aliases.sh
      │                               └► shared aliases: save, aw, ls, mc, 00, la, ll
      │
      └► Prompt root@VPN-EU-*:~# (cyan \e[38;5;87m)
```

**Important:** MOTD on VPN servers is shown via the mechanism described in `deploy_vpn_node.sh`.
VPN servers use the same flag-file deduplication as server 222.
There are **no MOTD files** in `/etc/profile.d/` on VPN servers (same as server 222, unlike server 109).

---

## 🆚 SOS on VPN vs SOS on 222/109

**These are different scripts!**

| | 222-DE-NetCup / 109-RU-FastVDS | VPN servers |
|---|---|---|
| **Script** | `scripts/sos-fastpanel.sh` | `VPN/sos_vpn.sh` |
| **Parameter** | `1h`, `3h`, `24h`, `120h` | `1`, `3`, `24`, `120` (hours as numbers) |
| **Aliases** | `sos` / `sos3` / `sos24` / `sos120` | `sos` / `sos3` / `sos24` / `sos120` |
| **Specific to** | FastPanel, Nginx, PHP-FPM, WP, Docker | AmneziaWG, WireGuard, Xray, VPN peers |

Do not use `sos-fastpanel.sh` on VPN servers and vice versa.

---

## ✏️ How to add a new alias

1. Open `VPN/.bashrc` in the repo
2. Find the right section and add a line
3. `save` → `load` on the server

**Shared aliases** (save, aw, 00, la, ll, mc) — in `scripts/shared_aliases.sh`. They are automatically included on all VPN servers.

---

## 🔧 Fresh install (new VPN server)

```bash
# 1. Clone the repo
git clone https://github.com/GinCz/Linux_Server_Public.git /root/Linux_Server_Public

# 2. Deploy MOTD + aliases
bash /root/Linux_Server_Public/VPN/deploy_vpn_node.sh

# 3. Reconnect via SSH — everything works
```

---

## ❌ Common errors and their causes

### MOTD shows twice

**Diagnostics (one command):**
```bash
grep -r "infooo\|motd\|bash.*\.sh" /etc/profile.d/ /root/.bashrc /root/.bash_profile 2>/dev/null && ls -la /etc/profile.d/
```

On VPN servers `/etc/profile.d/` should contain only standard Ubuntu files.
Any extra file — remove it:
```bash
rm /etc/profile.d/<extra_file>.sh
```

### MOTD not showing / aliases not working

```bash
cd /root/Linux_Server_Public && git pull --rebase
bash /root/Linux_Server_Public/VPN/deploy_vpn_node.sh
source /root/.bashrc
```

---

## 📋 Verification checklist after changes

```bash
# 1. Apply
load

# 2. Do aliases work?
type sos && type load && type audit

# 3. Is .bashrc up to date?
diff /root/.bashrc /root/Linux_Server_Public/VPN/.bashrc
# Output must be empty

# 4. No extra files?
ls -la /etc/profile.d/
```

---

## ⚠️ What NOT to do

- ❌ Do NOT create MOTD files in `/etc/profile.d/` — not needed on VPN servers
- ❌ Do NOT use `sos-fastpanel.sh` on VPN servers — they have their own `sos_vpn.sh`
- ❌ Do NOT edit `/root/.bashrc` on the server manually — only via repo and deploy
- ❌ Do NOT confuse VPN architecture with server 109 (109 uses `/etc/profile.d/`, VPN does not)

---

## 🔁 Architecture comparison across all servers

| | 222-DE-NetCup | 109-RU-FastVDS | VPN servers |
|---|---|---|---|
| **Main file** | `222/.bashrc` | `109/server_109.sh` | `VPN/.bashrc` |
| **MOTD file** | `222/motd_server.sh` | `109/server_109.sh` | `VPN/motd_server.sh` |
| **Aliases** | in `222/.bashrc` | in `server_109.sh` → `_aliases_109()` | in `VPN/.bashrc` + `shared_aliases.sh` |
| **`/etc/profile.d/`** | ❌ not used | ✅ `motd_server.sh` copied here | ❌ not used |
| **Deduplication** | flag-file `/tmp/motd_shown_*` | ENTRY POINT (bash vs source) | flag-file `/tmp/motd_shown_*` |
| **Update all command** | `load` (git pull) | `load` (git pull + `--install`) | `load` (git pull + deploy) |
| **SOS script** | `scripts/sos-fastpanel.sh` | `scripts/sos-fastpanel.sh` | `VPN/sos_vpn.sh` |
| **Prompt color** | 🟡 Yellow | 💗 Pink | 📦 Cyan |
