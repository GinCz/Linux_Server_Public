#!/usr/bin/env bash
# =============================================================
# Script:      bashrc_aliases.sh
# Version:     v2026.05.20
# Location:    server-222-DE/bashrc_aliases.sh
# Description: Aliases block for ~/.bashrc on FastPanel web servers.
#              Adds sos / sos1 / sos3 / sos24 / sos120 commands.
#              The sos binary must be installed first:
#                cp scripts/sos-fastpanel.sh /usr/local/bin/sos
#                chmod +x /usr/local/bin/sos
# Usage:       cat server-222-DE/bashrc_aliases.sh >> ~/.bashrc
#              source ~/.bashrc
# = Rooted by VladiMIR + AI | v2026.05.20 | github.com/GinCz =
# =============================================================

# ── SOS — server health monitor ───────────────────────────────────────────────
alias sos='sos 1h'
alias sos1='sos 1h'
alias sos3='sos 3h'
alias sos24='sos 24h'
alias sos120='sos 120h'
