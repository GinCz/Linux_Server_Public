#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  install_sos.sh | [v2026-05-25]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Deploy /usr/local/bin/sos audit binary to local system
# Servers     : All Linux Nodes
# Usage       : bash scripts/install_sos.sh
# ==========================================================================================
CYAN='\033[01;96m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
RESET='\033[0m'

LINE="================================================================================================="
REPO="/root/Linux_Server_Public"
REPO_URL="https://github.com/GinCz/Linux_Server_Public.git"
SOS_SRC="$REPO/scripts/sos.sh"
SOS_BIN="/usr/local/bin/sos"
BASHRC="/root/.bashrc"
BASH_PROFILE="/root/.bash_profile"

echo -e "${CYAN}${LINE}${RESET}"
echo -e "${GREEN}  SOS INSTALLER — Setting up server monitor...${RESET}"
echo -e "${CYAN}${LINE}${RESET}"

# --- STEP 1: Clone or update repo -------------------------------------------------------------
echo -e "${YELLOW}  [1/3] Syncing repository...${RESET}"
if [ ! -d "$REPO/.git" ]; then
    echo -e "        Cloning from GitHub..."
    cd /root && git clone "$REPO_URL"
else
    echo -e "        Updating existing repo..."
    cd "$REPO" && git pull origin main --no-rebase --no-edit
fi

if [ ! -f "$SOS_SRC" ]; then
    echo -e "${RED}  ERROR: $SOS_SRC not found after clone/pull. Aborting.${RESET}"
    exit 1
fi

# --- STEP 2: Install binary -------------------------------------------------------------------
echo -e "${YELLOW}  [2/3] Installing /usr/local/bin/sos...${RESET}"
cp "$SOS_SRC" "$SOS_BIN"
chmod +x "$SOS_BIN"
echo -e "        ${GREEN}Installed: $SOS_BIN${RESET}"

# --- STEP 3: Write aliases into .bashrc and .bash_profile -------------------------------------
echo -e "${YELLOW}  [3/3] Writing aliases...${RESET}"

ALIAS_MARKER="# === sos aliases ==="

for FILE in "$BASHRC" "$BASH_PROFILE"; do
    # Remove old sos alias block if exists
    grep -q "$ALIAS_MARKER" "$FILE" 2>/dev/null && \
        sed -i "/^${ALIAS_MARKER}/,/^# ===/{ /^# ===/!d; /^${ALIAS_MARKER}/d }" "$FILE" 2>/dev/null
    # Remove any stray sos alias lines
    sed -i '/alias sos[0-9]*=/d' "$FILE" 2>/dev/null
    # Write fresh block
    printf '%s\n' \
        "" \
        "$ALIAS_MARKER" \
        "alias sos='/usr/local/bin/sos 24h'" \
        "alias sos1='/usr/local/bin/sos 1h'" \
        "alias sos3='/usr/local/bin/sos 3h'" \
        "alias sos24='/usr/local/bin/sos 24h'" \
        "alias sos120='/usr/local/bin/sos 120h'" >> "$FILE"
done

source "$BASHRC" 2>/dev/null

echo -e "${CYAN}${LINE}${RESET}"
echo -e "${GREEN}  DONE! SOS installed and aliases configured.${RESET}"
echo -e ""
echo -e "  ${YELLOW}Usage:${RESET}"
echo -e "    ${GREEN}sos${RESET}         — audit last 24h (default)"
echo -e "    ${GREEN}sos1${RESET}        — audit last 1h"
echo -e "    ${GREEN}sos3${RESET}        — audit last 3h"
echo -e "    ${GREEN}sos24${RESET}       — audit last 24h"
echo -e "    ${GREEN}sos120${RESET}      — audit last 120h"
echo -e "    ${GREEN}sos 30m${RESET}     — audit last 30 minutes"
echo -e "    ${GREEN}sos 6h${RESET}      — any custom time window"
echo -e ""
echo -e "  Run: ${CYAN}source ~/.bashrc${RESET}  — to activate aliases in current session"
echo -e "${CYAN}${LINE}${RESET}"

# = Rooted by VladiMIR | AI = v2026-05-25 = github.com/GinCz/Linux_Server_Public
