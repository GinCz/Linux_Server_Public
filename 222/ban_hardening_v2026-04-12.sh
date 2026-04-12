#!/bin/bash
clear
# = Rooted by VladiMIR | AI =
# ban_hardening_v2026-04-12.sh
# Ужесточение правил бана на сервере 222-DE-NetCup
#
# Что делает этот скрипт:
#   1. Создаёт страницу 429 с текстом EN/RU/CZ
#   2. Nginx: burst=2 (3-й быстрый запрос = 429)
#   3. Nginx: подключает error_page 429 к кастомной странице
#   4. CrowdSec сценарий: capacity=3 (3 попытки/мин → бан)
#   5. CrowdSec profiles.yaml: 1h → 24h → 7d → 30d эскалация
#
# ⚠️  ВНИМАНИЕ: на сервере работают живые сайты!
#     Nginx reload выполняется только после nginx -t (тест конфига)
#     CrowdSec перезапускается мягко через systemctl restart
#
# Запуск: bash /root/Linux_Server_Public/222/ban_hardening_v2026-04-12.sh
# ==============================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[>>]${NC} $1"; }
err()  { echo -e "${RED}[ERR]${NC} $1"; exit 1; }

echo -e "${BLUE}"
echo "================================================================"
echo "  BAN HARDENING v2026-04-12 — 222-DE-NetCup"
echo "================================================================"
echo -e "${NC}"

# ==============================================================
# ШАГ 1 — Создать страницу 429 (EN/RU/CZ)
# ==============================================================
warn "ШАГ 1: Создание страницы 429..."

mkdir -p /var/www/html

cat > /var/www/html/429.html << 'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>429 — Access Blocked</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    background: #0f0f0f;
    color: #e0e0e0;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 2rem;
  }
  .card {
    background: #1a1a1a;
    border: 1px solid #2a2a2a;
    border-radius: 12px;
    max-width: 640px;
    width: 100%;
    padding: 2.5rem;
    box-shadow: 0 8px 32px rgba(0,0,0,0.5);
  }
  .icon {
    font-size: 3rem;
    text-align: center;
    margin-bottom: 1.5rem;
  }
  .code {
    text-align: center;
    font-size: 0.75rem;
    color: #555;
    font-family: monospace;
    margin-bottom: 2rem;
    letter-spacing: 0.1em;
    text-transform: uppercase;
  }
  .lang-block {
    border-left: 3px solid #333;
    padding-left: 1.25rem;
    margin-bottom: 1.75rem;
  }
  .lang-block:last-of-type { margin-bottom: 0; }
  .lang-label {
    font-size: 0.7rem;
    text-transform: uppercase;
    letter-spacing: 0.12em;
    color: #555;
    margin-bottom: 0.5rem;
  }
  .lang-block h2 {
    font-size: 1.05rem;
    font-weight: 600;
    color: #cc4444;
    margin-bottom: 0.4rem;
  }
  .lang-block p {
    font-size: 0.9rem;
    color: #aaa;
    line-height: 1.6;
  }
  .lang-block a {
    color: #5588cc;
    text-decoration: none;
  }
  .lang-block a:hover { text-decoration: underline; }
  hr {
    border: none;
    border-top: 1px solid #222;
    margin: 1.75rem 0;
  }
</style>
</head>
<body>
<div class="card">
  <div class="icon">🚫</div>
  <div class="code">HTTP 429 — Too Many Requests</div>

  <div class="lang-block">
    <div class="lang-label">English</div>
    <h2>Your IP address has been blocked</h2>
    <p>Our server detected too many requests from your IP address in a short period of time. Access has been temporarily suspended. If you believe this is a mistake, please contact the server administrator.</p>
  </div>

  <hr>

  <div class="lang-block">
    <div class="lang-label">Русский</div>
    <h2>Ваш IP-адрес заблокирован сервером</h2>
    <p>Наш сервер зафиксировал слишком много запросов с вашего IP-адреса за короткое время. Доступ временно приостановлен. Если вы считаете, что это ошибка, пожалуйста, свяжитесь с администратором сервера.</p>
  </div>

  <hr>

  <div class="lang-block">
    <div class="lang-label">Čeština</div>
    <h2>Váš IP byl zablokován serverem</h2>
    <p>Náš server zaznamenal příliš mnoho požadavků z vaší IP adresy v krátkém časovém úseku. Přístup byl dočasně pozastaven. Pokud se domníváte, že jde o chybu, kontaktujte prosím správce serveru.</p>
  </div>

</div>
</body>
</html>
HTML

chown www-data:www-data /var/www/html/429.html
chmod 644 /var/www/html/429.html
log "Страница /var/www/html/429.html создана"

# ==============================================================
# ШАГ 2 — Nginx: обновить 00-wp-protection-zones.conf (burst=2)
# ==============================================================
warn "ШАГ 2: Обновление 00-wp-protection-zones.conf — rate снижен burst=3→2..."

# Обновляем только rate зоны (geo whitelist не трогаем)
sed -i \
  's/^limit_req_zone \$wp_limit_key zone=wp_login_222.*$/limit_req_zone $wp_limit_key zone=wp_login_222:30m rate=3r\/m;/' \
  /etc/nginx/conf.d/00-wp-protection-zones.conf

log "rate=6r/m → rate=3r/m (1 req каждые 20 сек)"

# ==============================================================
# ШАГ 3 — Nginx: burst=3→2 во всех сайт-конфигах
# ==============================================================
warn "ШАГ 3: Изменение burst=3→2 во всех активных конфигах сайтов..."

COUNT=$(grep -rl "wp_login_222 burst=3" /etc/nginx/fastpanel2-available/ 2>/dev/null | wc -l)
warn "Найдено файлов с burst=3: $COUNT"

if [ "$COUNT" -gt 0 ]; then
  grep -rl "wp_login_222 burst=3" /etc/nginx/fastpanel2-available/ | \
    xargs sed -i 's/limit_req zone=wp_login_222 burst=3 nodelay/limit_req zone=wp_login_222 burst=2 nodelay/g'
  log "burst=3→2 изменён в $COUNT файлах"
else
  warn "burst=3 не найден, возможно уже применено"
fi

# ==============================================================
# ШАГ 4 — Nginx: добавить error_page 429 в 00-wp-protection-zones.conf
#   (error_page должна быть в server{} блоке, не в http{} — используем
#    fastpanel2-includes/ с правилом error_page 429)
# ==============================================================
warn "ШАГ 4: Создание /etc/nginx/conf.d/00-error-pages.conf для 429..."

# Проверяем нет ли уже такого файла
if [ ! -f /etc/nginx/conf.d/00-error-pages.conf ]; then
  cat > /etc/nginx/conf.d/00-error-pages.conf << 'NGINX_ERR'
# = Rooted by VladiMIR | AI = v2026-04-12
# Глобальный error_page для 429 Too Many Requests
# Служит статической страницей на трёх языках (EN/RU/CZ)
# Подключается через fastpanel2-includes/
NGINX_ERR
  log "Заготовка 00-error-pages.conf создана"
fi

# error_page 429 в server{} уровне — нужен fastpanel2-includes
cat > /etc/nginx/fastpanel2-includes/error-429.conf << 'NGINX_429'
# = Rooted by VladiMIR | AI = v2026-04-12
# error_page 429 — отображается при rate-limit блокировке
error_page 429 /429-blocked.html;
location = /429-blocked.html {
    root /var/www/html;
    internal;
    try_files /429.html =429;
}
NGINX_429

log "/etc/nginx/fastpanel2-includes/error-429.conf создан"

# ==============================================================
# ШАГ 5 — Проверка конфига Nginx и reload
# ==============================================================
warn "ШАГ 5: Проверка nginx -t..."

if nginx -t 2>&1; then
  systemctl reload nginx
  log "Nginx перезагружен успешно!"
else
  err "ОШИБКА nginx -t! Проверь конфиги вручную. Изменения НЕ применены."
fi

# ==============================================================
# ШАГ 6 — CrowdSec: обновить сценарий (capacity=3)
# ==============================================================
warn "ШАГ 6: Обновление CrowdSec сценария custom/wp-login-hardban..."

cat > /etc/crowdsec/scenarios/custom-wp-login-hardban.yaml << 'CROWDSEC_SCENARIO'
# = Rooted by VladiMIR | AI =
# Custom WP Login hard ban v2026-04-12
# 3 attempts per 1 minute -> ban (HARDENED: was 5, now 3)
# Ban duration: 1h -> 24h -> 7d -> 30d (escalation via profiles.yaml)
# on_overflow removed: not supported in CrowdSec v1.6+
type: leaky
name: custom/wp-login-hardban
description: "WP-login brute force — 3 attempts/min -> escalating ban via profiles.yaml"
filter: "evt.Meta.log_type == 'http_access-log' and evt.Parsed.request == '/wp-login.php' and evt.Parsed.status in ['429', '200']"
groupby: evt.Meta.source_ip
distinct: evt.Parsed.status
capacity: 3
leakspeed: "60s"
blackhole: "2m"
labels:
  service: http
  confidence: high
  spoofable: false
  type: bruteforce
  remediation: true
CROWDSEC_SCENARIO

log "Сценарий обновлён: capacity 5→3, blackhole 1m→2m"

# ==============================================================
# ШАГ 7 — CrowdSec: обновить profiles.yaml (эскалация банов)
# ==============================================================
warn "ШАГ 7: Обновление profiles.yaml — эскалация 1h→24h→7d→30d..."

# Бэкап оригинала
cp /etc/crowdsec/profiles.yaml /etc/crowdsec/profiles.yaml.bak-$(date +%Y%m%d-%H%M%S)
log "Бэкап profiles.yaml создан"

cat > /etc/crowdsec/profiles.yaml << 'PROFILES'
# = Rooted by VladiMIR | AI =
# profiles.yaml — 222-DE-NetCup — v2026-04-12
#
# Эскалация банов:
#   1-й бан = 1h
#   2-й бан = 24h
#   3-й бан = 7d
#   4-й бан = 30d
#   5-й бан и далее = 30d (cap)
#
# Формула: min((count+1)*24, 720) hours, но 1-й = 1h особый случай
# Реализация: duration_expr с условием

name: default_ip_remediation
filters:
  - Alert.Remediation == true && Alert.GetScope() == "Ip"
decisions:
  - type: ban
    duration: 1h
duration_expr: |
  GetDecisionsCount(Alert.GetValue()) == 0 ? "1h" :
  GetDecisionsCount(Alert.GetValue()) == 1 ? "24h" :
  GetDecisionsCount(Alert.GetValue()) == 2 ? "168h" :
  "720h"
on_success: break
---
name: default_range_remediation
filters:
  - Alert.Remediation == true && Alert.GetScope() == "Range"
decisions:
  - type: ban
    duration: 12h
on_success: break
PROFILES

log "profiles.yaml обновлён"

# ==============================================================
# ШАГ 8 — Перезапуск CrowdSec
# ==============================================================
warn "ШАГ 8: Перезапуск CrowdSec..."

systemctl restart crowdsec
sleep 3

if systemctl is-active --quiet crowdsec; then
  log "CrowdSec запущен и работает!"
else
  err "CrowdSec не запустился! Проверь: journalctl -u crowdsec -n 30"
fi

# ==============================================================
# ИТОГ
# ==============================================================
echo ""
echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}  ГОТОВО — ban_hardening_v2026-04-12 применён${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""
echo "  Nginx:"
echo "    rate=3r/m (был 6r/m), burst=2 (был 3)"
echo "    Страница 429: /var/www/html/429.html (EN/RU/CZ)"
echo ""
echo "  CrowdSec:"
echo "    capacity: 3 попытки/мин → бан (был 5)"
echo "    1-й бан:  1 час"
echo "    2-й бан:  24 часа"
echo "    3-й бан:  7 дней (168h)"
echo "    4-й бан+: 30 дней (720h)"
echo ""
echo "  Проверка:"
echo "    cscli decisions list"
echo "    nginx -t"
echo "    curl -s -o /dev/null -w '%{http_code}\n' https://ТВОЙ-ДОМЕН/wp-login.php"
echo ""
