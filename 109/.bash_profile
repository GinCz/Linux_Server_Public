# 109 PERMANENT PINK — loads on SSH login
# Version: v2026-04-27
# = Rooted by VladiMIR | AI =
#
# HOW TO APPLY (copy to server):
#   cp /root/Linux_Server_Public/109/.bash_profile /root/.bash_profile
#
# WHY bash_profile and not /etc/profile.d/ directly:
#   When ~/.bash_profile exists, Ubuntu reads IT instead of /etc/profile.
#   Files in /etc/profile.d/ are only executed via /etc/profile.
#   So we call MOTD directly here — bypassing /etc/profile entirely.

# Step 1: Show MOTD banner (aliases menu)
if [ -f /etc/profile.d/motd_server.sh ]; then
    bash /etc/profile.d/motd_server.sh
fi

# Step 2: Load aliases from repo
if [ -f /root/Linux_Server_Public/109/.bashrc ]; then
    source /root/Linux_Server_Public/109/.bashrc
fi

export PS1="\[\e[38;5;217m\]\u@\h:\w\[\e[m\]\$ "
