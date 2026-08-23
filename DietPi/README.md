# 🐧 DietPi Automated Cloud VPS Converter

Convert any existing **Debian 12 (Bookworm)** or **Ubuntu 24 LTS** virtual machine into an ultra-lightweight, high-performance **DietPi** instance in a single step.

---

## ⚡ Key Benefits

| Metric | Standard Ubuntu 24 | Standard Debian 12 | **DietPi (Optimized)** |
|:---|:---:|:---:|:---:|
| **Idle RAM Footprint** | ~500–600 MB | ~150–200 MB | **~30–40 MB** |
| **Clean Disk Usage** | ~7–8 GB | ~2.5–3 GB | **~1.0–1.2 GB** |
| **Active Background Daemons** | 45+ services | 25+ services | **< 10 essential services** |
| **Boot & Response Time** | Standard | Fast | **Instant (Low Latency)** |

---

## 🚀 One-Line Quick Installation

Run the command below via SSH on your Debian 12 / Ubuntu server:

```bash
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/DietPi/install_dietpi.sh | bash
```

### Unattended Automated Mode (with password argument)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/DietPi/install_dietpi.sh) -p "YourSecurePassword" --auto
```

---

## 🛠 What This Script Does

1. **Network Auto-Capture:** Detects static IP, subnet mask, default gateway, and DNS servers before conversion.
2. **Official Installer:** Fetches the official upstream DietPi conversion script from the DietPi project repository.
3. **Unattended Configuration:** Generates a pre-populated `/boot/dietpi.txt` to automatically apply network settings, disable telemetry surveys, configure timezone, and set root passwords on first boot.
4. **Automated Reboot:** Cleanly reboots into DietPi with working SSH and network connectivity.

---

## 📄 License & Attribution

* DietPi project created and maintained by **MichaIng** ([dietpi.com](https://dietpi.com)).
* Converter script maintained by **GinCz** ([GitHub](https://github.com/GinCz)).
* Licensed under the GNU General Public License v2 (GPL-2.0).