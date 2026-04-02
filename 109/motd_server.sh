#!/bin/bash
# = Rooted by VladiMIR | AI = v2026-04-02
clear
BLUE='\033[1;36m'
LGREEN='\033[1;92m'
LYELLOW='\033[1;93m'
NC='\033[0m'
BORDER='════════════════════════════════════════════════════════════════════════════════'
echo -e "${BLUE}${BORDER}${NC}"
echo -e "  ${LGREEN}🖥  109-ru-vds${NC}               ${LYELLOW}212.109.223.109${NC}          ${LGREEN}RAM:$(free -m|awk 'NR==2{printf "%.0f/%.0fMB", $3,$2}') CPU:$(awk '{u=$2+$4; t=$2+$3+$4+$5; if (NR==2){printf "%d%%",u*100/t}}' /proc/stat)${NC}"
echo -e "${BLUE}${BORDER}${NC}"
echo -e "  ${LYELLOW}SCAN & SECURITY${NC}           ${LYELLOW}SERVER${NC}                    ${LYELLOW}WORDPRESS${NC}"
echo -e "${BLUE}${BORDER}${NC}"
echo -e "  ${LGREEN}antivir(scan)${NC}             ${LGREEN}sos(now)${NC}                  ${LGREEN}wpupd(WP update)${NC}"
echo -e "  ${LGREEN}fight(block bots)${NC}         ${LGREEN}backup(system backup)${NC}      ${LGREEN}wpcron(WP cron)${NC}"
echo -e "  ${LGREEN}banlog(ban list)${NC}          ${LGREEN}watchdog(PHP-FPM)${NC}          ${LGREEN}mailclean(mail queue)${NC}"
echo -e "  ${LGREEN}cleanup(disk clean)${NC}       ${LGREEN}allinfo(all servers)${NC}       ${LGREEN}domains(domains)${NC}"
echo -e "${BLUE}${BORDER}${NC}"
echo -e "  ${LYELLOW}GIT${NC}                       ${LYELLOW}TOOLS${NC}"
echo -e "${BLUE}${BORDER}${NC}"
echo -e "  ${LGREEN}save(git push)${NC}            ${LGREEN}infooo(full info)${NC}         ${LGREEN}aws-test(latency test)${NC}"
echo -e "  ${LGREEN}load(git pull)${NC}            ${LGREEN}aw(VPN stats)${NC}             ${LGREEN}f5bot(docker backup)${NC}"
echo -e "  ${LGREEN}00(clear)${NC}                 ${LGREEN}f9bot(restore)${X}${NC}"
echo -e "${BLUE}${BORDER}${NC}"
echo -e "  ${LYELLOW}FastPanel | Ubuntu 24 | 212.109.223.109 | $(uptime -p|sed 's/^up //') | load: $(awk '{print $1" "$2" "$3}' /proc/loadavg)${NC}"
