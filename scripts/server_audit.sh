#!/usr/bin/env bash
# Deep Server Audit & Inventory Tool (Conflict-Proof Version)
source /root/scripts/common.sh

INV_DIR="/root/scripts/inventory"
REPORT_FILE="${INV_DIR}/$(hostname).md"
mkdir -p "$INV_DIR"

echo "--- Starting Audit: $(hostname) ---"

# --- 1. ПЕРЕД ТЕМ КАК ПИСАТЬ, ЗАБИРАЕМ ОБНОВЛЕНИЯ ---
cd /root/scripts && git pull origin main --quiet

# --- 2. ГЕНЕРИРУЕМ ОТЧЕТ ---
{
    echo "# Audit Report: $(hostname)"
    echo "Last Update: $(date '+%d-%m-%Y %H:%M:%S')"
    echo "---"
    echo "## 🔍 Hidden SSH/PAM Triggers"
    grep -rnE "curl|sendMessage|tg_send|login_notify" /etc/profile /etc/bash.bashrc ~/.bashrc ~/.profile /etc/pam.d/ /etc/ssh/ 2>/dev/null | sed 's/^/    /'
    
    echo "## 📅 Active Cron Jobs"
    crontab -l 2>/dev/null | grep -v "^#" | sed 's/^/    /'
    
    echo "## 📂 Custom Scripts (/usr/local/bin)"
    ls -l /usr/local/bin/ | grep ".sh" | sed 's/^/    /'
    
    echo "## 🖥️ System Resources"
    echo "    Disk Usage: $(df -h / | awk 'NR==2 {print $5}')"
    echo "    RAM Usage: $(free -h | awk 'NR==2 {print $3 "/" $2}')"
    
    echo "## 🌐 Active Services"
    ss -tulpn | grep -E '445|51820|1194|22' | sed 's/^/    /'
} > "$REPORT_FILE"

# --- 3. ОТПРАВЛЯЕМ В GIT ---
git add "$REPORT_FILE"
git commit -m "Auto-Inventory: $(hostname) $(date '+%H:%M')" --quiet
git push origin main --quiet

echo -e "${GREEN}>>> Audit report for $(hostname) synced with GitHub.${NC}"
