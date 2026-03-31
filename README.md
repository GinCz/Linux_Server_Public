# Linux_Server_Public

**Main public repository** for all my server scripts, Ansible playbooks, aliases, VPN tools and documentation.

Contains **only non-sensitive code**.  
All passwords, SSH keys, API secrets and full server details are stored in the strictly private repo:  
https://github.com/GinCz/Secret_Privat (never make it public).

---

## Repository Structure
| Folder       | Purpose |
|--------------|---------|
| 222/         | Germany server (NetCup + Cloudflare) |
| 109/         | Russia server (FastVDS, no Cloudflare) |
| VPN/         | AmneziaWG VPN nodes |
| ansible/     | Playbooks for Semaphore UI |
| scripts/     | General utilities |

---

## Quick Aliases
secret → cd ~/Secret_Privat && git pull && ls -la

---

## Style Rules
- Every file starts with clear
- Header: # = Rooted by VladiMIR | AI =
- Version: v2026-03-30
- Comments in short English
- No sensitive data here

---

## Basic Usage
cd ~/Linux_Server_Public && git pull
secret

---

Last updated: March 30, 2026
Maintained by: VladiMIR
Email: gin.vladimir@gmail.com

= Rooted by VladiMIR | AI =
v2026-03-30
