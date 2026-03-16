#!/usr/bin/env bash
# Description: Bulk create users in FastPanel via mogwai CLI.
# Alias: fpusers
U="4ton igor_kap alejandrofashion andrey_autoservis"; P="Vlad+608758301!"; for u in $U; do mogwai users list 2>/dev/null | grep -q "$u" && echo "[-] $u exists" || { mogwai users create --username="$u" --password="$P" --role=USER 2>/dev/null; echo "[+] $u created"; }; done;
