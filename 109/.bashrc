# =============================================================
# ~/.bashrc — server 109-RU-FastVDS (212.109.223.109)
# Loads for NON-LOGIN interactive shells (e.g. bash, su, screen)
# Version: v2026.05.21
# = Rooted by VladiMIR + AI | v.2026.05.21 | github.com/GinCz =
#
# IMPORTANT:
#   SSH login shell loads .bash_profile (MOTD shown there, ONCE)
#   .bashrc must NOT show MOTD — only load aliases
#
# HOW TO APPLY (copy to server):
#   cp /root/Linux_Server_Public/109/.bashrc /root/.bashrc
# =============================================================

# Load aliases ONLY — MOTD_SHOWN flag prevents duplicate banner
# even if someone runs 'bash' manually inside an existing session
if [ -f /root/Linux_Server_Public/109/server_109.sh ]; then
    source /root/Linux_Server_Public/109/server_109.sh
fi
