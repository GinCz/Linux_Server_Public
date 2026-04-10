# 109 PERMANENT PINK — loads on SSH login
# = Rooted by VladiMIR | AI = | v2026-04-10
# ВАЖНО: этот файл грузит .bashrc из РЕПОЗИТОРИЯ, не из /root/.bashrc
if [ -f /root/Linux_Server_Public/109/.bashrc ]; then
    source /root/Linux_Server_Public/109/.bashrc
fi
export PS1="\[\e[38;5;217m\]\u@\h:\w\[\e[m\]\$ "
