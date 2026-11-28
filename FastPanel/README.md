# FastPanel Diagnostics & Auto-Repair Utility (`fastpanel-fix.sh`)

> Repository: [GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public)  
> Author: [Vladimir Bulantsev (@GinCz)](https://github.com/GinCz)  
> License: MIT

Automated health diagnostic, port 8888 verification, firewall rule checker, and recovery utility for Linux servers running FastPanel.

---

## ⚡ Overview

When FastPanel becomes inaccessible on port `8888`, diagnosing the root cause typically involves checking multiple layers: service daemon status, listening sockets, local firewalls (UFW, iptables), systemd errors, and reverse proxy settings.

`fastpanel-fix.sh` automates the entire triage and repair pipeline in a single command.

### Key Capabilities

* **Service State Inspection:** Verifies `fastpanel2.service` active state, restarts if failed.
* **Port & Socket Audit:** Probes `127.0.0.1:8888` and public interfaces using `ss` / `netstat`.
* **Firewall Remediation:** Checks and automatically unblocks TCP port 8888 in `ufw` and `iptables`.
* **Nginx / FastPanel Config Validation:** Verifies configuration integrity and socket permissions.
* **Non-Destructive:** Safe to run in production without altering websites or databases.

---

## 🚀 1-Click Execution

Run directly as root via curl:

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/FastPanel/fastpanel-fix.sh)
```

Or clone and execute locally:

```bash
git clone https://github.com/GinCz/Linux_Server_Public.git
cd Linux_Server_Public/FastPanel
sudo bash fastpanel-fix.sh
```

---

## 📋 Version History

<details>
<summary><b>Click to expand changelog</b></summary>

### v2026-07-27
* Unified port 8888 check with automatic fallback between `ss` and `netstat`.
* Automated UFW and iptables port validation.
* Added colored diagnostic output and structured logging summary.

</details>
