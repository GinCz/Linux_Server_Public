#!/bin/bash
# Rooted by VladiMIR | AI = v2026-04-01
clear
BLUE='\033[1;36m'
LGREEN='\033[1;92m'
LYELLOW='\033[1;93m'
NC='\033[0m'
BORDER='════════════════════════════════════════════════════════════════════════════════'
echo -e "${BLUE}${BORDER}${NC}"
echo -e "  ${LGREEN}🖥 222-DE-NetCup${NC}            ${LYELLOW}152.53.182.222${NC}           ${LGREEN}RAM:$(free -m|awk 'NR==2{printf "%.0f/%.0fMB", $3,$2}') CPU:$(awk '{u=$2+$4; t=$2+$3+$4+$5; if (NR==2){printf "%d%%",u*100/t}}' /proc/stat)${NC}"
echo -e "${BLUE}${BORDER}${NC}"
echo -e "  ${LYELLOW}SCAN & SECURITY${NC}           ${LYELLOW}SERVER${NC}                    ${LYELLOW}WORDPRESS${NC}"
echo -e "${BLUE}${BORDER}${NC}"
echo -e "  ${LGREEN}antivir(scan)${NC}             ${LGREEN}sos(now)${NC}                  ${LGREEN}wpupd(WP update)${NC}"
echo -e "  ${LGREEN}fight(block bots)${NC}         ${LGREEN}sos3/24/120(3/24/120h)${NC}    ${LGREEN}wpcron(WP cron)${NC}"
echo -e "  ${LGREEN}banlog(ban list)${NC}          ${LGREEN}backup(system backup)${NC}      ${LGREEN}mailclean(mail queue)${NC}"
echo -e "  ${LGREEN}cleanup(disk clean)${NC}       ${LGREEN}dbackup(docker backup)${NC}     ${LGREEN}domains(domains)${NC}"
echo -e "${BLUE}${BORDER}${NC}"
echo -e "  ${LYELLOW}CRYPTO-BOT${NC}                ${LYELLOW}GIT${NC}                       ${LYELLOW}TOOLS${NC}"
echo -e "${BLUE}${BORDER}${NC}"
echo -e "  ${LGREEN}tr(quick report)${NC}          ${LGREEN}save(git push)${NC}            ${LGREEN}i(full info)${NC}"
echo -e "  ${LGREEN}clog(container logs)${NC}      ${LGREEN}load(git pull)${NC}            ${LGREEN}aws-test(speed test)${NC}"
echo -e "  ${LGREEN}torg/torg3/24/120${NC}        ${LGREEN}aw(VPN stats)${NC}             ${LGREEN}f5bot/dbackup${NC}"
echo -e "  ${LGREEN}reset(restart bot)${NC}        ${LGREEN}00(clear)${NC}                 ${LGREEN}f9bot/restore${NC}"
echo -e "${BLUE}${BORDER}${NC}"
echo -e "  ${LYELLOW}FastPanel | Ubuntu 24 | 152.53.182.222 | $(uptime -p|sed 's/^up //') | load: $(awk '{print $1" "$2" "$3}' /proc/loadavg)${NC}"
