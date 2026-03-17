# Linux Server Management Scripts 🚀
**Author:** Ing. VladiMIR Bulantsev | 2026
**Environment:** Ubuntu/Debian + FastPanel (PHP 8.3/8.4)

This repository contains a synchronized ecosystem of scripts for managing multiple servers (RU & DE). It ensures that all servers remain identical and up-to-date.

## 🛠 Global System Commands (Aliases)

These commands are available globally from any directory on the servers:

* `save` — **Auto-Sync to GitHub.** Automatically adds all local changes, creates a commit and pushes to GitHub.
* `load` — **Force-Sync from GitHub.** Hard resets the local repository to match `origin/main`.
* `infooo` — **Server Health Monitor.** Displays a detailed overview of CPU, RAM, Disk usage, etc.
* `domains` — **Live Domain Checker.** Scans Nginx memory for all active domains and checks HTTP status.
* `clamav` — **Antivirus Scanner.** Runs a low-priority deep scan of all websites, displays a live progress bar, and sends the report to Telegram.

## 🛡️ Security Tools
* **ClamAV Scanner** (`/Security/scan_clamav.sh`): Strict read-only malware scanner for web directories.
* **Cloudflare WAF Rules** (`/Cloudflare/rules.txt`): Standardized firewall rules.
* **.htaccess Deployer** (`/System/deploy_htaccess.sh`): Distributes standard security configurations.

---
*Maintained with synchronized precision.* 💻
