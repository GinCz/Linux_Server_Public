# Linux Server Infrastructure

## 222 - Server (DE, NetCup)
* **IP:** xxx.xxx.xxx.222
* **OS:** Ubuntu 24.04 LTS
* **Panel:** FASTPANEL (EU sites via Cloudflare)
* **Optimization Note:** Uses script `FastPanel/optimize_php.sh` to safely maintain PHP-FPM limits (max 8 children) and prevent OOM (Out Of Memory) crashes under heavy bot traffic.

## 109 - Server (RU, FastVDS)
* **IP:** xxx.xxx.xxx.109
* **OS:** Ubuntu 24.04 LTS
* **Panel:** FASTPANEL (RU sites, no Cloudflare)
* **Optimization Note:** Uses script `FastPanel/optimize_php.sh` for safe PHP resource allocation.

## Tools Library
* `System/node_audit.sh` - Lightweight monitor for VPN/Samba nodes (network/disk focus).

## Documentation
All utility scripts are categorized into `System/`, `FastPanel/`, `Security/`, and `VPN/`. Core commands (sos, fight, faudit, infooo) are hardcoded into `/usr/local/bin/` to bypass bash cache issues.
