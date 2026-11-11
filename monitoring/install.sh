#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█  CLUSTER RESOURCE & VPN LIVE MONITOR (stat_all) INSTALLER & LAUNCHER  █▓▒░
#  Author  : Vladimir Bulantsev (GinCz)
#  GitHub  : https://github.com/GinCz/Linux_Server_Public
# ==========================================================================================
set -e

# ANSI Colors
CYAN="\e[96m"
WHITE="\e[97m"
YELLOW="\e[93m"
GREEN="\e[92m"
RED="\e[91m"
RESET="\e[0m"
BOLD="\e[1m"

SCRIPT_URL="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/monitoring/stat_all.sh"
CONFIG_DIR="/etc/stat_all"
CONFIG_FILE="${CONFIG_DIR}/servers.conf"
BIN_TARGET="/usr/local/bin/stat_all"

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║     ░▒▓█  CLUSTER RESOURCE & VPN LIVE MONITOR (stat_all v10.0)  █▓▒░         ║${RESET}"
echo -e "${CYAN}║     Author: Vladimir Bulantsev (GinCz) | Open-Source Public Edition          ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${RESET}"
echo
echo -e "  ${YELLOW}1)${WHITE} ${BOLD}Run as portable version${RESET}  ${CYAN}(single execution without system installation)${RESET}"
echo -e "  ${YELLOW}2)${WHITE} ${BOLD}Install on this server${RESET}   ${GREEN}(into /usr/local/bin/stat_all + shell aliases)${RESET}"
echo -e "  ${YELLOW}3)${WHITE} ${BOLD}Exit${RESET}"
echo

# Read from /dev/tty to support pipe/process substitution execution (curl | bash)
if [ -t 0 ]; then
    read -rp "  Select an option [1-3] (default: 1): " CHOICE
else
    read -rp "  Select an option [1-3] (default: 1): " CHOICE < /dev/tty 2>/dev/null || CHOICE=1
fi
CHOICE=${CHOICE:-1}

case "$CHOICE" in
    1)
        echo -e "\n${CYAN}>>> Launching portable version...${RESET}\n"
        TMP_SCRIPT=$(mktemp /tmp/stat_all_portable.XXXXXX.sh 2>/dev/null || echo "/tmp/stat_all_portable.sh")
        
        # Check if local file exists
        DIR_NAME="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
        if [[ -f "${DIR_NAME}/stat_all.sh" ]]; then
            cp "${DIR_NAME}/stat_all.sh" "$TMP_SCRIPT"
        else
            curl -fsSL "$SCRIPT_URL" -o "$TMP_SCRIPT"
        fi
        
        chmod +x "$TMP_SCRIPT"
        # Run script
        bash "$TMP_SCRIPT" < /dev/tty || bash "$TMP_SCRIPT"
        rm -f "$TMP_SCRIPT"
        ;;
    2)
        echo -e "\n${CYAN}>>> Installing stat_all to system...${RESET}"
        
        # Check root permissions
        if [[ $EUID -ne 0 ]]; then
            echo -e "${RED}[!] Root (sudo) privileges required for installation. Please run as root or via sudo.${RESET}"
            exit 1
        fi

        # 1. Download or copy binary
        DIR_NAME="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
        if [[ -f "${DIR_NAME}/stat_all.sh" ]]; then
            cp "${DIR_NAME}/stat_all.sh" "$BIN_TARGET"
        else
            curl -fsSL "$SCRIPT_URL" -o "$BIN_TARGET"
        fi
        chmod 755 "$BIN_TARGET"

        # 2. Create symlinks for aliases
        ln -sf "$BIN_TARGET" /usr/local/bin/st
        ln -sf "$BIN_TARGET" /usr/local/bin/stat
        ln -sf "$BIN_TARGET" /usr/local/bin/stars
        ln -sf "$BIN_TARGET" /usr/local/bin/servers_stat

        # 3. Create config directory and template if not exists
        mkdir -p "$CONFIG_DIR"
        if [[ ! -f "$CONFIG_FILE" ]]; then
            LOCAL_HOSTNAME=$(hostname -s 2>/dev/null || echo "localhost")
            LOCAL_PRIMARY_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
            LOCAL_PRIMARY_IP=${LOCAL_PRIMARY_IP:-"127.0.0.1"}

            cat <<EOF > "$CONFIG_FILE"
# ==============================================================================
#  stat_all — Cluster Server List Configuration
#  Format: ServerName:IP_or_Host (one per line)
#  Comments starting with '#' and blank lines are ignored.
# ==============================================================================

# Local Master Node
${LOCAL_HOSTNAME}:${LOCAL_PRIMARY_IP}

# Remote Cluster Nodes (Requires SSH key /root/.ssh/id_ed25519 or id_rsa)
# web-01:192.168.1.10
# db-01:192.168.1.20
# vpn-01:10.0.0.1
EOF
            chmod 644 "$CONFIG_FILE"
            echo -e "  ${GREEN}✔${RESET} Created server configuration file: ${CYAN}${CONFIG_FILE}${RESET}"
        else
            echo -e "  ${YELLOW}ℹ${RESET} Server configuration file already exists: ${CYAN}${CONFIG_FILE}${RESET}"
        fi

        # 4. Create profile alias script
        cat << 'EOF' > /etc/profile.d/stat_all.sh
alias st='stat_all'
alias stat='stat_all'
alias stars='stat_all'
alias servers_stat='stat_all'
EOF
        chmod 644 /etc/profile.d/stat_all.sh

        echo -e "\n${GREEN}==============================================================================${RESET}"
        echo -e "  ${GREEN}${BOLD}✔ Installation completed successfully!${RESET}"
        echo -e "  ${WHITE}Executable binary     :${RESET} ${CYAN}${BIN_TARGET}${RESET}"
        echo -e "  ${WHITE}Server configuration  :${RESET} ${CYAN}${CONFIG_FILE}${RESET}"
        echo -e "  ${WHITE}Launch commands       :${RESET} ${YELLOW}st${RESET}  ${WHITE}|${RESET}  ${YELLOW}stat_all${RESET}  ${WHITE}|${RESET}  ${YELLOW}stat${RESET}  ${WHITE}|${RESET}  ${YELLOW}stars${RESET}"
        echo -e "${GREEN}==============================================================================${RESET}\n"

        echo -e "  ${WHITE}To add your servers to the live monitor, edit the config file:${RESET}"
        echo -e "  ${CYAN}nano ${CONFIG_FILE}${RESET}\n"

        if [ -t 0 ]; then
            read -rp "  Launch stat_all right now? [Y/n]: " RUN_NOW
        else
            read -rp "  Launch stat_all right now? [Y/n]: " RUN_NOW < /dev/tty 2>/dev/null || RUN_NOW="y"
        fi
        if [[ "$RUN_NOW" =~ ^[Yy]?$ || -z "$RUN_NOW" ]]; then
            exec "$BIN_TARGET"
        fi
        ;;
    3)
        echo -e "\n${YELLOW}Exiting.${RESET}\n"
        exit 0
        ;;
    *)
        echo -e "\n${RED}[!] Invalid option.${RESET}\n"
        exit 1
        ;;
esac
