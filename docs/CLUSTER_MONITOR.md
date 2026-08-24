# ⭐ Cluster Resource & WireGuard 10-Star Monitor

> **Interactive, ultra-fast cluster monitoring dashboard with visual 10-star workload indicators and WireGuard / AmneziaWG active client tracking.**

---

## 📸 Key Features

- ⚡ **Asynchronous Parallel Collection**: Concurrently queries all cluster nodes in parallel (~0.6s total runtime).
- 🌟 **10-Star Visual Workload Meter (`[★★★★★★★☆☆☆]`)**:
  - 🟢 **Green** `< 75%` — Normal operating load
  - 🟡 **Yellow** `75%–89%` — Warning threshold
  - 🔴 **Red** `≥ 90%` — Critical alert
- 🛡️ **WireGuard & AmneziaWG Online Tracking**: Automatic detection of active connections (handshakes within last 3 minutes).
- 🖥️ **Precision CPU Metering**: Direct hardware `/proc/stat` delta calculations.
- 💾 **RAM & NVMe/SSD Storage**: Used vs total breakdown with instant free space alerts.

---

## 🚀 One-Line Execution (No Install Required)

Run directly from GitHub on any master node (`DE-222` / `RU-109`):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/all_servers_stars.sh)
```

---

## ⌨️ Shortcuts & Aliases

| Alias | Description |
|---|---|
| `stars` | Run 10-Star Cluster Hardware Monitor |
| `mc` -> `S` | Launch monitor directly from Midnight Commander User Menu |

---

*Author: [GinCz (Vladimir Bulantsev)](https://github.com/GinCz)*