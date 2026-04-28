#!/bin/bash
clear
# =============================================================================
#  vpn_restore.sh  v2026-04-13
#  = Rooted by VladiMIR | AI =
#  Run from: 222-DE-NetCup (152.53.182.222)
#  Usage: bash /root/vpn_restore.sh
# =============================================================================
CY="\033[1;96m"; GN="\033[1;92m"; YL="\033[1;93m"
RD="\033[1;91m"; WH="\033[1;97m"; OR="\033[38;5;214m"
LG="\033[38;5;120m"; X="\033[0m"
HR="${CY}========================================================================${X}"

declare -A NODE_IPS=(
    ["ALEX_47"]="109.234.38.47"
    ["4TON_237"]="144.124.228.237"
    ["TATRA_9"]="144.124.232.9"
    ["SHAHIN_227"]="144.124.228.227"
    ["STOLB_24"]="144.124.239.24"
    ["PILIK_178"]="91.84.118.178"
    ["ILYA_176"]="146.103.110.176"
    ["SO_38"]="144.124.233.38"
)
declare -A NODE_INFO=(
    ["ALEX_47"]="AmneziaWG + Samba"
    ["4TON_237"]="AWG + Samba + Prometheus"
    ["TATRA_9"]="AWG + Samba + Kuma"
    ["SHAHIN_227"]="AWG + Samba"
    ["STOLB_24"]="AWG + Samba + AdGuard"
    ["PILIK_178"]="AWG + Samba"
    ["ILYA_176"]="AWG + Samba"
    ["SO_38"]="AWG + Samba"
)

BACKUP_ROOT="/BACKUP/vpn"
SSH_KEY="/root/.ssh/id_ed25519"
CONTAINER="amnezia-awg"

ssh_cmd() {
    local ip="$1"; shift
    [ -f "$SSH_KEY" ] \
        && ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=15 root@"$ip" "$@" \
        || ssh -o StrictHostKeyChecking=no -o ConnectTimeout=15 root@"$ip" "$@"
}
scp_cmd() {
    [ -f "$SSH_KEY" ] \
        && scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "$1" "$2" \
        || scp -o StrictHostKeyChecking=no "$1" "$2"
}

# HEADER
echo -e "$HR"
echo -e "  RESTORE VPN | 222-DE-NetCup | $(hostname -I | awk '{print $1}')"
echo -e "  Restores amnezia-awg Docker container on a VPN node"
echo -e "$HR\n"

# STEP 1 — Select node
declare -a NODES=()
for d in "$BACKUP_ROOT"/*/; do
    n=$(basename "$d")
    c=$(ls "$d"*.tar.gz 2>/dev/null | wc -l)
    [ "$c" -gt 0 ] && NODES+=("$n")
done
[ ${#NODES[@]} -eq 0 ] && echo -e "${RD}No backups found in $BACKUP_ROOT${X}" && exit 1

echo -e "  ${WH}Nodes with backups:${X}\n"
for i in "${!NODES[@]}"; do
    n="${NODES[$i]}"
    c=$(ls "$BACKUP_ROOT/$n/"*.tar.gz 2>/dev/null | wc -l)
    lat=$(ls -t "$BACKUP_ROOT/$n/"*.tar.gz 2>/dev/null | head -1 | xargs basename 2>/dev/null)
    echo -e "  ${CY}[$((i+1))]${X} ${YL}${n}${X}  ${WH}${NODE_IPS[$n]}${X}  ${LG}${c} arch${X}  ${OR}${NODE_INFO[$n]}${X}"
    echo -e "       latest: ${WH}${lat}${X}"
done
echo
read -rp "$(echo -e "  ${WH}Select node number: ${X}")" ni
ni=$((ni-1))
[ "$ni" -lt 0 ] || [ "$ni" -ge "${#NODES[@]}" ] && echo -e "${RD}Invalid${X}" && exit 1

NODE="${NODES[$ni]}"
IP="${NODE_IPS[$NODE]}"
echo -e "\n  ${GN}Selected: ${YL}${NODE}${X}  ${WH}${IP}${X}\n"

# STEP 2 — Select archive
echo -e "$HR\n  ${WH}Archives for ${YL}${NODE}${X}:\n"
declare -a ARCHS=()
mapfile -t ARCHS < <(ls -t "$BACKUP_ROOT/$NODE/"*.tar.gz 2>/dev/null)
[ ${#ARCHS[@]} -eq 0 ] && echo -e "${RD}No archives for $NODE${X}" && exit 1

for i in "${!ARCHS[@]}"; do
    a="${ARCHS[$i]}"
    sz=$(du -sh "$a" | cut -f1)
    mt=$(stat -c"%y" "$a" | cut -d'.' -f1)
    m=""; [ "$i" -eq 0 ] && m="  ${GN}<-- latest${X}"
    echo -e "  ${CY}[$((i+1))]${X}  ${OR}${sz}${X}  ${WH}${mt}${X}  ${YL}$(basename "$a")${X}${m}"
done
echo
read -rp "$(echo -e "  ${WH}Select archive (Enter = latest): ${X}")" ai
[ -z "$ai" ] && ai=1
ai=$((ai-1))
[ "$ai" -lt 0 ] || [ "$ai" -ge "${#ARCHS[@]}" ] && echo -e "${RD}Invalid${X}" && exit 1

ARCH="${ARCHS[$ai]}"
ARCH_BASE=$(basename "$ARCH")
REMOTE_ARCH="/tmp/$ARCH_BASE"
echo -e "\n  ${GN}Archive: ${YL}${ARCH_BASE}${X}\n"

# STEP 3 — Confirm
echo -e "$HR"
echo -e "  ${RD}WARNING: container on ${YL}${NODE}${RD} (${IP}) will stop ~30-60 sec!${X}"
echo -e "  ${WH}Services: ${OR}${NODE_INFO[$NODE]}${X}"
echo
read -rp "$(echo -e "  ${RD}Type YES to continue: ${X}")" ok
[ "$ok" != "YES" ] && echo -e "\n  ${YL}Aborted.${X}\n" && exit 0

# STEP 4 — Upload
echo -e "\n$HR\n  ${CY}Uploading archive to ${YL}${NODE}${X}..."
scp_cmd "$ARCH" "root@${IP}:${REMOTE_ARCH}" || { echo -e "${RD}Upload failed!${X}"; exit 1; }
echo -e "  ${GN}Upload OK${X}"

# STEP 5 — Restore on node
echo -e "  ${CY}Restoring on ${YL}${NODE}${X}..."
ssh_cmd "$IP" bash -s << ENDSSH
set -e
docker stop $CONTAINER 2>/dev/null || true
docker rm   $CONTAINER 2>/dev/null || true
docker load < "$REMOTE_ARCH"
docker images | grep "${CONTAINER}-bak" | awk '{print \$1":"\$2}' | xargs -r docker rmi 2>/dev/null || true
docker run -d \
  --name $CONTAINER --restart unless-stopped --privileged \
  --cap-add NET_ADMIN --cap-add SYS_MODULE --network bridge \
  --sysctl net.ipv4.ip_forward=1 --sysctl net.ipv4.conf.all.src_valid_mark=1 \
  -p 51820:51820/udp \
  -v /lib/modules:/lib/modules \
  -v /opt/amnezia/awg:/opt/amnezia/awg \
  -v /opt/amnezia/start.sh:/opt/amnezia/start.sh \
  $CONTAINER:latest
sleep 5
docker ps | grep $CONTAINER || { echo "ERROR: container not running!"; exit 1; }
docker exec $CONTAINER wg show wg0 2>/dev/null | grep "^peer" | wc -l | xargs -I{} echo "{} peers registered"
rm -f "$REMOTE_ARCH"
ENDSSH

if [ $? -eq 0 ]; then
    echo -e "\n$HR"
    echo -e "  ${GN}RESTORE COMPLETE${X}"
    echo -e "  ${WH}Node   : ${YL}${NODE}${X}  ${WH}${IP}${X}"
    echo -e "  ${WH}Archive: ${OR}${ARCH_BASE}${X}"
    echo -e "$HR\n"
else
    echo -e "\n${RD}RESTORE FAILED — check output above${X}\n"
    exit 1
fi
echo -e "  ${YL}= Rooted by VladiMIR | AI =\n${X}"
