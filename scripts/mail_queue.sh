#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  mail_queue.sh | [v2026-08-15]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Exim4 mail queue monitoring and cleanup tool
# Servers     : 222-DE / 109-RU Mail Nodes
# Usage       : bash scripts/mail_queue.sh
# ==========================================================================================
echo "Queue size: $(exim -bpc 2>/dev/null)"; read -p "Clear all? (y/n): " A; [ "$A" = "y" ] && { exipick -i 2>/dev/null | xargs -r exim -Mrm 2>/dev/null; echo "Queue cleared."; }

# = Rooted by VladiMIR | AI = v2026-08-15 = github.com/GinCz/Linux_Server_Public
