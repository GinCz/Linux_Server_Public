# ClamAV Antivirus Suite & Automated Scanner (`antivir`)

> Repository: [GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public)  
> Author: [Vladimir Bulantsev (@GinCz)](https://github.com/GinCz)  
> Directory: `antivir/`

Automated ClamAV antivirus deployment, daily background signature updates, malware scanning engine, and automated quarantine management for Linux production servers.

---

## ⚡ Overview & Capabilities

* **Automated Installation (`install_clamav.sh`):** Installs ClamAV daemon, configures `freshclam` daily update timers, and allocates quarantine directories (`/var/quarantine`).
* **Deep Malware Scanner (`scan_clamav.sh`):** High-speed multi-threaded scanner probing web roots (`/var/www/`), user homes, and `/tmp/` for PHP web shells, ELF trojans, and crypto-miners.
* **Low System Overhead:** Runs with nice/ionice priority to prevent I/O bottlenecks or CPU starvation on live production hosts.

---

## 🚀 Execution

```bash
# Run manual full system scan:
sudo bash /root/Linux_Server_Public/antivir/scan_clamav.sh
```

---

## 🏷️ Keywords & Topics
`#clamav` `#linux-antivirus` `#malware-scanner` `#webshell-detector` `#sysadmin` `#devops` `#server-hardening`
