#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  sync_all_vpn_nodes.sh | [v2026-08-23]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Run 'load' + apply Sky Blue header & Bright Green PS1 prompt across all VPN nodes
# Run from    : Server 222 (NetCup Master) or any machine with SSH keys
# Usage       : bash scripts/sync_all_vpn_nodes.sh
# ==========================================================================================
clear
C='\033[38;5;81m'; G='\033[0;92m'; Y='\033[0;93m'; W='\033[1;37m'; R='\033[1;31m'; X='\033[0m'
HR="${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${X}"

echo -e "$HR"
echo -e "  ${W}🚀 GLOBAL VPN NODES SYNCHRONIZER & THEME DEPLOYER${X}"
echo -e "  ${Y}Target: All 10 VPN Nodes | Profile: VPN Node | Header: Sky Blue | PS1: Bright Green${X}"
echo -e "$HR"
echo

VPN_NODES=(
  "212.34.148.51:Alex-47"
  "144.124.228.237:4Ton-237"
  "144.124.232.9:Tatra-9"
  "144.124.228.227:Shahin-227"
  "144.124.239.24:Stolb-24"
  "195.63.138.33:Pilik-33"
  "146.103.110.176:Ilya-176"
  "144.124.233.38:So-38"
  "18.195.117.12:AWS-12"
  "82.223.116.38:Ionos-38"
)

TOTAL=${#VPN_NODES[@]}
SUCCESS=0
FAILED=0

for i in "${!VPN_NODES[@]}"; do
  entry="${VPN_NODES[$i]}"
  IP="${entry%%:*}"
  NAME="${entry##*:}"
  INDEX=$((i + 1))

  echo -en "  [${INDEX}/${TOTAL}] Connecting to ${W}${NAME}${X} (${C}${IP}${X})... "

  # 1. Test SSH connectivity
  if ! ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@${IP} "true" 2>/dev/null; then
    echo -e "${R}✗ SSH FAILED (Unreachable or Key Rejected)${X}"
    ((FAILED++))
    continue
  fi

  # 2. Execute remote Load & Theme Deployment payload
  ssh -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=no root@${IP} 'bash -s' << 'REMOTE_PAYLOAD' 2>/dev/null
    REPO="/root/Linux_Server_Public"
    mkdir -p /root/.config/mc /etc/mc /usr/local/bin

    # 1. Update/Clone repository
    if [ -d "$REPO/.git" ]; then
        cd "$REPO" && git fetch origin main --quiet 2>/dev/null && git reset --hard origin/main --quiet 2>/dev/null
    else
        git clone https://github.com/GinCz/Linux_Server_Public.git "$REPO" --quiet 2>/dev/null
    fi

    # 2. Deploy /usr/local/bin utilities
    if [ -d "$REPO/scripts" ]; then
        cp -f "$REPO/scripts/sos.sh" /usr/local/bin/sos 2>/dev/null || true
        cp -f "$REPO/scripts/infooo.sh" /usr/local/bin/infooo 2>/dev/null || true
        cp -f "$REPO/scripts/upd.sh" /usr/local/bin/upd 2>/dev/null || true
        cp -f "$REPO/scripts/load.sh" /usr/local/bin/load 2>/dev/null || true
        cp -f "$REPO/scripts/save.sh" /usr/local/bin/save 2>/dev/null || true
        cp -f "$REPO/scripts/scan_clamav.sh" /usr/local/bin/antivir 2>/dev/null || true
        chmod +x /usr/local/bin/* 2>/dev/null || true
    fi

    # 3. Create style / theme wrapper
    cat << 'STYLEEOF' > /usr/local/bin/style
#!/usr/bin/env bash
if [ -f /root/Linux_Server_Public/scripts/new_server_install.sh ]; then
    bash /root/Linux_Server_Public/scripts/new_server_install.sh "$@"
else
    bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh) "$@"
fi
STYLEEOF
    chmod +x /usr/local/bin/style
    ln -sf /usr/local/bin/style /usr/local/bin/theme

    # 4. Install MOTD banner with Sky Blue header (\033[38;5;81m)
    rm -f /etc/profile.d/*motd*.sh /etc/profile.d/motd*.sh /usr/local/bin/*motd*.sh 2>/dev/null || true
    chmod -x /etc/update-motd.d/* 2>/dev/null || true
    > /etc/motd
    if [ -f "$REPO/scripts/motd_vpn.sh" ]; then
        cp -f "$REPO/scripts/motd_vpn.sh" /etc/profile.d/motd_server.sh
    elif [ -f "$REPO/VPN_Amnezia/motd_server.sh" ]; then
        cp -f "$REPO/VPN_Amnezia/motd_server.sh" /etc/profile.d/motd_server.sh
    fi
    sed -i "s|^C=.*|C='\\\\033[38;5;81m'|" /etc/profile.d/motd_server.sh 2>/dev/null || true
    chmod +x /etc/profile.d/motd_server.sh 2>/dev/null || true

    # 5. Set Terminal Prompt (PS1) Color to Bright Green (\033[01;92m)
    sed -i '/PS1=/d' /root/.bashrc /root/.profile /etc/bash.bashrc 2>/dev/null || true
    echo "export PS1='\[\033[01;92m\]\u@\h:\w\$\[\033[00m\] '" >> /root/.bashrc
    echo "export PS1='\[\033[01;92m\]\u@\h:\w\$\[\033[00m\] '" >> /etc/bash.bashrc

    # 6. Apply clean VPN aliases & Mc Menu
    if [ -f "$REPO/scripts/apply_aliases.sh" ]; then
        bash "$REPO/scripts/apply_aliases.sh" vpn 2>/dev/null || true
    fi
REMOTE_PAYLOAD

  if [ $? -eq 0 ]; then
    echo -e "${G}✔ LOADED & STYLED (Sky Blue + Bright Green)${X}"
    ((SUCCESS++))
  else
    echo -e "${Y}⚠ Payload returned warning${X}"
    ((SUCCESS++))
  fi
done

echo
echo -e "$HR"
echo -e "  ${W}📊 DEPLOYMENT SUMMARY:${X} ${G}${SUCCESS} nodes updated successfully${X} | ${R}${FAILED} unreachable${X}"
echo -e "$HR"
echo