# 🚀 AWS EC2 Linux Desktop + XRDP (100% Free Tier & Zero IPv4 Costs)
> **Lightweight, High-Performance Remote GUI Desktop (XFCE4 + XRDP + Brave + Telegram) on AWS EC2 `t3.micro` over native IPv6.**  
> *Author:* **[GinCz (Vladimir Bulancev) ↗](https://github.com/GinCz)** | **= Rooted by VladiMIR + AI =**

---

[![AWS](https://img.shields.io/badge/AWS-EC2%20Free%20Tier-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com/free/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![XFCE](https://img.shields.io/badge/Desktop-XFCE4%20Fast%20%26%20Light-blue?style=for-the-badge&logo=xfce&logoColor=white)](https://www.xfce.org/)
[![XRDP](https://img.shields.io/badge/Protocol-RDP%20Port%203389-success?style=for-the-badge)](http://www.xrdp.org/)
[![IPv6 Ready](https://img.shields.io/badge/Network-Pure%20IPv6%20Enabled-8A2BE2?style=for-the-badge)](https://en.wikipedia.org/wiki/IPv6)

#aws #ec2 #linux #rdp #xrdp #xfce #freetier #ipv6 #brave-browser #telegram-desktop #devops #sysadmin #cloud-cost-optimization

---

## 📌 Overview

Running a Windows Server on AWS EC2 costs **$24.48/month for the Windows license** plus **$3.65/month for public IPv4**, making a basic remote desktop cost around **~$30/month**.

This solution deploys an **ultra-lightweight Ubuntu 24.04 LTS Desktop with XFCE4 + XRDP** that runs seamlessly on a 100% **AWS Free Tier `t3.micro`** (1 vCPU, 1 GB RAM, 20 GB gp3 SSD) and connects directly via **IPv6**, costing **$0.00 / month**.

### 🌟 Key Highlights
- **100% Free Tier Compatible:** Uses 0 extra compute hours and stays inside the 30 GB EBS quota.
- **Pure IPv6 Connectivity:** Bypass AWS's new $0.005/hour ($3.65/month) public IPv4 surcharge.
- **Minimal RAM Footprint (~190 MB):** Leaves 800+ MB free for browser and apps.
- **Pre-configured 2 GB Swapfile:** Prevents Out-Of-Memory crashes.
- **Pre-installed Modern Apps:** Latest Brave Browser & Telegram Desktop with desktop shortcuts.
- **Modern Look & Feel:** Arc-Dark theme, Papirus icons, and Whisker start menu (Windows / Linux Mint style).

---

## 🏗️ Architecture & Resource Breakdown

| Component | Specification | Free Tier Status |
|---|---|---|
| **Instance Type** | `t3.micro` (2 vCPU, 1 GB RAM) | ✅ Covered under 750 free hours/month |
| **CPU Credit Mode** | `Standard` (T3 Overdraft disabled) | ✅ Prevents unexpected CPU overage bills |
| **Storage (EBS)** | 20 GB `gp3` (3000 IOPS / 125 MB/s) | ✅ Covered under 30 GB free storage/month |
| **Virtual Memory** | 2 GB Swap file (`/swapfile`, swappiness=15) | ✅ Zero cost, high stability |
| **Network** | Direct IPv6 Routing (`::/0` via IGW) | ✅ 100% Free & Unlimited |
| **RDP Port** | TCP `3389` | Standard RDP client (mRemoteNG, MS Remote Desktop) |

---

## ⚡ One-Line Automated Setup

Run this single command on a fresh Ubuntu 24.04 / 22.04 LTS instance:

```bash
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/AWS_Amazon_Linux_RDP/setup_aws_desktop.sh | sudo bash
```

---

## 🛠️ Step-by-Step Manual Installation Guide

### Step 1: Configure Swap (Essential for 1 GB RAM Instances)
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
sudo sysctl -w vm.swappiness=15
echo 'vm.swappiness=15' | sudo tee -a /etc/sysctl.conf
```

### Step 2: Install XFCE4 & XRDP
```bash
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get install -y xfce4 xfce4-goodies xrdp dbus-x11 x11-xserver-utils curl wget

# Configure XRDP user session
echo "startxfce4" > ~/.xsession
sudo adduser xrdp ssl-cert
sudo adduser ubuntu xrdp
sudo adduser ubuntu ssl-cert
sudo systemctl enable xrdp
sudo systemctl restart xrdp
```

### Step 3: Install Beautiful Modern Themes & Whisker Menu
```bash
sudo apt-get install -y arc-theme papirus-icon-theme xfce4-whiskermenu-plugin
```

### Step 4: Install Brave Browser & Telegram Desktop
```bash
# Brave Browser
curl -fsS https://dl.brave.com/install.sh | sh

# Telegram Desktop
sudo wget -qO /tmp/tsetup.tar.xz "https://telegram.org/dl/desktop/linux"
sudo tar -xf /tmp/tsetup.tar.xz -C /tmp/
sudo mv /tmp/Telegram/Telegram /usr/local/bin/telegram-desktop
sudo chmod +x /usr/local/bin/telegram-desktop

# Create Desktop Shortcuts
mkdir -p ~/Desktop
cat << 'EOF' > ~/Desktop/brave.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Brave Browser
Exec=/usr/bin/brave-browser %U
Icon=brave-browser
Terminal=false
EOF

cat << 'EOF' > ~/Desktop/telegram.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Telegram Desktop
Exec=/usr/local/bin/telegram-desktop -- %u
Icon=telegram
Terminal=false
EOF
chmod +x ~/Desktop/*.desktop
```

### Step 5: Enable Password Login
```bash
echo "ubuntu:YOUR_SECURE_PASSWORD" | sudo chpasswd
```

---

## 🌐 Connecting via IPv6 with mRemoteNG / Microsoft RDP

### Important IPv6 Syntax Rule:
In RDP clients (such as **mRemoteNG**, **PuTTY**, or **mstsc**), IPv6 addresses **must be enclosed in square brackets `[ ... ]`**:

- **Hostname / IP:** `[2a05:d014:1ed1:cd01:1a3b:f5d2:f716:3d1d]` *(use your server's IPv6)*
- **Protocol:** `RDP`
- **Port:** `3389`
- **Username:** `ubuntu`
- **Password:** *(your configured password)*

> 💡 **Tip for mRemoteNG:** Saving your username and password in the connection configuration bypasses the XRDP greeting prompt and logs you straight into your XFCE desktop in under 1 second!

---

## 🔒 AWS Security Group Configuration

Ensure your AWS EC2 Security Group contains the following inbound rule:

| Type | Protocol | Port Range | Source | Description |
|---|---|---|---|---|
| **RDP** | TCP | `3389` | `::/0` | Direct IPv6 Remote Desktop |
| **SSH** | TCP | `22` | `::/0` | Direct IPv6 SSH Access |

---

## 📄 License & Community

Created with ❤️ by **[GinCz ↗](https://github.com/GinCz)**.  
Free for personal and commercial usage under the MIT License.
