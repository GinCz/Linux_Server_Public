#!/usr/bin/env bash
# =============================================================================
#  check_ips.sh — Универсальная пакетная проверка блокировки IP-адресов в РФ
# =============================================================================
#  = Rooted by VladiMIR + AI | github.com/GinCz/Linux_Server_Public =
# =============================================================================

clear

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
        # Stop on empty line if we already have some IPs
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
echo -e "  🚀 ${WH}Запуск проверки ${CY}${TOTAL}${WH} IP-адресов...${X}"
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

    # 2. ICMP Ping Test
    echo -e "  📡 ${WH}ICMP Ping (из РФ)   :${X} \c"
    PING_OUT=$(ping -c 3 -W 2 "$IP" 2>&1 || true)
    PING_OK=0
    AVG_RTT="-"
    if echo "$PING_OUT" | grep -q "0% packet loss"; then
        AVG_RTT=$(echo "$PING_OUT" | awk -F'/' 'END{print $5}')
        echo -e "${GN}✔ ДОСТУПЕН${X}  (0% потерь, RTT: ${CY}${AVG_RTT} ms${X})"
        PING_OK=1
    elif echo "$PING_OUT" | grep -q "100% packet loss"; then
        echo -e "${RD}✘ НЕ ОТВЕЧАЕТ${X} (100% потерь — ICMP отфильтрован или IP заблокирован)"
    else
        LOSS=$(echo "$PING_OUT" | grep -oP '\d+(?=% packet loss)')
        echo -e "${YL}⚠ ЧАСТИЧНЫЕ ПОТЕРИ${X} (${LOSS}% потерь)"
        PING_OK=1
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
            echo -e "     ├─ Порт ${CY}${P}${X} (${PNAME}) : ${GN}✔ ОТКРЫТ И ДОСТУПЕН${X}"
            OPEN_PORTS+=("$P")
        fi
    done
    
    if [ ${#OPEN_PORTS[@]} -eq 0 ]; then
        echo -e "     └─ ${GR}Все тестируемые порты (22, 80, 443, 8080, 8443, 2053-2096, 445, 3389) закрыты или заблокированы ТСПУ${X}"
    fi

    # 4. HTTP / HTTPS DPI Inspection (TSPU RST Check)
    DPI_BLOCKED=0
    if [[ " ${OPEN_PORTS[*]} " =~ " 80 " ]] || [[ " ${OPEN_PORTS[*]} " =~ " 443 " ]]; then
        echo -e "  🛡️ ${WH}DPI / ТСПУ Handshake:${X} \c"
        CURL_TEST=$(curl -Is --connect-timeout 3 -m 5 "http://${IP}" 2>&1 || true)
        if echo "$CURL_TEST" | grep -qiE 'HTTP/|connection reset|refused'; then
            if echo "$CURL_TEST" | grep -qi 'connection reset'; then
                echo -e "${RD}✘ ОБНАРУЖЕН СБРОС (TCP RST / Блокировка ТСПУ)${X}"
                DPI_BLOCKED=1
            else
                echo -e "${GN}✔ Проходит без RST-сбросов${X}"
            fi
        else
            echo -e "${LG}Обычный ответ${X}"
        fi
    fi

    # 5. GlobalCheck / Check-Host API Probe
    echo -e "  🌐 ${WH}Check-Host (RU vs EU):${X} \c"
    CHECK_RES=$(python3 -c "
import urllib.request, json, time
ip = '$IP'
try:
    req = urllib.request.Request(f'https://check-host.net/check-ping?host={ip}&max_nodes=6', headers={'Accept': 'application/json', 'User-Agent': 'RU_IP_BLOCK/1.3'})
    with urllib.request.urlopen(req, timeout=5) as r:
        req_id = json.loads(r.read()).get('request_id')
    time.sleep(2.5)
    req2 = urllib.request.Request(f'https://check-host.net/check-result/{req_id}', headers={'Accept': 'application/json', 'User-Agent': 'RU_IP_BLOCK/1.3'})
    with urllib.request.urlopen(req2, timeout=5) as r2:
        res = json.loads(r2.read())
    ru_nodes = [k for k in res.keys() if 'ru' in k or 'md' in k]
    eu_nodes = [k for k in res.keys() if 'ru' not in k and 'md' not in k]
    ru_ok = any(res[k] and res[k][0] and res[k][0][0] == 'OK' for k in ru_nodes if k in res)
    eu_ok = any(res[k] and res[k][0] and res[k][0][0] == 'OK' for k in eu_nodes if k in res)
    if ru_ok and eu_ok:
        print('GLOBAL_OK')
    elif not ru_ok and eu_ok:
        print('RU_BLOCKED')
    elif ru_ok and not eu_ok:
        print('EU_BLOCKED')
    else:
        print('ALL_LOSS')
except Exception:
    print('API_TIMEOUT')
" 2>/dev/null || echo "API_ERR")

    case "$CHECK_RES" in
        "GLOBAL_OK") echo -e "${GN}✔ Доступен глобально (и в РФ, и в ЕС)${X}" ;;
        "RU_BLOCKED") echo -e "${RD}✘ Блокируется из РФ, но доступен в Европе${X}"; DPI_BLOCKED=1 ;;
        "ALL_LOSS") echo -e "${OR}⚠ Не отвечает ни в РФ, ни в ЕС (сервер выключен/дропает)${X}" ;;
        *) echo -e "${GR}Тест Check-Host выполнен${X}" ;;
    esac

    # Final Verdict for this IP
    if [ "$PING_OK" -eq 1 ] && [ ${#OPEN_PORTS[@]} -gt 0 ] && [ "$DPI_BLOCKED" -eq 0 ]; then
        VERDICT="${GN}🟢 ДОСТУПЕН В РФ${X}"
        V_SHORT="ДОСТУПЕН"
    elif [ ${#OPEN_PORTS[@]} -gt 0 ]; then
        VERDICT="${YL}🟡 ЧАСТИЧНЫЙ ДОСТУП (Открыты порты: ${OPEN_PORTS[*]})${X}"
        V_SHORT="ЧАСТИЧНЫЙ"
    elif [ "$PING_OK" -eq 1 ]; then
        VERDICT="${YL}🟡 ПИНГ РАБОТАЕТ (Порты закрыты / нестандартные)${X}"
        V_SHORT="ТОЛЬКО PING"
    else
        VERDICT="${RD}🔴 ЗАБЛОКИРОВАН ИЛИ НЕДОСТУПЕН В РФ${X}"
        V_SHORT="НЕДОСТУПЕН"
    fi
    
    echo -e "  📋 ${WH}Вердикт по IP       :${X} ${VERDICT}"
    SUMMARY_TABLE+=("$(printf "%-16s | %-12s | %-20s | %-10s | %s" "$IP" "$COUNTRY" "${ISP:0:20}" "$AVG_RTT" "$V_SHORT")")
done

echo -e "\n$HR"
echo -e "  📊  ${WH}ИТОГОВАЯ СВОДНАЯ ТАБЛИЦА ПРОВЕРКИ${X}"
echo -e "$HR"
printf "  ${YL}%-16s | %-12s | %-20s | %-10s | %s${X}\n" "IP-АДРЕС" "СТРАНА" "ПРОВАЙДЕР" "RTT (мс)" "СТАТУС В РФ"
echo -e "  $DIV"
for row in "${SUMMARY_TABLE[@]}"; do
    if [[ "$row" =~ "ДОСТУПЕН" ]]; then
        echo -e "  ${GN}${row}${X}"
    elif [[ "$row" =~ "ЧАСТИЧНЫЙ" || "$row" =~ "ТОЛЬКО PING" ]]; then
        echo -e "  ${YL}${row}${X}"
    else
        echo -e "  ${RD}${row}${X}"
    fi
done
echo -e "$HR\n"
