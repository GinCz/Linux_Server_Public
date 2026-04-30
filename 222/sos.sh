#!/usr/bin/env bash
# =============================================================
# Script:      222/sos.sh  — compatibility wrapper
# Version:     v2026-04-30
# Description: SOS moved to scripts/sos.sh (universal for all servers).
#              This file is kept as a redirect for backward compatibility.
# = Rooted by VladiMIR | AI =
# =============================================================
exec bash "$(dirname "$(readlink -f "$0")")/../../scripts/sos.sh" "$@"
# Fallback if relative path fails:
# bash /root/Linux_Server_Public/scripts/sos.sh "$@"
