clear
if [ -f ~/Linux_Server_Public/scripts/shared_aliases_109.sh ]; then
    . ~/Linux_Server_Public/scripts/shared_aliases_109.sh
fi

# bright magenta prompt for 109-RU-FastVDS
PS1='\[\e[95m\]root@109-RU-FastVDS\[\e[0m\]:\[\e[33m\]\w\[\e[0m\]# '

if [ -f ~/Linux_Server_Public/109/motd_server.sh ]; then
    bash ~/Linux_Server_Public/109/motd_server.sh
fi

