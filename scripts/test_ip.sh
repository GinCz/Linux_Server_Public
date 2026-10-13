#!/usr/bin/env bash
# ==============================================================================
# Execution Context : Bash (root)
# Target Server     : Debian 12 / Ubuntu 24
# Description       : Fast IP ban check server for Ping-Admin (<ip>/server-<octet>)
# Author            : GinCz (Vladimir Bulantsev)
# Repository        : https://github.com/GinCz/Linux_Server_Public
# ==============================================================================

clear
set -e

C_RESET='\033[0m'
C_GREEN='\033[1;32m'
C_CYAN='\033[1;36m'
C_YELLOW='\033[1;33m'
C_BOLD='\033[1m'

echo -e "${C_CYAN}${C_BOLD}=================================================================${C_RESET}"
echo -e "${C_GREEN}${C_BOLD} 🚀 FAST IP BAN CHECK SERVER DEPLOYMENT (Ping-Admin) ${C_RESET}"
echo -e "${C_CYAN}${C_BOLD}=================================================================${C_RESET}"
echo -e "${C_YELLOW}>>> Setting up lightweight HTTP test endpoint...${C_RESET}\n"

# Ensure essential tools
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null 2>&1 || true
apt-get install -y -qq python3 curl iptables >/dev/null 2>&1 || true

# Open HTTP port in iptables / ufw if present
iptables -I INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || true
if command -v ufw >/dev/null 2>&1; then
  ufw allow 80/tcp >/dev/null 2>&1 || true
fi

# Stop any previous instance of test server
pkill -f "python3 -m http.server 80" 2>/dev/null || true
rm -rf /var/www/test /var/www/test_ip 2>/dev/null || true

# Detect public IP
DETECTED_IP="$(curl -4s https://api.ipify.org 2>/dev/null || curl -4s https://icanhazip.com 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')"
LAST_OCTET="$(echo "$DETECTED_IP" | awk -F. '{print $NF}')"

# Slug format: server-<last_octet> (e.g. server-43)
CHECK_SLUG="server-${LAST_OCTET}"

# Clean test directory
TEST_DIR="/var/www/test_ip"
mkdir -p "$TEST_DIR/$CHECK_SLUG"

HTML_CONTENT='<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Server Online</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0f172a; color: #f8fafc; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
        .box { background: #1e293b; padding: 40px; border-radius: 12px; text-align: center; border: 1px solid #334155; }
        h1 { color: #22c55e; margin: 0 0 10px; font-size: 28px; }
        p { color: #94a3b8; margin: 0; font-size: 16px; }
    </style>
</head>
<body>
    <div class="box">
        <h1>200 OK — Server Online</h1>
        <p>Ping-Admin test verification endpoint.</p>
    </div>
</body>
</html>'

# Place index.html at root, inside slug dir and as flat file
echo "$HTML_CONTENT" > "$TEST_DIR/index.html"
echo "$HTML_CONTENT" > "$TEST_DIR/$CHECK_SLUG/index.html"
echo "$HTML_CONTENT" > "$TEST_DIR/$CHECK_SLUG.html"

# Start python background HTTP server
cd "$TEST_DIR"
nohup python3 -m http.server 80 >/dev/null 2>&1 &
sleep 1

# Direct link without http://
CLEAN_LINK="${DETECTED_IP}/${CHECK_SLUG}"

clear
echo -e "\n${C_CYAN}${C_BOLD}=================================================================${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}  ✅ TEST SERVER IS RUNNING & READY! ${C_RESET}"
echo -e "${C_CYAN}${C_BOLD}=================================================================${C_RESET}"
echo -e "  Server IP Address : ${C_YELLOW}${DETECTED_IP}${C_RESET}"
echo -e "${C_CYAN}-----------------------------------------------------------------${C_RESET}"
echo -e "  ${C_BOLD}👉 Скопируй эту строку для вставки в Ping-Admin:${C_RESET}"
echo -e ""
echo -e "  ${C_GREEN}${C_BOLD}${CLEAN_LINK}${C_RESET}"
echo -e ""
echo -e "${C_CYAN}-----------------------------------------------------------------${C_RESET}"
echo -e "  ${C_BOLD}🔗 Форма проверки: ${C_CYAN}https://ping-admin.com/free_test/${C_RESET}"
echo -e "${C_CYAN}${C_BOLD}=================================================================${C_RESET}\n"
