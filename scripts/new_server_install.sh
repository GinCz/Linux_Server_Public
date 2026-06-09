#!/bin/bash
# =============================================================
# Script:      new_server_install.sh
# Version:     v2026.06.10c
# Description: FULLY STANDALONE — no calls to other repo scripts.
#              All tools (sos, infooo, antivir, upd, 00, ports, load)
#              are embedded inline as heredocs.
#              Three server types:
#                1 = VPN (XRay + AmneziaWG + AdGuard)
#                2 = FastPanel + Cloudflare (server 222)
#                3 = FastPanel only (server 109, no Cloudflare)
#              Always FULL install — apt upgrade, UFW, CrowdSec, full setup
#
# Usage:
#   bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh)
#
# WARNING: Touches hostname, UFW, installs packages — FRESH servers only!
# = Rooted by VladiMIR + AI | v.2026.06.10c | github.com/GinCz =
# =============================================================
clear
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin

C='\033[1;37m'; X='\033[0m'
echo -e "${C}=========================================${X}"
echo -e "${C}   NEW SERVER SETUP v2026.06.10c${X}"
echo -e "${C}   = Rooted by VladiMIR + AI | github.com/GinCz =${X}"
echo -e "${C}=========================================${X}"
echo

# ─── Server name ────────────────────────────────────────────
read -rp "Enter server name (e.g. VPN-DE-1 or Srv-222): " SRV_NAME
[[ -n "${SRV_NAME:-}" ]] || { echo "Server name cannot be empty"; exit 1; }

# ─── Server type ────────────────────────────────────────────
echo
echo "Select server type:"
echo "  1) VPN              (XRay + AmneziaWG + AdGuard + Semaphore)"
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
echo -e "  \033[01;95m5) Bright Magenta  — малиновый\033[0m"
echo -e "  \033[38;5;208m6) Orange          — оранжевый\033[0m"
echo -e "  \033[38;5;213m7) Bright Pink     — розовый\033[0m"
echo -e "  \033[01;97m8) Bright White    — белый (109 default)\033[0m"

case "$SRV_TYPE" in
  2) DEF_COLOR=4 ;;
  3) DEF_COLOR=8 ;;
  *) DEF_COLOR=1 ;;
esac
read -rp "Color [1-8, default ${DEF_COLOR}]: " CC
CC="${CC:-${DEF_COLOR}}"
case "$CC" in
  1) PS1_CODE='01;96m';    PS1_NAME="Bright Cyan"    ; MOTD_COLOR='\033[01;96m' ;;
  2) PS1_CODE='01;91m';    PS1_NAME="Bright Red"     ; MOTD_COLOR='\033[01;91m' ;;
  3) PS1_CODE='01;92m';    PS1_NAME="Bright Green"   ; MOTD_COLOR='\033[01;92m' ;;
  4) PS1_CODE='01;93m';    PS1_NAME="Bright Yellow"  ; MOTD_COLOR='\033[01;93m' ;;
  5) PS1_CODE='01;95m';    PS1_NAME="Bright Magenta" ; MOTD_COLOR='\033[01;95m' ;;
  6) PS1_CODE='38;5;208m'; PS1_NAME="Orange"         ; MOTD_COLOR='\033[38;5;208m' ;;
  7) PS1_CODE='38;5;213m'; PS1_NAME="Bright Pink"    ; MOTD_COLOR='\033[38;5;213m' ;;
  8) PS1_CODE='01;97m';    PS1_NAME="Bright White"   ; MOTD_COLOR='\033[01;97m' ;;
  *) PS1_CODE='01;96m';    PS1_NAME="Bright Cyan"    ; MOTD_COLOR='\033[01;96m' ;;
esac

case "$SRV_TYPE" in
  2) TYPE_NAME="Web 222 / FastPanel / Cloudflare / XRay / CryptoBot" ;;
  3) TYPE_NAME="Web 109 / FastPanel / XRay (no Cloudflare)" ;;
  *) TYPE_NAME="VPN / XRay / AmneziaWG / AdGuard / Semaphore" ;;
esac

# ─── Summary ────────────────────────────────────────────────
echo
echo -e "  \033[${PS1_CODE}●\033[0m  Server : ${SRV_NAME}"
echo -e "  \033[${PS1_CODE}●\033[0m  Type   : ${TYPE_NAME}"
echo -e "  \033[${PS1_CODE}●\033[0m  Color  : ${PS1_NAME}"
echo -e "  \033[1;31m⚠️  FULL install — apt upgrade + UFW + CrowdSec will run!\033[0m"
echo
read -rp "Continue? [YES/no]: " OK
[[ "${OK:-YES}" =~ ^(YES|yes|y|)$ ]] || { echo "Aborted"; exit 1; }

# ═══════════════════════════════════════════════════════════════
# STEP 1 — Hostname + timezone + SSH cleanup
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}[1/10] Hostname + timezone + SSH settings...\033[0m"
hostnamectl set-hostname "${SRV_NAME}"
grep -q '^127.0.1.1' /etc/hosts \
  && sed -i "s/^127.0.1.1.*/127.0.1.1 ${SRV_NAME}/" /etc/hosts \
  || echo "127.0.1.1 ${SRV_NAME}" >> /etc/hosts
echo "${SRV_NAME}" > /etc/hostname
timedatectl set-timezone Europe/Prague
timedatectl set-ntp true
update-locale LANG=en_US.UTF-8 >/dev/null 2>&1 || true

# ── SSH: hide "Using username" / "Last login" banner lines ──
# PrintLastLog no  → убирает строку «Last login: ...»
# PrintMotd no     → убирает /etc/motd через PAM (мы показываем свой MOTD)
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
# STEP 2 — apt update + upgrade
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}[2/10] apt update + upgrade...\033[0m"
killall apt apt-get unattended-upgrade 2>/dev/null || true
rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock
dpkg --configure -a >/dev/null 2>&1 || true
apt update -y && apt upgrade -y
echo -e "\033[1;32mOK\033[0m"

# ═══════════════════════════════════════════════════════════════
# STEP 3 — Base packages
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}[3/10] Installing base packages + fail2ban...\033[0m"
apt install -y mc curl wget git htop net-tools sysbench \
  clamav clamav-freshclam ca-certificates uuid-runtime jq socat ufw fail2ban
echo -e "\033[1;32mOK\033[0m"

# ═══════════════════════════════════════════════════════════════
# STEP 4 — Clone / update GitHub repo
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}[4/10] Cloning / updating GitHub repo...\033[0m"
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
# STEP 5 — Install scripts INLINE (no calls to repo scripts)
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}[5/10] Installing scripts inline to /usr/local/bin/...\033[0m"

# ──────────────────────────────────────────────
# 5a. sos — full inline embed
# ──────────────────────────────────────────────
cat > /usr/local/bin/sos << 'SOS_EOF'
#!/usr/bin/env bash
clear
TW="${1:-24h}"
G=$'\033[1;32m'; C=$'\033[1;36m'; Y=$'\033[1;33m'; R=$'\033[1;31m'; W=$'\033[1;37m'; X=$'\033[0m'
have(){ command -v "$1" >/dev/null 2>&1; }
SEP="${C}$(printf '=%.0s' {1..90})${X}"
H(){ printf "\n${C}=============== %s${X}\n" "$1"; }
M=1440
[[ "$TW" =~ ^([0-9]+)m$ ]] && M="${BASH_REMATCH[1]}"
[[ "$TW" =~ ^([0-9]+)h$ ]] && M="$(( ${BASH_REMATCH[1]} * 60 ))"
NOW=$(date '+%Y-%m-%d %H:%M:%S'); HOST=$(hostname)
IP=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
CORES=$(nproc 2>/dev/null || echo 1)
LOAD=$(awk '{print $1,$2,$3}' /proc/loadavg); LOAD1=$(awk '{print $1}' /proc/loadavg)
LOAD_PCT=$(awk -v l="$LOAD1" -v c="$CORES" 'BEGIN{printf "%.0f",(l/c)*100}')
[ "${LOAD_PCT:-0}" -ge 90 ] && LC="$R" || { [ "${LOAD_PCT:-0}" -ge 60 ] && LC="$Y" || LC="$G"; }
ROLE="GENERIC"
have nginx && [ -d /var/www ] && ROLE="WEB"
have xray  && ROLE="VPN/XRAY"
have wg    && ROLE="VPN/WG"
[ "$ROLE" = "GENERIC" ] && have docker && ROLE="DOCKER/NODE"
printf "%s\n" "$SEP"
printf "  ${W}SOS ${Y}%s${X}  |  ${G}%s${X}  |  ${C}%s${X}  ${G}%s${X}  Load: ${LC}%s${X} (${LC}%s%%${X}/%sc)  ${W}[%s]${X}\n" \
  "$TW" "$NOW" "$HOST" "$IP" "$LOAD" "$LOAD_PCT" "$CORES" "$ROLE"
printf "%s\n" "$SEP"
printf "  ${C}Uptime:${X} %s" "$(uptime -p)"
free -h | awk -v c="$C" -v x="$X" '/^Mem:/{printf "   %sRAM:%s %s/%s (free %s)",c,x,$3,$2,$4}'
free -h | awk -v c="$C" -v x="$X" '/^Swap:/{printf "   %sSwap:%s %s/%s\n",c,x,$3,$2}'
H "DISK"
df -h --output=source,size,used,avail,pcent,target 2>/dev/null \
  | grep -E '^(Filesystem|/dev)' \
  | awk -v c="$C" -v x="$X" \
    'NR==1{printf "  %-20s %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6;next}
           {printf "  %s%-20s%s %6s %6s %6s %5s  %s\n",c,$1,x,$2,$3,$4,$5,$6}'
H "TOP-5 CPU + RAM"
printf "  ${C}Top 5 by CPU:${X}\n"
ps -eo pid,user,%cpu,%mem,args --sort=-%cpu 2>/dev/null \
  | head -6 | tail -5 \
  | awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-12s CPU:%5s%%  MEM:%5s%%  %s\n",c,$1,x,$2,$3,$4,$5}'
printf "\n  ${C}Top 5 by RAM:${X}\n"
ps -eo pid,user,%cpu,%mem,rss,args --sort=-rss 2>/dev/null \
  | head -6 | tail -5 \
  | awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-12s CPU:%5s%%  MEM:%5s%%  %6.1fMB  %s\n",c,$1,x,$2,$3,$4,$5/1024,$6}'
H "OOM KILLER"
OOM_HITS=$(dmesg 2>/dev/null | grep -c 'oom-kill\|Out of memory\|Killed process' || echo 0)
[ "${OOM_HITS:-0}" -gt 0 ] \
  && printf "  ${R}OOM events: %d${X}\n" "$OOM_HITS" \
  && dmesg 2>/dev/null | grep -E 'oom-kill|Out of memory|Killed process' | tail -5 | sed "s/^/  /" \
  || printf "  ${G}No OOM kills detected${X}\n"
H "SERVICES"
SVC_LIST=(nginx mariadb mysql crowdsec fail2ban smbd nmbd docker ssh xray AdGuardHome semaphore)
for SVC in "${SVC_LIST[@]}"; do
  systemctl list-units --type=service --all 2>/dev/null | grep -q "${SVC}.service" && {
    STATE=$(systemctl is-active "$SVC" 2>/dev/null)
    [ "$STATE" = "active" ] && SC="$G" || SC="$R"
    printf "  ${C}%-35s${X} %s%s${X}\n" "$SVC" "$SC" "$STATE"
  }
done
H "ALL OPEN PORTS"
printf "  ${C}TCP listening:${X}\n"
ss -tlnp 2>/dev/null | awk 'NR>1 && /LISTEN/{addr=$4;proc=$NF;gsub(/users:\(\(|\)\)/,"",proc);sub(/,.*/,"",proc);printf "    %-25s %s\n",addr,proc}' | sort -t: -k2 -n
printf "\n  ${C}UDP listening:${X}\n"
ss -ulnp 2>/dev/null | awk 'NR>1{addr=$4;proc=$NF;gsub(/users:\(\(|\)\)/,"",proc);sub(/,.*/,"",proc);printf "    %-25s %s\n",addr,proc}' | sort -t: -k2 -n
H "LAST LOGINS"
last -n 10 -a 2>/dev/null | head -12 | awk -v g="$G" -v c="$C" -v y="$Y" -v x="$X" \
  '/^reboot/{printf "  %s  %-10s%s  %s\n",y,$1,x,substr($0,28);next}
   /still logged/{printf "  %s%-10s%s  still logged in\n",g,$1,x;next}
   /^$|^wtmp/{next}
   {printf "  %s%-10s%s  %s\n",c,$1,x,substr($0,28)}'
H "APT UPDATES"
UPD_COUNT=$(apt list --upgradable 2>/dev/null | grep -c '/') || UPD_COUNT=0
SEC_COUNT=$(apt list --upgradable 2>/dev/null | grep -ci 'security') || SEC_COUNT=0
[ "${UPD_COUNT:-0}" -gt 0 ] \
  && printf "  ${C}Upgradable:${X} ${Y}%d${X}  (security: ${R}%d${X})\n" "$UPD_COUNT" "$SEC_COUNT" \
  || printf "  ${G}System is up to date${X}\n"
H "FAIL2BAN"
have fail2ban-client && {
  F2B_ST=$(systemctl is-active fail2ban 2>/dev/null)
  [ "$F2B_ST" = "active" ] && printf "  ${G}active${X}\n" || printf "  ${R}inactive${X}\n"
  TOTAL_BANNED=0
  for JAIL in $(fail2ban-client status 2>/dev/null | grep 'Jail list' | sed 's/.*Jail list://;s/,/ /g'); do
    [ -z "$JAIL" ] && continue
    BANNED=$(fail2ban-client status "$JAIL" 2>/dev/null | awk '/Currently banned/{print $NF}')
    TOTAL_BANNED=$((TOTAL_BANNED + ${BANNED:-0}))
    printf "    ${C}%-25s${X} banned: ${R}%s${X}\n" "$JAIL" "${BANNED:-0}"
  done
  [ "$TOTAL_BANNED" -gt 0 ] && printf "  ${R}Total banned: %d${X}\n" "$TOTAL_BANNED" || printf "  ${G}No IPs banned${X}\n"
} || printf "  ${Y}fail2ban not installed${X}\n"
H "DOCKER"
have docker && {
  DOCK_ST=$(systemctl is-active docker 2>/dev/null)
  [ "$DOCK_ST" = "active" ] && SC="$G" || SC="$R"
  printf "  ${C}Docker:${X} %s%s${X}\n" "$SC" "$DOCK_ST"
  docker ps -a --format "  {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null \
    | awk -v g="$G" -v r="$R" -v c="$C" -v x="$X" \
      '{col=($2~/Up/)?g:r; printf "    %s%-28s%s %s%-20s%s  %s\n",c,$1,x,col,$2,x,$3}'
} || printf "  ${Y}Docker not installed${X}\n"
printf "\n%s\n  ${W}SOS v2026.06.10c${X} | ${C}Rooted by VladiMIR + AI${X} | ${C}github.com/GinCz${X}\n%s\n" "$SEP" "$SEP"
SOS_EOF
chmod +x /usr/local/bin/sos
echo -e "  \033[1;32mOK: sos\033[0m"

# ──────────────────────────────────────────────
# 5b. infooo — inline
# ──────────────────────────────────────────────
cat > /usr/local/bin/infooo << 'INFOOO_EOF'
#!/bin/bash
# = Rooted by VladiMIR + AI | github.com/GinCz =
clear
G='\033[1;32m'; C='\033[1;36m'; Y='\033[1;33m'; R='\033[1;31m'; W='\033[1;37m'; X='\033[0m'
LINE=$(printf '%0.s─' {1..70})
echo -e "${C}${LINE}${X}"
echo -e "  ${W}SERVER INFO${X}  $(hostname)  |  $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${C}${LINE}${X}"
echo -e "  ${C}Hostname:${X}  $(hostname)"
echo -e "  ${C}OS:${X}        $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY | cut -d= -f2 | tr -d '\"')"
echo -e "  ${C}Kernel:${X}    $(uname -r)"
echo -e "  ${C}Uptime:${X}    $(uptime -p)"
echo -e "  ${C}IPs:${X}       $(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | tr '\n' ' ')"
echo -e "${C}${LINE}${X}"
echo -e "  ${C}CPU:${X}       $(nproc) cores — $(grep 'model name' /proc/cpuinfo 2>/dev/null | head -1 | cut -d: -f2 | xargs)"
RAM_USED=$(free -m | awk '/Mem:/{print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
RAM_PCT=$(awk -v u="$RAM_USED" -v t="$RAM_TOTAL" 'BEGIN{printf "%.0f",(u/t)*100}')
echo -e "  ${C}RAM:${X}       ${RAM_USED}MB / ${RAM_TOTAL}MB (${RAM_PCT}%)"
echo -e "  ${C}Load:${X}      $(awk '{print $1,$2,$3}' /proc/loadavg)"
echo -e "${C}${LINE}${X}"
echo -e "  ${C}Disk usage:${X}"
df -h 2>/dev/null | grep '^/dev' | awk -v c="$C" -v x="$X" '{printf "    %s%-20s%s %6s / %6s  (%s used)  %s\n",c,$1,x,$3,$2,$5,$6}'
echo -e "${C}${LINE}${X}"
echo -e "  ${C}Services:${X}"
for SVC in nginx php8.1-fpm php8.2-fpm mariadb mysql crowdsec fail2ban xray docker smbd AdGuardHome semaphore; do
  if systemctl list-units --type=service --all 2>/dev/null | grep -q "${SVC}.service"; then
    ST=$(systemctl is-active "$SVC" 2>/dev/null)
    [ "$ST" = "active" ] && COL="$G" || COL="$R"
    printf "    %s%-35s%s %s%s%s\n" "$C" "$SVC" "$X" "$COL" "$ST" "$X"
  fi
done
echo -e "${C}${LINE}${X}"
echo -e "  ${C}Open ports (TCP):${X}"
ss -tlnp 2>/dev/null | awk 'NR>1 && /LISTEN/{printf "    %s\n",$4}' | sort -t: -k2 -n | head -20
echo -e "${C}${LINE}${X}"
echo -e "  ${W}infooo v2026.06.10c${X} | ${C}Rooted by VladiMIR + AI${X} | ${C}github.com/GinCz${X}"
INFOOO_EOF
chmod +x /usr/local/bin/infooo
echo -e "  \033[1;32mOK: infooo\033[0m"

# ──────────────────────────────────────────────
# 5c. antivir (ClamAV scan) — inline
# ──────────────────────────────────────────────
cat > /usr/local/bin/antivir << 'ANTIVIR_EOF'
#!/bin/bash
# = Rooted by VladiMIR + AI | github.com/GinCz =
clear
G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; C='\033[1;36m'; W='\033[1;37m'; X='\033[0m'
SCAN_DIR="${1:-/var/www}"
LOG="/var/log/clamav_scan_$(date +%Y%m%d_%H%M%S).log"
echo -e "${C}========================================${X}"
echo -e "  ${W}ClamAV Antivirus Scan${X}"
echo -e "  Scan dir: ${Y}${SCAN_DIR}${X}"
echo -e "  Log:      ${Y}${LOG}${X}"
echo -e "${C}========================================${X}"
if ! command -v clamscan >/dev/null 2>&1; then
  echo -e "${R}ClamAV not installed. Run: apt install clamav clamav-freshclam${X}"
  exit 1
fi
echo -e "${Y}Updating virus definitions...${X}"
systemctl stop clamav-freshclam 2>/dev/null || true
freshclam 2>&1 | tail -5 || true
systemctl start clamav-freshclam 2>/dev/null || true
echo -e "${G}Starting scan of: ${SCAN_DIR}${X}"
START_T=$(date +%s)
clamscan -r --infected --log="$LOG" --exclude-dir='^/sys' --exclude-dir='^/proc' \
  --move=/root/quarantine/ "$SCAN_DIR" 2>&1
END_T=$(date +%s)
ELAPSED=$(( END_T - START_T ))
echo -e "${C}========================================${X}"
echo -e "  ${W}Scan complete${X} | Duration: ${Y}${ELAPSED}s${X}"
INFECTED=$(grep -c 'FOUND' "$LOG" 2>/dev/null || echo 0)
if [ "${INFECTED:-0}" -gt 0 ]; then
  echo -e "  ${R}⚠ INFECTED FILES: ${INFECTED}${X}"
  grep 'FOUND' "$LOG" | sed 's/^/    /'
else
  echo -e "  ${G}✓ No infected files found${X}"
fi
echo -e "  Log saved: ${Y}${LOG}${X}"
echo -e "${C}========================================${X}"
ANTIVIR_EOF
chmod +x /usr/local/bin/antivir
mkdir -p /root/quarantine
echo -e "  \033[1;32mOK: antivir\033[0m"

# ──────────────────────────────────────────────
# 5d. upd — apt upgrade + cleanup + optional reboot
# ──────────────────────────────────────────────
cat > /usr/local/bin/upd << 'UPD_EOF'
#!/bin/bash
# = Rooted by VladiMIR + AI | github.com/GinCz =
clear
G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; C='\033[1;36m'; W='\033[1;37m'; X='\033[0m'
echo -e "${C}========================================${X}"
echo -e "  ${W}UPD — System Update${X}  $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${C}========================================${X}"
export DEBIAN_FRONTEND=noninteractive
killall apt apt-get unattended-upgrade 2>/dev/null || true
rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock
dpkg --configure -a >/dev/null 2>&1 || true
echo -e "${Y}Running apt update...${X}"
apt update -y
echo -e "${Y}Running apt upgrade...${X}"
apt upgrade -y
echo -e "${Y}Running apt autoremove + clean...${X}"
apt autoremove -y && apt autoclean -y
echo -e "${C}========================================${X}"
if [ -f /var/run/reboot-required ]; then
  echo -e "  ${R}⚠ REBOOT REQUIRED${X}"
  read -rp "Reboot now? [y/N]: " RB
  [[ "${RB:-N}" =~ ^[Yy]$ ]] && reboot
else
  echo -e "  ${G}✓ No reboot required${X}"
fi
echo -e "${C}========================================${X}"
UPD_EOF
chmod +x /usr/local/bin/upd
echo -e "  \033[1;32mOK: upd\033[0m"

# ──────────────────────────────────────────────
# 5e. 00 — clear screen alias script
# ──────────────────────────────────────────────
cat > /usr/local/bin/00 << 'OO_EOF'
#!/bin/bash
clear
OO_EOF
chmod +x /usr/local/bin/00
echo -e "  \033[1;32mOK: 00\033[0m"

# ──────────────────────────────────────────────
# 5f. ports — show open ports
# ──────────────────────────────────────────────
cat > /usr/local/bin/ports << 'PORTS_EOF'
#!/bin/bash
# = Rooted by VladiMIR + AI | github.com/GinCz =
clear
C='\033[1;36m'; G='\033[1;32m'; Y='\033[1;33m'; W='\033[1;37m'; X='\033[0m'
echo -e "${C}══════════════════════════════════════════${X}"
echo -e "  ${W}OPEN PORTS — $(hostname)${X}"
echo -e "${C}══════════════════════════════════════════${X}"
echo -e "\n  ${C}TCP LISTEN:${X}"
ss -tlnp 2>/dev/null | awk 'NR>1 && /LISTEN/{
  addr=$4; proc=$NF
  gsub(/users:\(\(|\)\)/,"",proc); sub(/,.*/,"",proc)
  printf "    %-25s %s\n", addr, proc
}' | sort -t: -k2 -n
echo -e "\n  ${C}UDP LISTEN:${X}"
ss -ulnp 2>/dev/null | awk 'NR>1{
  addr=$4; proc=$NF
  gsub(/users:\(\(|\)\)/,"",proc); sub(/,.*/,"",proc)
  printf "    %-25s %s\n", addr, proc
}' | sort -t: -k2 -n
echo -e "\n  ${C}Key ports:${X}"
declare -A PNAMES=([22]="SSH" [25]="SMTP" [53]="DNS" [80]="HTTP" [443]="HTTPS" [445]="Samba" [3000]="Semaphore/AGH" [8080]="AGH-Web" [51820]="WireGuard")
for P in 22 25 53 80 443 445 3000 8080 51820; do
  NAME="${PNAMES[$P]}"
  TC=$(ss -tlnp 2>/dev/null | grep -c ":${P} " || echo 0)
  UC=$(ss -ulnp 2>/dev/null | grep -c ":${P} " || echo 0)
  TOTAL=$((TC+UC))
  if [ "$TOTAL" -gt 0 ]; then
    PROTO=""; [ "$TC" -gt 0 ] && PROTO="${PROTO}TCP "; [ "$UC" -gt 0 ] && PROTO="${PROTO}UDP"
    printf "    ${G}%-6s${X} ${C}%-15s${X} ${G}open${X} [%s]\n" "$P" "$NAME" "$PROTO"
  else
    printf "    ${Y}%-6s${X} ${C}%-15s${X} closed\n" "$P" "$NAME"
  fi
done
echo -e "${C}══════════════════════════════════════════${X}"
PORTS_EOF
chmod +x /usr/local/bin/ports
echo -e "  \033[1;32mOK: ports\033[0m"

# ──────────────────────────────────────────────
# 5g. load — git pull + deploy scripts
# ──────────────────────────────────────────────
cat > /usr/local/bin/load << 'LOAD_EOF'
#!/bin/bash
# = Rooted by VladiMIR + AI | github.com/GinCz =
clear
C='\033[1;36m'; G='\033[1;32m'; Y='\033[1;33m'; W='\033[1;37m'; X='\033[0m'
echo -e "${C}========================================${X}"
echo -e "  ${W}LOAD — Git Pull + Deploy${X}"
echo -e "${C}========================================${X}"
if [ ! -d /root/Linux_Server_Public ]; then
  echo -e "${Y}Cloning repo...${X}"
  git clone https://github.com/GinCz/Linux_Server_Public.git /root/Linux_Server_Public
fi
cd /root/Linux_Server_Public
echo -e "${Y}Pulling latest from GitHub...${X}"
git fetch origin main
git stash 2>/dev/null || true
git rebase origin/main
git stash pop 2>/dev/null || true
echo -e "${G}OK: Repo updated${X}"
for SCRIPT in sos infooo antivir upd 00 ports; do
  SRC=""
  [ -f "/root/Linux_Server_Public/scripts/${SCRIPT}.sh" ] && SRC="/root/Linux_Server_Public/scripts/${SCRIPT}.sh"
  [ -z "$SRC" ] && [ -f "/root/Linux_Server_Public/scripts/scan_clamav.sh" ] && [ "$SCRIPT" = "antivir" ] && SRC="/root/Linux_Server_Public/scripts/scan_clamav.sh"
  if [ -n "$SRC" ]; then
    cp "$SRC" "/usr/local/bin/${SCRIPT}"
    chmod +x "/usr/local/bin/${SCRIPT}"
    echo -e "  ${G}updated: ${SCRIPT}${X}"
  fi
done
source /root/.bashrc 2>/dev/null || true
echo -e "${C}========================================${X}"
echo -e "  ${G}✓ Load complete${X}"
LOAD_EOF
chmod +x /usr/local/bin/load
echo -e "  \033[1;32mOK: load\033[0m"

# ──────────────────────────────────────────────
# 5h. f2 — fail2ban helper
# ──────────────────────────────────────────────
[ -f /root/Linux_Server_Public/scripts/f2.sh ] \
  && cp /root/Linux_Server_Public/scripts/f2.sh /usr/local/bin/f2 \
  && chmod +x /usr/local/bin/f2 \
  && echo -e "  \033[1;32mOK: f2\033[0m"

echo -e "\033[1;32mOK: all scripts installed\033[0m"

# ═══════════════════════════════════════════════════════════════
# STEP 6 — fail2ban config
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}[6/10] Configuring fail2ban...\033[0m"
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
# STEP 7 — .bashrc with aliases
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}[7/10] Writing .bashrc...\033[0m"

ALIASES_COMMON='
# ── Shell ───────────────────────────────────────────────────────
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

# ── Tools ──────────────────────────────────────────────────────
alias ports="/usr/local/bin/ports"
alias sos="/usr/local/bin/sos 1h"
alias sos3="/usr/local/bin/sos 3h"
alias sos24="/usr/local/bin/sos 24h"
alias sos120="/usr/local/bin/sos 120h"
alias infooo="/usr/local/bin/infooo"
alias antivir="/usr/local/bin/antivir"
alias upd="/usr/local/bin/upd"
alias load="/usr/local/bin/load"

# ── Services ──────────────────────────────────────────────────
alias nginx_st="systemctl status nginx"
alias crowdsec_st="systemctl status crowdsec"
alias banlist="cscli decisions list 2>/dev/null || echo CrowdSec not installed"
alias xray_log="journalctl -u xray -n 50 --no-pager 2>/dev/null"

# ── Git ───────────────────────────────────────────────────────
alias gs="git status"
alias gl="git log --oneline -10"
'

ALIASES_SAVELOAD="
# ── save / load ──────────────────────────────────────────────
alias save='cd /root/Linux_Server_Public \\
  && git add -A \\
  && (git diff --cached --quiet && echo \\\"Nothing to commit\\\" \\
    || git commit -m \\\"save: \\\$(hostname) \\\$(date +%Y-%m-%d_%H:%M)\\\") \\
  && git pull origin main --no-rebase --no-edit \\
  && git push origin main \\
  && echo \\\"=== Saved to GitHub ==\\\"'
"

ALIASES_VPN='
# ── VPN ─────────────────────────────────────────────────────
alias amn_st="systemctl status amneziawg 2>/dev/null || echo AmneziaWG not installed"
alias adg_st="systemctl status AdGuardHome 2>/dev/null || echo AdGuard not installed"
alias adg_restart="systemctl restart AdGuardHome 2>/dev/null || true"
alias adg_log="journalctl -u AdGuardHome -n 30 --no-pager 2>/dev/null"
alias wg_st="wg show 2>/dev/null || echo WireGuard not active"
'

ALIASES_222='
# ── FastPanel 222 ────────────────────────────────────────────
alias fp="cd /var/www && ll"
alias fp_log="tail -f /var/log/nginx/error.log"
alias nginx_reload="systemctl reload nginx"
alias nginx_test="nginx -t"
alias php_restart="systemctl restart php8.1-fpm 2>/dev/null || systemctl restart php-fpm 2>/dev/null || true"
alias bot_log="journalctl -u cryptobot -n 50 --no-pager 2>/dev/null || echo CryptoBot not found"
alias bot_st="systemctl status cryptobot 2>/dev/null || echo CryptoBot not configured"
alias bk="bash /root/Linux_Server_Public/222/backup_clean.sh 2>/dev/null || echo backup_clean.sh not found"
'

ALIASES_109='
# ── FastPanel 109 ────────────────────────────────────────────
alias fp="cd /var/www && ll"
alias fp_log="tail -f /var/log/nginx/error.log"
alias nginx_reload="systemctl reload nginx"
alias nginx_test="nginx -t"
alias php_restart="systemctl restart php8.1-fpm 2>/dev/null || systemctl restart php-fpm 2>/dev/null || true"
alias bk="bash /root/Linux_Server_Public/109/backup_clean.sh 2>/dev/null || echo backup_clean.sh not found"
'

BASHRC_HEADER="# ~/.bashrc — ${SRV_NAME}
# Type: ${TYPE_NAME}
# Version: v2026.06.10c | Color: ${PS1_NAME}
# = Rooted by VladiMIR + AI | github.com/GinCz =

export PS1='\[\033[${PS1_CODE}\]\u@\h:\w\$\[\033[00m\] '

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize
"

case "$SRV_TYPE" in
  2) TYPE_BLOCK="$ALIASES_222" ;;
  3) TYPE_BLOCK="$ALIASES_109" ;;
  *) TYPE_BLOCK="$ALIASES_VPN" ;;
esac

printf '%s\n%s\n%s\n%s\n' \
  "$BASHRC_HEADER" \
  "$ALIASES_COMMON" \
  "$ALIASES_SAVELOAD" \
  "$TYPE_BLOCK" > /root/.bashrc

source /root/.bashrc 2>/dev/null || true
echo -e "\033[1;32mOK: .bashrc written\033[0m"

# ═══════════════════════════════════════════════════════════════
# STEP 8 — MOTD banner (inline, type-based)
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}[8/10] Installing MOTD banner...\033[0m"

# ── CLEANUP: remove ALL old/duplicate MOTD scripts before installing new ──
chmod -x /etc/update-motd.d/* 2>/dev/null || true
rm -f /etc/update-motd.d/10-help-text 2>/dev/null || true
rm -f /etc/update-motd.d/50-motd-news 2>/dev/null || true
rm -f /etc/update-motd.d/91-release-upgrade 2>/dev/null || true
rm -f /etc/update-motd.d/99-* 2>/dev/null || true
rm -f /etc/profile.d/motd_server.sh 2>/dev/null || true
rm -f /etc/profile.d/motd*.sh 2>/dev/null || true
rm -f /etc/profile.d/setup_motd*.sh 2>/dev/null || true
rm -f /etc/profile.d/*motd*.sh 2>/dev/null || true
> /etc/motd 2>/dev/null || true
sed -i '/motd/d' /etc/bash.bashrc 2>/dev/null || true
sed -i '/motd/d' /etc/profile 2>/dev/null || true
if [ -f /etc/pam.d/sshd ]; then
  sed -i 's/^\(.*pam_motd.*\)$/#\1/' /etc/pam.d/sshd 2>/dev/null || true
fi
echo -e "  \033[1;33mOK: all old MOTD scripts removed\033[0m"

# Build MOTD content based on server type
case "$SRV_TYPE" in
  1)
    MOTD_TYPE_SHORT="VPN"
    MOTD_SERVICES='xray AdGuardHome amneziawg semaphore crowdsec fail2ban smbd'
    MOTD_CHEATSHEET='  ${G}amn_st${X}(AmneziaWG)    ${G}adg_st${X}(AdGuard)      ${G}save${X}(git push)
  ${G}antivir${X}(ClamAV)       ${G}banlist${X}(бан-лист)    ${G}load${X}(git pull)
  ${G}sos${X}(audit 1h)         ${G}sos24${X}(audit 24h)     ${G}infooo${X}(server info)
  ${G}upd${X}(apt upgrade)      ${G}ports${X}(open ports)    ${G}00${X}(clear screen)'
    ;;
  2)
    MOTD_TYPE_SHORT="Web-222/CF"
    MOTD_SERVICES='nginx mariadb xray crowdsec fail2ban smbd'
    MOTD_CHEATSHEET='  ${G}save${X}(git push)        ${G}fp${X}(web dir)           ${G}antivir${X}(ClamAV)
  ${G}load${X}(git pull)        ${G}nginx_test${X}           ${G}infooo${X}(server info)
  ${G}bk${X}(backup)            ${G}bot_log${X}(CryptoBot)   ${G}upd${X}(apt upgrade)
  ${G}sos${X}(audit 1h)         ${G}sos24${X}(audit 24h)     ${G}ports${X}(open ports)'
    ;;
  3)
    MOTD_TYPE_SHORT="Web-109"
    MOTD_SERVICES='nginx mariadb xray crowdsec fail2ban smbd'
    MOTD_CHEATSHEET='  ${G}save${X}(git push)        ${G}fp${X}(web dir)           ${G}antivir${X}(ClamAV)
  ${G}load${X}(git pull)        ${G}nginx_test${X}           ${G}infooo${X}(server info)
  ${G}bk${X}(backup)            ${G}nginx_reload${X}         ${G}upd${X}(apt upgrade)
  ${G}sos${X}(audit 1h)         ${G}sos24${X}(audit 24h)     ${G}ports${X}(open ports)'
    ;;
esac

# Write NEW MOTD script with chosen color
# NOTE: LINE color is ALWAYS fixed \033[38;5;87m (cold cyan) — independent of PS1 color!
cat > /etc/profile.d/motd_server.sh << MOTD_SCRIPT
#!/bin/bash
# MOTD — ${SRV_NAME} | v2026.06.10c
# = Rooted by VladiMIR + AI | github.com/GinCz =
shopt -q login_shell || return 0 2>/dev/null || exit 0
[ -n "\$SSH_CONNECTION" ] || return 0 2>/dev/null || exit 0

LC='\033[38;5;87m'  # LINE color — always fixed cold cyan, never changes with PS1
C="${MOTD_COLOR}"   # PS1 accent color — for hostname/IP/RAM/CPU values
G='\033[1;32m'; Y='\033[1;33m'; W='\033[1;37m'; R='\033[1;31m'; X='\033[0m'
LINE=\$(printf '%0.s━' {1..78})

HN=\$(cat /etc/hostname 2>/dev/null | head -1 | tr -d '[:space:]')
[[ -z "\$HN" ]] && HN=\$(hostname 2>/dev/null || echo "unknown")
IP=\$(hostname -I 2>/dev/null | awk '{print \$1}')
RAM_USED=\$(free -m | awk '/Mem:/{print \$3}')
RAM_TOTAL=\$(free -m | awk '/Mem:/{print \$2}')
CPU=\$(top -bn1 | grep 'Cpu(s)' | awk '{print int(\$2+\$4)}')
UPTIME=\$(uptime -p | sed 's/up //')
LOAD=\$(awk '{print \$1" "\$2" "\$3}' /proc/loadavg)

# Services status block (type-specific)
SVC_STATUS=""
for SVC in ${MOTD_SERVICES}; do
  if systemctl list-units --type=service --all 2>/dev/null | grep -q "\${SVC}.service"; then
    ST=\$(systemctl is-active "\$SVC" 2>/dev/null)
    [ "\$ST" = "active" ] && SC="\$G" || SC="\$R"
    SVC_STATUS="\${SVC_STATUS}  \${SC}● \${SVC}\${X}"
  fi
done

# CrowdSec status — combined with Type on one line
if systemctl is-active --quiet crowdsec 2>/dev/null; then
  BAN_COUNT=\$(cscli decisions list -o raw 2>/dev/null | grep -c ',' || echo 0)
  CS_LINE="  \${Y}Type:\${X} ${MOTD_TYPE_SHORT}   \${Y}CrowdSec:\${X} \${G}● ACTIVE\${X} | bans: \${W}\${BAN_COUNT}\${X}"
else
  CS_LINE="  \${Y}Type:\${X} ${MOTD_TYPE_SHORT}   \${Y}CrowdSec:\${X} \${R}✗ INACTIVE\${X}"
fi

echo -e "\${LC}\${LINE}\${X}"
echo -e "  \${LC}🖥\${X}  \${W}\${HN}\${X}  \${Y}\${IP}\${X}  RAM:\${W}\${RAM_USED}/\${RAM_TOTAL}MB\${X}  CPU:\${W}\${CPU}%\${X}  up \${W}\${UPTIME}\${X}"
echo -e "\${CS_LINE}"
echo -e "\${LC}\${LINE}\${X}"
echo -e "  \${Y}Services:\${X}\${SVC_STATUS}"
echo -e "\${LC}\${LINE}\${X}"
echo -e "  \${Y}CHEATSHEET:\${X}"
echo -e "${MOTD_CHEATSHEET}"
echo -e "\${LC}\${LINE}\${X}"
echo -e "  load: \${G}\${LOAD}\${X}  |  \${Y}Ubuntu 24\${X}  |  \${W}= Rooted by VladiMIR + AI =\${X}"
echo
MOTD_SCRIPT

chmod +x /etc/profile.d/motd_server.sh
echo -e "\033[1;32mOK: MOTD installed (/etc/profile.d/motd_server.sh)\033[0m"

# ═══════════════════════════════════════════════════════════════
# STEP 9 — UFW firewall
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}[9/10] Configuring UFW...\033[0m"
ufw --force reset >/dev/null 2>&1
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
# Whitelist all trusted IPs
for TRUSTED_IP in \
  152.53.182.222 212.109.223.109 109.234.38.47 \
  144.124.228.237 144.124.232.9 144.124.228.227 \
  144.124.239.24 91.84.118.178 146.103.110.176 \
  144.124.233.38 3.79.14.42 \
  185.100.197.16 185.14.233.235 185.14.232.0 \
  90.181.133.10; do
  ufw allow from "$TRUSTED_IP" to any >/dev/null 2>&1 || true
done
ufw --force enable
echo -e "\033[1;32mOK: UFW active, trusted IPs whitelisted\033[0m"

# ═══════════════════════════════════════════════════════════════
# STEP 10 — mc.menu (Midnight Commander user menu)
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}[10/10] Installing mc.menu...\033[0m"
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
i  INFOOO — server info
    /usr/local/bin/infooo
p  PORTS — open ports
    /usr/local/bin/ports
a  ANTIVIR — ClamAV scan /var/www
    /usr/local/bin/antivir /var/www
u  UPD — apt upgrade
    /usr/local/bin/upd
g  GIT save (push)
    cd /root/Linux_Server_Public && git add -A && git commit -m "save: $(hostname) $(date +%Y-%m-%d)" && git push origin main
l  GIT load (pull)
    /usr/local/bin/load
MCMENU_EOF
  echo -e "\033[1;32mOK: mc.menu (inline fallback)\033[0m"
fi

# ═══════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ═══════════════════════════════════════════════════════════════
echo -e "\n\033[${PS1_CODE}════════════════════════════════════════\033[0m"
echo -e "\033[1;32m"
echo "   SETUP COMPLETE — ${SRV_NAME}"
echo "   Type   : ${TYPE_NAME}"
echo "   Color  : ${PS1_NAME}"
echo "  ════════════════════════════════════════"
echo -e "  Scripts installed to /usr/local/bin/:"
for S in sos infooo antivir upd 00 ports load; do
  [ -x "/usr/local/bin/$S" ] && echo "    ✓ $S" || echo "    ✗ $S (MISSING)"
done
echo -e "\033[0m"
echo -e "  \033[1;33mNext steps:\033[0m"
echo -e "  1) Run: \033[1;36msource ~/.bashrc\033[0m"
echo -e "  2) Test: \033[1;36msos\033[0m  |  \033[1;36minfooo\033[0m  |  \033[1;36mports\033[0m"
echo -e "  3) Reconnect SSH to see new MOTD\033[0m (no more login banner!)"
echo -e "  4) Configure CrowdSec, Xray, Samba as needed"
echo
echo -e "  \033[1;37m= Rooted by VladiMIR + AI | v.2026.06.10c | github.com/GinCz =\033[0m"
