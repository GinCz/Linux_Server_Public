#!/usr/bin/env bash
# =============================================================================
#  domain_check.sh — Universal Domain Health Monitor
#  Works on: server 222 (EU/FastPanel) and server 109 (RU/FastPanel)
#  Checks : HTTP response code, SSL cert expiry
#  Auto-detects all domains from live Nginx config
#  Redirect-only vhosts (return 301/302, no backend) shown in cyan — not errors
#  Version: 2026.06.29
# =============================================================================
#
#  Usage:
#    bash /root/scripts/domain_check.sh            # alert only on problems
#    bash /root/scripts/domain_check.sh --report   # always send Telegram report
#
#  Cron examples:
#    0 */6 * * * /root/scripts/domain_check.sh
#    0 8   * * * /root/scripts/domain_check.sh --report
# =============================================================================

source /root/.server_env 2>/dev/null || true
source /root/scripts/common.sh 2>/dev/null || true

# ── Telegram fallback (if not set via .server_env) ────────────────────────────
TG_TOKEN="${TG_TOKEN:-1226649515:AAEW2Vk2HSb_O693hhHfiHcPgfye4AcTURQ}"
TG_CHAT_ID="${TG_CHAT_ID:-261784949}"

# ── Colours ───────────────────────────────────────────────────────────────────
G='\033[1;32m'   # bright green  — OK
Y='\033[1;33m'   # bright yellow — SSL warning
R='\033[1;91m'   # bright red    — error / down
C='\033[1;36m'   # bright cyan   — redirect (by design)
W='\033[1;37m'   # bright white  — header
X='\033[0m'      # reset

# ── Config ────────────────────────────────────────────────────────────────────
WARN_DAYS=14          # SSL warning threshold (days)
CONNECT_TIMEOUT=7
MAX_TIME=12
RETRY=3
RETRY_DELAY=8
SERVER_TAG="${SERVER_TAG:-$(hostname)}"

# ── Helper: Telegram ──────────────────────────────────────────────────────────
send_telegram() {
    local msg="$1"
    if [[ $(type -t send_tg) == function ]]; then
        send_tg "$msg"
    elif [[ -n "$TG_TOKEN" && -n "$TG_CHAT_ID" ]]; then
        curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
             -d "chat_id=${TG_CHAT_ID}" \
             --data-urlencode "text=${msg}" > /dev/null
    fi
}

# ── Helper: SSL expiry in days (-1 = no cert / error) ─────────────────────────
check_ssl_expiry() {
    local domain="$1"
    local expiry_date
    expiry_date=$(echo | timeout 5 openssl s_client \
        -connect "${domain}:443" -servername "$domain" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null \
        | cut -d= -f2)
    [[ -z "$expiry_date" ]] && { echo -1; return; }
    local epoch
    epoch=$(date -d "$expiry_date" +%s 2>/dev/null) || { echo -1; return; }
    echo $(( (epoch - $(date +%s)) / 86400 ))
}

# ── Collect domains from Nginx (live config + file fallback) ──────────────────
collect_domains() {
    local domains
    # Primary: parse live compiled config (includes all includes)
    domains=$(nginx -T 2>/dev/null \
        | grep -E '^\s*server_name\s' \
        | sed 's/server_name//g; s/;//g' \
        | tr ' ' '\n' \
        | sed 's/^\s*//; s/\s*$//' \
        | grep '\.' \
        | grep -v '^www\.' \
        | grep -v 'localhost' \
        | grep -v '^\*' \
        | sort -u)

    # Fallback: grep config files directly
    if [[ -z "$domains" ]]; then
        domains=$(grep -roP 'server_name \K[^;]+' \
            /etc/nginx/sites-enabled/ \
            /etc/nginx/fastpanel2-sites/ \
            /etc/nginx/fastpanel2-available/ \
            /etc/nginx/conf.d/ 2>/dev/null \
            | awk -F: '{print $2}' \
            | tr ' ' '\n' \
            | sed 's/^www\.//' \
            | grep '\.' | grep -v 'localhost' \
            | sort -u)
    fi
    echo "$domains"
}

# ── Detect pure-redirect vhost (return 301/302, no proxy/fastcgi backend) ─────
# Strategy: extract the full server{} block that owns this domain from nginx -T
is_redirect_only() {
    local domain="$1"
    # Grab the server block(s) that contain this server_name
    # nginx -T outputs merged config; we collect lines between matching
    # server { ... } boundaries that include our domain in server_name
    local in_block=0 brace=0 block=""
    while IFS= read -r line; do
        if [[ $in_block -eq 0 ]]; then
            # Look for a server block opening
            if echo "$line" | grep -qE '^\s*server\s*\{'; then
                in_block=1; brace=1; block="$line"
                continue
            fi
        else
            block+=$'\n'"$line"
            # Count braces to find end of block
            opens=$(echo "$line" | grep -o '{' | wc -l)
            closes=$(echo "$line" | grep -o '}' | wc -l)
            brace=$(( brace + opens - closes ))
            if [[ $brace -le 0 ]]; then
                # Block ended — check if it contains our domain
                if echo "$block" | grep -qE "server_name[^;]*[[:space:]]${domain}([[:space:];])"; then
                    local has_return has_backend
                    has_return=$(echo "$block" | grep -cE 'return\s+(301|302)')
                    has_backend=$(echo "$block" | grep -cE 'proxy_pass|fastcgi_pass|uwsgi_pass')
                    if [[ $has_return -gt 0 && $has_backend -eq 0 ]]; then
                        echo "redirect"; return
                    fi
                fi
                in_block=0; block=""
            fi
        fi
    done < <(nginx -T 2>/dev/null)
    echo "active"
}

# ── MAIN ──────────────────────────────────────────────────────────────────────
clear
echo -e "${W}╔══════════════════════════════════════════════════════════╗${X}"
echo -e "${W}║  🌐 DOMAIN HEALTH CHECK — ${SERVER_TAG}${X}"
echo -e "${W}╚══════════════════════════════════════════════════════════╝${X}"
echo ""

DOMAINS=$(collect_domains)
if [[ -z "$DOMAINS" ]]; then
    echo -e "${R}❌ No domains found in Nginx config. Aborting.${X}"
    exit 1
fi

TOTAL=0; OK=0; WARN_COUNT=0; FAIL_COUNT=0; SKIP_COUNT=0
REPORT_LINES=()
ALERT_LINES=()

printf "${W}%-44s %-10s %-12s${X}\n" "DOMAIN" "HTTP" "SSL"
echo "──────────────────────────────────────────────────────────────────"

for domain in $DOMAINS; do
    (( TOTAL++ ))

    # ── Redirect-only vhost? ──────────────────────────────────────────────
    if [[ $(is_redirect_only "$domain") == "redirect" ]]; then
        (( SKIP_COUNT++ ))
        printf "${C}%-44s %-10s %-12s${X}\n" "$domain" "301" "—"
        REPORT_LINES+=("↩️  ${domain} | 301 redirect")
        continue
    fi

    # ── HTTP check with retries ───────────────────────────────────────────
    http_code="0"
    for (( attempt=1; attempt<=RETRY; attempt++ )); do
        http_code=$(curl -4 -Ls -o /dev/null \
            -w "%{http_code}" \
            --connect-timeout "$CONNECT_TIMEOUT" \
            --max-time "$MAX_TIME" \
            "https://${domain}" 2>/dev/null || echo "0")
        [[ "$http_code" =~ ^[23] ]] && break
        [[ $attempt -lt $RETRY ]] && sleep "$RETRY_DELAY"
    done

    # ── SSL check ─────────────────────────────────────────────────────────
    ssl_days=$(check_ssl_expiry "$domain")
    if [[ "$ssl_days" -lt 0 ]]; then
        ssl_label="NO SSL";          ssl_color="$R"; ssl_ok=false
    elif [[ "$ssl_days" -le "$WARN_DAYS" ]]; then
        ssl_label="${ssl_days}d ⚠";  ssl_color="$Y"; ssl_ok=false
    else
        ssl_label="${ssl_days}d";    ssl_color="$G"; ssl_ok=true
    fi

    # ── HTTP result ───────────────────────────────────────────────────────
    http_ok=false
    [[ "$http_code" =~ ^[23] ]] && http_ok=true
    $http_ok && http_color="$G" || http_color="$R"

    # ── Print row (HTTP and SSL columns coloured independently) ───────────
    printf "${http_color}%-44s %-10s${X}${ssl_color}%-12s${X}\n" \
        "$domain" "$http_code" "$ssl_label"

    # ── Counters & report lines ───────────────────────────────────────────
    if $http_ok && $ssl_ok; then
        (( OK++ ));         icon="✅"
    elif $http_ok; then
        (( WARN_COUNT++ )); icon="⚠️"
    else
        (( FAIL_COUNT++ )); icon="❌"
    fi

    REPORT_LINES+=("${icon} ${domain} | HTTP:${http_code} | SSL:${ssl_label}")
    ! $http_ok        && ALERT_LINES+=("🚨 DOWN: ${domain} | HTTP ${http_code} (${RETRY} retries)")
    $http_ok && ! $ssl_ok && ALERT_LINES+=("⚠️ SSL WARN: ${domain} — ${ssl_days}d left")
done

echo "──────────────────────────────────────────────────────────────────"
echo -e "  Total:${TOTAL}  ${G}OK:${OK}${X}  ${Y}Warn:${WARN_COUNT}${X}  ${R}Down:${FAIL_COUNT}${X}  ${C}Redirects:${SKIP_COUNT}${X}"
echo ""

# ── Telegram ──────────────────────────────────────────────────────────────────
REPORT_BODY=$(printf '%s\n' "${REPORT_LINES[@]}")
FULL_MSG="🌐 Domain Health | ${SERVER_TAG}
──────────────────────────
${REPORT_BODY}
──────────────────────────
Total:${TOTAL} | ✅${OK} | ⚠️${WARN_COUNT} | ❌${FAIL_COUNT} | ↩️${SKIP_COUNT}"

if [[ ${#ALERT_LINES[@]} -gt 0 || "$1" == "--report" ]]; then
    send_telegram "$FULL_MSG"
    [[ ${#ALERT_LINES[@]} -gt 0 ]] \
        && echo -e "${R}  ⚡ Problems found — alert sent to Telegram${X}" \
        || echo -e "${C}  📨 Full report sent to Telegram (--report)${X}"
else
    echo -e "${G}  ✓ All domains OK — no Telegram alert needed${X}"
fi
echo ""
