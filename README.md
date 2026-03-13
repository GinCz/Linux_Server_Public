# VladiMIR's Linux Server Automation (v2026)

Collection of production-ready Bash scripts for quick & secure Linux server setup (Ubuntu 22/24, NetCup/FastVDS, FastPanel, WireGuard Amnezia + Samba, Cloudflare proxy rules).

## ✨ Features
- **Functional architecture**: Separated by service/concept.
- **Clear separation of concerns**: One idea = one file.
- **Strictly English**: All code comments, documentation, and output are in English.
- **Clean UI**: Pre-execution screen clearing (`clear`) for better readability.
- **Silent mode**: Error-only alerts in monitoring scripts.
- **Alliance Security**: Global blacklist/whitelist synchronization across multiple servers via GitHub.

## 📂 Structure
| Folder         | Purpose                                                                 |
|----------------|-------------------------------------------------------------------------|
| `System/`      | Core installation scripts, MC menus, and basic monitoring (infooo, sos) |
| `Security/`    | Global whitelists, blacklists, sync scripts, and ban logs               |
| `FastPanel/`   | FastPanel tweaks, domain checkers, and PHP-FPM dynamic limits (70/30)   |
| `Cloudflare/`  | Cloudflare proxy configurations and setup scripts                       |
| `WordPress/`   | WP-specific WAF rules and optimization documentation (English only)     |
| `VPN/`         | WireGuard (Amnezia) and Samba shared folders configurations             |

## 📄 License
This project is licensed under the MIT License.
