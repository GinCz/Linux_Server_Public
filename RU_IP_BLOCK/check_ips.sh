#!/usr/bin/env bash
# =============================================================================
#  check_ips.sh — Универсальная пакетная проверка блокировки IP-адресов в РФ
# =============================================================================
#  = Rooted by VladiMIR + AI | github.com/GinCz/Linux_Server_Public =
# =============================================================================

clear 2>/dev/null || true

# --- Colors ---
CY="\033[1;96m"; GN="\033[1;92m"; LG="\033[38;5;120m"
YL="\033[1;93m"; LY="\033[38;5;228m"; PK="\033[1;95m"
RD="\033[1;91m"; OR="\033[38;5;214m"; WH="\033[1;97m"; GR="\033[1;90m"; X="\033[0m"
HR="${CY}$(printf '═%.0s' {1..90})${X}"
DIV="${GR}$(printf '─%.0s' {1..90})${X}"

echo -e "$HR"
echo -e "  🛡️  ${WH}ПРОВЕРКА ДОСТУПНОСТИ И БЛОКИРОВОК IP-АДРЕСОВ В РФ${X}  ·  ${YL}v2026.09.22${X}"
echo -e "  📍 Место проверки: ${CY}$(hostname -I 2>/dev/null | awk '{print $1}') ($(hostname 2>/dev/null))${X}"
echo -e "$HR"

IP_LIST=()

if [ $# -gt 0 ]; then
    for arg in "$@"; do
        clean_ip=$(echo "$arg" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' || true)
        [ -n "$clean_ip" ] && IP_LIST+=("$clean_ip")
    done
fi

if [ ${#IP_LIST[@]} -eq 0 ]; then
    echo -e "\n${LY}Вставьте список IP-адресов (в столбик).${X}"
    echo -e "${GR}Для завершения ввода нажмите [Enter] на пустой строке (или Ctrl+D):${X}\n"
    
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            [ ${#IP_LIST[@]} -gt 0 ] && break || continue
        fi
        for token in $line; do
            clean_ip=$(echo "$token" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' || true)
            if [ -n "$clean_ip" ]; then
                IP_LIST+=("$clean_ip")
                echo -e "   ${GN}+${X} Добавлен: ${WH}${clean_ip}${X}"
            fi
        done
    done
fi

TOTAL=${#IP_LIST[@]}

if [ "$TOTAL" -eq 0 ]; then
    echo -e "\n${RD}✘ Не введено ни одного корректного IPv4-адреса.${X}\n"
    exit 1
fi

echo -e "\n$HR"
echo -e "  🚀 ${WH}Запуск комплексной проверки ${CY}${TOTAL}${WH} IP-адресов...${X}"
echo -e "$HR"

declare -a SUMMARY_TABLE=()
IDX=0

for IP in "${IP_LIST[@]}"; do
    IDX=$((IDX+1))
    echo -e "\n${CY}[${IDX}/${TOTAL}]${X} 🔍 ${WH}АНАЛИЗ IP:${X} ${YL}${IP}${X}"
    echo -e "$DIV"
    
    # 1. GeoIP & WHOIS Info
    GEO_INFO=$(curl -s --connect-timeout 3 -m 5 "http://ip-api.com/json/${IP}?fields=status,country,city,isp,org,as,query" 2>/dev/null || true)
    COUNTRY=$(echo "$GEO_INFO" | grep -oP '"country":"\K[^"]+' 2>/dev/null || echo "Unknown")
    CITY=$(echo "$GEO_INFO" | grep -oP '"city":"\K[^"]+' 2>/dev/null || echo "")
    ISP=$(echo "$GEO_INFO" | grep -oP '"isp":"\K[^"]+' 2>/dev/null || echo "Unknown")
    ASN=$(echo "$GEO_INFO" | grep -oP '"as":"\K[^"]+' 2>/dev/null || echo "")
    
    echo -e "  🌍 ${WH}Локация / Провайдер :${X} ${PK}${COUNTRY}${X} ${CITY:+($CITY)}, ${CY}${ISP}${X} ${ASN:+[$ASN]}"

    # 2. Local ICMP Ping Test
    echo -e "  📡 ${WH}Локальный Ping (из РФ):${X} \c"
    PING_OUT=$(ping -c 3 -W 2 "$IP" 2>&1 || true)
    LOCAL_PING_OK=0
    AVG_RTT="-"
    if echo "$PING_OUT" | grep -q "0% packet loss"; then
        AVG_RTT=$(echo "$PING_OUT" | awk -F'/' 'END{print $5}')
        echo -e "${GN}✔ ДОСТУПЕН${X} (0% потерь, RTT: ${CY}${AVG_RTT} ms${X})"
        LOCAL_PING_OK=1
    elif echo "$PING_OUT" | grep -q "100% packet loss"; then
        echo -e "${RD}✘ НЕ ОТВЕЧАЕТ${X} (100% потерь)"
    else
        LOSS=$(echo "$PING_OUT" | grep -oP '\d+(?=% packet loss)')
        AVG_RTT=$(echo "$PING_OUT" | awk -F'/' 'END{print $5}')
        echo -e "${YL}⚠ ЧАСТИЧНЫЕ ПОТЕРИ${X} (${LOSS}% потерь, RTT: ${AVG_RTT} ms)"
        LOCAL_PING_OK=1
    fi

    # 3. TCP Port Probing
    PORTS=(22 80 443 8080 8443 2053 2083 2087 2096 445 3389)
    PORT_NAMES=(
        [22]="SSH" [80]="HTTP" [443]="HTTPS" [8080]="HTTP-Alt"
        [8443]="HTTPS-Alt" [2053]="CF-SSL" [2083]="CF-SSL"
        [2087]="CF-SSL" [2096]="CF-SSL" [445]="SMB" [3389]="RDP"
    )
    
    OPEN_PORTS=()
    echo -e "  🔌 ${WH}Проверка портов (TCP):${X}"
    for P in "${PORTS[@]}"; do
        PNAME="${PORT_NAMES[$P]:-$P}"
        if timeout 1.5 bash -c "</dev/tcp/${IP}/${P}" 2>/dev/null; then
            echo -e "     ├─ Порт ${CY}${P}${X} (${PNAME}) : ${GN}✔ ОТКРЫТ И ДОСТУПЕН ИЗ РФ${X}"
            OPEN_PORTS+=("$P")
        fi
    done
    
    if [ ${#OPEN_PORTS[@]} -eq 0 ]; then
        echo -e "     └─ ${GR}Все тестируемые порты (22, 80, 443, 8080, 8443, 2053-2096, 445, 3389) закрыты${X}"
    fi

    # 4. Check-Host Multi-Node RU vs EU/US Probe
    echo -e "  🌐 ${WH}Check-Host (RU vs Мир):${X}"
    CHECK_JSON=$(python3 - "$IP" << 'PYEOF'
import urllib.request, json, time, sys

ip = sys.argv[1]
url = f'https://check-host.net/check-ping?host={ip}&node=ru1.node.check-host.net&node=ru2.node.check-host.net&node=de1.node.check-host.net&node=nl1.node.check-host.net&node=us1.node.check-host.net'

try:
    req = urllib.request.Request(url, headers={'Accept': 'application/json', 'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=5) as r:
        req_id = json.loads(r.read()).get('request_id')
    
    res = {}
    for _ in range(4):
        time.sleep(2)
        req2 = urllib.request.Request(f'https://check-host.net/check-result/{req_id}', headers={'Accept': 'application/json', 'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req2, timeout=5) as r2:
            res = json.loads(r2.read())
        if all(res.get(k) is not None for k in ['ru1.node.check-host.net', 'de1.node.check-host.net']):
            break

    def get_node(val):
        if val and isinstance(val, list) and len(val) > 0 and isinstance(val[0], list) and len(val[0]) > 0:
            item = val[0][0]
            if isinstance(item, list) and len(item) > 0 and item[0] == 'OK':
                return True, (item[1]*1000 if len(item)>1 else 0)
        return False, 0

    ru1_ok, ru1_rtt = get_node(res.get('ru1.node.check-host.net'))
    ru2_ok, ru2_rtt = get_node(res.get('ru2.node.check-host.net'))
    de1_ok, de1_rtt = get_node(res.get('de1.node.check-host.net'))
    nl1_ok, nl1_rtt = get_node(res.get('nl1.node.check-host.net'))
    us1_ok, us1_rtt = get_node(res.get('us1.node.check-host.net'))

    ru_avail = ru1_ok or ru2_ok
    eu_avail = de1_ok or nl1_ok or us1_ok

    out = {
        'ru1': f'{ru1_rtt:.1f} ms' if ru1_ok else 'LOSS',
        'ru2': f'{ru2_rtt:.1f} ms' if ru2_ok else 'LOSS',
        'de1': f'{de1_rtt:.1f} ms' if de1_ok else 'LOSS',
        'nl1': f'{nl1_rtt:.1f} ms' if nl1_ok else 'LOSS',
        'us1': f'{us1_rtt:.1f} ms' if us1_ok else 'LOSS',
        'ru_avail': ru_avail,
        'eu_avail': eu_avail
    }
    print(json.dumps(out))
except Exception as e:
    print(json.dumps({'error': str(e)}))
PYEOF
)

    RU1_STAT=$(echo "$CHECK_JSON" | grep -oP '"ru1":\s*"\K[^"]+' 2>/dev/null || echo "N/A")
    RU2_STAT=$(echo "$CHECK_JSON" | grep -oP '"ru2":\s*"\K[^"]+' 2>/dev/null || echo "N/A")
    DE1_STAT=$(echo "$CHECK_JSON" | grep -oP '"de1":\s*"\K[^"]+' 2>/dev/null || echo "N/A")
    NL1_STAT=$(echo "$CHECK_JSON" | grep -oP '"nl1":\s*"\K[^"]+' 2>/dev/null || echo "N/A")
    US1_STAT=$(echo "$CHECK_JSON" | grep -oP '"us1":\s*"\K[^"]+' 2>/dev/null || echo "N/A")
    RU_AVAIL=$(echo "$CHECK_JSON" | grep -oP '"ru_avail":\s*\K(true|false)' 2>/dev/null || echo "false")
    EU_AVAIL=$(echo "$CHECK_JSON" | grep -oP '"eu_avail":\s*\K(true|false)' 2>/dev/null || echo "false")

    # Format Node Lines
    if [ "$RU1_STAT" != "LOSS" ] && [ "$RU1_STAT" != "N/A" ]; then RU1_FMT="${GN}✔ ${RU1_STAT}${X}"; else RU1_FMT="${RD}✘ LOSS${X}"; fi
    if [ "$RU2_STAT" != "LOSS" ] && [ "$RU2_STAT" != "N/A" ]; then RU2_FMT="${GN}✔ ${RU2_STAT}${X}"; else RU2_FMT="${RD}✘ LOSS${X}"; fi
    if [ "$DE1_STAT" != "LOSS" ] && [ "$DE1_STAT" != "N/A" ]; then DE1_FMT="${GN}✔ ${DE1_STAT}${X}"; else DE1_FMT="${RD}✘ LOSS${X}"; fi
    if [ "$NL1_STAT" != "LOSS" ] && [ "$NL1_STAT" != "N/A" ]; then NL1_FMT="${GN}✔ ${NL1_STAT}${X}"; else NL1_FMT="${RD}✘ LOSS${X}"; fi
    if [ "$US1_STAT" != "LOSS" ] && [ "$US1_STAT" != "N/A" ]; then US1_FMT="${GN}✔ ${US1_STAT}${X}"; else US1_FMT="${RD}✘ LOSS${X}"; fi

    echo -e "     ├─ 🇷🇺 RU Ноды (Москва / СПб)     : ru1: ${RU1_FMT}  |  ru2: ${RU2_FMT}"
    echo -e "     └─ 🌍 EU/US Ноды (DE / NL / US)   : de: ${DE1_FMT}  |  nl: ${NL1_FMT}  |  us: ${US1_FMT}"

    # Final Verdict for this IP
    if [ "$LOCAL_PING_OK" -eq 1 ] && [ "$RU_AVAIL" = "true" ] && [ "$EU_AVAIL" = "true" ]; then
        VERDICT="${GN}🟢 ДОСТУПЕН ПОЛНОСТЬЮ (РФ + Весь мир)${X}"
        RU_SUMMARY_STATUS="${GN}✔ ${AVG_RTT} ms${X}"
        EU_SUMMARY_STATUS="${GN}✔ ${DE1_STAT}${X}"
    elif [ "$LOCAL_PING_OK" -eq 1 ] && [ "$RU_AVAIL" = "true" ]; then
        VERDICT="${GN}🟢 ДОСТУПЕН В РФ${X}"
        RU_SUMMARY_STATUS="${GN}✔ ${AVG_RTT} ms${X}"
        EU_SUMMARY_STATUS="${RD}✘ LOSS${X}"
    elif [ "$EU_AVAIL" = "true" ] && [ "$LOCAL_PING_OK" -eq 0 ] && [ "$RU_AVAIL" = "false" ]; then
        VERDICT="${RD}🔴 ЗАБЛОКИРОВАН В РФ (ТСПУ / РКН) — Доступен в Европе${X}"
        RU_SUMMARY_STATUS="${RD}✘ БЛОКИРОВКА${X}"
        EU_SUMMARY_STATUS="${GN}✔ ${DE1_STAT}${X}"
    elif [ ${#OPEN_PORTS[@]} -gt 0 ]; then
        VERDICT="${YL}🟡 ЧАСТИЧНЫЙ ДОСТУП (Открыты порты: ${OPEN_PORTS[*]})${X}"
        RU_SUMMARY_STATUS="${YL}⚠ ПОРТЫ${X}"
        EU_SUMMARY_STATUS="${LG}${DE1_STAT}${X}"
    else
        VERDICT="${RD}🔴 НЕДОСТУПЕН (Хост выключен или фильтрует все пакеты)${X}"
        RU_SUMMARY_STATUS="${RD}✘ LOSS${X}"
        EU_SUMMARY_STATUS="${RD}✘ LOSS${X}"
    fi
    
    echo -e "  📋 ${WH}Вердикт по IP          :${X} ${VERDICT}"
    SUMMARY_TABLE+=("$(printf "%-16s | %-12s | %-18s | %-14b | %-14b | %b" "$IP" "$COUNTRY" "${ISP:0:18}" "$RU_SUMMARY_STATUS" "$EU_SUMMARY_STATUS" "$VERDICT")")
done

echo -e "\n$HR"
echo -e "  📊  ${WH}ИТОГОВАЯ СВОДНАЯ ТАБЛИЦА ПРОВЕРКИ${X}"
echo -e "$HR"
printf "  ${YL}%-16s | %-12s | %-18s | %-14s | %-14s | %s${X}\n" "IP-АДРЕС" "СТРАНА" "ПРОВАЙДЕР" "🇷🇺 РФ (109/RU)" "🇩🇪 ЕВРОПА (DE)" "ИТОГОВЫЙ СТАТУС"
echo -e "  $DIV"
for row in "${SUMMARY_TABLE[@]}"; do
    echo -e "  ${row}"
done
echo -e "$HR\n"
