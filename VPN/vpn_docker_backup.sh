#!/bin/bash
clear
# =============================================================================
#  vpn_docker_backup.sh  -  AmneziaWG VPN backup (amnezia-awg container)
# =============================================================================
#  = Rooted by VladiMIR | AI =
# -----------------------------------------------------------------------------
#  Version    : v2026-04-08g
#  Author     : Ing. VladiMIR Bulantsev
#  GitHub     : https://github.com/GinCz/Linux_Server_Public
#  License    : MIT
# =============================================================================

CY="\033[1;96m"; GN="\033[1;92m"; YL="\033[1;93m"
RD="\033[1;91m"; WH="\033[1;97m"; OR="\033[38;5;214m"; X="\033[0m"

HR="${CY}\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550${X}"

BACKUP_ROOT="/BACKUP/222/vpn"
KEEP=3
SERVER_LABEL="222-DE-NetCup"
CONTAINER="amnezia-awg"
DATE=$(date +%Y-%m-%d_%H-%M)
START_TIME=$(date +%s)
ERRORS=0

if command -v pigz &>/dev/null; then
    COMPRESS="pigz"; COMP_LABEL="pigz \u26a1"
else
    COMPRESS="gzip"; COMP_LABEL="gzip"
fi

mkdir -p "${BACKUP_ROOT}"
ARCH="${BACKUP_ROOT}/${CONTAINER}_${DATE}.tar.gz"

echo -e "$HR"
echo -e "  ${CY}\u2756 VPN BACKUP${X}  ${WH}|||${X}  ${YL}${SERVER_LABEL}${X}  ${WH}|||${X}  ${WH}IP: $(hostname -I | awk '{print $1}')${X}  ${WH}|||${X}  ${YL}= Rooted by VladiMIR | AI =${X}"
echo -e "  ${WH}|||${X} ${CY}$(date '+%Y-%m-%d')${X}  ${WH}|||${X}  ${CY}$(date '+%H:%M:%S')${X}   ${WH}compression: ${GN}${COMP_LABEL}${X}"
echo -e "  ${CY}\u25ba Disk free: ${GN}$(df -h /BACKUP 2>/dev/null | awk 'NR==2{print $4}' || df -h / | awk 'NR==2{print $4}')${X}   ${WH}Load: $(uptime | awk -F'load average:' '{print $2}' | xargs)${X}"
echo -e "$HR"

# --- Cleanup inside container ---
echo -e "${CY}$(date +%H:%M:%S)${X}  ${YL}\u25bc${X} ${YL}${CONTAINER}${X} cleanup inside..."
docker exec "$CONTAINER" sh -c "
    find /tmp -type f -delete 2>/dev/null;
    find /var/log -type f \( -name '*.log' -o -name '*.gz' \) -delete 2>/dev/null;
" 2>/dev/null

# --- Docker commit ---
echo -e "${CY}$(date +%H:%M:%S)${X}  ${CY}\u25cf${X} ${YL}${CONTAINER}${X} docker commit snapshot..."
COMMIT_ID=$(docker commit "$CONTAINER" "${CONTAINER}-vpn-backup:${DATE}" 2>/dev/null | cut -d: -f2 | cut -c1-12)

if [ -z "$COMMIT_ID" ]; then
    echo -e "${RD}$(date +%H:%M:%S) \u2718 docker commit FAILED (container running?)${X}"
    exit 1
fi
echo -e "     ${GN}\u2514\u2500 commit: ${YL}${COMMIT_ID}${X}"

# --- Archive ---
echo -e "${CY}$(date +%H:%M:%S)${X}  ${OR}\u25a3${X} ${YL}${CONTAINER}${X} archiving ${WH}(${COMP_LABEL})${X}..."
t_start=$(date +%s)
docker save "${CONTAINER}-vpn-backup:${DATE}" | ${COMPRESS} > "$ARCH"
t_end=$(date +%s)
elapsed=$((t_end - t_start))
docker rmi "${CONTAINER}-vpn-backup:${DATE}" >/dev/null 2>&1

if [ -s "$ARCH" ]; then
    SZ=$(du -sh "$ARCH" | cut -f1)
    raw=$(stat -c%s "$ARCH" 2>/dev/null || echo 0)
    speed=""; [ "$elapsed" -gt 0 ] && speed=$(echo "scale=1; $raw / $elapsed / 1048576" | bc 2>/dev/null)
    echo -e "${GN}$(date +%H:%M:%S) \u2714 ${YL}${CONTAINER}${GN}: ${OR}$(basename "$ARCH")${X}"
    echo -e "     ${WH}\u251c\u2500 Size   : ${GN}${SZ}${X}"
    echo -e "     ${WH}\u251c\u2500 Time   : ${CY}${elapsed}s${X}${speed:+  @ ${speed} MB/s}"
    echo -e "     ${WH}\u2514\u2500 Status : ${GN}OK \u2713${X}"
else
    echo -e "${RD}$(date +%H:%M:%S) \u2718 archive FAILED or empty${X}"
    ERRORS=1
fi

# --- Rotate ---
ls -t "${BACKUP_ROOT}"/*.tar.gz 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -f
CNT=$(ls "${BACKUP_ROOT}"/*.tar.gz 2>/dev/null | wc -l)
echo -e "     ${CY}\u25a4 Archives: ${WH}${CNT}/${KEEP} kept${X}"
ls -t "${BACKUP_ROOT}"/*.tar.gz 2>/dev/null | tail -n +2 | head -2 | while read f; do
    fsz=$(du -sh "$f" 2>/dev/null | cut -f1)
    fdt=$(stat -c%y "$f" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
    echo -e "        ${CY}\u2514\u2500 ${OR}${fsz}${X} ${WH}${fdt}${X} \u2014 $(basename "$f")"
done

END_TIME=$(date +%s)
TOTAL_ELAPSED=$((END_TIME - START_TIME))

echo -e "$HR"
[ "$ERRORS" -eq 0 ] \
    && echo -e "  ${GN}\u2714  ALL DONE \u2014 NO ERRORS${X}" \
    || echo -e "  ${RD}\u26a0  COMPLETED WITH ERRORS${X}"
echo -e "  ${WH}\u2514\u2500 Finished at : ${YL}$(date '+%Y-%m-%d %H:%M:%S')${X}  ${WH}time: ${CY}${TOTAL_ELAPSED}s${X}"
echo -e "$HR"
echo -e "              ${YL}= Rooted by VladiMIR | AI =${X}"
echo
