#!/bin/bash
clear
# set_color.sh — Universal PS1 color picker
# Version: v2026-03-24
# Usage: bash /root/Linux_Server_Public/scripts/set_color.sh

echo ""
echo "=========================================="
echo "   SELECT TERMINAL COLOR FOR THIS SERVER"
echo "=========================================="
echo ""
echo -e "  \e[01;33m1) YELLOW       — EU servers (222 DE)\e[0m"
echo -e "  \e[38;5;217m2) LIGHT PINK   — RU servers (109 RU)\e[0m"
echo -e "  \e[38;5;87m3) LIGHT BLUE   — VPN / Tunnel\e[0m"
echo -e "  \e[01;32m4) BRIGHT GREEN — AWS / Cloud\e[0m"
echo -e "  \e[38;5;214m5) ORANGE       — Dev / Test servers\e[0m"
echo ""
read -p "  Enter number [1-5]: " CHOICE

case $CHOICE in
  1)
    COLOR_CODE='\[\033[01;33m\]'
    COLOR_RESET='\[\033[00m\]'
    COLOR_NAME='YELLOW'
    ;;
  2)
    COLOR_CODE='\[\e[38;5;217m\]'
    COLOR_RESET='\[\e[m\]'
    COLOR_NAME='LIGHT PINK'
    ;;
  3)
    COLOR_CODE='\[\e[38;5;87m\]'
    COLOR_RESET='\[\e[m\]'
    COLOR_NAME='LIGHT BLUE'
    ;;
  4)
    COLOR_CODE='\[\033[01;32m\]'
    COLOR_RESET='\[\033[00m\]'
    COLOR_NAME='BRIGHT GREEN'
    ;;
  5)
    COLOR_CODE='\[\e[38;5;214m\]'
    COLOR_RESET='\[\e[m\]'
    COLOR_NAME='ORANGE'
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

PS1_LINE="export PS1='${COLOR_CODE}\\u@\\h:\\w\\$${COLOR_RESET} '"

# Write to /root/.bashrc
if grep -q 'export PS1=' /root/.bashrc; then
  sed -i "s|export PS1=.*|${PS1_LINE}|g" /root/.bashrc
else
  echo "${PS1_LINE}" >> /root/.bashrc
fi

# Write to /root/.bash_profile
if [ -f /root/.bash_profile ]; then
  if grep -q 'export PS1=' /root/.bash_profile; then
    sed -i "s|export PS1=.*|${PS1_LINE}|g" /root/.bash_profile
  else
    echo "${PS1_LINE}" >> /root/.bash_profile
  fi
else
  echo "${PS1_LINE}" > /root/.bash_profile
  echo "[ -f /root/.bashrc ] && source /root/.bashrc" >> /root/.bash_profile
fi

# Apply immediately
export PS1="${COLOR_CODE}\u@\h:\w\$ ${COLOR_RESET}"
source /root/.bashrc

echo ""
echo "✅ Color set to: ${COLOR_NAME}"
echo "✅ Saved to /root/.bashrc and /root/.bash_profile"
echo "✅ Permanent — works after reconnect via SSH"
echo ""
