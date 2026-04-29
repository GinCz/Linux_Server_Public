#!/bin/bash
# =============================================================================
# f9servers.sh — Interactive restore: choose server + what to restore
# Version     : v2026-04-30
# Run from    : Server 222 (152.53.182.222)
# Description : Menu-driven restore for all servers.
#               Level 1: which server (222 / 109 / 0=all)
#               Level 2: what to restore
# = Rooted by VladiMIR | AI =
# =============================================================================
clear

REPO="/root/Linux_Server_Public"
S109="root@212.109.223.109"
SSH_OPTS="-o ConnectTimeout=15 -o StrictHostKeyChecking=no -o BatchMode=yes"

G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; R='\033[1;31m'; X='\033[0m'

ok()  { echo -e "  ${G}✅ $1${X}"; }
err() { echo -e "  ${R}❌ $1${X}"; }
wrn() { echo -e "  ${Y}⚠️  $1${X}"; }
hdr() { echo; echo -e "${Y}=== $1 ===${X}"; echo; }

confirm() {
    echo -e "  ${R}WARNING: This will OVERWRITE current data!${X}"
    read -rp "  Type YES to confirm: " YN
    [[ "${YN}" == "YES" ]]
}

# =============================================================================
# RESTORE FUNCTIONS — SERVER 222 (local)
# =============================================================================

r222_docker() {
    hdr "222 — Restore Crypto-Bot Docker"
    wrn "This will stop and restore the crypto-bot container."
    confirm || { echo "  Cancelled."; return; }
    if [[ -f "${REPO}/222/crypto_restore.sh" ]]; then
        bash "${REPO}/222/crypto_restore.sh" && ok "Crypto-bot restored" || err "Restore FAILED"
    else
        err "crypto_restore.sh not found in repo"
    fi
}

r222_git_pull() {
    hdr "222 — Pull configs from GitHub (load)"
    cd "${REPO}" || { err "Repo not found: ${REPO}"; return 1; }
    git stash 2>/dev/null || true
    git pull --rebase && git stash pop 2>/dev/null || true
    source "${REPO}/222/.bashrc"
    ok "Configs pulled and reloaded"
}

r222_all() {
    r222_docker
    r222_git_pull
}

# =============================================================================
# RESTORE FUNCTIONS — SERVER 109 (remote via SSH)
# =============================================================================

_ssh109() {
    ssh ${SSH_OPTS} "${S109}" "$1"
    local RC=$?
    [[ ${RC} -ne 0 ]] && err "SSH to 109 failed (exit ${RC}). Check: ssh ${S109}"
    return ${RC}
}

r109_xray() {
    hdr "109 — Restore Xray / x-ui from latest backup"
    wrn "This will stop x-ui and restore x-ui.db from latest backup."
    confirm || { echo "  Cancelled."; return; }
    _ssh109 "
        BDIR=~/backups/xray
        LATEST_DB=\$(ls -t \${BDIR}/x-ui_*.db 2>/dev/null | head -1)
        if [[ -z \"\${LATEST_DB}\" ]]; then
            echo 'ERROR: No x-ui backup found in \${BDIR}'
            exit 1
        fi
        echo \"Restoring from: \${LATEST_DB}\"
        systemctl stop x-ui 2>/dev/null || true
        cp \"\${LATEST_DB}\" /usr/local/x-ui/db/x-ui.db
        systemctl start x-ui
        systemctl is-active x-ui && echo 'x-ui started OK' || echo 'x-ui failed to start'
    " && ok "109 Xray restored" || true
}

r109_git_pull() {
    hdr "109 — Pull configs from GitHub (remote)"
    _ssh109 "
        cd ~/Linux_Server_Public || exit 1
        git stash 2>/dev/null || true
        git pull --rebase
        git stash pop 2>/dev/null || true
        source ~/Linux_Server_Public/109/.bashrc 2>/dev/null \
            || source ~/Linux_Server_Public/222/.bashrc 2>/dev/null \
            || true
        echo 'Configs pulled on 109'
    " && ok "109 Git pull done" || true
}

r109_all() {
    r109_xray
    r109_git_pull
}

# =============================================================================
# MENUS
# =============================================================================

menu_222() {
    echo -e "${C}Server 222 (152.53.182.222) — What to restore?${X}\n"
    echo -e "  ${Y}1)${X} Docker       (crypto-bot from backup)"
    echo -e "  ${Y}2)${X} Git pull     (reload all configs from GitHub)"
    echo -e "  ${Y}0)${X} ALL          (1 + 2)"
    echo
    read -rp "  Choice [0-2]: " C222
    case "${C222}" in
        1) r222_docker ;;
        2) r222_git_pull ;;
        0) r222_all ;;
        *) err "Invalid choice" ;;
    esac
}

menu_109() {
    echo -e "${C}Server 109 (212.109.223.109) — What to restore?${X}\n"
    echo -e "  ${Y}1)${X} Xray         (x-ui.db from latest backup)"
    echo -e "  ${Y}2)${X} Git pull     (reload all configs from GitHub)"
    echo -e "  ${Y}0)${X} ALL          (1 + 2)"
    echo
    read -rp "  Choice [0-2]: " C109
    case "${C109}" in
        1) r109_xray ;;
        2) r109_git_pull ;;
        0) r109_all ;;
        *) err "Invalid choice" ;;
    esac
}

# =============================================================================
# MAIN MENU
# =============================================================================

echo -e "${Y}============================================${X}"
echo -e "${Y}   F9SERVERS — RESTORE v2026-04-30${X}"
echo -e "${Y}   = Rooted by VladiMIR | AI =${X}"
echo -e "${Y}============================================${X}"
echo
echo -e "  ${Y}1)${X} Server ${C}222${X} (152.53.182.222) — this server"
echo -e "  ${Y}2)${X} Server ${C}109${X} (212.109.223.109) — remote via SSH"
echo -e "  ${Y}0)${X} ${C}ALL servers${X} (222 + 109)"
echo
read -rp "  Which server? [0-2]: " SRV

case "${SRV}" in
    1) menu_222 ;;
    2) menu_109 ;;
    0)
        echo -e "\n${R}WARNING: Restoring ALL servers at once!${X}"
        confirm || { echo "Cancelled."; exit 0; }
        r222_all
        r109_all
        ;;
    *) err "Invalid choice"; exit 1 ;;
esac

echo
echo -e "${Y}============================================${X}"
echo -e "${G}   F9SERVERS — RESTORE DONE${X}"
echo -e "${Y}============================================${X}"
