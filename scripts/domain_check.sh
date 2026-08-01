#!/usr/bin/env bash
# =============================================================================
#  domain_check.sh — Universal Domain Health Monitor
#  Works on: server 222 (EU/FastPanel) and server 109 (RU/FastPanel)
#  Checks : HTTP response code, SSL cert expiry
#  Auto-detects all domains from live Nginx config (nginx -T)
#
#  Redirect logic (curl-based):
#    - curl follows up to 10 redirects (-L flag)
#    - If final URL is on a DIFFERENT domain -> REDIRECT (cyan)
#    - www -> non-www, http -> https = same domain -> NOT a redirect
#    - If final code is 0/4xx/5xx -> DOWN (red)
#
#  nginx-redirect domains: auto-detected from nginx configs
#    (return 301 without proxy_pass) -> green, no curl, no alert
#
#  Version: 2026.08.01-v7
#  NOTE: Set TG_TOKEN and TG_CHAT_ID in /root/.server_env
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
# = Rooted by VladiMIR + AI | v.2026.08.01 | github.com/GinCz =

source /root/.server_env 2>/dev/null || true
source /root/scripts/common.sh 2>/dev/null || true

# -- Telegram ------------------------------------------------------------------
TG_TOKEN="${TG_TOKEN:-}"
TG_CHAT_ID="${TG_CHAT_ID:-261784949}"

# -- Colours -------------------------------------------------------------------
G=$'\033[1;32m'   # bright green  -- OK
Y=$'\033[1;33m'   # bright yellow -- SSL warning
R=$'\033[1;91m'   # bright red    -- error / down
C=$'\033[1;36m'   # bright cyan   -- external redirect
W=$'\033[1;37m'   # bright white  -- header
X=$'\033[0m'      # reset

SEP="${Y}$(printf '=%.0s' {1..90})${X}"

# -- Config --------------------------------------------------------------------
WARN_DAYS=14
CONNECT_TIMEOUT=5
MAX_TIME=10
RETRY=1
RETRY_DELAY=4
SERVER_TAG="${SERVER_TAG:-$(hostname)}"

# -- Helper: send Telegram (with timeout to prevent hanging) -------------------
send_telegram() {
    local msg="$1"
    [ -z "$TG_TOKEN" ] && return
    if [[ $(type -t send_tg) == function ]]; then
        send_tg "$msg"
    else
        curl -s --max-time 10 --connect-timeout 5 \
             -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
             -d "chat_id=${TG_CHAT_ID}" \
             --data-urlencode "text=${msg}" > /dev/null 2>&1 || true
    fi
}

# -- Helper: SSL expiry in days  (-1 = no cert / error) -----------------------
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

# -- Collect domains from Nginx ------------------------------------------------
collect_domains() {
    local raw
    raw=$(nginx -T 2>/dev/null \
        | grep -E '^\s*server_name\s' \
        | sed 's/server_name//g; s/;//g' \
        | tr ' ' '\n')

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

# -- Auto-detect nginx-redirect-only domains -----------------------------------
detect_nginx_redirects() {
    local conf domain has_return has_proxy target
    local -A seen

    while IFS= read -r line; do
        [[ "$line" =~ ^#\ configuration\ file\ (.+): ]] || continue
        conf="${BASH_REMATCH[1]}"
        [[ -f "$conf" ]] || continue
        [[ -n "${seen[$conf]+x}" ]] && continue
        seen[$conf]=1

        domain=$(grep -oP 'server_name\s+\K[^;]+' "$conf" 2>/dev/null \
            | tr ' ' '\n' \
            | grep '\.' \
            | grep -vE '^www\.' \
            | head -1)
        [[ -z "$domain" ]] && continue

        has_return=$(grep -cE 'return\s+30[1-9]' "$conf" 2>/dev/null | tr -d '[:space:]')
        has_proxy=$(grep -cE 'proxy_pass|fastcgi_pass' "$conf" 2>/dev/null | tr -d '[:space:]')
        has_return="${has_return:-0}"
        has_proxy="${has_proxy:-0}"

        if [[ "$has_return" -gt 0 && "$has_proxy" -eq 0 ]]; then
            target=$(grep -oP 'return\s+30[1-9]\s+\K\S+' "$conf" 2>/dev/null \
                | head -1 \
                | sed 's|https\?://||; s|[$/?].*||; s|;||g')
            [[ -z "$target" ]] && target="(redirect)"
            echo "${domain}:${target}"
        fi
    done < <(nginx -T 2>/dev/null)

    if [[ ${#seen[@]} -eq 0 ]]; then
        for conf in \
            /etc/nginx/sites-enabled/* \
            /etc/nginx/sites-available/* \
            /etc/nginx/conf.d/*.conf \
            /etc/nginx/fastpanel2-sites/* \
            /etc/nginx/fastpanel2-available/*; do
            [[ -f "$conf" ]] || continue

            domain=$(grep -oP 'server_name\s+\K[^;]+' "$conf" 2>/dev/null \
                | tr ' ' '\n' \
                | grep '\.' \
                | grep -vE '^www\.' \
                | head -1)
            [[ -z "$domain" ]] && continue

            has_return=$(grep -cE 'return\s+30[1-9]' "$conf" 2>/dev/null | tr -d '[:space:]')
            has_proxy=$(grep -cE 'proxy_pass|fastcgi_pass' "$conf" 2>/dev/null | tr -d '[:space:]')
            has_return="${has_return:-0}"
            has_proxy="${has_proxy:-0}"

            if [[ "$has_return" -gt 0 && "$has_proxy" -eq 0 ]]; then
                target=$(grep -oP 'return\s+30[1-9]\s+\K\S+' "$conf" 2>/dev/null \
                    | head -1 \
                    | sed 's|https\?://||; s|[$/?].*||; s|;||g')
                [[ -z "$target" ]] && target="(redirect)"
                echo "${domain}:${target}"
            fi
        done
    fi
}

# -- Core check ---------------------------------------------------------------
check_domain() {
    local domain="$1"

    strip_domain() { echo "$1" | sed -E 's|^https?://(www\.)?||; s|/.*||'; }

    local final_url http_code
    for (( attempt=1; attempt<=RETRY+1; attempt++ )); do
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

    if ! [[ "$http_code" =~ ^[23] ]]; then
        echo "down:$http_code"
        return
    fi

    local orig_root final_root
    orig_root=$(strip_domain "$domain")
    final_root=$(strip_domain "$final_url")

    if [[ -n "$final_root" && "$final_root" != "$orig_root" ]]; then
        echo "redirect:$final_url"
    else
        echo "ok:$http_code"
    fi
}

# =============================================================================
#  MAIN
# =============================================================================
clear

printf "%s\n" "$SEP"
printf " ${W}🌐 DOMAIN HEALTH CHECK${X}  ${C}%s${X}  ${Y}v.2026.08.01-v7${X}\n" "$SERVER_TAG"
printf "%s\n\n" "$SEP"

DOMAINS=$(collect_domains)
if [[ -z "$DOMAINS" ]]; then
    printf "${R}❌ No domains found in Nginx config. Aborting.${X}\n"
    exit 1
fi

declare -A NGINX_REDIRECT_MAP
while IFS=: read -r rd_domain rd_target; do
    [[ -n "$rd_domain" ]] && NGINX_REDIRECT_MAP["$rd_domain"]="${rd_target:-redirect}"
done < <(detect_nginx_redirects)

TOTAL=0; OK=0; WARN_COUNT=0; FAIL_COUNT=0; SKIP_COUNT=0; NGINX_REDIR_COUNT=0
REPORT_LINES=()
ALERT_LINES=()

printf "${W}%-44s %-10s %-12s${X}\n" "DOMAIN" "HTTP" "SSL"
printf '%s\n' "$(printf '=%.0s' {1..90})"

for domain in $DOMAINS; do
    (( TOTAL++ ))

    if [[ -n "${NGINX_REDIRECT_MAP[$domain]+x}" ]]; then
        (( NGINX_REDIR_COUNT++ ))
        target="${NGINX_REDIRECT_MAP[$domain]}"
        printf "${G}↩ %-43s${X} ${C}%-10s${X} ${G}-> %-10s${X}\n" \
            "$domain" "301" "$target"
        REPORT_LINES+=("↩️ ${domain} | nginx redirect -> ${target}")
        continue
    fi

    result=$(check_domain "$domain")
    kind="${result%%:*}"
    detail="${result#*:}"

    case "$kind" in
      redirect)
        (( SKIP_COUNT++ ))
        clean_url=$(echo "$detail" | sed 's|https\?://||; s|/.*||')
        printf "${C}↩️ %-43s %-10s -> %-10s${X}\n" "$domain" "301" "$clean_url"
        REPORT_LINES+=("↩️ ${domain} | redirect -> ${clean_url}")
        ;;
      ok)
        http_code="$detail"
        ssl_days=$(check_ssl_expiry "$domain")
        if   [[ "$ssl_days" -lt 0 ]];            then ssl_label="NO SSL";        ssl_color="$R"; ssl_ok=false
        elif [[ "$ssl_days" -le "$WARN_DAYS" ]]; then ssl_label="${ssl_days}d ⚠"; ssl_color="$Y"; ssl_ok=false
        else                                          ssl_label="${ssl_days}d";  ssl_color="$G"; ssl_ok=true
        fi
        printf "${G}✅ %-43s %-10s${X}${ssl_color}%-12s${X}\n" \
            "$domain" "$http_code" "$ssl_label"
        if $ssl_ok; then
            (( OK++ ))
            REPORT_LINES+=("✅ ${domain} | HTTP:${http_code} | SSL:${ssl_label}")
        else
            (( WARN_COUNT++ ))
            REPORT_LINES+=("⚠️ ${domain} | HTTP:${http_code} | SSL:${ssl_label}")
            ALERT_LINES+=("⚠️ SSL expiring: ${domain} — ${ssl_days}d left")
        fi
        ;;
      down)
        http_code="$detail"
        ssl_days=$(check_ssl_expiry "$domain")
        [[ "$ssl_days" -lt 0 ]] && ssl_label="NO SSL" || ssl_label="${ssl_days}d"
        printf "${R}❌ %-43s %-10s %-12s${X}\n" \
            "$domain" "$http_code" "$ssl_label"
        (( FAIL_COUNT++ ))
        REPORT_LINES+=("❌ ${domain} | HTTP:${http_code} | SSL:${ssl_label}")
        ALERT_LINES+=("🚨 DOWN: ${domain} | HTTP:${http_code} | SSL:${ssl_label}")
        ;;
    esac
done

printf '%s\n' "$(printf '=%.0s' {1..90})"
printf "  Total:${W}%d${X}  ${G}✅ OK:%d${X}  ${Y}⚠️ Warn:%d${X}  ${R}❌ Down:%d${X}  ${C}↩️ Redir:%d${X}  ${G}↩ nginx-redir:%d${X}\n" \
    "$TOTAL" "$OK" "$WARN_COUNT" "$FAIL_COUNT" "$SKIP_COUNT" "$NGINX_REDIR_COUNT"
echo ""

REPORT_BODY=$(printf '%s\n' "${REPORT_LINES[@]}")
FULL_MSG="🌐 Domain Health | ${SERVER_TAG}
--------------------------
${REPORT_BODY}
--------------------------
Total:${TOTAL} | ✅${OK} | ⚠️${WARN_COUNT} | ❌${FAIL_COUNT} | ↩️${SKIP_COUNT} | ↩${NGINX_REDIR_COUNT}"

if [[ ${#ALERT_LINES[@]} -gt 0 || "$1" == "--report" ]]; then
    send_telegram "$FULL_MSG"
    [[ ${#ALERT_LINES[@]} -gt 0 ]] \
        && printf "${R}  ⚡ Problems found — alert sent to Telegram${X}\n" \
        || printf "${C}  📨 Full report sent to Telegram (--report)${X}\n"
else
    printf "${G}  ✓ All domains OK — no Telegram alert needed${X}\n"
fi
echo ""
