#!/usr/bin/env bash
# Script:  bot_sync.sh
# Version: v2026-04-12
# Usage:   bash /root/Linux_Server_Public/222/bot_sync.sh [load|save]
#
# load  — GitHub → Docker container  (overwrites running scripts, restarts bot)
# save  — Docker container → GitHub  (commits current live scripts to repo)
#
# = Rooted by VladiMIR | AI =

clear

CYAN="\033[1;36m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
WHITE="\033[1;37m"
DIM="\033[0;37m"
RESET="\033[0m"
BAR="${CYAN}$(printf '=%.0s' {1..66})${RESET}"
DASH="${CYAN}$(printf -- '-%.0s' {1..66})${RESET}"

REPO_DIR="/root/Linux_Server_Public"
SCRIPTS_REPO="${REPO_DIR}/crypto-docker/scripts"
CONTAINER="crypto-bot"
APP_SCRIPTS="/app/scripts"
GIT_USER="GinCz"
GIT_EMAIL="gin.vladimir@gmail.com"

# ── helper: check container running ────────────────────────────
check_container() {
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        echo -e "${RED}✖ Container '${CONTAINER}' is NOT running. Abort.${RESET}"
        exit 1
    fi
}

# ══════════════════════════════════════════════════════════════
# LOAD — pull from GitHub, push into container, restart bot
# ══════════════════════════════════════════════════════════════
cmd_load() {
    echo -e "$BAR"
    echo -e "${YELLOW}  🔽 LOAD: GitHub → Docker container${RESET}"
    echo -e "$BAR"

    check_container

    # 1. Pull latest from GitHub
    echo -e "${CYAN}[1/4] git pull...${RESET}"
    cd "$REPO_DIR" || { echo -e "${RED}✖ Repo dir not found: $REPO_DIR${RESET}"; exit 1; }
    git fetch origin main --quiet
    git reset --hard origin/main --quiet
    echo -e "${GREEN}✔ Repo up to date${RESET}"

    # 2. Copy scripts into container
    echo -e "${CYAN}[2/4] Copying scripts to container...${RESET}"
    for f in scanner.py paper_trade.py tr_report.py; do
        SRC="${SCRIPTS_REPO}/${f}"
        if [ -f "$SRC" ]; then
            docker cp "$SRC" "${CONTAINER}:${APP_SCRIPTS}/${f}"
            echo -e "  ${GREEN}✔ ${f}${RESET}"
        else
            echo -e "  ${DIM}⚠ ${f} not found in repo — skipped${RESET}"
        fi
    done

    # 3. Stop old paper_trade.py process
    echo -e "${CYAN}[3/4] Stopping paper_trade.py inside container...${RESET}"
    docker exec "$CONTAINER" pkill -f paper_trade.py 2>/dev/null && echo -e "  ${GREEN}✔ Stopped${RESET}" || echo -e "  ${DIM}(not running)${RESET}"
    sleep 1

    # 4. Start fresh paper_trade.py inside container
    echo -e "${CYAN}[4/4] Starting paper_trade.py...${RESET}"
    docker exec -d "$CONTAINER" python3 "${APP_SCRIPTS}/paper_trade.py"
    sleep 1
    RUNNING=$(docker exec "$CONTAINER" pgrep -f paper_trade.py 2>/dev/null)
    if [ -n "$RUNNING" ]; then
        echo -e "  ${GREEN}✔ paper_trade.py running (PID ${RUNNING})${RESET}"
    else
        echo -e "  ${RED}✖ paper_trade.py failed to start — check logs!${RESET}"
    fi

    echo -e "$BAR"
    echo -e "${GREEN}  ✅ LOAD COMPLETE — bot updated and restarted${RESET}"
    echo -e "$BAR"
}

# ══════════════════════════════════════════════════════════════
# SAVE — copy from container back to repo, commit + push
# ══════════════════════════════════════════════════════════════
cmd_save() {
    echo -e "$BAR"
    echo -e "${YELLOW}  🔼 SAVE: Docker container → GitHub${RESET}"
    echo -e "$BAR"

    check_container

    # 1. Copy scripts out of container
    echo -e "${CYAN}[1/3] Extracting scripts from container...${RESET}"
    mkdir -p "$SCRIPTS_REPO"
    for f in scanner.py paper_trade.py tr_report.py; do
        docker cp "${CONTAINER}:${APP_SCRIPTS}/${f}" "${SCRIPTS_REPO}/${f}" 2>/dev/null && \
            echo -e "  ${GREEN}✔ ${f}${RESET}" || \
            echo -e "  ${DIM}⚠ ${f} not in container — skipped${RESET}"
    done

    # 2. Git commit
    echo -e "${CYAN}[2/3] Committing...${RESET}"
    cd "$REPO_DIR" || exit 1
    git config user.name  "$GIT_USER"  2>/dev/null
    git config user.email "$GIT_EMAIL" 2>/dev/null
    git add crypto-docker/scripts/scanner.py \
            crypto-docker/scripts/paper_trade.py \
            crypto-docker/scripts/tr_report.py
    CHANGED=$(git diff --cached --name-only)
    if [ -z "$CHANGED" ]; then
        echo -e "  ${DIM}Nothing changed — no commit needed${RESET}"
    else
        DATE=$(date +%Y-%m-%d)
        git commit -m "crypto: auto-save from container v${DATE}"
        echo -e "  ${GREEN}✔ Committed${RESET}"
    fi

    # 3. Push to GitHub
    echo -e "${CYAN}[3/3] Pushing to GitHub...${RESET}"
    git push origin main
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✔ Pushed successfully${RESET}"
    else
        echo -e "  ${RED}✖ Push failed — check SSH key / credentials${RESET}"
        exit 1
    fi

    echo -e "$BAR"
    echo -e "${GREEN}  ✅ SAVE COMPLETE — container scripts saved to GitHub${RESET}"
    echo -e "$BAR"
}

# ══════════════════════════════════════════════════════════════
# ENTRY POINT
# ══════════════════════════════════════════════════════════════
case "${1:-}" in
    load) cmd_load ;;
    save) cmd_save ;;
    *)
        echo -e "$BAR"
        echo -e "${WHITE}  bot_sync.sh v2026-04-12${RESET}"
        echo -e "$DASH"
        echo -e "  ${GREEN}load${RESET}  — GitHub → контейнер → рестарт бота"
        echo -e "  ${YELLOW}save${RESET}  — контейнер → GitHub (commit + push)"
        echo -e "$DASH"
        echo -e "  ${DIM}Пример:  bash /root/Linux_Server_Public/222/bot_sync.sh load${RESET}"
        echo -e "$BAR"
        ;;
esac
