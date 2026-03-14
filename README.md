# Linux Server Management Scripts 🚀
**Author:** Ing. VladiMIR Bulantsev | 2026
**Environment:** Ubuntu/Debian + FastPanel (PHP 8.3/8.4)

This repository contains a synchronized ecosystem of scripts for managing multiple servers (RU & DE). It ensures that all servers remain identical and up-to-date.

## 🛠 Global System Commands (Aliases)

These commands are available globally from any directory on the servers:

* \`save\` — **Auto-Sync to GitHub.** Automatically adds all local changes, creates a commit with the server name and timestamp, and pushes to GitHub. Clears bash cache.
* \`load\` — **Force-Sync from GitHub.** Hard resets the local repository to match \`origin/main\`, ignoring local conflicts. Updates permissions and clears bash cache.
* \`infooo\` — **Server Health Monitor.** Displays a detailed overview of CPU, RAM, Disk usage, active connections, and top processes.
* \`domains\` — **Live Domain Checker.** Scans Nginx memory for all active domains (filtering out \`www.\` aliases) and performs a live HTTP 200/301 status check, outputting results to the console and Telegram.

## ⚙️ Automated Tasks (Cron)

* **Global WP-Cron Runner** (\`/System/run_all_wp_cron.sh\`): Runs every 2 hours via PHP-CLI to force WordPress updates across all FastPanel sites, bypassing PHP 8.4 loopback/WAF restrictions.

## 🛡️ Security

* **Cloudflare WAF Rules** (\`/Cloudflare/rules.txt\`): Standardized firewall rules for blocking bad bots and protecting WordPress admin areas.
* **.htaccess Deployer** (\`/System/deploy_htaccess.sh\`): Automatically distributes standard security configurations to WordPress roots and fixes permissions.

---
*Maintained with synchronized precision.* 💻
