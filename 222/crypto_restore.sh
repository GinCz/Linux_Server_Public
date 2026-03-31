#!/bin/bash
clear
# =============================================================================
# crypto_restore.sh — Restore crypto-bot Docker from backup
# =============================================================================
# Version  : v2026-03-31
# Author   : Ing. VladiMIR Bulantsev
# GitHub   : https://github.com/GinCz/Linux_Server_Public
# = Rooted by VladiMIR | AI =
# =============================================================================

BACKUP_DIR="/BACKUP/222/docker/crypto"
COMPOSE_DIR="/root/crypto-docker"

# --- Colors ---
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
WHITE='\033[1;37m'
RESET='\033[0m'
BAR="${CYAN}=================================================================${RESET}"

# --- Header ---
echo -e "${BAR}"
echo -e "${CYAN}==${RESET}  ${YELLOW}   ███ CRYPTO-BOT │ BACKUP RESTORE ███   ${RESET}  ${CYAN}==${RESET}"
echo -e "${BAR}"
echo ""

# --- Verify backup directory exists ---
if [ ! -d "${BACKUP_DIR}" ]; then
    echo -e "${RED}[ERROR]${RESET} Backup directory not found: ${YELLOW}${BACKUP_DIR}${RESET}"
    exit 1
fi

# --- List last 3 backups ---
echo -e "${CYAN}  Available backups (last 3):${RESET}"
echo -e "${CYAN}-----------------------------------------------------------------${RESET}"

mapfile -t BACKUPS < <(ls -t "${BACKUP_DIR}"/*.tar.gz 2>/dev/null | head -3)

if [ ${#BACKUPS[@]} -eq 0 ]; then
    echo -e "${RED}[ERROR]${RESET} No backups found in ${YELLOW}${BACKUP_DIR}${RESET}"
    exit 1
fi

for i in "${!BACKUPS[@]}"; do
    SIZE=$(du -sh "${BACKUPS[$i]}" 2>/dev/null | cut -f1)
    DATE=$(stat -c '%y' "${BACKUPS[$i]}" | cut -d'.' -f1)
    echo -e "  ${YELLOW}[$((i+1))]${RESET} ${WHITE}$(basename "${BACKUPS[$i]}")${RESET}  ${GREEN}[${SIZE}]${RESET}  ${CYAN}${DATE}${RESET}"
done

echo -e "${CYAN}-----------------------------------------------------------------${RESET}"
echo ""
echo -en "  ${YELLOW}Select backup [1-${#BACKUPS[@]}]:${RESET} "
read -r CHOICE

# --- Validate input ---
if ! [[ "${CHOICE}" =~ ^[1-3]$ ]] || [ "${CHOICE}" -gt "${#BACKUPS[@]}" ]; then
    echo -e "\n${RED}[ERROR]${RESET} Invalid selection."
    exit 1
fi

SELECTED="${BACKUPS[$((CHOICE-1))]}"
echo ""
echo -e "  ${GREEN}[✔ SELECTED]${RESET} ${WHITE}$(basename "${SELECTED}")${RESET}"
echo ""

# --- Confirmation ---
echo -e "${CYAN}-----------------------------------------------------------------${RESET}"
echo -e "  ${RED}⚠  WARNING:${RESET} ${WHITE}Current crypto-bot container will be STOPPED!${RESET}"
echo -e "${CYAN}-----------------------------------------------------------------${RESET}"
echo -en "  ${YELLOW}Are you sure? [y/N]:${RESET} "
read -r CONFIRM
if [[ ! "${CONFIRM}" =~ ^[Yy]$ ]]; then
    echo -e "\n  ${YELLOW}[CANCELLED]${RESET} Nothing changed."
    exit 0
fi
echo ""
echo -e "${BAR}"
echo ""

# --- Stop and remove container ---
echo -e "  ${CYAN}[1/5]${RESET} ${WHITE}Stopping and removing crypto-bot container...${RESET}"
docker stop crypto-bot 2>/dev/null && docker rm crypto-bot 2>/dev/null
echo -e "        ${GREEN}✔ Done.${RESET}"
echo ""

# --- Backup current state ---
BACK_STAMP=$(date +%Y-%m-%d_%H-%M)
echo -e "  ${CYAN}[2/5]${RESET} ${WHITE}Backing up current crypto-docker → crypto-docker.bak_${BACK_STAMP}${RESET}"
cp -a "${COMPOSE_DIR}" "/root/crypto-docker.bak_${BACK_STAMP}"
echo -e "        ${GREEN}✔ Done.${RESET}"
echo ""

# --- Extract archive ---
echo -e "  ${CYAN}[3/5]${RESET} ${WHITE}Extracting $(basename "${SELECTED}") to /...${RESET}"
tar -xzf "${SELECTED}" -C /
echo -e "        ${GREEN}✔ Done.${RESET}"
echo ""

# --- Load Docker image ---
DOCKER_IMAGE="/tmp/crypto-bot-image.tar.gz"
if [ -f "${DOCKER_IMAGE}" ]; then
    echo -e "  ${CYAN}[4/5]${RESET} ${WHITE}Loading Docker image...${RESET}"
    docker load -i "${DOCKER_IMAGE}"
    echo -e "        ${GREEN}✔ Done.${RESET}"
else
    echo -e "  ${CYAN}[4/5]${RESET} ${YELLOW}No Docker image found in archive — skipping.${RESET}"
fi
echo ""

# --- Start container ---
echo -e "  ${CYAN}[5/5]${RESET} ${WHITE}Starting crypto-bot via docker-compose...${RESET}"
cd "${COMPOSE_DIR}" && docker-compose up -d
echo ""

# --- Done ---
echo -e "${BAR}"
echo -e "${CYAN}==${RESET}  ${GREEN}   ✔✔✔  RESTORE COMPLETE ✔✔✔   ${RESET}  ${CYAN}==${RESET}"
echo -e "${BAR}"
echo ""
docker ps | grep crypto
echo ""
