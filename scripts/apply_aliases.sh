#!/usr/bin/env bash
TYPE="${1:-222}"
SCRIPTS_DIR="/root/Linux_Server_Public/scripts"
mkdir -p /root/.config/mc /etc/mc /usr/local/bin

# ── Auto-deploy executable binaries to /usr/local/bin ──────────
if [ -d "$SCRIPTS_DIR" ]; then
    for script in "$SCRIPTS_DIR"/*.sh; do
        [ -f "$script" ] || continue
        bname=$(basename "$script")
        cp -f "$script" "/usr/local/bin/$bname" 2>/dev/null || true
        chmod +x "/usr/local/bin/$bname" 2>/dev/null || true
    done
    [ -f "$SCRIPTS_DIR/sos.sh" ] && cp -f "$SCRIPTS_DIR/sos.sh" /usr/local/bin/sos && chmod +x /usr/local/bin/sos
    [ -f "$SCRIPTS_DIR/infooo.sh" ] && cp -f "$SCRIPTS_DIR/infooo.sh" /usr/local/bin/infooo && chmod +x /usr/local/bin/infooo
    [ -f "$SCRIPTS_DIR/upd.sh" ] && cp -f "$SCRIPTS_DIR/upd.sh" /usr/local/bin/upd && chmod +x /usr/local/bin/upd
    [ -f "$SCRIPTS_DIR/load.sh" ] && cp -f "$SCRIPTS_DIR/load.sh" /usr/local/bin/load && chmod +x /usr/local/bin/load
    [ -f "$SCRIPTS_DIR/save.sh" ] && cp -f "$SCRIPTS_DIR/save.sh" /usr/local/bin/save && chmod +x /usr/local/bin/save
    [ -f "$SCRIPTS_DIR/scan_clamav.sh" ] && cp -f "$SCRIPTS_DIR/scan_clamav.sh" /usr/local/bin/antivir && chmod +x /usr/local/bin/antivir
fi

cat << 'STYLEEOF' > /usr/local/bin/style
#!/usr/bin/env bash
if [ -f /root/Linux_Server_Public/scripts/new_server_install.sh ]; then
    bash /root/Linux_Server_Public/scripts/new_server_install.sh "$@"
else
    bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh) "$@"
fi
STYLEEOF
chmod +x /usr/local/bin/style
ln -sf /usr/local/bin/style /usr/local/bin/theme

unalias -a 2>/dev/null

cat << 'ALIASEOF' >> /root/.bashrc

# ================= MOTD ALIASES (v.2026.08.20) =================
alias sos='/usr/local/bin/sos 1h'
alias antivir='/usr/local/bin/scan_clamav.sh'
alias cleanup='/usr/local/bin/server_cleanup.sh'
alias fight='/usr/local/bin/block_bots.sh'
alias backup='/usr/local/bin/system_backup.sh'
alias infooo='/usr/local/bin/infooo.sh'
alias banlog='/usr/local/bin/banlog.sh'
alias upd='/usr/local/bin/upd.sh'
alias banlist='cscli decisions list 2>/dev/null || echo "CrowdSec not installed"'
alias banunblock='cscli decisions delete --ip'
alias banblock='cscli decisions add --duration 24h --ip'
alias save='bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/save.sh)'
alias load='bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/load.sh)'
alias repo='cd /root/Linux_Server_Public'
alias secret='cd /root/Secret_Privat 2>/dev/null || cd /root/Linux_Server_Public_Private 2>/dev/null || echo "Private repo directory not found"'
alias aw='/usr/local/bin/amnezia_stat.sh'
alias ports='ss -tulnp'
alias style='bash /root/Linux_Server_Public/scripts/new_server_install.sh 2>/dev/null || bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh)'
alias theme='style'
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
