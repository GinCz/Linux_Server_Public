#!/usr/bin/env bash
TYPE="${1:-222}"
mkdir -p /root/.config/mc /etc/mc /usr/local/bin

unalias -a 2>/dev/null

cat << 'ALIASEOF' >> /root/.bashrc

# ================= MOTD ALIASES (v.2026.08.17) =================
alias sos='/usr/local/bin/sos'
alias antivir='/usr/local/bin/scan_clamav.sh'
alias cleanup='/usr/local/bin/server_cleanup.sh'
alias fight='/usr/local/bin/block_bots.sh'
alias backup='/usr/local/bin/system_backup.sh'
alias infooo='/usr/local/bin/infooo.sh'
alias banlog='/usr/local/bin/banlog.sh'
alias banlist='cscli decisions list 2>/dev/null || echo "CrowdSec not installed"'
alias banunblock='cscli decisions delete --ip'
alias banblock='cscli decisions add --duration 24h --ip'
alias save='bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/save.sh)'
alias load='bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/load.sh)'
alias repo='cd /root/Linux_Server_Public'
alias secret='cd /root/Secret_Privat 2>/dev/null || cd /root/Linux_Server_Public_Private 2>/dev/null || echo "Private repo directory not found"'
alias aw='bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/amnezia_stat.sh)'
alias ports='ss -tulnp'
ALIASEOF

if [ "$TYPE" = "222" ]; then
cat << 'ALIASEOF' >> /root/.bashrc
alias wpupd='/usr/local/bin/wp_update_all.sh'
alias wpcron='/usr/local/bin/run_all_wp_cron.sh'
alias domains='/usr/local/bin/domains.sh'
alias mailclean='/usr/local/bin/mailclean.sh'
alias watchdog='/usr/local/bin/php_fpm_watchdog.sh'
alias setphp='bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/set_php_fpm_limits.sh)'
alias wphealth='sudo -u fastuser wp --path=/var/www/$(ls /var/www | grep -v "lost+found\|fastuser" | head -1)/data/www/$(ls /var/www/*/data/www 2>/dev/null | head -1) doctor check 2>/dev/null || echo "WP Health check complete."'
alias nginx-reload='nginx -t && systemctl reload nginx'
alias fpm-reload='systemctl reload php8.3-fpm 2>/dev/null || systemctl reload php8.1-fpm 2>/dev/null'
alias reload-all='nginx -t && systemctl reload nginx && systemctl restart php*-fpm 2>/dev/null'
alias bot_st='cd /root/crypto-docker 2>/dev/null && docker compose ps 2>/dev/null || systemctl status cryptobot 2>/dev/null || echo "CryptoBot service not found"'
ALIASEOF
fi
