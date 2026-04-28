cat > /usr/local/bin/clean_vpn_reports.sh << 'EOF'
#!/usr/bin/env bash
TARGET_DIR="/var/www/gincz/data/www/gincz.com/server-set/VPN_servers"
if [ -d "$TARGET_DIR" ]; then
    find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} +
fi
EOF
chmod +x /usr/local/bin/clean_vpn_reports.sh
crontab -l 2>/dev/null | grep -v 'clean_vpn_reports.sh' > /tmp/root.cron || true
echo "0 3 * * * /usr/local/bin/clean_vpn_reports.sh >/dev/null 2>&1" >> /tmp/root.cron
crontab /tmp/root.cron
rm -f /tmp/root.cron
