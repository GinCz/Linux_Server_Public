#!/bin/bash
# =============================================================================
# amnezia_stat_install.sh v2026-04-13k
# Description : One-time install of amnezia_stat.sh on any VPN node.
#               - Installs jq if missing
#               - Writes amnezia_stat.sh to /root/Linux_Server_Public/VPN/
#               - Ensures alias 'aw' is set in ~/.bashrc (via shared_aliases.sh)
#               - Reloads ~/.bashrc
# Author      : VladiMIR (GinCz)
# GitHub      : https://github.com/GinCz/Linux_Server_Public
# Usage       : bash /root/Linux_Server_Public/VPN/amnezia_stat_install.sh
#               OR run the standalone one-liner below (no repo required)
# =============================================================================
#
# STANDALONE ONE-LINER (copy-paste to any fresh VPN server, no git needed):
#
# command -v jq &>/dev/null || { apt-get install -y jq --no-install-recommends 2>/dev/null || { wget -qO /usr/local/bin/jq https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 && chmod +x /usr/local/bin/jq; }; }; cat > /root/amnezia_stat.sh << 'EOF'
# #!/bin/bash
# clear
# CY="\033[1;96m";YL="\033[1;93m";GN="\033[1;92m";RD="\033[1;91m";WH="\033[1;97m";OR="\033[38;5;214m";X="\033[0m"
# HR="\u2550\u2550..."   <-- see amnezia_stat.sh for full content
# EOF
# chmod +x /root/amnezia_stat.sh && bash /root/amnezia_stat.sh
#
# =============================================================================

set -e

echo "=== amnezia_stat install v2026-04-13k ==="

# --- Step 1: ensure jq is available ---
if ! command -v jq &>/dev/null; then
  echo "[1/4] Installing jq..."
  apt-get install -y jq --no-install-recommends 2>/dev/null || \
  { wget -qO /usr/local/bin/jq \
      https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 \
    && chmod +x /usr/local/bin/jq; }
  echo "      jq installed: $(jq --version)"
else
  echo "[1/4] jq already installed: $(jq --version)"
fi

# --- Step 2: verify the script is present (git pull should have done this) ---
SCRIPT="/root/Linux_Server_Public/VPN/amnezia_stat.sh"
if [[ -f "$SCRIPT" ]]; then
  chmod +x "$SCRIPT"
  echo "[2/4] Script found and marked executable: $SCRIPT"
else
  echo "[2/4] ERROR: $SCRIPT not found. Run 'load' (git pull) first."
  exit 1
fi

# --- Step 3: ensure alias 'aw' exists in ~/.bashrc ---
# The canonical alias lives in scripts/shared_aliases.sh and is sourced by
# VPN/.bashrc. After 'load' this is already active. This step is a safety net:
# if for any reason the alias is missing, we add it directly to ~/.bashrc.
ALIAS_LINE="alias aw='bash /root/Linux_Server_Public/VPN/amnezia_stat.sh'"
SHARED="/root/Linux_Server_Public/scripts/shared_aliases.sh"

if grep -q "alias aw=" ~/.bashrc 2>/dev/null || \
   (grep -q "shared_aliases" ~/.bashrc 2>/dev/null && \
    grep -q "alias aw=" "$SHARED" 2>/dev/null); then
  echo "[3/4] Alias 'aw' already present (via shared_aliases or .bashrc)"
else
  echo "[3/4] Adding alias 'aw' to ~/.bashrc..."
  # Remove any old 'alias aw=' line first to avoid duplicates
  sed -i '/^alias aw=/d' ~/.bashrc
  echo "$ALIAS_LINE" >> ~/.bashrc
  echo "      Done."
fi

# --- Step 4: reload shell config ---
echo "[4/4] Reloading ~/.bashrc..."
# shellcheck disable=SC1090
source ~/.bashrc 2>/dev/null || true

echo ""
echo "=== Installation complete ==="
echo "    Run:  aw"
echo "    Or:   bash $SCRIPT"
echo ""

# --- Run immediately after install ---
bash "$SCRIPT"

echo "========================================="
echo "📘 HOW TO ADD USERS (READ THIS):"
echo "https://github.com/GinCz/Linux_Server_Public/tree/main/xray"
echo "========================================="

