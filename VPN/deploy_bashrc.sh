#!/usr/bin/env bash
clear
# =============================================================================
# deploy_bashrc.sh — Apply .bashrc + mc_lastdir_wrapper to VPN server
# =============================================================================
# Version : v2026-03-30
# Author  : Ing. VladiMIR Bulantsev
# Usage   : bash /root/Linux_Server_Public/VPN/deploy_bashrc.sh
# = Rooted by VladiMIR | AI =
# =============================================================================

G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; C='\033[1;36m'; X='\033[0m'

echo -e "${Y}=== VPN: Deploy .bashrc + mc wrapper ===${X}"
echo -e "${C}Server:${X} $(hostname)"
echo

REPO="/root/Linux_Server_Public"
BASHRC_SRC="${REPO}/VPN/.bashrc"
WRAPPER_SRC="${REPO}/222/mc_lastdir_wrapper.sh"
BASHRC_DST="/root/.bashrc"
WRAPPER_DST="/root/.mc_lastdir_wrapper.sh"

# --- Step 1: git pull ---
echo -e "${C}[1/4]${X} git pull..."
cd "$REPO" && git pull --rebase 2>&1 | tail -n2
echo

# --- Step 2: remove immutable flag if set ---
echo -e "${C}[2/4]${X} Checking immutable flag on .bashrc..."
if lsattr "$BASHRC_DST" 2>/dev/null | grep -q '\-i\-'; then
    chattr -i "$BASHRC_DST" && echo -e "  ${Y}immutable flag removed${X}"
else
    echo -e "  ${G}no immutable flag${X}"
fi
echo

# --- Step 3: copy files ---
echo -e "${C}[3/4]${X} Copying files..."
cp "$BASHRC_SRC" "$BASHRC_DST"  && echo -e "  ${G}✔${X} .bashrc copied"
cp "$WRAPPER_SRC" "$WRAPPER_DST" && echo -e "  ${G}✔${X} mc_lastdir_wrapper.sh copied"
chmod +x "$WRAPPER_DST"         && echo -e "  ${G}✔${X} wrapper chmod +x"
echo

# --- Step 4: source ---
echo -e "${C}[4/4]${X} Applying aliases..."
# shellcheck disable=SC1090
source "$BASHRC_DST" && echo -e "  ${G}✔${X} .bashrc sourced"
echo

echo -e "${Y}=== DONE — aliases active ===${X}"
echo -e "Try: ${G}infooo${X}  |  ${G}sos${X}  |  ${G}mc${X}  |  ${G}00${X}"
