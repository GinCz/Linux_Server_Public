#!/bin/bash
# =============================================================================
# 222/motd_server.sh — DEPRECATED, redirects to VPN/motd_server.sh
# Version : v2026-04-07
# This file is kept for compatibility only.
# The ACTUAL MOTD is: /root/Linux_Server_Public/VPN/motd_server.sh
# Installed to:       /etc/profile.d/motd_server.sh
# To update:  bash /root/Linux_Server_Public/VPN/deploy_vpn_node.sh
# = Rooted by VladiMIR | AI =
# =============================================================================

# Do nothing — the real MOTD is managed by VPN/motd_server.sh
# If this file is installed as /etc/profile.d/motd_server.sh by mistake,
# it will be replaced by deploy_vpn_node.sh on next run.
exec bash /root/Linux_Server_Public/VPN/motd_server.sh 2>/dev/null
