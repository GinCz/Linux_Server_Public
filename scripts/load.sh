#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  load.sh | [v2026-07-30]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Pull latest changes from GitHub, reinstall SOS and reload shell
# Servers     : All Linux Nodes
# Usage       : bash scripts/load.sh
# ==========================================================================================
REPO="/root/Linux_Server_Public"
SOS_SRC="$REPO/scripts/sos.sh"
SOS_BIN="/usr/local/bin/sos"

if [ ! -d "$REPO/.git" ]; then
    echo "ERROR: $REPO is not a git repo. Clone first:"
    echo "  git clone https://github.com/GinCz/Linux_Server_Public.git $REPO"
    exit 1
fi

cd "$REPO" || exit 1
echo "=== git pull origin main ==="
git pull origin main --no-rebase --no-edit

# Auto-reinstall sos binary after pull
if [ -f "$SOS_SRC" ]; then
    cp "$SOS_SRC" "$SOS_BIN"
    chmod +x "$SOS_BIN"
    SOS_VER=$(grep -oP 'v\.\K[0-9.]+' "$SOS_SRC" | head -1)
    echo -e "\033[1;36m   /usr/local/bin/sos updated (v${SOS_VER:-?})\033[0m"
fi

# Auto-reinstall style binary
cat << 'STYLEEOF' > /usr/local/bin/style
#!/usr/bin/env bash
if [ -f /root/Linux_Server_Public/scripts/new_server_install.sh ]; then
    bash /root/Linux_Server_Public/scripts/new_server_install.sh "$@"
else
    bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh) "$@"
fi
STYLEEOF
chmod +x /usr/local/bin/style
ln -sf /usr/local/bin/style /usr/local/bin/theme
echo -e "\033[1;36m   /usr/local/bin/style & theme updated\033[0m"

# Auto-refresh MOTD and Aliases
if [ -f "$REPO/scripts/apply_aliases.sh" ]; then
    bash "$REPO/scripts/apply_aliases.sh" 2>/dev/null || true
fi

echo ""
echo -e "\033[1;32m✅ LOADED OK — $(hostname) — $(date '+%Y-%m-%d %H:%M')\033[0m"
echo -e "\033[1;33mReloading shell (exec bash -l)...\033[0m"
echo ""

exec bash -l

# = Rooted by VladiMIR | AI = v2026-07-30 = github.com/GinCz/Linux_Server_Public
