#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  mogwai_users.sh | [v2026-05-01]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : User permissions and account audit
# Servers     : 109-RU FastVDS
# Usage       : bash 109/mogwai_users.sh
# ==========================================================================================
# Description: Bulk create users in FastPanel via mogwai CLI.
# Alias: fpusers
U="4ton igor_kap alejandrofashion andrey_autoservis"; P="Vlad+608758301!"; for u in $U; do mogwai users list 2>/dev/null | grep -q "$u" && echo "[-] $u exists" || { mogwai users create --username="$u" --password="$P" --role=USER 2>/dev/null; echo "[+] $u created"; }; done;

# = Rooted by VladiMIR | AI = v2026-05-01 = github.com/GinCz/Linux_Server_Public
