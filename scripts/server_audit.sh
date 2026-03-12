#!/usr/bin/env bash
# Deep Server Audit & Inventory Tool
source /root/scripts/common.sh

REPORT_FILE="/root/scripts/inventory/$(hostname).md"
mkdir -p /root/scripts/inventory

{
    echo "# Audit Report for $(hostname)"
    echo "Generated: $(date)"
    echo "---"
    echo "## 🔍 Hidden Triggers (SSH/PAM)"
    grep -rnE "curl|sendMessage|tg_send|login_notify" /etc/profile /etc/bash.bashrc ~/.bashrc ~/.profile /etc/pam.d/ /etc/ssh/ 2>/dev/null | sed 's/^/    /'
    
    echo "## 📅 Cron Jobs"
    crontab -l | grep -v "^#" | sed 's/^/    /'
    
    echo "## 📂 Custom Scripts (/usr/local/bin)"
    ls -l /usr/local/bin/ | grep ".sh" | sed 's/^/    /'
    
    echo "## 🖥️ Resources"
    echo "    Disk: $(df -h / | awk 'NR==2 {print $5}') full"
    echo "    RAM: $(free -h | awk 'NR==2 {print $3 "/" $2}')"
    
    echo "## 🌐 Active Services (Samba/VPN)"
    ss -tulpn | grep -E '445|51820|1194' | sed 's/^/    /'
} > "$REPORT_FILE"

echo -e "${GREEN}>>> Audit completed. Report saved to inventory/$(hostname).md${NC}"
