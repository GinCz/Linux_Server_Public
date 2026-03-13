# VladiMIR's Linux Server Automation (v2026)

## Server Structure
- `00_common` — Shared files, global lists (whitelist, blacklist), MC menu.
- `01_eu_server_222_cloudflare_fastpanel_ubuntu24` — EU 222 (NetCup + Cloudflare Proxy + FastPanel Ubuntu 24).
- `02_ru_server_109_fastpanel_ubuntu24` — Moscow 109 (FastVDS + FastPanel Ubuntu 24, strictly NO Cloudflare).
- `03_vpn_amnezia_wireguard_ubuntu22_samba` — VPN Nodes (Ubuntu 22 + WireGuard Amnezia + Samba Shares).
- `04_general_scripts` — Universal scripts running across all servers.
- `docs` — Security rules and WAF configurations.

## Guidelines
- **Clear Screen**: Every script must start with `clear`.
- **Language**: All code comments and output must be in **English**.
- **Separation of Concerns**: Each idea or module must reside in its own separate file.
