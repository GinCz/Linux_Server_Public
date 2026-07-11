# How the Shell Startup Works on Server 109

> Server: 109-RU-FastVDS | IP: 212.109.223.109 | Ubuntu 24 / FASTPANEL
> = Rooted by VladiMIR + AI | v.2026.05.21 | github.com/GinCz =

---

## Architecture — Boot Chain

```
SSH LOGIN
  └─► ~/.bash_profile
        ├─ [1] MOTD_SHOWN=? → if empty → show banner ONCE
        │        └─ bash /etc/profile.d/motd_server.sh
        │                 └─ calls _motd_109() from server_109.sh
        └─ [2] source server_109.sh → loads aliases (_aliases_109)

bash / screen / su (non-login shell)
  └─► ~/.bashrc
        └─ source server_109.sh → loads aliases (_aliases_109)
             (MOTD_SHOWN is already = 1 → banner is not duplicated)
```

**Rule:** MOTD is shown exactly once — controlled by the `MOTD_SHOWN` flag.

---

## Files and Their Roles

| File | Location | Role |
|------|----------|------|
| `.bash_profile` | `/root/` | Login shell: MOTD + aliases |
| `.bashrc` | `/root/` | Non-login shell: aliases only |
| `server_109.sh` | `/root/Linux_Server_Public/109/` | Main file: MOTD + aliases + MC menu |
| `motd_server.sh` | `/etc/profile.d/` | Copy of server_109.sh installed via --install |
| `shared_aliases.sh` | `/root/Linux_Server_Public/scripts/` | Shared aliases (save, aw, grep, ls, mc) |

---

## Why There Are NO Duplicates

1. **MOTD:** the `MOTD_SHOWN` flag is exported on first display. On every subsequent call to `.bashrc` or `source server_109.sh` the flag is already set → banner is not shown again.
2. **Aliases:** `server_109.sh` when sourced always calls only `_aliases_109()`. The function `_motd_109()` is called ONLY from `motd_server.sh` (located in `/etc/profile.d/`).
3. **MC menu:** installed once via `load` or `bash server_109.sh --install`. The menu itself does NOT call nano and does NOT prompt for an editor — it is written using `cat > file << 'HEREDOC'`.

---

## How `server_109.sh` Works — Three Blocks

```bash
# ENTRY POINT logic:
if [[ "${1}" == "--install" ]]; then
    # Copies itself to /etc/profile.d/motd_server.sh
    # Installs MC menu
elif [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Launched via source → loads aliases only
    _aliases_109
else
    # Launched directly via bash server_109.sh → shows MOTD
    _motd_109
fi
```

---

## MC Menu — How It Works

Menu file: `/root/.config/mc/menu`

- Opened with **F2** in Midnight Commander
- Each item is a separate script with `clear` + `read -n 1` at the end
- MC menu does NOT call an editor automatically — it simply runs commands
- Installation: `bash /root/Linux_Server_Public/109/server_109.sh --install` or alias `load`

### No-duplicate Rule for MC Menu

The MC menu is installed via `_install_mc_menu_109()` using a heredoc:
```bash
cat > "$MC_MENU" << 'MCMENU'
...content...
MCMENU
```
This overwrites the file completely — duplicates are impossible.

---

## Commands to Apply

### Initial installation (once):
```bash
cp /root/Linux_Server_Public/109/.bash_profile /root/.bash_profile
cp /root/Linux_Server_Public/109/.bashrc /root/.bashrc
bash /root/Linux_Server_Public/109/server_109.sh --install
source /root/.bash_profile
```

### After git pull (update):
```bash
load
# or manually:
cd /root/Linux_Server_Public && git pull --rebase
bash /root/Linux_Server_Public/109/server_109.sh --install
source /root/Linux_Server_Public/109/server_109.sh
```

### Check there are no duplicates:
```bash
grep -r 'motd\|MOTD\|_motd' /etc/profile.d/ ~/.bash_profile ~/.bashrc 2>/dev/null
# Should only show /etc/profile.d/motd_server.sh and the MOTD_SHOWN flag line in .bash_profile
```

### Verify shared_aliases.sh exists:
```bash
ls -la /root/Linux_Server_Public/scripts/shared_aliases.sh
```

---

## Common Errors

| Symptom | Cause | Fix |
|---------|-------|-----|
| MOTD shown twice | `.bashrc` contains a banner call | Remove everything from `.bashrc` except `source server_109.sh` |
| `shared_aliases.sh: No such file` | File not copied to `/scripts/` | `cp /root/Linux_Server_Public/222/shared_aliases.sh /root/Linux_Server_Public/scripts/` |
| nano opens after login | An extra file with `nano` exists in `/etc/profile.d/` | `grep -r nano /etc/profile.d/` |
| MC menu loads twice | `_install_mc_menu_109()` called twice | `load` overwrites the file — calling it again is safe |
