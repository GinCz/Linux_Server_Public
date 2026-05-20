# =============================================================
# ~/.bash_profile — server 109-RU-FastVDS (212.109.223.109)
# Loads on SSH login (interactive login shell)
# Version: v2026.05.21
# = Rooted by VladiMIR + AI | v.2026.05.21 | github.com/GinCz =
#
# HOW TO APPLY (copy to server):
#   cp /root/Linux_Server_Public/109/.bash_profile /root/.bash_profile
#   cp /root/Linux_Server_Public/109/.bashrc /root/.bashrc
# =============================================================

# Step 1: Show MOTD banner ONCE per session (flag prevents duplicate)
if [ -z "$MOTD_SHOWN" ] && [ -f /etc/profile.d/motd_server.sh ]; then
    export MOTD_SHOWN=1
    bash /etc/profile.d/motd_server.sh
fi

# Step 2: Load aliases (only when sourced, never runs MOTD again)
if [ -f /root/Linux_Server_Public/109/server_109.sh ]; then
    source /root/Linux_Server_Public/109/server_109.sh
fi

export PS1="\[\e[38;5;217m\]\u@\h:\w\[\e[m\]\$ "
