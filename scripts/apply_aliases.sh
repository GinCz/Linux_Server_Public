#!/usr/bin/env bash
# Script: apply_aliases.sh
# Version: v2026-03-17
# Purpose: Create stable command links and shell aliases for shared server tools.
# What it does: creates symlinks in /usr/local/bin, adds root aliases if missing,
# refreshes shell command cache, and keeps command names consistent across servers.
# Usage: sudo /opt/server_tools/scripts/apply_aliases.sh
# Notes: safe to run multiple times; old duplicate paths were replaced with /opt/server_tools/scripts.

set -euo pipefail; B="/opt/server_tools/scripts"; R="/root/.bashrc"; ln -sf "$B/change_hostname.sh" /usr/local/bin/chname; ln -sf "$B/quick_status.sh" /usr/local/bin/qstat; ln -sf "$B/mail_queue.sh" /usr/local/bin/mailclean; ln -sf "$B/aws_ping.sh" /usr/local/bin/awsping; ln -sf "$B/amnezia_stat.sh" /usr/local/bin/awgstat; ln -sf "$B/install_panel.sh" /usr/local/bin/fpinstall; ln -sf "$B/optimize_session.sh" /usr/local/bin/fpopt; ln -sf "$B/mogwai_users.sh" /usr/local/bin/fpusers; ln -sf "$B/global_htaccess.sh" /usr/local/bin/wpsec; ln -sf "$B/vpn_hard_shield.sh" /usr/local/bin/vpnshield; ln -sf "$B/log_303.sh" /usr/local/bin/log303; grep -qxF "alias mcm='mc /opt/news-rss/scripts/'" "$R" || echo "alias mcm='mc /opt/news-rss/scripts/'" >> "$R"; grep -qxF "alias rss='python3 /opt/news-rss/scripts/fetch_news.py'" "$R" || echo "alias rss='python3 /opt/news-rss/scripts/fetch_news.py'" >> "$R"; grep -qxF "alias 303='sudo /opt/server_tools/scripts/log_303.sh'" "$R" || echo "alias 303='sudo /opt/server_tools/scripts/log_303.sh'" >> "$R"; hash -r; echo "Updated: chname qstat mailclean awsping awgstat fpinstall fpopt fpusers wpsec vpnshield log303 mcm rss 303"
