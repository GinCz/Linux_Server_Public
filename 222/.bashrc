# ~/.bashrc — 222-DE-NetCup
# Version: v2026-03-23
# PS1 color: yellow (1;93m)

alias 00='clear'
alias m='mc'
alias infooo='/opt/server_tools/scripts/infooo.sh'
alias load='bash /opt/server_tools/scripts/load.sh && source /root/.bashrc'
alias save='bash /opt/server_tools/scripts/save.sh'
alias sos='/opt/server_tools/scripts/server_audit.sh'
alias sos1='/opt/server_tools/scripts/server_audit.sh 1h'
alias sos3='/opt/server_tools/scripts/server_audit.sh 3h'
alias sos6='/opt/server_tools/scripts/server_audit.sh 6h'
alias sos24='/opt/server_tools/scripts/server_audit.sh 24h'
alias sos120='/opt/server_tools/scripts/server_audit.sh 120h'
alias fight='/opt/server_tools/scripts/block_bots.sh'
alias domains='/opt/server_tools/scripts/domains.sh'
alias antivir='bash /opt/server_tools/scripts/antivir.sh'
alias antivir-stop='bash /opt/server_tools/scripts/antivir.sh --stop'
alias antivir-status='bash /opt/server_tools/scripts/antivir.sh --status'
alias banlog='cscli alerts list -l 20'
alias backup='/opt/server_tools/scripts/system_backup.sh'

# v2026-03-17
c303() {
    local tmp="/tmp/screen_303_$(date +%Y-%m-%d_%H-%M-%S).txt"
    if [ -n "$TMUX" ] && command -v tmux >/dev/null 2>&1; then
        tmux capture-pane -p -S - > "$tmp"
    elif [ -n "$STY" ] && command -v screen >/dev/null 2>&1; then
        screen -X hardcopy -h "$tmp"
    else
        echo "c303: not in tmux/screen, cannot capture full screen"
        return 1
    fi
    if command -v base64 >/dev/null 2>&1; then
        printf '\033]52;c;%s\a' "$(base64 -w 0 < "$tmp")"
        echo
        echo "c303: copied to local clipboard if terminal supports OSC52"
    fi
    echo "c303: saved file -> $tmp"
}

# v2026-03-17
_303_start_log() {
    local out="/root/ssh_full_$(date +%Y-%m-%d_%H-%M-%S).log"
    echo "303: logging started -> $out"
    echo "303: type exit to stop"
    script -q -f "$out"
}

source /opt/server_tools/shared_aliases.sh
export PS1='\[\e[1;93m\]\u@\h:\w\$\[\e[m\] '
