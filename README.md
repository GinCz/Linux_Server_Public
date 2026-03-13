# VladiMIR's Linux Server Automation (v2026)

## Functional Structure
- `Security/` — Global whitelists, blacklists, sync scripts, and ban logs.
- `Cloudflare/` — Cloudflare proxy setup and API scripts.
- `WordPress/` — WP-specific WAF rules and optimization docs.
- `FastPanel/` — FastPanel tweaks, domain checkers, and PHP-FPM limits (70/30).
- `VPN/` — WireGuard (Amnezia) and Samba configurations.
- `System/` — Core installation scripts and Midnight Commander menus.

## Guidelines
- **Clear Screen**: Every script must start with `clear`.
- **Language**: All code comments and output must be in **English**.
- **Separation of Concerns**: Each idea or module must reside in its own separate file.
