#!/usr/bin/env bash
# Description: Creates global symlinks for all new mini-tools.
ln -sf /root/scripts/System/change_hostname.sh /usr/local/bin/chname
ln -sf /root/scripts/System/quick_status.sh /usr/local/bin/qstat
ln -sf /root/scripts/System/mail_queue.sh /usr/local/bin/mailclean
ln -sf /root/scripts/System/aws_ping.sh /usr/local/bin/awsping
ln -sf /root/scripts/FastPanel/install_panel.sh /usr/local/bin/fpinstall
ln -sf /root/scripts/FastPanel/optimize_session.sh /usr/local/bin/fpopt
ln -sf /root/scripts/FastPanel/mogwai_users.sh /usr/local/bin/fpusers
ln -sf /root/scripts/WordPress/global_htaccess.sh /usr/local/bin/wpsec
ln -sf /root/scripts/VPN/vpn_hard_shield.sh /usr/local/bin/vpnshield
# Specific requested aliases for RSS:
echo "alias mcm='mc /opt/news-rss/scripts/'" >> /root/.bashrc
echo "alias rss='python3 /opt/news-rss/scripts/fetch_news.py'" >> /root/.bashrc
hash -r
echo "All aliases generated: chname, qstat, mailclean, awsping, fpinstall, fpopt, fpusers, wpsec, vpnshield, mcm, rss."
