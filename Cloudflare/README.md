# Cloudflare Security Scripts

> **Server:** 222-DE-NetCup (152.53.182.222)  
> **Run with:** `export CF_TOKEN="cfat_..."` then `bash <(curl -sL ...)`  
> **= Rooted by VladiMIR + AI | v2026.06.04c | github.com/GinCz =**

---

## Overview

All scripts apply **3-layer Cloudflare WAF security** to **ALL active zones** (auto-fetched from CF account).

| Rule # | Name | Action |
|--------|------|--------|
| **27** | Whitelist Skip | 14 trusted IPs → bypass ALL CF rules |
| **37** | Firewall (variant) | Attack paths + bad UA → Managed Challenge |
| **47** | Rate Limit | 100 req / 10s → Block 429 |

---

## Scripts

### `cf-all-domains-wp.sh` — WordPress Extended

```bash
export CF_TOKEN="cfat_..."
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Cloudflare/cf-all-domains-wp.sh)
```

**Rule 37 protects:**
- `/wp-login.php`, `/xmlrpc.php`, `/wp-cron.php`, `/wp-signup.php`, `/wp-register.php`
- `/wp-trackback.php`, `/wp-comments-post.php`
- `/wp-config`, `/.env`, `/.git`, `/.htaccess`, `/config.php`
- `/setup.php`, `/install.php`, `/upgrade.php`, `/phpinfo`
- `/adminer`, `/phpmyadmin`, `/pma`, `/mysql`
- `/wp-content/debug.log`, `/wp-includes/ms-files.php`
- `/wp-admin/*` (except `admin-ajax.php`)
- `/wp-json/wp/v2/users`, `/wp/v2/settings`
- Empty UA, `sqlmap`, `nikto`, `nmap`, `masscan`, `zgrab`
- `python-requests`, `go-http-client`, `curl/`, `libwww-perl`
- `WPScan`, `Acunetix`, `dirbuster`, `nuclei`

---

### `cf-all-domains-wp-woo.sh` — WordPress + WooCommerce

```bash
export CF_TOKEN="cfat_..."
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Cloudflare/cf-all-domains-wp-woo.sh)
```

**WooCommerce additions (Rule 37):**
- `/wc-api/` — REST API abuse
- `/wp-json/wc/` — WC REST API unauthorized access
- `?wc-ajax=` — AJAX flood
- `/checkout/` — carding attacks
- `/my-account/` — brute force accounts
- `/cart/` — cart flooding

---

### `cf-all-domains-wp-ads.sh` — WordPress + Classified Ads

```bash
export CF_TOKEN="cfat_..."
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Cloudflare/cf-all-domains-wp-ads.sh)
```

**Classified Ads additions (Rule 37):**
- `/wp-json/*/listings` — listing scraping
- `?action=dokan*`, `?action=wcfm*` — vendor AJAX abuse
- `/author/` — user enumeration via author pages
- `/feed/` — RSS/Atom feed scraping
- `/?attachment_id=` — media enumeration
- Bad bots: `AhrefsBot`, `SemrushBot`, `MJ12bot`, `DotBot`, `PetalBot`

---

## Whitelisted IPs (Rule 27)

| IP | Server / Name |
|----|---------------|
| `152.53.182.222` | DE server 222 |
| `212.109.223.109` | RU server 109 |
| `109.234.38.47` | VPN ALEX_47 |
| `144.124.228.237` | VPN 4TON_237 |
| `144.124.232.9` | VPN TATRA_9 |
| `144.124.228.227` | VPN SHAHIN_227 |
| `144.124.239.24` | VPN STOLB_24 |
| `91.84.118.178` | VPN PILIK_178 |
| `146.103.110.176` | VPN ILYA_176 |
| `144.124.233.38` | VPN SO_38 |
| `185.100.197.16` | Home IP |
| `185.14.233.235` | Home IP |
| `185.14.232.0` | Home IP |
| `90.181.133.10` | Work IP |

---

## Legacy Scripts (single-domain)

- `cloudflare-wp.sh` — original WP single-domain
- `cloudflare-wp-woo.sh` — original WP+Woo single-domain
- `cloudflare-wp-class.sh` — original classified ads single-domain
- `cloudflare-wp-security.sh` — original extended security single-domain
- `cloudflare-wp-batch.sh` — batch script for specific domain list

---

---

# Cloudflare API — Полное руководство по запросам и устранению ошибок

> Эта секция написана на основе реального опыта работы со скриптами на сервере 222.  
> Здесь задокументированы все типичные ошибки, их причины и правильные решения.

---

## 1. Правильный порядок действий перед запуском скрипта

Перед каждым запуском скрипта обязательно выполни следующую проверку:

### 1.1 Проверка токена

```bash
# Проверка что токен работает и имеет нужные права
curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" | python3 -m json.tool
```

**Ожидаемый ответ:**
```json
{
  "success": true,
  "result": {
    "id": "...",
    "status": "active"
  }
}
```

Если `"success": false` — токен невалидный или истёк. Создай новый в [CF Dashboard → My Profile → API Tokens](https://dash.cloudflare.com/profile/api-tokens).

### 1.2 Необходимые права токена

Токен должен иметь ВСЕ следующие права:

| Permission | Access |
|------------|--------|
| `Zone → Zone Settings` | Edit |
| `Zone → Zone` | Read |
| `Zone → Firewall Services` | Edit |
| `Zone → WAF` | Edit |

**Zone Resources:** `Include → All zones` (или конкретный аккаунт)

> ⚠️ **ВАЖНО:** Если токен создан с правами `All zones` через Account-level, он может не иметь доступа к Zone-level rulesets. В этом случае создай токен через **Zone Resources → All zones** в разделе Zone-level permissions.

### 1.3 Проверка доступных зон

```bash
# Получить список всех активных зон и их ID
curl -s -X GET "https://api.cloudflare.com/client/v4/zones?status=active&per_page=50" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  | python3 -c "
import sys, json
d = json.load(sys.stdin)
if not d.get('success'):
    print('ERROR:', d.get('errors'))
else:
    for z in d['result']:
        print(z['id'], z['name'], z['status'])
    print('Total:', len(d['result']))
"
```

---

## 2. Архитектура Cloudflare Rulesets API (важно понять)

CF использует **два разных API** для правил — старый и новый. Скрипты используют **новый Rulesets API (v4)**.

```
Аккаунт
└── Зона (Zone)
    ├── Firewall Custom Rules  → /zones/{zone_id}/rulesets  (phase: http_request_firewall_custom)
    └── Rate Limiting Rules    → /zones/{zone_id}/rulesets/phases/http_ratelimit/entrypoint
```

### Ключевое правило: PUT заменяет ВСЕ правила целиком

- `POST /zones/{id}/rulesets` — создаёт новый ruleset (только если его нет)
- `PUT /zones/{id}/rulesets/{ruleset_id}` — **ЗАМЕНЯЕТ** весь ruleset (все старые правила удаляются)
- `GET /zones/{id}/rulesets` — получает список всех rulesets зоны

> ⚠️ Именно поэтому скрипт сначала читает существующий ruleset ID, а потом делает PUT с новыми правилами — иначе создаётся дублирующий ruleset и CF возвращает ошибку.

---

## 3. Типичные ошибки и их решения

### Ошибка: `"Could not route to /zones/.../rulesets, perhaps your object identifier is invalid"`

**Причина:** Неверный Zone ID или Zone ID от другого аккаунта.  
**Решение:**
```bash
# Получить правильный Zone ID для конкретного домена
curl -s "https://api.cloudflare.com/client/v4/zones?name=example.com" \
  -H "Authorization: Bearer $CF_TOKEN" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result'][0]['id'] if d['result'] else 'NOT FOUND')"
```

---

### Ошибка: `"firewall.api.not_entitled"` или `"This zone is not allowed to use this feature"`

**Причина:** Зона на FREE плане пытается использовать Pro/Business функции.  
**Что работает на FREE:**
- Custom Firewall Rules (WAF) — ✅ до 5 правил
- Rate Limiting (новый Rulesets API) — ✅ 1 правило
- Security Level — ✅
- Browser Integrity Check — ✅

**Что НЕ работает на FREE:**
- Bot Management API (`/bot_management`) — ❌ только Pro+
- Advanced Rate Limiting (несколько правил) — ❌ только Pro+
- Managed Rulesets (OWASP, CF Managed) — ❌ только Pro+

**Решение в скрипте:** Bot Fight Mode через API игнорируется с тихой ошибкой, вместо этого выводится `OK (set via Dashboard)`. Установить вручную: **CF Dashboard → Security → Bots → Bot Fight Mode → ON**.

---

### Ошибка: `"Invalid request: There is already a phase ruleset for phase 'http_request_firewall_custom'"`

**Причина:** Попытка создать второй ruleset через POST когда он уже существует.  
**Правило:** На каждую зону может быть только ОДИН ruleset для каждой phase.

**Решение:** Скрипт правильно делает это автоматически:
1. GET /rulesets → ищем существующий ruleset с нужной phase
2. Если найден → PUT (обновляем)
3. Если не найден → POST (создаём)

**Ручная проверка:**
```bash
ZONE_ID="ваш_zone_id"
curl -s "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/rulesets" \
  -H "Authorization: Bearer $CF_TOKEN" \
  | python3 -c "
import sys, json
d = json.load(sys.stdin)
for r in d.get('result', []):
    print(r['id'], r.get('phase'), r.get('name'))
"
```

---

### Ошибка: `"rulesets.response_body_too_large"` или Expression too long

**Причина:** Выражение WAF правила превышает лимит CF (~4096 символов на FREE плане).  
**Решение:** Разбить одно большое правило на два (использовать 2 правила вместо 1 в Rule 37).  

```bash
# Проверить длину выражения перед отправкой
echo -n "$WP_FIREWALL_EXPR" | wc -c
# Лимит FREE плана: ~4096 символов
# Лимит Pro плана: ~8192 символов
```

---

### Ошибка: `"ratelimit.api.not_entitled"` или `429` при создании Rate Limit

**Причина 1:** Неправильный endpoint для нового Rate Limit API.  
**Неправильно (старый API):** `POST /zones/{id}/rate_limits`  
**Правильно (новый API):** `PUT /zones/{id}/rulesets/phases/http_ratelimit/entrypoint`

**Причина 2:** На FREE плане лимит — 1 Rate Limit правило. Если уже есть правило — нужно заменить, а не добавить.

**Правильный запрос для Rate Limit:**
```bash
ZONE_ID="ваш_zone_id"
curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/rulesets/phases/http_ratelimit/entrypoint" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "rules": [{
      "description": "47-RateLimit-100req-10s-block",
      "expression": "http.request.uri.path ne \"\"",
      "action": "block",
      "ratelimit": {
        "characteristics": ["ip.src", "cf.colo.id"],
        "period": 10,
        "requests_per_period": 100,
        "mitigation_timeout": 10
      },
      "enabled": true
    }]
  }' | python3 -m json.tool
```

---

### Ошибка: `"security_level.api.not_entitled"` 

**Причина:** Security Level на FREE плане можно менять только на значения: `off`, `essentially_off`, `low`, `medium`, `high`, `under_attack`.  
**НЕ работает:** `"I'm Under Attack"` — используй `"under_attack"` строчными буквами.

```bash
# Правильные значения security_level:
# off | essentially_off | low | medium | high | under_attack
curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/settings/security_level" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"value": "high"}'
```

---

### Ошибка: `"action_parameters.ruleset: Invalid value"` при создании Whitelist Skip rule

**Причина:** Неправильная структура `action_parameters` для action `skip`.  
**Неправильно:**
```json
{"action": "skip", "action_parameters": {"ruleset": "all"}}
```
**Правильно:**
```json
{"action": "skip", "action_parameters": {"ruleset": "current"}}
```

> `"current"` = пропустить все правила текущего ruleset. `"all"` используется только на уровне аккаунта.

---

### Ошибка: `"parse error"` или пустой ответ от API

**Причина:** CF API вернул HTML вместо JSON (rate limiting самого API, 503, 520).  
**Решение:**
```bash
# Увеличить API_SLEEP с 0.5 до 1.0 или 1.5 в скрипте
API_SLEEP=1.0

# Проверить что CF API отвечает корректно
curl -v "https://api.cloudflare.com/client/v4/zones?per_page=1" \
  -H "Authorization: Bearer $CF_TOKEN" 2>&1 | head -30
```

---

### Ошибка: `"managed_challenge: action requires 5 or fewer conditions"` (редко)

**Причина:** В expression слишком много OR-условий для action `managed_challenge` на FREE плане.  
**Решение:** Разбить Rule 37 на два правила: Rule 37a (WP paths) и Rule 37b (bad UA).

```bash
# Правило 37a — только пути (paths)
# Правило 37b — только User-Agent фильтры
# Оба с action: managed_challenge
# Итого: 27 + 37a + 37b + 47 = 4 правила (лимит FREE = 5)
```

---

## 4. Полный ручной сброс и переустановка правил для одного домена

Если что-то пошло не так и нужно вручную пересоздать правила для одного домена:

```bash
#!/bin/bash
# ▶ RUN ON: Server 222 (152.53.182.222)
# Ручной сброс и переустановка правил для одного домена

export CF_TOKEN="cfat_..."
DOMAIN="example.com"

# Шаг 1: Получить Zone ID
ZONE_ID=$(curl -s "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}" \
  -H "Authorization: Bearer $CF_TOKEN" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result'][0]['id'])")
echo "Zone ID: $ZONE_ID"

# Шаг 2: Получить Ruleset ID для firewall
FW_RULESET_ID=$(curl -s "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/rulesets" \
  -H "Authorization: Bearer $CF_TOKEN" \
  | python3 -c "
import sys,json
d=json.load(sys.stdin)
for r in d.get('result',[]):
    if r.get('phase')=='http_request_firewall_custom': print(r['id']); break
")
echo "FW Ruleset ID: $FW_RULESET_ID"

# Шаг 3: Очистить firewall правила
if [[ -n "$FW_RULESET_ID" ]]; then
  curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/rulesets/${FW_RULESET_ID}" \
    -H "Authorization: Bearer $CF_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"rules": []}' | python3 -c "import sys,json; d=json.load(sys.stdin); print('Cleared OK' if d.get('success') else d.get('errors'))"
fi

# Шаг 4: Очистить rate limit правила
curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/rulesets/phases/http_ratelimit/entrypoint" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"rules": []}' > /dev/null 2>&1
echo "Rate limit cleared"

# Шаг 5: Применить правила заново
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Cloudflare/cf-all-domains-wp.sh)
```

---

## 5. Диагностика — что смотреть когда скрипт упал

### 5.1 Получить полный ответ API без скрипта

```bash
# Полный JSON ответ для одной зоны — показывает точную ошибку
ZONE_ID="ваш_zone_id"
curl -s "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/rulesets" \
  -H "Authorization: Bearer $CF_TOKEN" \
  | python3 -m json.tool 2>&1 | head -60
```

### 5.2 Посмотреть все текущие правила зоны

```bash
ZONE_ID="ваш_zone_id"
# Все rulesets
curl -s "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/rulesets" \
  -H "Authorization: Bearer $CF_TOKEN" \
  | python3 -c "
import sys, json
d = json.load(sys.stdin)
if not d.get('success'):
    print('ERROR:', json.dumps(d.get('errors'), indent=2))
    exit(1)
for r in d.get('result', []):
    print(f"Ruleset: {r['id']} | Phase: {r.get('phase')} | Rules: {len(r.get('rules', []))}")
    for rule in r.get('rules', []):
        print(f"  -> [{rule.get('action')}] {rule.get('description', '?')}")
"
```

### 5.3 Посмотреть текущие Rate Limit правила

```bash
ZONE_ID="ваш_zone_id"
curl -s "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/rulesets/phases/http_ratelimit/entrypoint" \
  -H "Authorization: Bearer $CF_TOKEN" \
  | python3 -m json.tool
```

---

## 6. Лимиты Cloudflare FREE плана

| Ресурс | FREE | Pro | Business |
|--------|------|-----|----------|
| Custom Firewall Rules (WAF) | 5 | 20 | 100 |
| Rate Limiting rules | 1 | 10 | 100 |
| Expression length | ~4096 chars | ~8192 chars | ~16384 chars |
| Bot Management API | ❌ | ✅ | ✅ |
| Managed Rulesets (OWASP) | ❌ | ✅ | ✅ |
| Page Rules | 3 | 20 | 50 |
| Workers | ✅ (100k/day) | ✅ | ✅ |

> Скрипты написаны под FREE план: используют 3 правила из 5 (Rule 27 + Rule 37 + Rule 47).

---

## 7. Правильная структура JSON для каждого типа правила

### 7.1 Whitelist Skip Rule (Rule 27)

```json
{
  "description": "27-Whitelist-VladiMIR",
  "expression": "(ip.src eq 1.2.3.4) or (ip.src eq 5.6.7.8)",
  "action": "skip",
  "action_parameters": {
    "ruleset": "current"
  },
  "enabled": true
}
```

> `action: skip` + `action_parameters: {ruleset: current}` — единственная правильная комбинация для bypass на FREE плане.

### 7.2 WAF Firewall Rule (Rule 37)

```json
{
  "description": "37-WP-Extended-Challenge",
  "expression": "(http.request.uri.path eq \"/wp-login.php\") or ...",
  "action": "managed_challenge",
  "enabled": true
}
```

> `action: managed_challenge` = Cloudflare CAPTCHA (лучше чем `block` — не блокирует реальных людей).  
> Альтернативы: `block` (жёстко), `js_challenge` (JS проверка), `challenge` (старый CAPTCHA).

### 7.3 Rate Limit Rule (Rule 47)

```json
{
  "description": "47-RateLimit-100req-10s-block",
  "expression": "http.request.uri.path ne \"\"",
  "action": "block",
  "ratelimit": {
    "characteristics": ["ip.src", "cf.colo.id"],
    "period": 10,
    "requests_per_period": 100,
    "mitigation_timeout": 10
  },
  "enabled": true
}
```

> `characteristics: ["ip.src", "cf.colo.id"]` — считает запросы по IP + дата-центру CF. Только `ip.src` тоже работает, но менее точно.

### 7.4 Полный PUT запрос для создания/обновления firewall ruleset

```bash
curl -s -X PUT \
  "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/rulesets/${RULESET_ID}" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "rules": [
      {
        "description": "27-Whitelist-VladiMIR",
        "expression": "(ip.src eq 185.100.197.16)",
        "action": "skip",
        "action_parameters": {"ruleset": "current"},
        "enabled": true
      },
      {
        "description": "37-WP-Extended-Challenge",
        "expression": "(http.request.uri.path eq \"/wp-login.php\")",
        "action": "managed_challenge",
        "enabled": true
      }
    ]
  }'
```

---

## 8. Быстрая справка: CF API endpoints

```
BASE: https://api.cloudflare.com/client/v4

# Токен
GET  /user/tokens/verify                                   — проверить токен

# Зоны
GET  /zones?status=active&per_page=50&page=N               — список зон
GET  /zones?name=example.com                               — зона по имени

# Zone Settings
PATCH /zones/{id}/settings/security_level                  — уровень безопасности
PATCH /zones/{id}/settings/browser_check                   — browser integrity check

# Rulesets
GET  /zones/{id}/rulesets                                  — все rulesets зоны
GET  /zones/{id}/rulesets/{ruleset_id}                     — конкретный ruleset с правилами
POST /zones/{id}/rulesets                                  — создать новый ruleset
PUT  /zones/{id}/rulesets/{ruleset_id}                     — обновить ruleset (заменить все правила)

# Rate Limiting
GET  /zones/{id}/rulesets/phases/http_ratelimit/entrypoint — текущие rate limit правила
PUT  /zones/{id}/rulesets/phases/http_ratelimit/entrypoint — установить rate limit правила

# Bot Management (только Pro+)
GET  /zones/{id}/bot_management
PUT  /zones/{id}/bot_management
```

---

## 9. Если всё равно не работает — пошаговый дебаг

```bash
#!/bin/bash
# ▶ RUN ON: Server 222 (152.53.182.222)
# Пошаговый дебаг для одного домена

export CF_TOKEN="cfat_..."
DOMAIN="example.com"

echo "=== ШАГ 1: Проверка токена ==="
curl -s "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer $CF_TOKEN" | python3 -m json.tool

echo ""
echo "=== ШАГ 2: Получение Zone ID ==="
ZONE_ID=$(curl -s "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}" \
  -H "Authorization: Bearer $CF_TOKEN" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); z=d.get('result',[]); print(z[0]['id'] if z else 'NOT_FOUND')")
echo "Zone ID: $ZONE_ID"

[[ "$ZONE_ID" == "NOT_FOUND" ]] && echo "STOP: домен не найден в аккаунте" && exit 1

echo ""
echo "=== ШАГ 3: Список всех rulesets ==="
curl -s "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/rulesets" \
  -H "Authorization: Bearer $CF_TOKEN" | python3 -c "
import sys,json
d=json.load(sys.stdin)
if not d.get('success'): print('ERROR:', d['errors']); exit(1)
for r in d['result']:
    print(f\"  {r['id']} | {r.get('phase')} | {r.get('name')} | rules: {len(r.get('rules',[]))}\")
"

echo ""
echo "=== ШАГ 4: Тест Security Level ==="
curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/settings/security_level" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"value": "high"}' \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('OK' if d.get('success') else d.get('errors'))"

echo ""
echo "=== ШАГ 5: Тест Rate Limit API ==="
curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/rulesets/phases/http_ratelimit/entrypoint" \
  -H "Authorization: Bearer $CF_TOKEN" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('OK — rules:', len(d.get('result',{}).get('rules',[]))) if d.get('success') else print('ERROR:', d.get('errors'))"

echo ""
echo "=== ДЕБАГ ЗАВЕРШЁН ==="
```

---

*= Rooted by VladiMIR + AI | v2026.06.04c | github.com/GinCz =*
