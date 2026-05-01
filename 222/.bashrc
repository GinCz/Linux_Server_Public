# clear — removed: was wiping MOTD on login

# ── PS1 prompt: RED for 222-DE-NetCup ─────────────────────────────────────────
PS1='\[\e[1;33m\]root@222-DE-NetCup\[\e[0m\]:\[\e[1;33m\]\w\[\e[0m\]# '

# ── MOTD: показываем ОДИН РАЗ за SSH-сессию ───────────────────────────────────
# Используем флаг-файл /tmp/motd_shown_<PID родителя>
# При переподключении PID меняется — MOTD снова показывается
_MOTD_FLAG="/tmp/motd_shown_${SSH_CLIENT// /_}"
if [ -n "$SSH_CONNECTION" ] && [ ! -f "$_MOTD_FLAG" ]; then
    touch "$_MOTD_FLAG"
    [ -f /root/Linux_Server_Public/222/motd_server.sh ] && bash /root/Linux_Server_Public/222/motd_server.sh
fi
unset _MOTD_FLAG

# ==============================================================================
# ALIASES — server 222-DE-NetCup
# ==============================================================================

# ── NAVIGATION ────────────────────────────────────────────────────────────────
alias 00='clear'
alias mc='/usr/bin/mc'
alias ..='cd ..'
alias ...='cd ../..'

# ── GIT ───────────────────────────────────────────────────────────────────────
alias save='cd /root/Linux_Server_Public && git add -A && git commit -m "auto: $(date +%Y-%m-%d_%H:%M)" && git push'
alias load='cd /root/Linux_Server_Public && git pull'
alias repo='cd /root/Linux_Server_Public && git pull'
alias secret='cd /root/Linux_Server_Public_Private && git pull'

# ── SERVER INFO ───────────────────────────────────────────────────────────────
alias infooo='bash /root/Linux_Server_Public/scripts/infooo.sh'
alias allinfo='bash /root/Linux_Server_Public/scripts/infooo.sh'
alias allservers='bash /root/Linux_Server_Public/scripts/backup_all_servers.sh --status 2>/dev/null || echo "use: allinfo"'

# ── SCAN & SECURITY ───────────────────────────────────────────────────────────
alias antivir='bash /root/Linux_Server_Public/scripts/scan_clamav.sh'
alias fight='bash /root/Linux_Server_Public/scripts/block_bots.sh'
alias banlog='grep "Ban\|block\|NOTICE" /var/log/crowdsec.log 2>/dev/null | tail -40 || journalctl -u crowdsec --no-pager | tail -40'
alias cleanup='bash /root/Linux_Server_Public/222/backup_clean.sh'

# ── SERVER LOGS (SOS) ─────────────────────────────────────────────────────────
alias sos='bash /root/Linux_Server_Public/222/sos.sh'
alias sos3='bash /root/Linux_Server_Public/222/sos.sh 3'
alias sos24='bash /root/Linux_Server_Public/222/sos.sh 24'
alias watchdog='bash /root/Linux_Server_Public/scripts/php_fpm_watchdog.sh'

# ── WORDPRESS ─────────────────────────────────────────────────────────────────
alias wpupd='bash /root/Linux_Server_Public/scripts/deploy_htaccess.sh'
alias wpcron='bash /root/Linux_Server_Public/scripts/run_all_wp_cron.sh'
alias wphealth='echo "WP health: check FastPanel or run: wp cron event list"'
alias domains='bash /root/Linux_Server_Public/scripts/domains.sh'

# ── CRYPTO-BOT ────────────────────────────────────────────────────────────────
alias tr='cd /root/trading-bot && docker compose up -d && echo "[OK] Bot started"'
alias reset='cd /root/trading-bot && docker compose restart && echo "[OK] Bot restarted"'
alias clog100='cd /root/trading-bot && docker compose logs --tail=100 -f'
alias f5bot='bash /root/Linux_Server_Public/222/docker_backup.sh'
alias f9bot='bash /root/Linux_Server_Public/222/docker_restore.sh 2>/dev/null || echo "restore script: 222/docker_restore.sh"'

# ── VPN / BACKUP ──────────────────────────────────────────────────────────────
alias f5vpn='bash /root/Linux_Server_Public/VPN/vpn_docker_backup.sh'
alias allvpnstat='bash /root/Linux_Server_Public/VPN/amnezia_stat.sh'
alias backup='bash /root/Linux_Server_Public/222/backup_clean.sh'
alias aws-test='bash /root/Linux_Server_Public/scripts/aws_ping.sh'

# ── SYSTEM / TOOLS ────────────────────────────────────────────────────────────
alias mailclean='bash /root/Linux_Server_Public/scripts/mail_queue.sh'
alias nginx-reload='nginx -t && systemctl reload nginx && echo "[OK] nginx reloaded"'

