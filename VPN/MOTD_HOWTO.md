# MOTD & `.bashrc` — Full Documentation and Known Issues

> Version: v2026-05-01  
> = Rooted by VladiMIR | AI =

## Purpose

This document explains how the SSH banner (MOTD), `.bashrc`, and Midnight Commander menu work across the public server repository. It also captures the known traps that caused repeated debugging time, so they are not repeated again.

## Files by server group

### VPN nodes
- `VPN/motd_server.sh` — active MOTD banner source for VPN nodes.
- `VPN/.bashrc` — shell aliases and prompt setup for VPN nodes.
- `VPN/mc.menu` — Midnight Commander F2 user menu for VPN nodes.
- `VPN/deploy_vpn_node.sh` — deploys the VPN MOTD and related shell settings.

### Server 222
- `222/.bashrc` — server-specific shell aliases and prompt setup.
- `222/motd_server.sh` — MOTD source for server 222.
- `222/mc.menu` — Midnight Commander menu for server 222.

### Server 109
- `109/.bashrc` — server-specific shell aliases and prompt setup.
- `109/motd_server.sh` — MOTD source for server 109.
- `109/mc.menu` — Midnight Commander menu for server 109.

## How login works

When SSH starts, two different startup paths may run:
1. Login shell startup through `/etc/profile` and `/etc/profile.d/*.sh`.
2. Interactive shell startup through `/root/.bashrc`.

If a banner is printed from both paths, you see a duplicate MOTD. That is not a visual glitch; it is a configuration problem.

## Required guard for MOTD scripts

Every active MOTD script should begin with these checks:

```bash
shopt -q login_shell || return 0 2>/dev/null || exit 0
[ -n "$SSH_CONNECTION" ] || return 0 2>/dev/null || exit 0
```

The first line ensures the script runs only in a login shell. The second line ensures the session is a real SSH session. Together they prevent duplicate banner output.

## Known issue 1: duplicate banner on SSH login

### Symptoms
- Banner appears twice after login.
- MOTD appears both before and after shell prompt initialization.

### Root causes
- More than one MOTD file in `/etc/profile.d/`.
- MOTD logic is present in both `/etc/profile.d/` and `.bashrc`.
- The required login-shell guard is missing.

### Fix
- Keep only one active MOTD source for each server group.
- Remove legacy banner files from `/etc/profile.d/`.
- Ensure `motd_server.sh` has the guard lines above.

## Known issue 2: Midnight Commander F2 menu shows garbage

This was caused by the wrong file being read first.

### File search order
1. `~/.mc.menu`
2. `~/.config/mc/menu`
3. `~/.config/mc/mc.menu`
4. `/etc/mc/mc.menu`

### Trap
If `~/.mc.menu` exists, mc may show it instead of the real user menu. That file can contain old ini fragments such as panel paths and `user_menu=1`, which makes F2 look broken.

### Fix
- Delete `~/.mc.menu` if it exists.
- Keep the real menu in `~/.config/mc/menu`.
- Set `auto_save_setup=false` in `~/.config/mc/ini`.

## Known issue 3: `.bashrc` and MOTD confusion

The public repo intentionally separates:
- shared aliases in `scripts/shared_aliases.sh`
- server-specific aliases in `222/.bashrc`, `109/.bashrc`, and `VPN/.bashrc`
- banner output in `motd_server.sh`

Do not move server-specific `load` aliases into the shared alias file if they depend on a local server path.

## Editing rules

- Every script must have a short header.
- Every script must have the version inside the file, never in the filename.
- Public repository content must be in English.
- Temporary work must go into `temp/`.
- If a file becomes obsolete, remove it rather than keeping a duplicate copy with a different name.

## Diagnostics

```bash
ls -la /etc/profile.d/
ls -la /root/.mc.menu 2>/dev/null || true
grep -n "auto_save_setup\\|auto_menu" ~/.config/mc/ini 2>/dev/null || true
```
