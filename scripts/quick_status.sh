#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  quick_status.sh | [v2026-08-15]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Lightning-fast server health overview (Load, RAM, Disk, Services)
# Servers     : All Linux Nodes (222-DE / 109-RU / VPN Nodes)
# Usage       : bash scripts/quick_status.sh
# ==========================================================================================

# Interactive check
if [ -t 0 ] && [ -t 1 ] && [ "${1:-}" != "--run" ]; then
    if [ ! -f /usr/local/bin/qs ] || ! grep -q "alias qs=" /root/.bashrc 2>/dev/null; then
        echo "============================================================"
        echo "  Quick Status (qs) — Select Mode:"
        echo "    1) Run quick status directly"
        echo "    2) Install (alias 'qs' + /usr/local/bin/qs)"
        echo "============================================================"
        read -rp "Enter choice [1]: " CHOICE
        CHOICE=${CHOICE:-1}

        if [ "$CHOICE" = "2" ]; then
            cp "$0" /usr/local/bin/qs 2>/dev/null || curl -fsSL "https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/quick_status.sh" -o /usr/local/bin/qs
            chmod +x /usr/local/bin/qs
            if ! grep -q "alias qs=" /root/.bashrc 2>/dev/null; then
                echo "alias qs='/usr/local/bin/qs --run'" >> /root/.bashrc
            fi
            echo "✔ Installed to /usr/local/bin/qs"
            echo "✔ Alias added to /root/.bashrc: qs"
            echo ""
        fi
    fi
fi

clear
G='\033[1;32m'; C='\033[1;36m'; Y='\033[1;33m'; R='\033[1;31m'; X='\033[0m'
svc_st(){ systemctl is-active "$1" >/dev/null 2>&1 && echo -e "${G}ACTIVE${X}" || echo -e "${R}DOWN${X}"; }

echo -e "${Y}==================== QUICK STATUS: $(hostname) ====================${X}"
echo -e "${C}Uptime:${X}    $(uptime -p 2>/dev/null || uptime)"
echo -e "${C}Load Avg:${X}  $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
echo -e "${C}Memory:${X}    ${G}$(free -h 2>/dev/null | awk '/^Mem:/{print $3"/"$2}')${X} (Swap: $(free -h 2>/dev/null | awk '/^Swap:/{print $3"/"$2}'))"
echo -e "${C}Disk /:${X}    ${G}$(df -h / 2>/dev/null | awk 'NR==2{print $3"/"$2" ("$5")"}')${X}"
echo -e "${Y}------------------------------------------------------------${X}"
echo -e "${C}Services:${X}  Nginx: $(svc_st nginx) | MariaDB: $(svc_st mariadb || svc_st mysql) | SSH: $(svc_st ssh || svc_st sshd)"
if [ -d /usr/local/fastpanel2 ]; then
    echo -e "${C}FastPanel:${X} $(svc_st fastpanel2) | CrowdSec: $(svc_st crowdsec)"
fi
echo -e "${Y}============================================================${X}"

# = Rooted by VladiMIR | AI = v2026-08-15 = github.com/GinCz/Linux_Server_Public
