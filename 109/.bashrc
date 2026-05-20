# =============================================================
# ~/.bashrc — server 109-RU-FastVDS (212.109.223.109)
# MOTD runs once via /etc/profile.d/motd_server.sh
# Do NOT call motd_server.sh here — causes duplicate/flicker
# =============================================================

# Load aliases
if [ -f ~/Linux_Server_Public/scripts/shared_aliases_109.sh ]; then
    . ~/Linux_Server_Public/scripts/shared_aliases_109.sh
fi

# Prompt: bright magenta for 109-RU-FastVDS
PS1='\[\e[95m\]root@109-RU-FastVDS\[\e[0m\]:\[\e[33m\]\w\[\e[0m\]# '
