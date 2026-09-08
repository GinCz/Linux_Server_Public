#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  load.sh | [v2026-09-08]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Bulletproof Git sync & deployment tool for all Linux servers
# Servers     : All Linux Nodes (222, 109, VPN nodes, etc.)
# Usage       : load (or bash scripts/load.sh)
# ==========================================================================================

REPO="/root/Linux_Server_Public"
SOS_SRC="$REPO/scripts/sos.sh"
SOS_BIN="/usr/local/bin/sos"
REMOTE_HTTPS="https://github.com/GinCz/Linux_Server_Public.git"
REMOTE_SSH="git@github.com:GinCz/Linux_Server_Public.git"

echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " 🚀 \033[1;37mBULLETPROOF LOAD\033[0m | Syncing \033[1;36m$(hostname)\033[0m with \033[1;33mGitHub: GinCz/Linux_Server_Public\033[0m..."
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

# 1. Check / Clone repo if missing
if [ ! -d "$REPO/.git" ]; then
    echo -e "⚠️  Repo not found in $REPO. Cloning..."
    mkdir -p "$REPO"
    if ! git clone "$REMOTE_HTTPS" "$REPO" 2>/dev/null; then
        git clone "$REMOTE_SSH" "$REPO" || {
            echo -e "\033[1;31m❌ FATAL: Failed to clone repository!\033[0m"
            exit 1
        }
    fi
fi

cd "$REPO" || exit 1

# 2. Cleanup stale git lock files & unfinished operations
rm -f "$REPO/.git/index.lock" "$REPO/.git/refs/heads/*.lock" "$REPO/.git/ORIG_HEAD.lock" 2>/dev/null || true
git merge --abort 2>/dev/null || true
git rebase --abort 2>/dev/null || true
git am --abort 2>/dev/null || true

# 3. Prevent permission / filemode conflicts from causing dirty tree
git config core.fileMode false
git config pull.rebase false

# 4. Fetch latest from origin
echo -e "📥 Fetching latest commits from GitHub..."
FETCH_OK=0
if git fetch origin main --prune 2>/dev/null; then
    FETCH_OK=1
elif git fetch "$REMOTE_HTTPS" main --prune 2>/dev/null; then
    FETCH_OK=1
elif git fetch "$REMOTE_SSH" main --prune 2>/dev/null; then
    FETCH_OK=1
fi

if [ $FETCH_OK -eq 0 ]; then
    echo -e "\033[1;31m❌ Warning: git fetch failed (network or auth issue).\033[0m"
    echo -e "Attempting git pull directly..."
    git pull origin main --no-rebase --no-edit || true
else
    # 5. Bulletproof Hard Reset to origin/main (Discards local file changes/conflicts cleanly)
    git checkout -f main 2>/dev/null || true
    git reset --hard origin/main
    git clean -fd 2>/dev/null || true
fi

# 6. Ensure all scripts are executable
find "$REPO" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true

# 7. Update binaries in /usr/local/bin
mkdir -p /usr/local/bin

# Update load and save binaries
cp -f "$REPO/scripts/load.sh" /usr/local/bin/load 2>/dev/null && chmod +x /usr/local/bin/load
cp -f "$REPO/scripts/save.sh" /usr/local/bin/save 2>/dev/null && chmod +x /usr/local/bin/save

# Auto-reinstall sos binary
if [ -f "$SOS_SRC" ]; then
    cp -f "$SOS_SRC" "$SOS_BIN"
    chmod +x "$SOS_BIN"
    SOS_VER=$(grep -oP 'v\.\K[0-9.]+' "$SOS_SRC" | head -1)
    echo -e "   \033[1;36m/usr/local/bin/sos updated (v${SOS_VER:-?})\033[0m"
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
echo -e "   \033[1;36m/usr/local/bin/style & theme updated\033[0m"

# 8. Auto-refresh MOTD and Aliases
if [ -f "$REPO/scripts/apply_aliases.sh" ]; then
    bash "$REPO/scripts/apply_aliases.sh" 2>/dev/null || true
fi

CURRENT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
COMMIT_MSG=$(git log -1 --pretty=%B 2>/dev/null | head -1)

echo ""
echo -e "\033[1;32m✅ LOADED OK [${CURRENT_COMMIT}] — $(hostname) — $(date '+%Y-%m-%d %H:%M')\033[0m"
[ -n "$COMMIT_MSG" ] && echo -e "   \033[0;37mLast commit: ${COMMIT_MSG}\033[0m"
echo -e "\033[1;33mReloading shell (exec bash -l)...\033[0m"
echo ""

exec bash -l

# = Rooted by VladiMIR | AI = v2026-09-08 = github.com/GinCz/Linux_Server_Public
