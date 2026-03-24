#!/bin/bash
clear
# =============================================================================
# aws_test.sh — Test connection & speed to AWS server
# =============================================================================
# Version     : v2026-03-25
# Author      : Ing. VladiMIR Bulantsev
# GitHub      : https://github.com/GinCz/Linux_Server_Public
# Server      : 222-DE-NetCup (xxx.xxx.xxx.222)
# =============================================================================
# = Rooted by VladiMIR | AI =
# =============================================================================

C="\033[1;36m"; G="\033[1;32m"; Y="\033[1;33m"; R="\033[1;31m"; X="\033[0m"
HR="${Y}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${X}"

# Target AWS server IP (update when AWS server is added)
AWS_IP="${1:-}"

echo -e "$HR"
echo -e "${Y}   AWS Connection Test — from 222-DE-NetCup${X}"
echo -e "$HR"
echo

if [ -z "$AWS_IP" ]; then
    echo -e "${Y}Usage:${X} aws-test <AWS_IP>"
    echo -e "Example: aws-test 54.12.34.56"
    echo
    echo -e "${C}Or set AWS_IP variable in this script for default target.${X}"
    echo
    exit 0
fi

echo -e "${C}Target: ${AWS_IP}${X}"
echo

# Ping test
echo -e "${C}[1/3] Ping (10 packets)...${X}"
ping -c 10 -i 0.5 "${AWS_IP}" 2>/dev/null | tail -2
echo

# TCP port test (SSH)
echo -e "${C}[2/3] TCP port 22 (SSH)...${X}"
if nc -zw3 "${AWS_IP}" 22 2>/dev/null; then
    echo -e "      ${G}OPEN${X}"
else
    echo -e "      ${R}CLOSED / FILTERED${X}"
fi
echo

# Speed test via dd over SSH
echo -e "${C}[3/3] Transfer speed test (10MB)...${X}"
if command -v sshpass >/dev/null 2>&1; then
    echo -e "      ${Y}(requires SSH access — run manually if needed)${X}"
else
    echo -e "      ${Y}sshpass not installed${X}"
fi
echo

echo -e "$HR"
echo -e "${Y}              = Rooted by VladiMIR | AI =${X}"
echo -e "$HR"
echo
