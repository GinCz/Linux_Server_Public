#!/bin/bash
# ============================================================
# = Rooted by VladiMIR + AI | v.2026.06.10                  =
# = github.com/GinCz                                         =
# = update_scripts.sh — auto-update all scripts from GitHub  =
# ============================================================

REPO="GinCz/Linux_Server_Public"
BRANCH="main"
SCRIPTS_DIR_URL="https://api.github.com/repos/${REPO}/contents/scripts?ref=${BRANCH}"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}/scripts"
INSTALL_DIR="/usr/local/bin"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Root check ────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] Run as root: sudo bash update_scripts.sh${NC}"
    exit 1
fi

# ─── Dependencies ──────────────────────────────────────────
for cmd in curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${YELLOW}[INFO] Installing missing dependency: $cmd${NC}"
        apt-get install -y "$cmd" -qq
    fi
done

echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║       GitHub Script Updater — GinCz/Linux_Server     ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo -e "  ${CYAN}Repo  :${NC} https://github.com/${REPO}"
echo -e "  ${CYAN}Branch:${NC} ${BRANCH}"
echo -e "  ${CYAN}Target:${NC} ${INSTALL_DIR}"
echo ""

# ─── Fetch file list from GitHub API ───────────────────────
echo -e "${YELLOW}[→] Fetching script list from GitHub...${NC}"
API_RESPONSE=$(curl -fsSL "${SCRIPTS_DIR_URL}")

if [[ -z "$API_RESPONSE" ]] || echo "$API_RESPONSE" | jq -e '.message' &>/dev/null; then
    echo -e "${RED}[ERROR] Failed to reach GitHub API. Check internet connection.${NC}"
    echo "$API_RESPONSE" | jq -r '.message' 2>/dev/null
    exit 1
fi

# Only .sh files
SCRIPTS=$(echo "$API_RESPONSE" | jq -r '.[] | select(.name | endswith(".sh")) | .name')

if [[ -z "$SCRIPTS" ]]; then
    echo -e "${RED}[ERROR] No .sh files found in scripts/ directory.${NC}"
    exit 1
fi

COUNT=$(echo "$SCRIPTS" | wc -l)
echo -e "${GREEN}[✓] Found ${COUNT} scripts to install.${NC}"
echo ""

# ─── Download & install ────────────────────────────────────
INSTALLED=0
FAILED=0
FAILED_LIST=()

while IFS= read -r script; do
    DEST="${INSTALL_DIR}/${script}"
    URL="${RAW_BASE}/${script}"

    printf "  ${CYAN}%-45s${NC}" "${script}"

    if curl -fsSL "${URL}" -o "${DEST}" 2>/dev/null; then
        chmod +x "${DEST}"
        echo -e "${GREEN}✓ installed${NC}"
        ((INSTALLED++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((FAILED++))
        FAILED_LIST+=("$script")
    fi
done <<< "$SCRIPTS"

# ─── Summary ───────────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}✓ Installed : ${INSTALLED}${NC}"
if [[ $FAILED -gt 0 ]]; then
    echo -e "  ${RED}✗ Failed    : ${FAILED}${NC}"
    echo -e "  ${RED}  Failed scripts:${NC}"
    for f in "${FAILED_LIST[@]}"; do
        echo -e "    ${RED}• ${f}${NC}"
    done
else
    echo -e "  ${GREEN}✗ Failed    : 0${NC}"
fi
echo -e "${BOLD}══════════════════════════════════════════════════════${NC}"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}[✓] All scripts updated successfully!${NC}"
    echo -e "${CYAN}    Run any script by name, e.g.: sos.sh | upd.sh | infooo.sh${NC}"
else
    echo -e "${YELLOW}[!] Some scripts failed. Check internet connection or GitHub availability.${NC}"
fi

echo ""
