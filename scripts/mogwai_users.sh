#!/usr/bin/env bash
# Script:  mogwai_users.sh
# Version: v2026-03-17
# Purpose: Bulk create FastPanel users via mogwai CLI.
#          Skips users that already exist.
# Usage:   /opt/server_tools/scripts/mogwai_users.sh
# Alias:   fpusers

clear
G='\033[1;32m'; Y='\033[1;33m'; X='\033[0m'

read -s -p "Password for all new users: " P
echo ""

USERS="4ton igor_kap alejandrofashion andrey-maiorov arslan andrey-autoservis
sveta_tuk balance_b2b_ tan-adrian bio_zahrada car_bus_auto car_bus_serv
serg_pimonov alex_zas dmitry-vary alex_detailing diamond-drivers doski
serg_et gincz gadanie-tel geodesia hulk viktoria olga_pisareva karina
vlad_lazarev palantins kirill_mtek valeriia natal-karta neonella novorr
bayerhoff reklama-white serg_reno anastasia_bul tatiana_podzolkova
stomat-bel vobs anatoly_solodilin sveta_drobot spa tatra kirill-tri-sure
tstwist ugfp ver7 wowflow stanok"

echo -e "${Y}>>> Creating FastPanel users...${X}"
for u in $USERS; do
    if mogwai users list 2>/dev/null | grep -q "$u"; then
        echo "[-] $u already exists"
    else
        mogwai users create --username="$u" --password="$P" --role=USER 2>/dev/null \
            && echo -e "${G}[+] $u created${X}" \
            || echo "[ ] $u failed"
    fi
done

echo -e "\n${Y}Done. Verify: mogwai users list${X}"
