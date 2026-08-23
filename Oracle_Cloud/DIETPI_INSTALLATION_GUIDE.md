# 🚀 Step-by-Step Guide: Deploying Pure 350 MB Mini-Linux (DietPi) on Oracle Cloud

> **Target OS:** [DietPi ↗](https://dietpi.com) (Ultra-lightweight Debian-based Linux, ~350 MB download image, < 50 MB idle RAM)  
> **Repository:** [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public)  
> **Script:** [`Oracle_Cloud/dietpi_installer.sh ↗`](dietpi_installer.sh)

---

## 🎯 Why DietPi on Oracle Cloud?

Standard cloud images (Ubuntu, Oracle Linux) ship with dozens of background daemons, snap packages, and telemetry agents consuming **300–800 MB RAM** at idle.

**DietPi** reduces this footprint to the absolute bare minimum:
- ⚡ **Idle RAM consumption:** Less than **50 MB** RAM.
- 📦 **Download image size:** Only **~350 MB** compressed.
- 🛠️ **Built-in `dietpi-software`:** 1-click optimized installations for Docker, Xray, WireGuard, AdGuard Home, Pi-hole, Nginx, MariaDB, Node.js, and monitoring tools.
- 🛡️ **Zero Bloat:** Pure Debian Bookworm base with fine-tuned logging, RAM disk logging (`dietpi-ramlog`), and CPU governor controls.

---

## 📋 Step-by-Step Installation Process

### Step 1: Launch a Base Debian 12 Instance in Oracle Cloud
1. Log in to the [Oracle Cloud Console ↗](https://cloud.oracle.com).
2. Go to **Compute** ➔ **Instances** ➔ **Create Instance**.
3. **Shape:** Choose either:
   - **Ampere A1 Flex** (`VM.Standard.A1.Flex`) — ARM64 (1 to 4 OCPU, 2 to 24 GB RAM);
   - **AMD Micro** (`VM.Standard.E2.1.Micro`) — x86_64 (1/8 OCPU, 1 GB RAM).
4. **Image:** Click **Change Image** ➔ Select **Canonical Ubuntu** or **Debian 12** (Minimal).
5. **Networking:** Ensure a **Public IPv4 address** is assigned.
6. **SSH Keys:** Paste your public SSH key (`id_ed25519.pub` or `id_rsa.pub`).
7. Click **Create** and wait 30 seconds for the instance to transition to the **Running** state.

---

### Step 2: Connect to your Server via SSH
Open your terminal and connect as `root` (or `ubuntu`/`debian` user, then switch to root):

```bash
# Connect to your newly created instance
ssh debian@<YOUR_SERVER_PUBLIC_IP>

# Switch to root account
sudo -i
```

---

### Step 3: Run the In-RAM DietPi Installer (One-Liner)

Run the universal installer script directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Oracle_Cloud/dietpi_installer.sh | bash
```

---

### Step 4: What Happens Automatically Behind the Scenes

1. **Architecture Detection:** The script checks `uname -m` and identifies whether your instance is **ARM64** (Ampere A1) or **x86_64** (AMD Micro).
2. **Official Source Fetching:** It downloads the official pure image directly from the official **`dietpi.com`** CDN mirror:
   - For **ARM64 (Ampere A1)**: `https://dietpi.com/downloads/images/DietPi_ARMv8-UEFI-Bookworm.img.xz`
   - For **x86_64 (AMD Micro)**: `https://dietpi.com/downloads/images/DietPi_NativePC-BIOS-x86_64-Bookworm.img.xz` (or UEFI version)
3. **In-RAM Buffering:** The ~350 MB archive is buffered directly into temporary memory (`/dev/shm`), avoiding disk conflicts.
4. **SSH Key Preservation:** Your existing `/root/.ssh/authorized_keys` are safely backed up in RAM.
5. **Disk Flashing:** The image is written on-the-fly directly to the root block device (`/dev/sda` or `/dev/vda`).
6. **Instant Hardware Reboot:** The script executes a kernel hardware reset via `/proc/sysrq-trigger` to immediately boot into fresh DietPi.

---

### Step 5: Reconnect to Fresh DietPi

Wait **20–30 seconds** for the instance to complete its first boot, then reconnect via SSH:

```bash
ssh root@<YOUR_SERVER_PUBLIC_IP>
```

* **Default root password:** `dietpi` (or your preserved SSH key).
* **Initial Setup:** On first login, DietPi will automatically expand the root filesystem to fill your entire disk (e.g. 50 GB or 150 GB) and prompt you through the initial setup wizard.

---

## 🛠️ Recommended Post-Install Tweaks

Once logged in to DietPi:

```bash
# Launch DietPi Software Center
dietpi-software

# Launch DietPi Configuration Panel (CPU governor, network, display)
dietpi-config

# Launch DietPi Backup & System Utilities
dietpi-backup
```