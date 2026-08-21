# 🚀 Master Server Provisioning & Management Scripts
# = Rooted by VladiMIR + AI | v.2026.08.21 | github.com/GinCz =

Production-grade automation suite for Ubuntu 22.04 / 24.04 LTS servers (VPN Nodes, Web Clusters, Reverse Proxies).

---

## 🖥️ `new_server_install.sh` — Universal Server Setup Wizard

The master automated provisioning and synchronization script for new and existing Linux nodes.

### ⚡ Quick Launch:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh)
```

---

### 🎨 1. Interactive 5-Step Configuration Wizard

When launched, the script guides you through an interactive setup before performing any actions:

1. **Server Hostname:**
   * Prompts for server name. Pressing `[Enter]` keeps the existing system hostname.
2. **Server Architecture & Role (1 / 2 / 3):**
   * `[1] VPN Node` — XRay, AmneziaWG, AdGuard Home, CrowdSec, WireGuard.
   * `[2] Web Server 222` — FastPanel, Nginx Reverse Proxy, Cloudflare WAF, WordPress, CryptoBot PRO.
   * `[3] Web Server 109` — FastPanel RU, Direct Web Services, MariaDB.
3. **MOTD Header & Telemetry Color Palette (1 – 8):**
   * `1) Sky Blue` (VPN default), `2) Bright Red`, `3) Bright Green`, `4) Bright Yellow` (222 default), `5) Bright Magenta`, `6) Orange`, `7) Bright Pink`, `8) Light Grey` (109 default).
4. **PS1 Prompt Font Color (1 – 8):**
   * Configures persistent colored shell prompt (`root@host:~#`).
5. **Installation Mode (1 / 2 / 3):**
   * `1) FULL Mode` — Fresh server deployment: full `apt update && apt upgrade`, base tools installation, UFW firewall initialization, Fail2ban and CrowdSec security hardening.
   * `2/3) UPDATE Mode` — Safe live update: refreshes scripts in `/usr/local/bin/`, updates `.bashrc` aliases, regenerates dynamic MOTD and Midnight Commander menus without touching active network services or databases.

---

### 📊 2. Three Specialized MOTD Telemetry Banners

The script generates a customized, lightweight dynamic login banner (`/etc/profile.d/motd_server.sh`) tailored to the server's role:

#### 🔹 Type 1: VPN Node Banner (e.g., SO-38, ALEX-47, TATRA-9, STOLB-24)
* **Real-Time Telemetry:** RAM (used/total), Swap (used/total), CPU usage %, Uptime, Load Average.
* **Live Service Status Indicators:** `● Xray` · `● AmneziaWG` · `● AdGuardHome` · `● CrowdSec` · `● fail2ban` · `● smbd`.
* **Quick-Access Command Matrix:** `antivir` · `sos` · `fight` · `aw` · `banlist` · `backup` · `infooo` · `save` · `load`.

#### 🔹 Type 2: Web Server 222 Banner (DE NetCup Master Node)
* **Full Web Stack Status:** Nginx, Apache / PHP-FPM (8.1, 8.2, 8.3), MariaDB, FastPanel, Cloudflare integration.
* **Web & Maintenance Tools:** `wpupd` (bulk WordPress update), `wpcron` (CLI cron processor), `domains` (SSL & DNS audit), `nginx-reload`, `fpm-reload`.

#### 🔹 Type 3: Web Server 109 Banner (RU FastVDS Node)
* **RU Web Stack Status:** Direct FastPanel web cluster, local PHP pools, Samba shares, server health monitors.

---

### ⌨️ 3. Midnight Commander Hotkey Integration (F2 User Menu)

Configures native **F2** menu shortcuts in `/root/.config/mc/menu` and `/etc/mc/mc.menu`:

| Key | Action | Description |
| :---: | :--- | :--- |
| **`s`** | **SOS Audit** | Launches interactive master system auditor (`/usr/local/bin/sos`) |
| **`a`** | **Antivirus** | Opens interactive ClamAV scanner menu (`/usr/local/bin/scan_clamav.sh`) |
| **`x`** | **Xray Logs** | Displays the last 50 lines of Xray service journal |
| **`g`** | **AdGuard Status** | Checks live AdGuard Home daemon status |
| **`w`** | **WireGuard Status** | Displays active WireGuard / AmneziaWG peers and interface stats |
| **`u`** | **WP Update All** | Runs bulk updates for Core, Plugins, and Themes across all sites |
| **`c`** | **WP Cron** | Executes WordPress WP-Cron events via WP-CLI |
| **`d`** | **Domains Check** | Runs HTTP response and SSL certificate validation |
| **`b`** | **Banlist** | Displays active CrowdSec blocked IPs |

---

### 🛠️ 4. Deployed Binary Utilities (`/usr/local/bin/`)

The installer pulls the latest versions of all maintenance scripts directly from GitHub:

* **`sos`** (`v2026.08.08a`): 31-section comprehensive server audit & performance diagnostic tool.
* **`infooo`**: Hardware specification, network interfaces, and kernel diagnostic reporter.
* **`wp_update_all`** & **`run_all_wp_cron`**: Batch WordPress maintenance automation.
* **`server_cleanup`**: Disk space recovery (journal vacuuming, apt cleanup, temporary file purging).
* **`block_bots`** & **`banlog`**: CrowdSec & IPGuard automated threat defense.
* **`system_backup`**: Automated system backup utility.
* **`domains`**: Mass domain and SSL certificate health validator.

---

*= Rooted by VladiMIR + AI | github.com/GinCz/Linux_Server_Public =*
