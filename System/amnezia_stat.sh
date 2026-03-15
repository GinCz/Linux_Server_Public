#!/usr/bin/env bash
echo -e "\033[1;36m=== AmneziaWG / WireGuard Traffic ===\033[0m"
if command -v wg &> /dev/null; then
    wg show all transfer
else
    echo -e "\033[1;31mWireGuard не установлен или интерфейс неактивен.\033[0m"
fi
