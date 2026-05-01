# 222 PERMANENT YELLOW — loads on SSH login
# Version: v2026-05-01
# = Rooted by VladiMIR | AI =
#
# HOW TO APPLY (copy to server):
#   cp /root/Linux_Server_Public/222/.bash_profile /root/.bash_profile

# Step 1: Load aliases from repo .bashrc (contains MOTD + aliases + PS1)
if [ -f /root/Linux_Server_Public/222/.bashrc ]; then
    source /root/Linux_Server_Public/222/.bashrc
fi

# Step 2: Force YELLOW PS1 (overrides anything set above)
export PS1="\[\033[01;33m\]\u@\h:\w\[\033[00m\]\$ "
