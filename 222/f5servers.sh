#!/bin/bash
# =============================================================================
# f5servers.sh — Interactive backup: choose server + what to save
# Version     : v2026-04-30
# Run from    : Server 222 (152.53.182.222)
# Description : Menu-driven backup for all servers.
#               Level 1: which server (222 / 109 / 0=all)
#               Level 2: what to backup (full / docker / xray / git / 0=all)
# = Rooted by VladiMIR | AI =
# =============================================================================
clear

REPO="/root/Linux_Server_Public"
S109="root@212.109.223.109"
SSH_OPTS="-o ConnectTimeout=15 -o StrictHostKeyChecking=no -o BatchMode=yes"

G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; R='\033[1;31m'; B='\033[1;34m'; X='\033[0m'

ok()  { echo -e "  ${G}✅ $1${X}"; }
err() { echo -e "  ${R}❌ $1${X}"; }
hdr() { echo; echo -e "${Y}=== $1 ===${X}"; echo; }

# =============================================================================
# BACKUP FUNCTIONS — SERVER 222 (local)
# =============================================================================

b222_full() {
    hdr "222 — Full Backup (files + databases → S3)"
    if [[ -f /root/backup_clean.sh ]]; then
        bash /root/backup_clean.sh && ok "Full backup done" || err "Full backup FAILED"
    elif [[ -f "${REPO}/222/backup_clean.sh" ]]; then
        bash "${REPO}/222/backup_clean.sh" && ok "Full backup done" || err "Full backup FAILED"
    else
        err "backup_clean.sh not found at /root/ or in repo"
    fi
}

b222_docker() {
    hdr "222 — Docker Crypto-Bot Backup"
    if [[ -f /root/docker_backup.sh ]]; then
        bash /root/docker_backup.sh && ok "Docker backup done" || err "Docker backup FAILED"
    elif [[ -f "${REPO}/222/docker_backup.sh" ]]; then
        bash "${REPO}/222/docker_backup.sh" && ok "Docker backup done" || err "Docker backup FAILED"
    else
        err "docker_backup.sh not found"
    fi
}

b222_git() {
    hdr "222 — Save configs to GitHub"
    cd "${REPO}" || { err "Repo dir not found: ${REPO}"; return 1; }
    git add -A
    if git diff --cached --quiet; then
        ok "Nothing to commit on 222 — repo is up to date"
    else
        git commit -m "backup: server 222 configs $(date +%Y-%m-%d\ %H:%M)" \
            && git push && ok "Git save done (222)" || err "Git push FAILED (222)"
    fi
}

b222_all() {
    b222_full
    b222_docker
    b222_git
}

# =============================================================================
# BACKUP FUNCTIONS — SERVER 109 (remote via SSH)
# =============================================================================

_ssh109() {
    ssh ${SSH_OPTS} "${S109}" "$1"
    local RC=$?
    [[ ${RC} -ne 0 ]] && err "SSH to 109 failed (exit ${RC}). Check: ssh ${S109}"
    return ${RC}
}

b109_full() {
    hdr "109 — Full Backup (remote)"
    _ssh109 "bash ~/Linux_Server_Public/scripts/backup.sh 2>/dev/null \
             || bash ~/backup_clean.sh 2>/dev/null \
             || echo 'ERROR: no backup script found on 109'" \
        && ok "109 full backup done" || true
}

b109_xray() {
    hdr "109 — Xray + x-ui config Backup (remote)"
    _ssh109 "
        set -e
        TS=\$(date +%Y%m%d_%H%M)
        BDIR=~/backups/xray
        mkdir -p \${BDIR}
        cp /usr/local/x-ui/db/x-ui.db \${BDIR}/x-ui_\${TS}.db 2>/dev/null && echo 'x-ui.db saved' || echo 'x-ui.db not found'
        cp /usr/local/x-ui/config.json \${BDIR}/xui_config_\${TS}.json 2>/dev/null && echo 'config.json saved' || echo 'config.json not found'
        systemctl is-active crowdsec &>/dev/null && cscli decisions list > \${BDIR}/crowdsec_decisions_\${TS}.txt && echo 'CrowdSec decisions saved' || echo 'CrowdSec not running'
        echo \"Backup dir: \${BDIR}\"
        ls -lh \${BDIR} | tail -6
    " && ok "109 Xray backup done" || true
}

b109_git() {
    hdr "109 — Save configs to GitHub (remote)"
    _ssh109 "
        cd ~/Linux_Server_Public || exit 1
        git add -A
        if git diff --cached --quiet; then
            echo 'Nothing to commit on 109'
        else
            git commit -m 'backup: server 109 configs \$(date +%Y-%m-%d\ %H:%M)'
            git push && echo 'Git push OK'
        fi
    " && ok "109 Git save done" || true
}

b109_all() {
    b109_full
    b109_xray
    b109_git
}

# =============================================================================
# MENUS
# =============================================================================

menu_222() {
    echo -e "${C}Server 222 (152.53.182.222) — What to backup?${X}\n"
    echo -e "  ${Y}1)${X} Full backup  (files + DB → S3)"
    echo -e "  ${Y}2)${X} Docker       (crypto-bot)"
    echo -e "  ${Y}3)${X} Git          (save configs to GitHub)"
    echo -e "  ${Y}0)${X} ALL          (1 + 2 + 3)"
    echo
    read -rp "  Choice [0-3]: " C222
    case "${C222}" in
        1) b222_full ;;
        2) b222_docker ;;
        3) b222_git ;;
        0) b222_all ;;
        *) err "Invalid choice" ;;
    esac
}

menu_109() {
    echo -e "${C}Server 109 (212.109.223.109) — What to backup?${X}\n"
    echo -e "  ${Y}1)${X} Full backup  (files + DB)"
    echo -e "  ${Y}2)${X} Xray         (x-ui.db + config + CrowdSec)"
    echo -e "  ${Y}3)${X} Git          (save configs to GitHub)"
    echo -e "  ${Y}0)${X} ALL          (1 + 2 + 3)"
    echo
    read -rp "  Choice [0-3]: " C109
    case "${C109}" in
        1) b109_full ;;
        2) b109_xray ;;
        3) b109_git ;;
        0) b109_all ;;
        *) err "Invalid choice" ;;
    esac
}

# =============================================================================
# MAIN MENU
# =============================================================================

echo -e "${Y}============================================${X}"
echo -e "${Y}   F5SERVERS — BACKUP v2026-04-30${X}"
echo -e "${Y}   = Rooted by VladiMIR | AI =${X}"
echo -e "${Y}============================================${X}"
echo
echo -e "  ${Y}1)${X} Server ${C}222${X} (152.53.182.222) — this server"
echo -e "  ${Y}2)${X} Server ${C}109${X} (212.109.223.109) — remote via SSH"
echo -e "  ${Y}0)${X} ${C}ALL servers${X} (222 + 109, backup everything)"
echo
read -rp "  Which server? [0-2]: " SRV

case "${SRV}" in
    1) menu_222 ;;
    2) menu_109 ;;
    0)
        echo -e "\n${C}Running FULL backup on ALL servers...${X}"
        b222_all
        b109_all
        ;;
    *) err "Invalid choice"; exit 1 ;;
esac

echo
echo -e "${Y}============================================${X}"
echo -e "${G}   F5SERVERS — BACKUP DONE${X}"
echo -e "${Y}============================================${X}"
