# clear — removed: was wiping MOTD on login

# ── PS1 prompt: YELLOW for 222-EU-NetCup ──────────────────────────────────────
PS1='\[\e[1;33m\]root@222-EU-NetCup\[\e[0m\]:\[\e[1;33m\]\w\[\e[0m\]# '

# ── MOTD: показываем ОДИН РАЗ за SSH-сессию ──────────────────────────────────
_MOTD_FLAG="/tmp/motd_shown_${SSH_CLIENT// /_}"
if [ -n "$SSH_CONNECTION" ] && [ ! -f "$_MOTD_FLAG" ]; then
    touch "$_MOTD_FLAG"
    [ -f /root/Linux_Server_Public/222/motd_server.sh ] && bash /root/Linux_Server_Public/222/motd_server.sh
fi
unset _MOTD_FLAG

# ==============================================================================
# ALIASES — server 222-EU-NetCup
# ==============================================================================

# ── NAVIGATION ──────────────────────────────────────────────────────────────────────────
alias 00='clear'
alias mc='/usr/bin/mc'
alias ..='cd ..'
alias ...='cd ../..'

# ── GIT ───────────────────────────────────────────────────────────────────────────────
alias save='cd /root/Linux_Server_Public && git add -A && git commit -m "auto: $(date +%Y-%m-%d_%H:%M)" && git push'
alias load='bash /root/Linux_Server_Public/scripts/load.sh'
alias repo='cd /root/Linux_Server_Public && git pull'
alias secret='cd /root/Linux_Server_Public_Private && git pull'

# ── SERVER INFO ─────────────────────────────────────────────────────────────────────
alias infooo='bash /root/Linux_Server_Public/scripts/infooo.sh'
alias allinfo='bash /root/Linux_Server_Public/109/all_servers_info.sh'

# ── SCAN & SECURITY ────────────────────────────────────────────────────────────────
alias antivir='bash /root/Linux_Server_Public/scripts/scan_clamav.sh'
alias fight='bash /root/Linux_Server_Public/scripts/block_bots.sh'
alias banlog='grep "Ban\|block\|NOTICE" /var/log/crowdsec.log 2>/dev/null | tail -40 || journalctl -u crowdsec --no-pager | tail -40'
alias cleanup='bash /root/Linux_Server_Public/222/backup_clean.sh'

# ── SERVER LOGS (SOS) ──────────────────────────────────────────────────────────────
alias sos='bash /root/Linux_Server_Public/scripts/sos-fastpanel.sh 1h'
alias sos1='bash /root/Linux_Server_Public/scripts/sos-fastpanel.sh 1h'
alias sos3='bash /root/Linux_Server_Public/scripts/sos-fastpanel.sh 3h'
alias sos24='bash /root/Linux_Server_Public/scripts/sos-fastpanel.sh 24h'
alias sos120='bash /root/Linux_Server_Public/scripts/sos-fastpanel.sh 120h'
alias watchdog='bash /root/Linux_Server_Public/scripts/php_fpm_watchdog.sh'

# ── WORDPRESS ────────────────────────────────────────────────────────────────────────
alias wpupd='bash /root/Linux_Server_Public/222/wp_update_all.sh'
alias wpcron='bash /root/Linux_Server_Public/scripts/run_all_wp_cron.sh'
alias wphealth='echo "WP health: check FastPanel or run: wp cron event list"'
alias domains='bash /root/Linux_Server_Public/scripts/domains.sh'

# ── CRYPTO-BOT (source: Crypto_BOT/bashrc_aliases.sh) ───────────────────────────
alias bot='bash /root/crypto-docker/scripts/tr_docker.sh'
alias reset='bash /root/crypto-docker/scripts/reset.sh'
alias torg='bash /root/crypto-docker/scripts/torg.sh 1'
alias torg1='bash /root/crypto-docker/scripts/torg.sh 1'
alias torg3='bash /root/crypto-docker/scripts/torg.sh 3'
alias torg24='bash /root/crypto-docker/scripts/torg.sh 24'
alias torg120='bash /root/crypto-docker/scripts/torg.sh 120'
alias clog='docker logs crypto-bot --tail 40'
alias clog100='docker logs crypto-bot --tail 100'
alias f5bot='bash /root/Linux_Server_Public/222/docker_backup.sh'
alias f9bot='bash /root/Linux_Server_Public/222/docker_restore.sh 2>/dev/null || echo "restore script: 222/docker_restore.sh"'

# ── BACKUP ────────────────────────────────────────────────────────────────────────────
alias backup='bash /root/Linux_Server_Public/222/backup_clean.sh'
alias aws-test='bash /root/Linux_Server_Public/scripts/aws_ping.sh'

# ── SYSTEM / TOOLS ──────────────────────────────────────────────────────────────────────
alias mailclean='bash /root/Linux_Server_Public/scripts/mail_queue.sh'
alias nginx-reload='nginx -t && systemctl reload nginx && echo "[OK] nginx reloaded"'
alias f5servers='bash /root/Linux_Server_Public/222/backup_servers.sh'
alias f9servers='bash /root/Linux_Server_Public/222/restore_servers.sh'
alias f2='bash /root/Linux_Server_Public/scripts/f2.sh'
