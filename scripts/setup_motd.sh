#!/bin/bash
clear
# setup_motd.sh — Universal SSH banner (MOTD) + color picker
# Version: v2026-03-24
# Usage: bash /root/Linux_Server_Public/scripts/setup_motd.sh
# Works on ANY server — auto-detects aliases and system info

SERVER_NAME=$(hostname)
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "====================================="
echo "  SETUP SSH BANNER FOR: $SERVER_NAME"
echo "====================================="

# --- COLLECT ALIASES ---
ALIASES_RAW=$(grep -h 'alias ' /root/.bashrc /root/.bash_profile /root/Linux_Server_Public/scripts/shared_aliases.sh 2>/dev/null | sed "s/alias //g" | sed "s/=.*//g" | sort -u)

# --- COLOR PICKER ---
echo ""
echo -e "  Pick banner color:"
echo -e "  1) \e[01;33mYELLOW\e[0m  2) \e[38;5;217mLIGHT PINK\e[0m  3) \e[38;5;87mTURQUOISE\e[0m  4) \e[01;32mGREEN\e[0m  5) \e[38;5;214mORANGE\e[0m"
echo ""
read -p "  Choose [1-5]: " C

case $C in
  1) P='\[\033[01;33m\]' ; R='\[\033[00m\]'  ; N='YELLOW'       ; BC='\033[01;33m' ;;
  2) P='\[\e[38;5;217m\]'; R='\[\e[m\]'      ; N='LIGHT PINK'   ; BC='\e[38;5;217m' ;;
  3) P='\[\e[38;5;87m\]' ; R='\[\e[m\]'      ; N='TURQUOISE'    ; BC='\e[38;5;87m' ;;
  4) P='\[\033[01;32m\]' ; R='\[\033[00m\]'  ; N='BRIGHT GREEN' ; BC='\033[01;32m' ;;
  5) P='\[\e[38;5;214m\]'; R='\[\e[m\]'      ; N='ORANGE'       ; BC='\e[38;5;214m' ;;
  *) echo "Wrong choice"; exit 1 ;;
esac

# --- SET PS1 ---
sed -i '/export PS1=/d' /root/.bashrc
echo "export PS1=\"${P}\u@\h:\w\$ ${R}\"" >> /root/.bashrc
sed -i '/export PS1=/d' /root/.bash_profile 2>/dev/null
echo "export PS1=\"${P}\u@\h:\w\$ ${R}\"" >> /root/.bash_profile

# --- BUILD MOTD SCRIPT ---
cat > /etc/profile.d/motd_banner.sh << MOTD_SCRIPT
#!/bin/bash
clear
SERVER_NAME=\$(hostname)
SERVER_IP=\$(hostname -I | awk '{print \$1}')
RAM_USED=\$(free -m | awk '/Mem:/{print \$3}')
RAM_TOTAL=\$(free -m | awk '/Mem:/{print \$2}')
CPU=\$(top -bn1 | grep 'Cpu(s)' | awk '{print int(\$2+\$4)}')
UPTIME=\$(uptime -p)
LOAD=\$(uptime | awk -F'load average:' '{print \$2}')

COLOR='${BC}'
RESET='\033[0m'
BOLD='\033[1m'
LINE=\$(printf '\u2500%.0s' {1..80})

echo -e "\${COLOR}\${LINE}\${RESET}"
printf "\${COLOR}  ♥  %-22s %-22s RAM:%s/%sMB  CPU:%s%%\n\${RESET}" "\$SERVER_NAME" "\$SERVER_IP" "\$RAM_USED" "\$RAM_TOTAL" "\$CPU"
echo -e "\${COLOR}\${LINE}\${RESET}"

# Auto-collect all aliases
ALL_ALIASES=\$(grep -h 'alias ' /root/.bashrc /root/.bash_profile /root/Linux_Server_Public/scripts/shared_aliases.sh 2>/dev/null | sed 's/alias //g' | awk -F'=' '{print \$1}' | sort -u | tr '\n' ' ')

echo -e "  \${BOLD}ALIASES:\${RESET} \$ALL_ALIASES" | fold -s -w 78 | sed '2,\$ s/^/  /'

echo -e "\${COLOR}\${LINE}\${RESET}"
echo -e "  \$(lsb_release -ds 2>/dev/null || echo Linux) | \$SERVER_IP | \$UPTIME | load:\$LOAD"
echo -e "\${COLOR}\${LINE}\${RESET}"
echo ""
MOTD_SCRIPT

chmod +x /etc/profile.d/motd_banner.sh

# Disable default MOTD
chmod -x /etc/update-motd.d/* 2>/dev/null

source /root/.bashrc

echo ""
echo "✅ Banner installed: /etc/profile.d/motd_banner.sh"
echo "✅ Color: ${N} — saved to .bashrc + .bash_profile"
echo "✅ Will show on every SSH login automatically"
echo "✅ Run now to preview:"
echo "    bash /etc/profile.d/motd_banner.sh"
echo ""

echo "========================================="

