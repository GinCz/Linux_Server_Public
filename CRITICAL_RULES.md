# CRITICAL OPERATIONAL RULES

**Valid for all servers: 222 / 109 / VPN**

---

## After installing or updating any script from the repository

The following two steps are MANDATORY and must be completed immediately:

### Step 1 — Persistent alias
Add the alias to `/opt/server_tools/scripts/shared_aliases.sh` using the
standard method. This ensures the alias survives shell restarts and server
reboots. Never use `alias` directly in terminal — it will be lost.

### Step 2 — Midnight Commander F2 menu
Add the script to `~/.config/mc/menu` so it is accessible from the
interactive server toolbox via F2.

**A script installation is NOT complete until both steps are done.**

---

## Current aliases (server_audit.sh)

| Alias  | Command                                       | Description       |
|--------|-----------------------------------------------|-------------------|
| sos    | server_audit.sh 24h                           | SOS default 24h   |
| sos1   | server_audit.sh 1h                            | SOS 1 hour        |
| sos3   | server_audit.sh 3h                            | SOS 3 hours       |
| sos24  | server_audit.sh 24h                           | SOS 24 hours      |
| sos120 | server_audit.sh 120h                          | SOS 120 hours     |
| awsping| aws_region_test.sh                            | AWS region test   |

---

## Alias method — shared_aliases.sh

All aliases are stored in:
  /opt/server_tools/scripts/shared_aliases.sh

This file must be sourced in ~/.bashrc on every server:
  source /opt/server_tools/scripts/shared_aliases.sh

## MC F2 Menu file location

  ~/.config/mc/menu

