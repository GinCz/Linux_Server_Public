#!/bin/bash
# =============================================================
# Script:      new_server_install.sh
# Version:     v2026.07.08
# Description: FULLY STANDALONE — no calls to other repo scripts.
#              Three server types:
#                1 = VPN (VPN)
#                2 = FastPanel + Cloudflare (server 222)
#                3 = FastPanel only (server 109, no Cloudflare)
#              NOTE: apt upgrade is a separate script — run: upd
# Usage:
#   bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh)
# = Rooted by VladiMIR + AI | v.2026.07.08 | github.com/GinCz =
# =============================================================
clear
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin

C='\033[1;37m'; X='\033[0m'
echo -e "${C}=========================================${X}"
echo -e "${C}   NEW SERVER SETUP v2026.07.08${X}"
echo -e "${C}   = Rooted by VladiMIR + AI | github.com/GinCz =${X}"
echo -e "${C}=========================================${X}"
echo

# ─── Server name ────────────────────────────────────────────
CURRENT_HOSTNAME=$(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null | head -1 | tr -d '[:space:]')
read -rp "Enter server name [${CURRENT_HOSTNAME}]: " SRV_NAME
SRV_NAME="${SRV_NAME:-${CURRENT_HOSTNAME}}"
[[ -n "${SRV_NAME:-}" ]] || { echo "Server name cannot be empty"; exit 1; }

# ─── Server type ────────────────────────────────────────────
echo
echo "Select server type:"
echo "  1) VPN              (VPN)"
echo "  2) FastPanel + CF   (server 222: Cloudflare + XRay + CryptoBot)"
echo "  3) FastPanel only   (server 109: Russian sites, no Cloudflare)"
read -rp "Type [1/2/3, default 1]: " SRV_TYPE
SRV_TYPE="${SRV_TYPE:-1}"
[[ "$SRV_TYPE" =~ ^[123]$ ]] || SRV_TYPE=1

# ─── PS1 color ───────────────────────────────────────────────
echo
echo "Select terminal PS1 color:"
echo -e "  \033[01;96m1) Bright Cyan     — бирюзовый (VPN default)\033[0m"
echo -e "  \033[01;91m2) Bright Red      — красный\033[0m"
echo -e "  \033[01;92m3) Bright Green    — зелёный\033[0m"
echo -e "  \033[01;93m4) Bright Yellow   — жёлтый (222 default)\033[0m"
echo -e "  \033[38;5;208m5) Orange          — оранжевый\033[0m"
echo -e "  \033[38;5;213m6) Bright Pink     — розовый\033[0m"
echo -e "  \033[01;97m7) Bright White    — белый (109 default)\033[0m"

case "$SRV_TYPE" in
  2) DEF_COLOR=4 ;;
  3) DEF_COLOR=7 ;;
  *) DEF_COLOR=1 ;;
esac
read -rp "Color [1-7, default ${DEF_COLOR}]: " CC
CC="${CC:-${DEF_COLOR}}"
case "$CC" in
  1) PS1_CODE='01;96m';    PS1_NAME="Bright Cyan"   ; MOTD_COLOR='\033[01;96m' ;;
  2) PS1_CODE='01;91m';    PS1_NAME="Bright Red"    ; MOTD_COLOR='\033[01;91m' ;;
  3) PS1_CODE='01;92m';    PS1_NAME="Bright Green"  ; MOTD_COLOR='\033[01;92m' ;;
  4) PS1_CODE='01;93m';    PS1_NAME="Bright Yellow" ; MOTD_COLOR='\033[01;93m' ;;
  5) PS1_CODE='38;5;208m'; PS1_NAME="Orange"        ; MOTD_COLOR='\033[38;5;208m' ;;
  6) PS1_CODE='38;5;213m'; PS1_NAME="Bright Pink"   ; MOTD_COLOR='\033[38;5;213m' ;;
  7) PS1_CODE='01;97m';    PS1_NAME="Bright White"  ; MOTD_COLOR='\033[01;97m' ;;
  *) PS1_CODE='01;96m';    PS1_NAME="Bright Cyan"   ; MOTD_COLOR='\033[01;96m' ;;
esac

case "$SRV_TYPE" in
  2) TYPE_NAME="Web 222 / FastPanel / Cloudflare / XRay / CryptoBot" ;;
  3) TYPE_NAME="Web 109 / FastPanel / XRay (no Cloudflare)" ;;
  *) TYPE_NAME="VPN" ;;
esac

# ─── Summary ────────────────────────────────────────────────
echo
echo -e "  \033[${PS1_CODE}●\033[0m  Server : ${SRV_NAME}"
echo -e "  \033[${PS1_CODE}●\033[0m  Type   : ${TYPE_NAME}"
echo -e "  \033[${PS1_CODE}●\033[0m  Color  : ${PS1_NAME}"
echo -e "  \033[1;33m⚠  apt upgrade is NOT included — run 'upd' manually after install\033[0m"
echo
echo "Continue?"
echo "  1) Yes"
echo "  2) No"
read -rp "Select [1/2, default 1]: " OK
OK="${OK:-1}"
[[ "$OK" == "1" ]] || { echo "Aborted"; exit 1; }

# ═══════════════════════════════════════════════════════════════
# STEP 1 — Hostname + timezone + SSH cleanup
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}[1/9] Hostname + timezone + SSH settings...\033[0m"
hostnamectl set-hostname "${SRV_NAME}"
grep -q '^127.0.1.1' /etc/hosts \
  && sed -i "s/^127.0.1.1.*/127.0.1.1 ${SRV_NAME}/" /etc/hosts \
  || echo "127.0.1.1 ${SRV_NAME}" >> /etc/hosts
echo "${SRV_NAME}" > /etc/hostname
timedatectl set-timezone Europe/Prague
timedatectl set-ntp true
update-locale LANG=en_US.UTF-8 >/dev/null 2>&1 || true

# ── SSH: hide "Last login" banner line ──
SEEKED_SSHD=/etc/ssh/sshd_config
if [ -f "$SEEKED_SSHD" ]; then
  sed -i 's/^#\?PrintLastLog.*/PrintLastLog no/'  "$SEEKED_SSHD"
  grep -q '^PrintLastLog' "$SEEKED_SSHD" || echo 'PrintLastLog no' >> "$SEEKED_SSHD"
  sed -i 's/^#\?PrintMotd.*/PrintMotd no/'        "$SEEKED_SSHD"
  grep -q '^PrintMotd'     "$SEEKED_SSHD" || echo 'PrintMotd no'     >> "$SEEKED_SSHD"
  systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true
  echo -e "  \033[1;32mOK: PrintLastLog=no, PrintMotd=no\033[0m"
fi
echo -e "\033[1;32mOK: hostname=${SRV_NAME}, TZ=Europe/Prague\033[0m"

# ═══════════════════════════════════════════════════════════════
# STEP 2 — Base packages
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}[2/9] Installing base packages + fail2ban...\033[0m"
apt install -y mc curl wget git htop net-tools sysbench \
  clamav clamav-freshclam ca-certificates uuid-runtime jq socat ufw fail2ban
echo -e "\033[1;32mOK\033[0m"

# ═══════════════════════════════════════════════════════════════
# STEP 3 — Clone / update GitHub repo
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}[3/9] Cloning / updating GitHub repo...\033[0m"
if [ -d /root/Linux_Server_Public ]; then
  cd /root/Linux_Server_Public \
    && git fetch origin main \
    && (git stash 2>/dev/null || true) \
    && git rebase origin/main \
    && (git stash pop 2>/dev/null || true)
  echo -e "\033[1;32mOK: Repo updated\033[0m"
else
  git clone https://github.com/GinCz/Linux_Server_Public.git /root/Linux_Server_Public
  echo -e "\033[1;32mOK: Repo cloned\033[0m"
fi
cd /root

# ═══════════════════════════════════════════════════════════════
# STEP 4 — Install scripts from GitHub to /usr/local/bin/
#
# Installed as system-wide binaries (callable without path):
#   sos      — server audit / error monitor
#   infooo   — system info + benchmark
#   antivir  — ClamAV scan wrapper
#   ports    — open ports viewer
#   load     — git pull + shell reload
#   upd      — system update (apt upgrade + cleanup)
#
# NOT included here (installed manually when needed):
#   ipguard  — manual install only
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}[4/9] Installing scripts from GitHub to /usr/local/bin/...\033[0m"

RAW_BASE="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts"
INSTALL_DIR="/usr/local/bin"

SCRIPTS_TO_INSTALL=(sos infooo antivir ports load upd)

for SCRIPT in "${SCRIPTS_TO_INSTALL[@]}"; do
  printf "  \033[1;36m%-12s\033[0m" "$SCRIPT"
  if curl -fsSL "${RAW_BASE}/${SCRIPT}.sh" -o "${INSTALL_DIR}/${SCRIPT}"; then
    chmod +x "${INSTALL_DIR}/${SCRIPT}"
    echo -e "\033[1;32m✓ installed\033[0m"
  else
    echo -e "\033[1;31m✗ FAILED\033[0m"
  fi
done

# 00 — simple clear shortcut
printf '#!/bin/bash\nclear\n' > /usr/local/bin/00
chmod +x /usr/local/bin/00
echo -e "  \033[1;36m00          \033[0m\033[1;32m✓ installed\033[0m"

echo -e "\033[1;32mOK: all scripts installed from GitHub\033[0m"

# ═══════════════════════════════════════════════════════════════
# STEP 5 — fail2ban config
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}[5/9] Configuring fail2ban...\033[0m"
systemctl enable fail2ban --now 2>/dev/null || true
cat > /etc/fail2ban/jail.local << 'F2BEOF'
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 5
backend  = systemd

[sshd]
enabled  = true
port     = ssh
logpath  = %(sshd_log)s
maxretry = 3
bantime  = 7200
F2BEOF
systemctl restart fail2ban 2>/dev/null || true
F2B=$(systemctl is-active fail2ban 2>/dev/null)
[[ "$F2B" == "active" ]] \
  && echo -e "  \033[1;32mOK: fail2ban active\033[0m" \
  || echo -e "  \033[1;33mWARN: fail2ban=${F2B}\033[0m"

# ═══════════════════════════════════════════════════════════════
# STEP 6 — .bashrc with aliases (type-specific via cat heredoc)
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}[6/9] Writing .bashrc...\033[0m"

# ── Common header (uses variables expanded NOW) ──
cat > /root/.bashrc << BASHRC_HEADER
# ~/.bashrc — ${SRV_NAME}
# Type: ${TYPE_NAME}
# Version: v2026.07.08 | Color: ${PS1_NAME}
# = Rooted by VladiMIR + AI | github.com/GinCz =

export PS1='\[\033[${PS1_CODE}\]\u@\h:\w\$\[\033[00m\] '

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize
BASHRC_HEADER

# ── Common aliases (quoted heredoc — no variable expansion) ──
cat >> /root/.bashrc << 'BASHRC_COMMON'
# ── Shell ───────────────────────────────────────────────────
alias 00="clear"
alias grep="grep --color=auto"
alias ls="ls --color=auto -h"
alias ll="ls -lh --color=auto"
alias la="ls -Ah --color=auto"
alias mc="/usr/bin/mc"
alias df="df -h"
alias du="du -sh"
alias myip="curl -s ifconfig.me && echo"
alias topcpu="ps aux --sort=-%cpu | head -10"
alias topmem="ps aux --sort=-%mem | head -10"

# ── Security ────────────────────────────────────────────────
alias banlist="cscli decisions list 2>/dev/null || echo CrowdSec not installed"
alias sos="/usr/local/bin/sos 1h"
alias sos3="/usr/local/bin/sos 3h"
alias sos24="/usr/local/bin/sos 24h"
alias sos120="/usr/local/bin/sos 120h"
alias antivir="/usr/local/bin/antivir"
alias f2b="fail2ban-client status 2>/dev/null"
alias f2b-ssh="fail2ban-client status sshd 2>/dev/null"
alias f2b-banned="fail2ban-client status sshd 2>/dev/null | grep 'Banned IP'"

# ── Server info ─────────────────────────────────────────────
alias infooo="/usr/local/bin/infooo"
alias ports="/usr/local/bin/ports"

# ── Updates ─────────────────────────────────────────────────
alias upd="/usr/local/bin/upd"

# ── Git ─────────────────────────────────────────────────────
alias gs="git status"
alias gl="git log --oneline -10"
alias load="/usr/local/bin/load"

# ── save (git push) ─────────────────────────────────────────
alias save='cd /root/Linux_Server_Public \
  && git add -A \
  && (git diff --cached --quiet && echo "Nothing to commit" \
    || git commit -m "save: $(hostname) $(date +%Y-%m-%d_%H:%M)") \
  && git pull origin main --no-rebase --no-edit \
  && git push origin main \
  && echo "=== Saved to GitHub ==="'
BASHRC_COMMON

# ── Type-specific aliases ──
case "$SRV_TYPE" in

# ── TYPE 1: VPN ──────────────────────────────────────────────
1)
cat >> /root/.bashrc << 'BASHRC_VPN'
# ── VPN specific ────────────────────────────────────────────
alias amn_st="systemctl status amneziawg 2>/dev/null || echo AmneziaWG not installed"
alias adg_st="systemctl status AdGuardHome 2>/dev/null || echo AdGuard not installed"
alias adg_restart="systemctl restart AdGuardHome 2>/dev/null || true"
alias adg_log="journalctl -u AdGuardHome -n 30 --no-pager 2>/dev/null"
alias wg_st="wg show 2>/dev/null || echo WireGuard not active"
alias xray_log="journalctl -u xray -n 50 --no-pager 2>/dev/null"
alias crowdsec_st="systemctl status crowdsec"
alias nginx_st="systemctl status nginx"
BASHRC_VPN
;;

# ── TYPE 2: FastPanel + Cloudflare (222) ─────────────────────
2)
cat >> /root/.bashrc << 'BASHRC_222'
# ── FastPanel 222 / Cloudflare ──────────────────────────────
alias fp="cd /var/www && ll"
alias fp_log="tail -f /var/log/nginx/error.log"
alias nginx-reload="systemctl reload nginx"
alias nginx_test="nginx -t"
alias reload-all="systemctl reload nginx && systemctl reload php8.2-fpm 2>/dev/null || systemctl reload php8.1-fpm 2>/dev/null || true"
alias fpm-reload="systemctl reload php8.2-fpm 2>/dev/null || systemctl reload php8.1-fpm 2>/dev/null || true"
alias php_restart="systemctl restart php8.2-fpm 2>/dev/null || systemctl restart php8.1-fpm 2>/dev/null || true"
alias bot_log="journalctl -u cryptobot -n 50 --no-pager 2>/dev/null || echo CryptoBot not found"
alias bot_st="systemctl status cryptobot 2>/dev/null || echo CryptoBot not configured"
alias bot_restart="systemctl restart cryptobot 2>/dev/null || echo CryptoBot not configured"
alias backup="bash /root/Linux_Server_Public/222/backup_clean.sh 2>/dev/null || echo backup_clean.sh not found"
alias bk="bash /root/Linux_Server_Public/222/backup_clean.sh 2>/dev/null || echo backup_clean.sh not found"
alias watchdog="bash /root/Linux_Server_Public/222/watchdog_phpfpm.sh 2>/dev/null || echo watchdog not found"
alias aw="bash /root/Linux_Server_Public/222/xray_stats.sh 2>/dev/null || echo xray_stats not found"
alias domains="bash /root/Linux_Server_Public/222/domains_list.sh 2>/dev/null || echo domains_list not found"
alias fight="bash /root/Linux_Server_Public/222/fight_bots.sh 2>/dev/null || echo fight_bots not found"
alias cleanup="bash /root/Linux_Server_Public/222/disk_cleanup.sh 2>/dev/null || echo disk_cleanup not found"
alias banlog="bash /root/Linux_Server_Public/222/banlog.sh 2>/dev/null || echo banlog not found"
alias banunblock="bash /root/Linux_Server_Public/222/ban_unblock.sh 2>/dev/null || echo ban_unblock not found"
alias banblock="bash /root/Linux_Server_Public/222/ban_block.sh 2>/dev/null || echo ban_block not found"
alias wpupd="bash /root/Linux_Server_Public/222/wp_update.sh 2>/dev/null || echo wp_update not found"
alias wpcron="bash /root/Linux_Server_Public/222/wp_cron.sh 2>/dev/null || echo wp_cron not found"
alias wphealth="bash /root/Linux_Server_Public/222/wp_health.sh 2>/dev/null || echo wp_health not found"
alias mailclean="bash /root/Linux_Server_Public/222/mail_clean.sh 2>/dev/null || echo mail_clean not found"
alias repo="bash /root/Linux_Server_Public/222/repo_pull.sh 2>/dev/null || git -C /root/Linux_Server_Public pull"
alias secret="bash /root/Linux_Server_Public/222/secret_pull.sh 2>/dev/null || echo secret_pull not found"
alias tr="bash /root/Linux_Server_Public/222/tr_stat.sh 2>/dev/null || echo tr_stat not found"
BASHRC_222
;;

# ── TYPE 3: FastPanel only (109) ─────────────────────────────
3)
cat >> /root/.bashrc << 'BASHRC_109'
# ── FastPanel 109 (no Cloudflare) ───────────────────────────
alias fp="cd /var/www && ll"
alias fp_log="tail -f /var/log/nginx/error.log"
alias nginx-reload="systemctl reload nginx"
alias nginx_test="nginx -t"
alias reload-all="systemctl reload nginx && systemctl reload php8.2-fpm 2>/dev/null || systemctl reload php8.1-fpm 2>/dev/null || true"
alias fpm-reload="systemctl reload php8.2-fpm 2>/dev/null || systemctl reload php8.1-fpm 2>/dev/null || true"
alias php_restart="systemctl restart php8.2-fpm 2>/dev/null || systemctl restart php8.1-fpm 2>/dev/null || true"
alias backup="bash /root/Linux_Server_Public/109/backup_clean.sh 2>/dev/null || echo backup_clean.sh not found"
alias bk="bash /root/Linux_Server_Public/109/backup_clean.sh 2>/dev/null || echo backup_clean.sh not found"
alias watchdog="bash /root/Linux_Server_Public/109/watchdog_phpfpm.sh 2>/dev/null || echo watchdog not found"
alias aw="bash /root/Linux_Server_Public/109/xray_stats.sh 2>/dev/null || echo xray_stats not found"
alias domains="bash /root/Linux_Server_Public/109/domains_list.sh 2>/dev/null || echo domains_list not found"
alias fight="bash /root/Linux_Server_Public/109/fight_bots.sh 2>/dev/null || echo fight_bots not found"
alias cleanup="bash /root/Linux_Server_Public/109/disk_cleanup.sh 2>/dev/null || echo disk_cleanup not found"
alias banlog="bash /root/Linux_Server_Public/109/banlog.sh 2>/dev/null || echo banlog not found"
alias banunblock="bash /root/Linux_Server_Public/109/ban_unblock.sh 2>/dev/null || echo ban_unblock not found"
alias banblock="bash /root/Linux_Server_Public/109/ban_block.sh 2>/dev/null || echo ban_block not found"
alias wpupd="bash /root/Linux_Server_Public/109/wp_update.sh 2>/dev/null || echo wp_update not found"
alias wpcron="bash /root/Linux_Server_Public/109/wp_cron.sh 2>/dev/null || echo wp_cron not found"
alias wphealth="bash /root/Linux_Server_Public/109/wp_health.sh 2>/dev/null || echo wp_health not found"
alias mailclean="bash /root/Linux_Server_Public/109/mail_clean.sh 2>/dev/null || echo mail_clean not found"
alias repo="bash /root/Linux_Server_Public/109/repo_pull.sh 2>/dev/null || git -C /root/Linux_Server_Public pull"
alias secret="bash /root/Linux_Server_Public/109/secret_pull.sh 2>/dev/null || echo secret_pull not found"
BASHRC_109
;;
esac

source /root/.bashrc 2>/dev/null || true
echo -e "\033[1;32mOK: .bashrc written\033[0m"

# ═══════════════════════════════════════════════════════════════
# STEP 7 — MOTD banner (type-specific: VPN / 222 / 109)
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}[7/9] Installing MOTD banner...\033[0m"

# ── CLEANUP: remove ALL old MOTD scripts ──
chmod -x /etc/update-motd.d/* 2>/dev/null || true
rm -f /etc/update-motd.d/10-help-text /etc/update-motd.d/50-motd-news \
      /etc/update-motd.d/91-release-upgrade /etc/update-motd.d/99-* 2>/dev/null || true
rm -f /etc/profile.d/motd_server.sh /etc/profile.d/motd*.sh \
      /etc/profile.d/setup_motd*.sh /etc/profile.d/*motd*.sh 2>/dev/null || true
> /etc/motd 2>/dev/null || true
sed -i '/motd/d' /etc/bash.bashrc 2>/dev/null || true
sed -i '/motd/d' /etc/profile 2>/dev/null || true
[ -f /etc/pam.d/sshd ] && sed -i 's/^\(.*pam_motd.*\)$/#\1/' /etc/pam.d/sshd 2>/dev/null || true
echo -e "  \033[1;33mOK: all old MOTD scripts removed\033[0m"

# ── Write MOTD based on server type ──
case "$SRV_TYPE" in

# ─────────────────────────────────────────────────────────────────
# TYPE 1: VPN
# ─────────────────────────────────────────────────────────────────
1)
cat > /etc/profile.d/motd_server.sh << MOTD_SCRIPT
#!/bin/bash
# MOTD — ${SRV_NAME} VPN | v2026.07.08
shopt -q login_shell || return 0 2>/dev/null || exit 0
[ -n "\$SSH_CONNECTION" ] || return 0 2>/dev/null || exit 0
clear
LC='\033[38;5;87m'
C="${MOTD_COLOR}"
G='\033[1;32m'; Y='\033[1;33m'; W='\033[1;37m'; R='\033[1;31m'; X='\033[0m'
LINE=\$(printf '%0.s━' {1..78})
HN=\$(cat /etc/hostname 2>/dev/null | head -1 | tr -d '[:space:]'); [[ -z "\$HN" ]] && HN=\$(hostname)
IP=\$(hostname -I 2>/dev/null | awk '{print \$1}')
RAM_USED=\$(free -m | awk '/Mem:/{print \$3}')
RAM_TOTAL=\$(free -m | awk '/Mem:/{print \$2}')
CPU=\$(top -bn1 | grep 'Cpu(s)' | awk '{print int(\$2+\$4)}')
UPTIME=\$(uptime -p | sed 's/up //')
LOAD=\$(awk '{print \$1" "\$2" "\$3}' /proc/loadavg)
SVC_STATUS=""
for SVC in xray AdGuardHome amneziawg semaphore crowdsec fail2ban smbd; do
  systemctl list-units --type=service --all 2>/dev/null | grep -q "\${SVC}.service" && {
    ST=\$(systemctl is-active "\$SVC" 2>/dev/null)
    [ "\$ST" = "active" ] && SC="\$G" || SC="\$R"
    SVC_STATUS="\${SVC_STATUS}  \${SC}● \${SVC}\${X}"
  }
done
if systemctl is-active --quiet crowdsec 2>/dev/null; then
  BAN_COUNT=\$(cscli decisions list -o raw 2>/dev/null | grep -c ',' || echo 0)
  CS_LINE="  \${Y}Type:\${X} VPN   \${Y}CrowdSec:\${X} \${G}● ACTIVE\${X} | bans: \${W}\${BAN_COUNT}\${X}"
else
  CS_LINE="  \${Y}Type:\${X} VPN   \${Y}CrowdSec:\${X} \${R}x INACTIVE\${X}"
fi
echo -e "\${LC}\${LINE}\${X}"
echo -e "  \U0001F511  \${W}\${HN}\${X}  \${Y}\${IP}\${X}  RAM:\${W}\${RAM_USED}/\${RAM_TOTAL}MB\${X}  CPU:\${W}\${CPU}%\${X}  up \${W}\${UPTIME}\${X}"
echo -e "\${CS_LINE}"
echo -e "\${LC}\${LINE}\${X}"
echo -e "  \${Y}Services:\${X}\${SVC_STATUS}"
echo -e "\${LC}\${LINE}\${X}"
echo -e "  \${Y}CHEATSHEET:\${X}"
echo -e "  \${G}amn_st\${X}(AmneziaWG)    \${G}adg_st\${X}(AdGuard)      \${G}save\${X}(git push)"
echo -e "  \${G}antivir\${X}(ClamAV)       \${G}banlist\${X}(бан-лист)    \${G}load\${X}(git pull)"
echo -e "  \${G}sos\${X}(audit 1h)         \${G}sos24\${X}(audit 24h)     \${G}infooo\${X}(server info)"
echo -e "  \${G}upd\${X}(apt upgrade)      \${G}ports\${X}(open ports)    \${G}f2b\${X}(fail2ban status)"
echo -e "  \${G}00\${X}(clear screen)"
echo -e "\${LC}\${LINE}\${X}"
echo -e "  load: \${G}\${LOAD}\${X}  |  \${Y}Ubuntu 24\${X}  |  \${W}= Rooted by VladiMIR + AI =\${X}"
echo
MOTD_SCRIPT
;;

# ─────────────────────────────────────────────────────────────────
# TYPE 2: FastPanel + Cloudflare (222)
# ─────────────────────────────────────────────────────────────────
2)
cat > /etc/profile.d/motd_server.sh << MOTD_SCRIPT
#!/bin/bash
# MOTD — ${SRV_NAME} Web-222 | v2026.07.08
shopt -q login_shell || return 0 2>/dev/null || exit 0
[ -n "\$SSH_CONNECTION" ] || return 0 2>/dev/null || exit 0
clear
LC='\033[38;5;87m'
C="${MOTD_COLOR}"
G='\033[1;32m'; Y='\033[1;33m'; W='\033[1;37m'; R='\033[1;31m'; X='\033[0m'
LINE=\$(printf '%0.s━' {1..80})
HN=\$(cat /etc/hostname 2>/dev/null | head -1 | tr -d '[:space:]'); [[ -z "\$HN" ]] && HN=\$(hostname)
IP=\$(hostname -I 2>/dev/null | awk '{print \$1}')
RAM_USED=\$(free -m | awk '/Mem:/{print \$3}')
RAM_TOTAL=\$(free -m | awk '/Mem:/{print \$2}')
CPU=\$(top -bn1 | grep 'Cpu(s)' | awk '{print int(\$2+\$4)}')
UPTIME=\$(uptime -p | sed 's/up //')
LOAD=\$(awk '{print \$1" "\$2" "\$3}' /proc/loadavg)
XRAY_ENABLED=\$(systemctl is-active xray 2>/dev/null | grep -c active || echo 0)
XRAY_TOTAL=\$(ss -tnp 2>/dev/null | grep -c xray || echo 0)
if systemctl is-active --quiet crowdsec 2>/dev/null; then
  CS_ENGINE="\${G}● ACTIVE\${X}"
  CS_FW="\${G}● ACTIVE\${X}"
else
  CS_ENGINE="\${R}● INACTIVE\${X}"
  CS_FW="\${R}● INACTIVE\${X}"
fi
CS_LINE="  Xray: \${W}\${XRAY_ENABLED}\${X} enabled / \${W}\${XRAY_TOTAL}\${X} total    CrowdSec Engine: \${CS_ENGINE}  Firewall: \${CS_FW}"
echo -e "\${LC}\${LINE}\${X}"
echo -e "  \U0001F310  \${W}\${HN}\${X}  \${Y}\${IP}\${X}  RAM:\${W}\${RAM_USED}/\${RAM_TOTAL}MB\${X}  CPU:\${W}\${CPU}%\${X}  up \${W}\${UPTIME}\${X}"
echo -e "\${CS_LINE}"
echo -e "\${LC}\${LINE}\${X}"
printf "  \${Y}%-26s\${X}  \${Y}%-26s\${X}  \${Y}%s\${X}\n" "SCAN & SECURITY" "SERVER" "WORDPRESS"
echo -e "\${LC}\${LINE}\${X}"
printf "  \${G}%-24s\${X}  \${G}%-24s\${X}  \${G}%s\${X}\n" "antivir(ClamAV scan)" "sos(errors now)" "wpupd(WP update)"
printf "  \${G}%-24s\${X}  \${G}%-24s\${X}  \${G}%s\${X}\n" "fight(block bots)" "sos3(last 3h)" "wpcron(WP cron)"
printf "  \${G}%-24s\${X}  \${G}%-24s\${X}  \${G}%s\${X}\n" "banlog(ban list)" "sos24(last 24h)" "wphealth(WP health)"
printf "  \${G}%-24s\${X}  \${G}%-24s\${X}  \${G}%s\${X}\n" "cleanup(disk clean)" "watchdog(PHP-FPM)" "domains(domain list)"
printf "  \${G}%-24s\${X}  \${G}%-24s\${X}  \${G}%s\${X}\n" "banunblock(unban IP)" "backup(system backup)" "mailclean(mail queue)"
printf "  \${G}%-24s\${X}  \${G}%-24s\${X}  \${G}%s\${X}\n" "banblock(manual ban)" "f2b(fail2ban status)" "f2b-banned(banned IPs)"
echo -e "\${LC}\${LINE}\${X}"
printf "  \${Y}%-26s\${X}  \${Y}%s\${X}\n" "GIT" "TOOLS"
echo -e "\${LC}\${LINE}\${X}"
printf "  \${G}%-24s\${X}  \${G}%-24s\${X}  \${G}%s\${X}\n" "save(git push)" "infooo(full info)" "bot_st(CryptoBot)"
printf "  \${G}%-24s\${X}  \${G}%-24s\${X}  \${G}%s\${X}\n" "load(git pull)" "aw(VPN stats)" "nginx-reload(reload)"
printf "  \${G}%-24s\${X}  \${G}%-24s\${X}  \${G}%s\${X}\n" "repo(pull public repo)" "fpm-reload(reload FPM)" "reload-all(both)"
printf "  \${G}%-24s\${X}  \${G}%-24s\${X}  \${G}%s\${X}\n" "secret(private repo)" "mc(Midnight Cmdr)" "00(clear screen)"
echo -e "\${LC}\${LINE}\${X}"
echo -e "  FastPanel+CF | Ubuntu 24 | \${Y}\${IP}\${X} | up \${W}\${UPTIME}\${X} | load: \${G}\${LOAD}\${X}"
echo
MOTD_SCRIPT
;;

# ─────────────────────────────────────────────────────────────────
# TYPE 3: FastPanel only (109)  — no Cloudflare, no CryptoBot
# ─────────────────────────────────────────────────────────────────
3)
cat > /etc/profile.d/motd_server.sh << MOTD_SCRIPT
#!/bin/bash
# MOTD — ${SRV_NAME} Web-109 | v2026.07.08
shopt -q login_shell || return 0 2>/dev/null || exit 0
[ -n "\$SSH_CONNECTION" ] || return 0 2>/dev/null || exit 0
clear
LC='\033[38;5;87m'
C="${MOTD_COLOR}"
G='\033[1;32m'; Y='\033[1;33m'; W='\033[1;37m'; R='\033[1;31m'; X='\033[0m'
LINE=\$(printf '%0.s━' {1..80})
HN=\$(cat /etc/hostname 2>/dev/null | head -1 | tr -d '[:space:]'); [[ -z "\$HN" ]] && HN=\$(hostname)
IP=\$(hostname -I 2>/dev/null | awk '{print \$1}')
RAM_USED=\$(free -m | awk '/Mem:/{print \$3}')
RAM_TOTAL=\$(free -m | awk '/Mem:/{print \$2}')
CPU=\$(top -bn1 | grep 'Cpu(s)' | awk '{print int(\$2+\$4)}')
UPTIME=\$(uptime -p | sed 's/up //')
LOAD=\$(awk '{print \$1" "\$2" "\$3}' /proc/loadavg)
XRAY_ENABLED=\$(systemctl is-active xray 2>/dev/null | grep -c active || echo 0)
XRAY_TOTAL=\$(ss -tnp 2>/dev/null | grep -c xray || echo 0)
if systemctl is-active --quiet crowdsec 2>/dev/null; then
  CS_ENGINE="\${G}● ACTIVE\${X}"
  CS_FW="\${G}● ACTIVE\${X}"
else
  CS_ENGINE="\${R}● INACTIVE\${X}"
  CS_FW="\${R}● INACTIVE\${X}"
fi
CS_LINE="  Xray: \${W}\${XRAY_ENABLED}\${X} enabled / \${W}\${XRAY_TOTAL}\${X} total    CrowdSec Engine: \${CS_ENGINE}  Firewall: \${CS_FW}"
echo -e "\${LC}\${LINE}\${X}"
echo -e "  \U0001F310  \${W}\${HN}\${X}  \${Y}\${IP}\${X}  RAM:\${W}\${RAM_USED}/\${RAM_TOTAL}MB\${X}  CPU:\${W}\${CPU}%\${X}  up \${W}\${UPTIME}\${X}"
echo -e "\${CS_LINE}"
echo -e "\${LC}\${LINE}\${X}"
printf "  \${Y}%-26s\${X}  \${Y}%-26s\${X}  \${Y}%s\${X}\n" "SCAN & SECURITY" "SERVER" "WORDPRESS"
echo -e "\${LC}\${LINE}\${X}"
printf "  \${G}%-24s\${X}  \${G}%-24s\${X}  \${G}%s\${X}\n" "antivir(ClamAV scan)" "sos(errors now)" "wpupd(WP update)"
printf "  \${G}%-24s\${X}  \${G}%-24s\${X}  \${G}%s\${X}\n" "fight(block bots)" "sos3(last 3h)" "wpcron(WP cron)"
printf "  \${G}%-24s\${X}  \${G}%-24s\${X}  \${G}%s\${X}\n" "banlog(ban list)" "sos24(last 24h)" "wphealth(WP health)"
printf "  \${G}%-24s\${X}  \${G}%-24s\${X}  \${G}%s\${X}\n" "cleanup(disk clean)" "watchdog(PHP-FPM)" "domains(domain list)"
printf "  \${G}%-24s\${X}  \${G}%-24s\${X}  \${G}%s\${X}\n" "banunblock(unban IP)" "backup(system backup)" "mailclean(mail queue)"
printf "  \${G}%-24s\${X}  \${G}%-24s\${X}  \${G}%s\${X}\n" "banblock(manual ban)" "f2b(fail2ban status)" "f2b-banned(banned IPs)"
echo -e "\${LC}\${LINE}\${X}"
printf "  \${Y}%-26s\${X}  \${Y}%s\${X}\n" "GIT" "TOOLS"
echo -e "\${LC}\${LINE}\${X}"
printf "  \${G}%-24s\${X}  \${G}%-24s\${X}  \${G}%s\${X}\n" "save(git push)" "infooo(full info)" "nginx-reload(reload)"
printf "  \${G}%-24s\${X}  \${G}%-24s\${X}  \${G}%s\${X}\n" "load(git pull)" "aw(VPN stats)" "fpm-reload(reload FPM)"
printf "  \${G}%-24s\${X}  \${G}%-24s\${X}  \${G}%s\${X}\n" "repo(pull public repo)" "mc(Midnight Cmdr)" "reload-all(both)"
printf "  \${G}%-24s\${X}  \${G}%-24s\${X}  \${G}%s\${X}\n" "secret(private repo)" "00(clear screen)" ""
echo -e "\${LC}\${LINE}\${X}"
echo -e "  FastPanel | Ubuntu 24 | \${Y}\${IP}\${X} | up \${W}\${UPTIME}\${X} | load: \${G}\${LOAD}\${X}"
echo
MOTD_SCRIPT
;;
esac

chmod +x /etc/profile.d/motd_server.sh
echo -e "\033[1;32mOK: MOTD installed (/etc/profile.d/motd_server.sh)\033[0m"

# ═══════════════════════════════════════════════════════════════
# STEP 8 — UFW firewall
# Whitelist (updated v2026.07.08):
#   152.53.182.222  — DE server 222 (FastPanel+CF+Samba+XRAY+CryptoBot)
#   212.109.223.109 — RU server 109 (FastPanel+Samba+XRAY)
#   82.223.116.38   — IONOS (XRAY)
#   3.79.14.42      — AWS (XRAY)
#   109.234.38.47   — VPN ALEX_47
#   144.124.228.237 — VPN 4TON_237
#   144.124.232.9   — VPN TATRA_9 (Samba+Kuma)
#   144.124.228.227 — VPN SHAHIN_227 (AmneziaWG)
#   144.124.239.24  — VPN STOLB_24 (AdGuard)
#   195.63.138.33   — VPN PILIK_33 (replaces old VPN_178)
#   146.103.110.176 — VPN ILYA_176
#   144.124.233.38  — VPN SO_38
#   185.100.197.XX  — Home IP (range)
#   185.14.233.235  — Home IP
#   185.14.232.0    — Home IP
#   90.181.133.10   — Work IP
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}[8/9] Configuring UFW...\033[0m"
ufw --force reset >/dev/null 2>&1
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
for TRUSTED_IP in \
  152.53.182.222 \
  212.109.223.109 \
  82.223.116.38 \
  3.79.14.42 \
  109.234.38.47 \
  144.124.228.237 \
  144.124.232.9 \
  144.124.228.227 \
  144.124.239.24 \
  195.63.138.33 \
  146.103.110.176 \
  144.124.233.38 \
  185.100.197.0/24 \
  185.14.233.235 \
  185.14.232.0 \
  90.181.133.10; do
  ufw allow from "$TRUSTED_IP" to any >/dev/null 2>&1 || true
done
ufw --force enable
echo -e "\033[1;32mOK: UFW active, trusted IPs whitelisted (v2026.07.08)\033[0m"

# ═══════════════════════════════════════════════════════════════
# STEP 9 — mc.menu (Midnight Commander user menu)
#
# Provides quick access to key tools via F2 in mc:
#   sos, infooo, ports, antivir, upd, fail2ban, git save/load
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}[9/9] Installing mc.menu...\033[0m"
mkdir -p /root/.config/mc
MC_MENU_SRC="/root/Linux_Server_Public/scripts/mc.menu"
[ ! -f "$MC_MENU_SRC" ] && MC_MENU_SRC="/root/Linux_Server_Public/mc.menu"
if [ -f "$MC_MENU_SRC" ]; then
  cp "$MC_MENU_SRC" /root/.config/mc/menu
  echo -e "\033[1;32mOK: mc.menu from repo\033[0m"
else
  cat > /root/.config/mc/menu << 'MCMENU_EOF'
+ Ctrl-x
s  SOS audit 1h
    /usr/local/bin/sos 1h
S  SOS audit 24h
    /usr/local/bin/sos 24h
i  INFOOO — server info + benchmark
    /usr/local/bin/infooo
p  PORTS — open ports
    /usr/local/bin/ports
a  ANTIVIR — ClamAV scan /var/www
    /usr/local/bin/antivir /var/www
u  UPD — apt upgrade
    /usr/local/bin/upd
f  FAIL2BAN — status sshd
    fail2ban-client status sshd
F  FAIL2BAN — all jails
    fail2ban-client status
g  GIT save (push)
    cd /root/Linux_Server_Public && git add -A && git commit -m "save: $(hostname) $(date +%Y-%m-%d)" && git push origin main
l  GIT load (pull)
    /usr/local/bin/load
MCMENU_EOF
  echo -e "\033[1;32mOK: mc.menu installed (inline)\033[0m"
fi

# ═══════════════════════════════════════════════════════════════
# AUTO source .bashrc
# ═══════════════════════════════════════════════════════════════
source /root/.bashrc 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}════════════════════════════════════════\033[0m"
echo -e "\033[1;32m"
echo "   ✓  SETUP COMPLETE — ${SRV_NAME}"
echo "   ✓  Type   : ${TYPE_NAME}"
echo "   ✓  Color  : ${PS1_NAME}"
echo -e "\033[0m"
echo -e "   Installed to /usr/local/bin/: sos infooo antivir ports load upd 00"
echo -e "   fail2ban: active | mc.menu: F2 in mc | f2b / f2b-ssh / f2b-banned"
echo -e "\033[1;33m   Next steps:\033[0m"
echo "   1. Run: source ~/.bashrc"
echo "   2. Run: upd  (apt upgrade)"
echo "   3. Reconnect SSH to see MOTD"
echo -e "\n\033[${PS1_CODE}════════════════════════════════════════\033[0m"
