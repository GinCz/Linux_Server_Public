# WordPress Multi-Site Batch Updater (`wpupd`)

> Repository: [GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public)  
> Author: [Vladimir Bulantsev (@GinCz)](https://github.com/GinCz)  
> Directory: `wpupd/`

Automated, safe batch updater for WordPress core, themes, translation packs, and plugins across multi-tenant hosting environments.

---

## ⚡ Key Capabilities

* **User Privilege Isolation:** Executes updates strictly under the designated Linux site owner (`sudo -u <user> wp ...`) to prevent root ownership file corruption.
* **Non-Destructive Core Checks:** Updates translation files and verified plugins while reporting core version status for staged upgrades.
* **Cron & Systemd Ready:** Optimized to run unattended via nightly systemd timers with structured exit codes and error logs.

---

## 🚀 Execution

```bash
sudo bash wp_update_all.sh
```

---

## 🏷️ Keywords & Topics
`#wordpress-updater` `#wp-cli` `#batch-update` `#multisite-maintenance` `#devops-automation`
