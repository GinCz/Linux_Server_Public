#!/bin/bash
clear
# =============================================================================
# FastPanel Port 8888 — Diagnostics & Auto-Fix
# Checks service status, firewall rules, port binding, config, SSL
# and attempts to automatically fix all found issues.
# =============================================================================
# = Rooted by VladiMIR + AI | v.2026.07.27 | github.com/GinCz =
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

FIXED=0
WARNS=0

log_ok()   { echo -e "${GREEN}[OK]${NC}    $1"; }
log_fix()  { echo -e "${YELLOW}[FIX]${NC}   $1"; ((FIXED++)); }
log_warn() { echo -e "${RED}[WARN]${NC}  $1"; ((WARNS++)); }
log_info() { echo -e "${CYAN}[INFO]${NC}  $1"; }
log_head() { echo -e "\n${BOLD}${CYAN}>>> $1${NC}"; }

require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Run as root: sudo bash $0${NC}"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# 1. SERVICE STATUS
# -----------------------------------------------------------------------------
check_service() {
    log_head "1. FastPanel service status"

    local svc
    for svc in fastpanel2 fastpanel; do
        if systemctl list-units --full -all | grep -q "${svc}.service"; then
            SERVICE_NAME="$svc"
            break
        fi
    done

    if [[ -z "$SERVICE_NAME" ]]; then
        log_warn "FastPanel service not found (fastpanel2 / fastpanel). Is it installed?"
        return
    fi

    STATUS=$(systemctl is-active "$SERVICE_NAME" 2>/dev/null)
    if [[ "$STATUS" == "active" ]]; then
        log_ok "Service $SERVICE_NAME is running."
    else
        log_warn "Service $SERVICE_NAME is NOT running (status: $STATUS). Attempting restart..."
        systemctl restart "$SERVICE_NAME"
        sleep 3
        STATUS=$(systemctl is-active "$SERVICE_NAME" 2>/dev/null)
        if [[ "$STATUS" == "active" ]]; then
            log_fix "Service $SERVICE_NAME restarted successfully."
        else
            log_warn "Restart FAILED. Check: journalctl -u $SERVICE_NAME -n 50"
            journalctl -u "$SERVICE_NAME" -n 20 --no-pager
        fi
    fi

    ENABLED=$(systemctl is-enabled "$SERVICE_NAME" 2>/dev/null)
    if [[ "$ENABLED" != "enabled" ]]; then
        log_warn "$SERVICE_NAME is not enabled on boot. Enabling..."
        systemctl enable "$SERVICE_NAME"
        log_fix "$SERVICE_NAME enabled on boot."
    else
        log_ok "$SERVICE_NAME is enabled on boot."
    fi
}

# -----------------------------------------------------------------------------
# 2. PORT 8888 BINDING
# -----------------------------------------------------------------------------
check_port() {
    log_head "2. Port 8888 binding"

    local bind
    bind=$(ss -tlnp 2>/dev/null | grep ':8888')

    if [[ -z "$bind" ]]; then
        log_warn "Nothing is listening on port 8888!"
        log_info "FastPanel may be configured on a different port or failed to bind."
        log_info "Checking all FastPanel-related ports:"
        ss -tlnp | grep -iE 'fastpanel|fp' || echo "  (none found)"
    else
        log_ok "Port 8888 is open:"
        echo "  $bind"

        if echo "$bind" | grep -q '127.0.0.1:8888'; then
            log_warn "FastPanel is bound only to 127.0.0.1 — not accessible from outside!"
            log_info "Check /etc/fastpanel2/*.conf or /etc/nginx/conf.d/ for listen directive."
            WARNS=$((WARNS+1))
        else
            log_ok "FastPanel is listening on a public interface."
        fi
    fi
}

# -----------------------------------------------------------------------------
# 3. UFW FIREWALL
# -----------------------------------------------------------------------------
check_ufw() {
    log_head "3. UFW firewall (port 8888)"

    if ! command -v ufw &>/dev/null; then
        log_info "UFW not installed."
        return
    fi

    UFW_STATUS=$(ufw status 2>/dev/null | head -1)
    if echo "$UFW_STATUS" | grep -q "inactive"; then
        log_info "UFW is inactive — no blocking."
        return
    fi

    log_ok "UFW is active."

    if ufw status verbose 2>/dev/null | grep -qE '8888.*ALLOW'; then
        log_ok "UFW allows port 8888."
    else
        log_warn "UFW does NOT allow port 8888. Adding rule..."
        ufw allow 8888/tcp comment 'FastPanel'
        log_fix "UFW rule added: 8888/tcp allowed."
    fi
}

# -----------------------------------------------------------------------------
# 4. IPTABLES
# -----------------------------------------------------------------------------
check_iptables() {
    log_head "4. iptables (port 8888)"

    if ! command -v iptables &>/dev/null; then
        log_info "iptables not installed."
        return
    fi

    BLOCK=$(iptables -L INPUT -n -v 2>/dev/null | grep -E 'DROP|REJECT' | grep -v '#')
    DROP8888=$(iptables -L INPUT -n -v 2>/dev/null | grep '8888' | grep -E 'DROP|REJECT')

    if [[ -n "$DROP8888" ]]; then
        log_warn "iptables is BLOCKING port 8888:"
        echo "  $DROP8888"
        log_info "Remove manually if needed: iptables -D INPUT <rule_number>"
    else
        log_ok "No iptables DROP/REJECT rule for port 8888."
    fi

    ACCEPT8888=$(iptables -L INPUT -n -v 2>/dev/null | grep '8888' | grep 'ACCEPT')
    if [[ -n "$ACCEPT8888" ]]; then
        log_ok "iptables ACCEPT rule for 8888 found."
    fi
}

# -----------------------------------------------------------------------------
# 5. NGINX (FastPanel often proxies through Nginx)
# -----------------------------------------------------------------------------
check_nginx() {
    log_head "5. Nginx config for port 8888"

    if ! command -v nginx &>/dev/null; then
        log_info "Nginx not installed."
        return
    fi

    NGINX_STATUS=$(systemctl is-active nginx 2>/dev/null)
    if [[ "$NGINX_STATUS" != "active" ]]; then
        log_warn "Nginx is not running (status: $NGINX_STATUS). Attempting restart..."
        nginx -t 2>&1
        systemctl restart nginx
        sleep 2
        if [[ $(systemctl is-active nginx) == "active" ]]; then
            log_fix "Nginx restarted successfully."
        else
            log_warn "Nginx restart FAILED. Check: nginx -t"
            nginx -t
        fi
    else
        log_ok "Nginx is running."
    fi

    NGINX_8888=$(grep -r '8888' /etc/nginx/ 2>/dev/null | grep 'listen')
    if [[ -n "$NGINX_8888" ]]; then
        log_ok "Nginx listen 8888 found:"
        echo "$NGINX_8888" | head -5 | sed 's/^/  /'
    else
        log_info "No 'listen 8888' in Nginx config. FastPanel may use its own built-in server."
    fi

    if nginx -t 2>&1 | grep -q "successful"; then
        log_ok "Nginx config test: OK."
    else
        log_warn "Nginx config test FAILED:"
        nginx -t
    fi
}

# -----------------------------------------------------------------------------
# 6. SSL CERTIFICATE
# -----------------------------------------------------------------------------
check_ssl() {
    log_head "6. SSL certificate for port 8888"

    if command -v openssl &>/dev/null; then
        CERT_INFO=$(echo | timeout 5 openssl s_client -connect 127.0.0.1:8888 -servername localhost 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)
        if [[ -n "$CERT_INFO" ]]; then
            EXPIRY=$(echo "$CERT_INFO" | grep 'notAfter' | cut -d= -f2)
            log_ok "SSL certificate found. Expires: $EXPIRY"

            EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s 2>/dev/null)
            NOW_EPOCH=$(date +%s)
            DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

            if [[ $DAYS_LEFT -lt 0 ]]; then
                log_warn "SSL certificate has EXPIRED ${DAYS_LEFT#-} days ago!"
            elif [[ $DAYS_LEFT -lt 30 ]]; then
                log_warn "SSL certificate expires in $DAYS_LEFT days — renew soon."
            else
                log_ok "Certificate valid for $DAYS_LEFT days."
            fi
        else
            log_info "Could not retrieve SSL certificate (service may be down or using HTTP)."
            log_info "Try in browser: http://152.53.182.222:8888 (without https)"
        fi
    else
        log_info "openssl not available, skipping SSL check."
    fi
}

# -----------------------------------------------------------------------------
# 7. FASTPANEL CONFIG
# -----------------------------------------------------------------------------
check_config() {
    log_head "7. FastPanel config files"

    local cfg_dirs=("/etc/fastpanel2" "/opt/fastpanel2" "/usr/local/fastpanel2")
    for dir in "${cfg_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_ok "Config directory found: $dir"
            ls "$dir" | sed 's/^/  /'

            PORT_CFG=$(grep -r '8888\|listen\|port' "$dir" 2>/dev/null | grep -v '.bak' | head -10)
            if [[ -n "$PORT_CFG" ]]; then
                log_info "Port-related config entries:"
                echo "$PORT_CFG" | sed 's/^/  /'
            fi
        fi
    done

    log_info "Recent FastPanel log tail:"
    local log_paths=("/var/log/fastpanel2/error.log" "/var/log/fastpanel2/fastpanel.log")
    for lp in "${log_paths[@]}"; do
        if [[ -f "$lp" ]]; then
            echo -e "${CYAN}--- $lp (last 15 lines) ---${NC}"
            tail -15 "$lp"
        fi
    done
}

# -----------------------------------------------------------------------------
# 8. CONNECTIVITY TEST
# -----------------------------------------------------------------------------
check_connectivity() {
    log_head "8. Local connectivity test (curl localhost:8888)"

    if command -v curl &>/dev/null; then
        HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" --connect-timeout 5 http://127.0.0.1:8888/ 2>/dev/null)
        HTTPS_CODE=$(curl -sk -o /dev/null -w "%{http_code}" --connect-timeout 5 https://127.0.0.1:8888/ 2>/dev/null)

        if [[ "$HTTP_CODE" =~ ^[23] ]]; then
            log_ok "HTTP response on port 8888: $HTTP_CODE"
        elif [[ "$HTTP_CODE" == "000" ]]; then
            log_warn "No HTTP response on port 8888 (connection refused or timeout)."
        else
            log_info "HTTP response code: $HTTP_CODE"
        fi

        if [[ "$HTTPS_CODE" =~ ^[23] ]]; then
            log_ok "HTTPS response on port 8888: $HTTPS_CODE"
        elif [[ "$HTTPS_CODE" == "000" ]]; then
            log_warn "No HTTPS response on port 8888."
        else
            log_info "HTTPS response code: $HTTPS_CODE"
        fi
    else
        log_info "curl not available."
    fi
}

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------
require_root

echo -e "${BOLD}${CYAN}"
echo "============================================================"
echo "  FastPanel Port 8888 — Diagnostics & Auto-Fix"
echo "  Host: $(hostname) | IP: $(hostname -I | awk '{print $1}')"
echo "  Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"
echo -e "${NC}"

check_service
check_port
check_ufw
check_iptables
check_nginx
check_ssl
check_config
check_connectivity

# -----------------------------------------------------------------------------
# SUMMARY
# -----------------------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}============================================================"
echo " SUMMARY"
echo -e "============================================================${NC}"

if [[ $FIXED -gt 0 ]]; then
    echo -e "${GREEN}[+] Auto-fixed: $FIXED issue(s)${NC}"
fi

if [[ $WARNS -gt 0 ]]; then
    echo -e "${RED}[!] Remaining warnings: $WARNS — check output above${NC}"
else
    echo -e "${GREEN}[OK] No critical issues detected.${NC}"
fi

echo -e "\n${CYAN}FastPanel panel URL: https://$(hostname -I | awk '{print $1}'):8888${NC}"
echo -e "${CYAN}If still unavailable — check NetCup external firewall in SCP panel.${NC}"

# = Rooted by VladiMIR + AI | v.2026.07.27 | github.com/GinCz =
