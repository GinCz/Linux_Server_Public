#!/usr/bin/env bash
# ==========================================================================================
#  master_all_servers_backup.sh — Full Configuration & System Settings Backup
# ==========================================================================================
# Description : Backs up all system configs, SSL certs, FastPanel DB/settings, X-Ray DB,
#               AdGuard, Samba, WireGuard, SSH keys, cron jobs and DNS records from ALL servers.
# Destination : Centralized in /BACKUP/all_servers/ on Server 222
# Mirror      : Mirrored to /BACKUP/all_servers/ on Server 109
# Retention   : Keeps last 24 weeks (~6 months)
# Schedule    : Weekly (Sunday 03:30 AM)
# ==========================================================================================
set -euo pipefail

BACKUP_TAG="$(date +%Y%m%d_%H%M%S)"
BACKUP_ROOT="/BACKUP/all_servers"
CURRENT_DIR="${BACKUP_ROOT}/backup_${BACKUP_TAG}"
REMOTE_109_IP="212.109.223.109"

mkdir -p "$CURRENT_DIR"

echo "=== [1/3] Backing up Server 222 (Master Web / FastPanel) ==="
tar -czf "${CURRENT_DIR}/server_222_master_${BACKUP_TAG}.tar.gz" \
  /etc/nginx \
  /etc/fastpanel2 \
  /usr/local/fastpanel2/app/db \
  /usr/local/fastpanel2/config \
  /usr/local/fastpanel2/ssl \
  /etc/letsencrypt \
  /root/.acme.sh \
  /etc/x-ui/x-ui.db \
  /usr/local/x-ui/bin/config.json \
  /etc/bind \
  /etc/named* \
  /etc/exim4 \
  /etc/dovecot \
  /etc/mysql \
  /etc/samba \
  /etc/fail2ban \
  /etc/crowdsec \
  /etc/iptables \
  /etc/ipset* \
  /etc/systemd/system \
  /etc/cron* \
  /var/spool/cron/crontabs \
  /root/.ssh \
  2>/dev/null || true

echo "=== [2/3] Backing up Server 109 (RU Web / FastPanel) ==="
ssh -o BatchMode=yes -o ConnectTimeout=10 root@${REMOTE_109_IP} "mkdir -p /tmp/bk_109 && tar -czf /tmp/bk_109/server_109_ru_${BACKUP_TAG}.tar.gz /etc/nginx /etc/fastpanel2 /usr/local/fastpanel2/app/db /usr/local/fastpanel2/config /usr/local/fastpanel2/ssl /etc/letsencrypt /root/.acme.sh /etc/x-ui/x-ui.db /usr/local/x-ui/bin/config.json /etc/bind /etc/named* /etc/exim4 /etc/dovecot /etc/mysql /etc/samba /etc/fail2ban /etc/crowdsec /etc/iptables /etc/ipset* /etc/systemd/system /etc/cron* /var/spool/cron/crontabs /root/.ssh 2>/dev/null || true"
scp -o BatchMode=yes -o ConnectTimeout=10 root@${REMOTE_109_IP}:/tmp/bk_109/server_109_ru_${BACKUP_TAG}.tar.gz "${CURRENT_DIR}/" || true
ssh -o BatchMode=yes -o ConnectTimeout=10 root@${REMOTE_109_IP} "rm -rf /tmp/bk_109"

echo "=== [3/3] Backing up all 10 VPN Nodes ==="
VPN_NODES=(
  "212.34.148.51:vpn_ALEX_51"
  "144.124.228.237:vpn_4ton_237"
  "144.124.232.9:vpn_tatra_9"
  "144.124.228.227:vpn_shahin_227"
  "144.124.239.24:vpn_stolb_24"
  "195.63.138.33:vpn_pilik_33"
  "146.103.110.176:vpn_ilya_176"
  "144.124.233.38:vpn_so_38"
  "18.195.117.12:vpn_aws_12"
  "82.223.116.38:vpn_ionos_38"
)

for entry in "${VPN_NODES[@]}"; do
  IP="${entry%%:*}"
  NAME="${entry##*:}"
  echo "--> Backing up ${NAME} (${IP})..."
  ssh -o BatchMode=yes -o ConnectTimeout=5 root@${IP} "mkdir -p /tmp/node_bk && tar -czf /tmp/node_bk/${NAME}_${BACKUP_TAG}.tar.gz /etc/x-ui/x-ui.db /usr/local/x-ui/bin/config.json /opt/AdGuardHome/AdGuardHome.yaml /etc/amnezia /etc/wireguard /etc/fail2ban /etc/samba /etc/iptables /etc/systemd/system /etc/cron* /var/spool/cron/crontabs /root/.ssh /etc/profile.d 2>/dev/null || true" || { echo "Failed connecting to ${IP}"; continue; }
  scp -o BatchMode=yes -o ConnectTimeout=5 root@${IP}:/tmp/node_bk/${NAME}_${BACKUP_TAG}.tar.gz "${CURRENT_DIR}/" || true
  ssh -o BatchMode=yes -o ConnectTimeout=5 root@${IP} "rm -rf /tmp/node_bk"
done

echo "=== Mirroring full backup package to Server 109 ==="
ssh -o BatchMode=yes -o ConnectTimeout=10 root@${REMOTE_109_IP} "mkdir -p ${BACKUP_ROOT}"
scp -o BatchMode=yes -o ConnectTimeout=30 -r "${CURRENT_DIR}" root@${REMOTE_109_IP}:"${BACKUP_ROOT}/"

echo "=== Managing 24-week retention (6 months) on 222 and 109 ==="
find "${BACKUP_ROOT}/" -maxdepth 1 -type d -name "backup_*" | sort -r | tail -n +25 | xargs -r rm -rf
ssh -o BatchMode=yes -o ConnectTimeout=10 root@${REMOTE_109_IP} "find ${BACKUP_ROOT}/ -maxdepth 1 -type d -name 'backup_*' | sort -r | tail -n +25 | xargs -r rm -rf" || true

echo "=== Master backup completed successfully! ==="
ls -lh "${CURRENT_DIR}"
