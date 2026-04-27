# 222 PERMANENT YELLOW — loads on SSH login
# Version: v2026-04-27
# = Rooted by VladiMIR | AI =
#
# HOW TO APPLY (copy to server):
#   cp /root/Linux_Server_Public/222/.bash_profile /root/.bash_profile

# Step 1: Show MOTD banner (aliases menu)
if [ -f /etc/profile.d/motd_server.sh ]; then
    bash /etc/profile.d/motd_server.sh
fi

# Step 2: Load aliases from repo
if [ -f /root/Linux_Server_Public/222/.bashrc ]; then
    source /root/Linux_Server_Public/222/.bashrc
fi

export PS1="\[\033[01;33m\]\u@\h:\w\[\033[00m\]\$ "
