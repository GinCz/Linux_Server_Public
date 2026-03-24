# Linux Server Public — Scripts & Configs
GitHub: https://github.com/GinCz/Linux_Server_Public
Author: Ing. VladiMIR Bulantsev

---

## MAIN RULE
Every script used on a specific server MUST be present in that server own folder.
Each server folder is self-contained and fully independent.
Scripts MAY be duplicated across folders — this is intentional.

---

## COLOR SCHEME (SSH terminal)
- 222 EU Germany  : YELLOW  PS1 033[01;33m
- 109 RU Russia   : LIGHT PINK  PS1 e[38;5;217m
- VPN             : GREEN (planned)
- AWS             : CYAN (planned)

Permanent color setup via /root/.bash_profile on each server.

---

## REPOSITORY STRUCTURE

    Linux_Server_Public/
    |-- 222/         <- EU Server Germany NetCup  xxx.xxx.xxx.222
    |-- 109/         <- RU Server Russia FastVDS  xxx.xxx.xxx.109
    |-- VPN/         <- VPN Server AmneziaWG + WireGuard
    |-- AWS/         <- AWS Server Amazon
    |-- scripts/     <- Universal scripts base (copy to server folder before use)
    |-- README.md

---

## 222/ — EU Server Germany (NetCup) xxx.xxx.xxx.222
Specs: 4 vCore AMD EPYC-Genoa / 8GB DDR5 ECC / 256GB NVMe / Ubuntu 24 / FastPanel
Sites: European sites WITH Cloudflare

| Script | Full Path | Run Command | Description |
|--------|-----------|-------------|-------------|
| sos.sh | /root/Linux_Server_Public/222/sos.sh | bash /root/Linux_Server_Public/222/sos.sh 1h | Server audit for period (15m/1h/3h/6h/24h) |
| infooo.sh | /root/Linux_Server_Public/222/infooo.sh | bash /root/Linux_Server_Public/222/infooo.sh | Quick server status: CPU/RAM/disk/nginx/PHP |
| quick_status.sh | /root/Linux_Server_Public/222/quick_status.sh | bash /root/Linux_Server_Public/222/quick_status.sh | One-line server health check |
| save.sh | /root/Linux_Server_Public/222/save.sh | bash /root/Linux_Server_Public/222/save.sh | Git add + commit + push to GitHub |
| system_backup.sh | /root/Linux_Server_Public/222/system_backup.sh | bash /root/Linux_Server_Public/222/system_backup.sh | Full system backup to archive |
| run_all_wp_cron.sh | /root/Linux_Server_Public/222/run_all_wp_cron.sh | bash /root/Linux_Server_Public/222/run_all_wp_cron.sh | Run WP-Cron for all WordPress sites |
| domains.sh | /root/Linux_Server_Public/222/domains.sh | bash /root/Linux_Server_Public/222/domains.sh | Check HTTP status of all domains (200/503/etc) |
| php_fpm_watchdog.sh | /root/Linux_Server_Public/222/php_fpm_watchdog.sh | bash /root/Linux_Server_Public/222/php_fpm_watchdog.sh | Auto-restart hung PHP-FPM pools |
| optimize_php.sh | /root/Linux_Server_Public/222/optimize_php.sh | bash /root/Linux_Server_Public/222/optimize_php.sh | Clean system + optimize PHP limits + restart nginx |
| block_bots.sh | /root/Linux_Server_Public/222/block_bots.sh | bash /root/Linux_Server_Public/222/block_bots.sh | Block bad bots via iptables/nginx |
| scan_clamav.sh | /root/Linux_Server_Public/222/scan_clamav.sh | bash /root/Linux_Server_Public/222/scan_clamav.sh | Antivirus scan via ClamAV |
| install_crowdsec.sh | /root/Linux_Server_Public/222/install_crowdsec.sh | bash /root/Linux_Server_Public/222/install_crowdsec.sh | Install and configure CrowdSec WAF |
| cloudflare_proxy.sh | /root/Linux_Server_Public/222/cloudflare_proxy.sh | bash /root/Linux_Server_Public/222/cloudflare_proxy.sh | Toggle Cloudflare proxy on/off for domains |
| global_htaccess.sh | /root/Linux_Server_Public/222/global_htaccess.sh | bash /root/Linux_Server_Public/222/global_htaccess.sh | Deploy .htaccess to all WordPress sites |
| set_php_limits.sh | /root/Linux_Server_Public/222/set_php_limits.sh | bash /root/Linux_Server_Public/222/set_php_limits.sh domain min max | Set PHP-FPM pool limits for specific domain |
| apply_aliases.sh | /root/Linux_Server_Public/222/apply_aliases.sh | bash /root/Linux_Server_Public/222/apply_aliases.sh | Apply bash aliases to current session |

---

## 109/ — RU Server Russia (FastVDS) xxx.xxx.xxx.109
Specs: 4 vCore AMD EPYC 7763 / 8GB RAM / 80GB NVMe / Ubuntu 24 LTS / FastPanel
Sites: Russian sites WITHOUT Cloudflare

| Script | Full Path | Run Command | Description |
|--------|-----------|-------------|-------------|
| sos.sh | /root/Linux_Server_Public/109/sos.sh | bash /root/Linux_Server_Public/109/sos.sh 1h | Server audit for period (15m/1h/3h/6h/24h) |
| infooo.sh | /root/Linux_Server_Public/109/infooo.sh | bash /root/Linux_Server_Public/109/infooo.sh | Quick server status: CPU/RAM/disk/nginx/PHP |
| quick_status.sh | /root/Linux_Server_Public/109/quick_status.sh | bash /root/Linux_Server_Public/109/quick_status.sh | One-line server health check |
| save.sh | /root/Linux_Server_Public/109/save.sh | bash /root/Linux_Server_Public/109/save.sh | Git add + commit + push to GitHub |
| system_backup.sh | /root/Linux_Server_Public/109/system_backup.sh | bash /root/Linux_Server_Public/109/system_backup.sh | Full system backup to archive |
| run_all_wp_cron.sh | /root/Linux_Server_Public/109/run_all_wp_cron.sh | bash /root/Linux_Server_Public/109/run_all_wp_cron.sh | Run WP-Cron for all WordPress sites |
| domains.sh | /root/Linux_Server_Public/109/domains.sh | bash /root/Linux_Server_Public/109/domains.sh | Check HTTP status of all domains (200/503/etc) |
| php_fpm_watchdog.sh | /root/Linux_Server_Public/109/php_fpm_watchdog.sh | bash /root/Linux_Server_Public/109/php_fpm_watchdog.sh | Auto-restart hung PHP-FPM pools |
| optimize_php.sh | /root/Linux_Server_Public/109/optimize_php.sh | bash /root/Linux_Server_Public/109/optimize_php.sh | Clean system + optimize PHP limits + restart nginx |
| block_bots.sh | /root/Linux_Server_Public/109/block_bots.sh | bash /root/Linux_Server_Public/109/block_bots.sh | Block bad bots via iptables/nginx |
| scan_clamav.sh | /root/Linux_Server_Public/109/scan_clamav.sh | bash /root/Linux_Server_Public/109/scan_clamav.sh | Antivirus scan via ClamAV |
| install_crowdsec.sh | /root/Linux_Server_Public/109/install_crowdsec.sh | bash /root/Linux_Server_Public/109/install_crowdsec.sh | Install and configure CrowdSec WAF |
| set_php_limits.sh | /root/Linux_Server_Public/109/set_php_limits.sh | bash /root/Linux_Server_Public/109/set_php_limits.sh domain min max | Set PHP-FPM pool limits for specific domain |
| apply_aliases.sh | /root/Linux_Server_Public/109/apply_aliases.sh | bash /root/Linux_Server_Public/109/apply_aliases.sh | Apply bash aliases to current session |

---

## VPN/ — VPN Server (AmneziaWG + WireGuard)
Purpose: Personal VPN, bypass censorship, secure tunnel

| Script | Full Path | Run Command | Description |
|--------|-----------|-------------|-------------|
| amnezia_stat.sh | /root/Linux_Server_Public/VPN/amnezia_stat.sh | bash /root/Linux_Server_Public/VPN/amnezia_stat.sh | AmneziaWG statistics and connected clients |
| vpn_server_audit.sh | /root/Linux_Server_Public/VPN/vpn_server_audit.sh | bash /root/Linux_Server_Public/VPN/vpn_server_audit.sh 1h | VPN server audit for period |
| vpn_node_clean_audit.sh | /root/Linux_Server_Public/VPN/vpn_node_clean_audit.sh | bash /root/Linux_Server_Public/VPN/vpn_node_clean_audit.sh | Purge logs + full VPN node status audit |
| vpn_hard_shield.sh | /root/Linux_Server_Public/VPN/vpn_hard_shield.sh | bash /root/Linux_Server_Public/VPN/vpn_hard_shield.sh | Install fail2ban + block bad IPs + clean logs (CAUTION: changes iptables!) |
| infooo.sh | /root/Linux_Server_Public/VPN/infooo.sh | bash /root/Linux_Server_Public/VPN/infooo.sh | Quick server status |
| save.sh | /root/Linux_Server_Public/VPN/save.sh | bash /root/Linux_Server_Public/VPN/save.sh | Git add + commit + push |
| system_backup.sh | /root/Linux_Server_Public/VPN/system_backup.sh | bash /root/Linux_Server_Public/VPN/system_backup.sh | Full system backup |

---

## AWS/ — Amazon Cloud Server

| Script | Full Path | Run Command | Description |
|--------|-----------|-------------|-------------|
| aws_ping.sh | /root/Linux_Server_Public/AWS/aws_ping.sh | bash /root/Linux_Server_Public/AWS/aws_ping.sh | Ping AWS endpoints and check latency |
| vpn_server_audit.sh | /root/Linux_Server_Public/AWS/vpn_server_audit.sh | bash /root/Linux_Server_Public/AWS/vpn_server_audit.sh 1h | Server audit for period |
| infooo.sh | /root/Linux_Server_Public/AWS/infooo.sh | bash /root/Linux_Server_Public/AWS/infooo.sh | Quick server status |
| save.sh | /root/Linux_Server_Public/AWS/save.sh | bash /root/Linux_Server_Public/AWS/save.sh | Git add + commit + push |
| disk_monitor.sh | /root/Linux_Server_Public/AWS/disk_monitor.sh | bash /root/Linux_Server_Public/AWS/disk_monitor.sh | Monitor disk usage |
| system_backup.sh | /root/Linux_Server_Public/AWS/system_backup.sh | bash /root/Linux_Server_Public/AWS/system_backup.sh | Full system backup |

---

## scripts/ — Universal Base Scripts
These are BASE versions. Copy to server folder before use.
Do NOT run directly from scripts/ on production servers.

| Script | Description | Use on |
|--------|-------------|--------|
| infooo.sh | Quick server status | all |
| quick_status.sh | One-line health check | all |
| amnezia_stat.sh | AmneziaWG stats | VPN |
| block_bots.sh | Block bad bots | 222 109 |
| scan_clamav.sh | ClamAV antivirus scan | 222 109 |
| save.sh | Git push | all |
| system_backup.sh | System backup | all |
| run_all_wp_cron.sh | WordPress cron | 222 109 |
| domains.sh | Domain HTTP check | 222 109 |
| php_fpm_watchdog.sh | PHP-FPM watchdog | 222 109 |
| optimize_php.sh | PHP optimize + clean | 222 109 |
| set_php_limits.sh | PHP pool limits | 222 109 |
| install_crowdsec.sh | CrowdSec WAF install | 222 109 |
| cloudflare_proxy.sh | Cloudflare toggle | 222 only |
| global_htaccess.sh | Deploy .htaccess | 222 109 |
| vpn_node_clean_audit.sh | VPN node audit | VPN |
| vpn_hard_shield.sh | VPN iptables shield | VPN only |
| migration_tool.sh | Site migration | 222 109 |
| new_server_install.sh | New server setup | all |
| aws_ping.sh | AWS ping test | AWS |
| change_hostname.sh | Change hostname | all |
| sync_blacklist.sh | Sync IP blacklist | 222 109 |
| sync_clamav_db.sh | Sync ClamAV DB | 222 109 |
| deploy_htaccess.sh | Deploy one .htaccess | 222 109 |
| domain_monitor.sh | Monitor domains/SSL | 222 109 |
| setup_eu_222.sh | Initial setup 222 | 222 |
| setup_ru_109.sh | Initial setup 109 | 109 |
| load.sh | Load monitor | all |
| mail_queue.sh | Mail queue check | 222 109 |
| node_audit.sh | Node.js audit | all |
| full_audit.sh | Full system audit | all |

---

Last updated: 2026-03-24
