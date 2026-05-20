# =============================================================
# ~/.bash_profile — server 109-RU-FastVDS (212.109.223.109)
# Loads on SSH login (interactive login shell)
# Version: v2026.05.21
# = Rooted by VladiMIR + AI | v.2026.05.21 | github.com/GinCz =
#
# MOTD is shown automatically via /etc/profile.d/motd_server.sh
# DO NOT add manual MOTD call here — it causes double banner!
#
# HOW TO APPLY (copy to server):
#   cp /root/Linux_Server_Public/109/.bash_profile /root/.bash_profile
# =============================================================

# Load aliases only — MOTD runs automatically via /etc/profile.d/
if [ -f /root/Linux_Server_Public/109/server_109.sh ]; then
    source /root/Linux_Server_Public/109/server_109.sh
fi

export PS1="\[\e[38;5;217m\]\u@\h:\w\[\e[m\]\$ "
