# System Swap & Journald Tuner (`setup_swap_and_journal.sh`)

> Repository: [GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public)  
> Author: [Vladimir Bulantsev (@GinCz)](https://github.com/GinCz)  
> License: MIT

Automated tuning utility to configure baseline swap files and systemd journal disk quotas for cloud VPS and bare-metal nodes.

---

## ⚡ Overview

Low-memory VPS instances (512MB–2GB RAM) frequently suffer from Out-Of-Memory (OOM) process termination and runaway systemd log growth.

`setup_swap_and_journal.sh` is an idempotent optimization script that:
* **Limits `systemd-journald`:** Caps maximum log consumption to 100MB and enforces a 7-day retention period (`SystemMaxUse=100M`, `MaxRetentionSec=7day`).
* **Optimizes Swap Space:** Detects existing swap; provisions an optimized 512MB fallback swapfile (`/swapfile`) with `chmod 600` if none exists.
* **Safe & Idempotent:** Re-running skips already-configured settings without downtime or file recreation.

---

## 🚀 1-Click Execution

Run directly as root:

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/SwapJournal_Tuner/setup_swap_and_journal.sh)
```

---

## 📋 Version History

<details>
<summary><b>Click to expand changelog</b></summary>

### v2026-07-11
* Added automated journald quota enforcement and daemon restart.
* Added safe swapfile allocation with fstab persistence check.
* Added idempotent configuration safeguards.

</details>
