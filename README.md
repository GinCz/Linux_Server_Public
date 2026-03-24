# Linux Server Public — Scripts and Configs

Repository of scripts and configs for all servers.
GitHub: https://github.com/GinCz/Linux_Server_Public

## Repository Structure

    Linux_Server_Public/
    |-- 222/        <- Server EU Germany NetCup  xxx.xxx.xxx.222
    |-- 109/        <- Server RU FastVDS Russia  xxx.xxx.xxx.109
    |-- VPN/        <- VPN server AmneziaWG + WireGuard
    |-- AWS/        <- AWS server Amazon
    |-- scripts/    <- Universal scripts for ALL servers
    |-- README.md
    |-- LICENSE

## MAIN RULE - MANDATORY

Every script used on a specific server MUST be present in that server own folder.

- 222/ contains ALL scripts actively used on server 222
- 109/ contains ALL scripts actively used on server 109
- VPN/ contains ALL scripts actively used on VPN server
- AWS/ contains ALL scripts actively used on AWS server

Scripts MAY be duplicated across folders - this is intentional.
Each server folder is self-contained and fully independent.
If a script differs between servers it MUST differ in its folder.

## Folder Details

### 222 - EU Server Germany NetCup
- IP: xxx.xxx.xxx.222
- Provider: NetCup.com Germany
- Specs: 4 vCore AMD EPYC-Genoa / 8GB DDR5 ECC / 256GB NVMe
- OS: Ubuntu 24 / FastPanel
- Sites: European sites WITH Cloudflare

### 109 - RU Server Russia FastVDS
- IP: xxx.xxx.xxx.109
- Provider: FastVDS.ru Russia
- Specs: 4 vCore AMD EPYC 7763 / 8GB RAM / 80GB NVMe
- OS: Ubuntu 24 LTS / FastPanel
- Sites: Russian sites WITHOUT Cloudflare

### VPN - VPN Server
- Stack: AmneziaWG + WireGuard
- Purpose: Personal VPN bypass censorship secure access

### AWS - Amazon Cloud Server
- Purpose: Amazon cloud server

### scripts - Universal Scripts
- Scripts that work identically on ALL servers
- Copy to server folder and customize if needed

## Workflow

1. Edit script on server
2. Copy to server folder: cp /opt/server_tools/scripts/myscript.sh ~/Linux_Server_Public/222/
3. Run save alias to commit and push
4. If universal also copy to scripts/

## Save Alias

alias save=cd /root/Linux_Server_Public and git add -A and git commit and git push origin main

Last updated: 2026-03-24
