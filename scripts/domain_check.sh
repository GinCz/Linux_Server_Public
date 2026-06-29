#!/usr/bin/env bash
# =============================================================================
#  domain_check.sh — Universal Domain Health Monitor
#  Works on: server 222 (EU/FastPanel) and server 109 (RU/FastPanel)
#  Checks : HTTP response code, SSL cert expiry
#  Auto-detects all domains from live Nginx config (nginx -T)
#
#  Redirect logic (curl-based, NOT nginx config analysis):
#    - curl follows up to 10 redirects (-L flag)
#    - If final code is 2xx/3xx AND final URL is on a DIFFERENT domain
#      (e.g. mariela.ru → wix.com) → marked as REDIRECT (cyan, no SSL check)
#    - www → non-www, http → https = same domain → NOT a redirect
#    - If final code is 0/4xx/5xx → DOWN (red)
#
#  Version: 2026.06.29-v3
# =============================================================================
#
#  Usage:
#    bash /root/scripts/domain_check.sh            # alert only on problems
#    bash /root/scripts/domain_check.sh --report   # always send Telegram report
#
#  Cron:
#    0 */6 * * * /root/scripts/domain_check.sh
#    0 8   * * * /root/scripts/domain_check.sh --report
# =============================================================================

source /root/.server_env 2>/dev/null || true
source /root/scripts/common.sh 2>/dev/null || true

# ── Telegram ──────────────────────────────────────────────────────────────────
TG_TOKEN="${TG_TOKEN:-1226649515:AAEW2Vk2HSb_O693hhHfiHcPgfye4AcTURQ}"
TG_CHAT_ID="${TG_CHAT_ID:-261784949}"

# ── Colours ───────────────────────────────────────────────────────────────────
G='\033[1;32m'   # bright green  — OK
Y='\033[1;33m'   # bright yellow — SSL warning (<= WARN_DAYS)
R='\033[1;91m'   # bright red    — error / down
C='\033[1;36m'   # bright cyan   — external redirect
W='\033[1;37m'   # bright white  — header
X='\033[0m'      # reset

# ── Config ────────────────────────────────────────────────────────────────────
WARN_DAYS=14
CONNECT_TIMEOUT=7
MAX_TIME=12
RETRY=2
RETRY_DELAY=6
SERVER_TAG="${SERVER_TAG:-$(hostname)}"

# ── Helper: send Telegram ───────────────────────────────────────────────────
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

# ── Helper: SSL expiry in days  (-1 = no cert / error) ─────────────────────
check_ssl_expiry() {
    local domain="$1"
    local expiry_date
    expiry_date=$(echo | timeout 6 openssl s_client \
        -connect "${domain}:443" -servername "$domain" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null \
        | cut -d= -f2)
    [[ -z "$expiry_date" ]] && { echo -1; return; }
    local epoch
    epoch=$(date -d "$expiry_date" +%s 2>/dev/null) || { echo -1; return; }
    echo $(( (epoch - $(date +%s)) / 86400 ))
}

# ── Collect domains from Nginx ───────────────────────────────────────────────
collect_domains() {
    local raw
    # Primary: nginx -T parses all includes correctly
    raw=$(nginx -T 2>/dev/null \
        | grep -E '^\s*server_name\s' \
        | sed 's/server_name//g; s/;//g' \
        | tr ' ' '\n')

    # Fallback: grep config dirs
    if [[ -z "$raw" ]]; then
        raw=$(grep -roP 'server_name \K[^;]+' \
            /etc/nginx/sites-enabled/ \
            /etc/nginx/fastpanel2-sites/ \
            /etc/nginx/fastpanel2-available/ \
            /etc/nginx/conf.d/ 2>/dev/null \
            | awk -F: '{print $2}' | tr ' ' '\n')
    fi

    echo "$raw" \
        | sed 's/^\s*//; s/\s*$//' \
        | grep '\.' \
        | grep -vE '^www\.' \
        | grep -vE 'localhost|^\*' \
        | sort -u
}

# ── Core check: returns "redirect:<final_url>" | "ok:<code>" | "down:<code>" ──
# Logic:
#   1. curl -L follows all redirects, captures final URL and final HTTP code
#   2. Extract root domain from final URL
#   3. If final domain != original domain → external redirect
#   4. If final domain == original domain → treat as normal (www/https redirect)
check_domain() {
    local domain="$1"

    # Extract root domain (strip www. prefix)
    strip_domain() { echo "$1" | sed -E 's|^https?://(www\.)?||; s|/.*||'; }

    local final_url http_code
    for (( attempt=1; attempt<=RETRY+1; attempt++ )); do
        # Write both final URL and status code
        read -r http_code final_url < <(
            curl -4 -L -s -o /dev/null \
                --connect-timeout "$CONNECT_TIMEOUT" \
                --max-time "$MAX_TIME" \
                --max-redirs 10 \
                -w "%{http_code} %{url_effective}" \
                "https://${domain}" 2>/dev/null
        )
        http_code="${http_code:-0}"
        [[ "$http_code" =~ ^[23] ]] && break
        [[ $attempt -le $RETRY ]] && sleep "$RETRY_DELAY"
    done

    # Down?
    if ! [[ "$http_code" =~ ^[23] ]]; then
        echo "down:$http_code"
        return
    fi

    # External redirect?
    local orig_root final_root
    orig_root=$(strip_domain "$domain")
    final_root=$(strip_domain "$final_url")

    # Compare root domains (remove www. before comparing)
    if [[ -n "$final_root" && "$final_root" != "$orig_root" ]]; then
        echo "redirect:$final_url"
    else
        echo "ok:$http_code"
    fi
}

# ──────────────────────────────────────────────────────────────────────
#  MAIN
# ──────────────────────────────────────────────────────────────────────
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
    result=$(check_domain "$domain")
    kind="${result%%:*}"
    detail="${result#*:}"

    case "$kind" in

      redirect)
        # External redirect — cyan, no SSL check, not an error
        (( SKIP_COUNT++ ))
        printf "${C}%-44s %-10s %-12s${X}\n" "$domain" "301→" "—"
        REPORT_LINES+=("↩️ ${domain} | redirect → ${detail}")
        ;;

      ok)
        http_code="$detail"
        # SSL check only for working sites
        ssl_days=$(check_ssl_expiry "$domain")
        if   [[ "$ssl_days" -lt 0 ]];            then ssl_label="NO SSL";         ssl_color="$R"; ssl_ok=false
        elif [[ "$ssl_days" -le "$WARN_DAYS" ]]; then ssl_label="${ssl_days}d ⚠"; ssl_color="$Y"; ssl_ok=false
        else                                          ssl_label="${ssl_days}d";   ssl_color="$G"; ssl_ok=true
        fi

        printf "${G}%-44s %-10s${X}${ssl_color}%-12s${X}\n" \
            "$domain" "$http_code" "$ssl_label"

        if $ssl_ok; then
            (( OK++ ));         icon="✅"
        else
            (( WARN_COUNT++ )); icon="⚠️"
            ALERT_LINES+=("⚠️ SSL WARN: ${domain} — ${ssl_days}d left")
        fi
        REPORT_LINES+=("${icon} ${domain} | HTTP:${http_code} | SSL:${ssl_label}")
        ;;

      down)
        http_code="$detail"
        # Still check SSL (might give useful info)
        ssl_days=$(check_ssl_expiry "$domain")
        [[ "$ssl_days" -lt 0 ]] && ssl_label="NO SSL" || ssl_label="${ssl_days}d"

        printf "${R}%-44s %-10s %-12s${X}\n" \
            "$domain" "$http_code" "$ssl_label"

        (( FAIL_COUNT++ ))
        REPORT_LINES+=("\u274c ${domain} | HTTP:${http_code} | SSL:${ssl_label}")
        ALERT_LINES+=("🚨 DOWN: ${domain} | HTTP:${http_code} | SSL:${ssl_label}")
        ;;
    esac
done

echo "──────────────────────────────────────────────────────────────────"
echo -e "  Total:${TOTAL}  ${G}OK:${OK}${X}  ${Y}Warn:${WARN_COUNT}${X}  ${R}Down:${FAIL_COUNT}${X}  ${C}Redirect:${SKIP_COUNT}${X}"
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
