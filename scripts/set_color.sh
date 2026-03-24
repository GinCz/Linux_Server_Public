#!/bin/bash
# set_color.sh — Universal PS1 color picker
# Version: v2026-03-24
# ============================================================
# COPY THIS ONE-LINE COMMAND TO ANY SERVER:
# ============================================================
#
# clear;echo -e "\n1) \e[01;33mYELLOW\e[0m  2) \e[38;5;217mLIGHT PINK\e[0m  3) \e[38;5;87mTURQUOISE\e[0m  4) \e[01;32mGREEN\e[0m  5) \e[38;5;214mORANGE\e[0m\n";read -p "Choose [1-5]: " C;case $C in 1) P='\[\033[01;33m\]' R='\[\033[00m\]';; 2) P='\[\e[38;5;217m\]' R='\[\e[m\]';; 3) P='\[\e[38;5;87m\]' R='\[\e[m\]';; 4) P='\[\033[01;32m\]' R='\[\033[00m\]';; 5) P='\[\e[38;5;214m\]' R='\[\e[m\]';; *) echo "Wrong";exit 1;; esac;sed -i '/export PS1=/d' /root/.bashrc;echo "export PS1=\"${P}\u@\h:\w\$ ${R}\"" >> /root/.bashrc;sed -i '/export PS1=/d' /root/.bash_profile 2>/dev/null;echo "export PS1=\"${P}\u@\h:\w\$ ${R}\"" >> /root/.bash_profile;source /root/.bashrc;echo "✅ Done"
#
# ============================================================

clear
echo ""
echo -e "  1) \e[01;33mYELLOW\e[0m       — EU servers (222 DE)"
echo -e "  2) \e[38;5;217mLIGHT PINK\e[0m   — RU servers (109 RU)"
echo -e "  3) \e[38;5;87mTURQUOISE\e[0m    — VPN / Tunnel"
echo -e "  4) \e[01;32mBRIGHT GREEN\e[0m  — AWS / Cloud"
echo -e "  5) \e[38;5;214mORANGE\e[0m        — Dev / Test servers"
echo ""
read -p "  Choose [1-5]: " C

case $C in
  1) P='\[\033[01;33m\]' ; R='\[\033[00m\]'  ; N='YELLOW'       ;;
  2) P='\[\e[38;5;217m\]'; R='\[\e[m\]'      ; N='LIGHT PINK'   ;;
  3) P='\[\e[38;5;87m\]' ; R='\[\e[m\]'      ; N='TURQUOISE'    ;;
  4) P='\[\033[01;32m\]' ; R='\[\033[00m\]'  ; N='BRIGHT GREEN' ;;
  5) P='\[\e[38;5;214m\]'; R='\[\e[m\]'      ; N='ORANGE'       ;;
  *) echo "Wrong choice"; exit 1 ;;
esac

sed -i '/export PS1=/d' /root/.bashrc
echo "export PS1=\"${P}\u@\h:\w\$ ${R}\"" >> /root/.bashrc

sed -i '/export PS1=/d' /root/.bash_profile 2>/dev/null
echo "export PS1=\"${P}\u@\h:\w\$ ${R}\"" >> /root/.bash_profile

source /root/.bashrc

echo ""
echo "✅ Color: ${N} — saved permanently to .bashrc and .bash_profile"
echo ""
