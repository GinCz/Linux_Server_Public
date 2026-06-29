# SSL / acme.sh / FastPanel — Полное исправление и настройка автообновления

> **Серверы:** 222 (152.53.182.222 / EU-NetCup) и 109 (212.109.223.109 / RU-FirstVDS)
> **Дата:** 2026-06-29
> **Исполнитель:** VladiMIR + AI (Perplexity / Claude Sonnet)

---

## Контекст и предыстория

На сервере 222 FastPanel обслуживает **50 доменов**, все через Cloudflare CDN.
На сервере 109 FastPanel обслуживает **23 домена**, без Cloudflare (прямой IP).

Обнаружили что 3 домена на сервере 222 имеют просроченные SSL-сертификаты:
- `timan-kuchyne.cz` — истёк 2026-06-24 (−4 дня)
- `eco-seo.eu` — истёк 2026-06-13 (−16 дней)
- `gincz.com` — истёк 2026-06-09 (−19 дней)

---

## Диагностика — Сервер 222

### Шаг 1: Проверка certbot и nginx

```bash
certbot certificates 2>/dev/null || docker exec fastpanel-main certbot certificates
nginx -T | grep -A5 "acme-challenge"
certbot renew --dry-run --domain timan-kuchyne.cz
```

**Результат:**
- certbot знает только один сертификат: `crypto.gincz.com` (истекает 2026-08-21) — выпущен отдельно вручную
- timan-kuchyne.cz в certbot **отсутствует**
- nginx ACME-challenge настроен правильно:
  ```nginx
  location ^~ /.well-known/acme-challenge/ {
      auth_basic off;
      alias /usr/local/fastpanel2/web/letsencrypt/;
      try_files $uri $uri/ @fallback-acme;
  }
  ```
- `certbot renew --dry-run --domain timan-kuchyne.cz` завершился с ошибкой — certbot не умеет обновлять по домену, только по имени сертификата

### Шаг 2: Проверка сервисов и cron

```bash
systemctl list-units | grep -i fast
systemctl status fastpanel2 --no-pager -n 20
crontab -l
ls /etc/cron.d/ | grep -i fast
```

**Результат:**
- FastPanel сервисы работают нормально: `fastpanel2.service` active since 2026-06-14
- `ls /etc/cron.d/` — **директории не существует** (пустой вывод)
- В crontab обнаружена строка: `15 16 * * * "/.acme.sh"/acme.sh --cron --home "/.acme.sh" > /dev/null`
- **Вывод:** FastPanel использует **acme.sh**, а не certbot!

### Шаг 3: Срок сертификата timan-kuchyne.cz

```bash
echo | openssl s_client -connect timan-kuchyne.cz:443 -servername timan-kuchyne.cz 2>/dev/null \
  | openssl x509 -noout -dates -issuer
```

**Результат:**
```
notBefore=Mar 26 18:25:09 2026 GMT
notAfter=Jun 24 18:25:08 2026 GMT   ← ИСТЁК
issuer=C = US, O = Let's Encrypt, CN = R13
```

### Шаг 4: Проверка логов FastPanel

```bash
tail -100 /usr/local/fastpanel2/data/logs/fastpanel.log | grep -i "cert\|ssl\|letsencrypt\|timan"
journalctl -u fastpanel2 --since "7 days ago" | grep -i "cert\|ssl\|renew" | tail -50
```

**Результат:** Оба лога — **пустой вывод**. FastPanel не предпринимала никаких попыток обновления.

---

## Корневая причина

### Почему сертификаты истекли?

FastPanel выпускала сертификаты через **свой внутренний механизм** (не через acme.sh системный).
Файлы хранились в `/var/www/httpd-cert/` с датой выпуска в имени:
```
/var/www/httpd-cert/timan-kuchyne.cz_2026-03-26-20-23_22.crt
/var/www/httpd-cert/timan-kuchyne.cz_2026-03-26-20-23_22.key
```

acme.sh (`/.acme.sh/`) об этих сертификатах **ничего не знал** — они не были зарегистрированы через него.
Поэтому `acme.sh --cron` каждый день запускался, ничего не находил и завершался без действий.

### Дополнительная проблема для сервера 222

Все домены на сервере 222 идут через **Cloudflare CDN** (оранжевое облако).
Это означает что HTTP-01 challenge (стандартный способ Let's Encrypt) **не работает надёжно** —
Cloudflare может перехватить запрос до того как он дойдёт до сервера.

**Решение:** использовать DNS-01 challenge через Cloudflare API.

---

## Исправление — Сервер 222

### Шаг 1: Проверка всех доменов

```bash
# Скан всех 50 доменов
for domain in alejandrofashion.cz autoservis-praha.eu ... ; do
  EXPIRY=$(echo | timeout 5 openssl s_client -connect ${domain}:443 -servername ${domain} 2>/dev/null \
    | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
  DAYS=$(( ($(date -d "$EXPIRY" +%s) - $(date +%s)) / 86400 ))
  # ... вывод статуса
done
```

**Результат скана:**
| Домен | Статус |
|-------|--------|
| `timan-kuchyne.cz` | 🔴 ИСТЁК −4 дн (Jun 24 2026) |
| `eco-seo.eu` | 🔴 ИСТЁК −16 дн (Jun 13 2026) |
| `gincz.com` | 🔴 ИСТЁК −19 дн (Jun 9 2026) |
| Остальные 47 доменов | ✅ OK (25–89 дней) |

### Шаг 2: Настройка acme.sh + Cloudflare DNS API

```bash
# Установить CA и выпустить сертификат через DNS-01
export CF_Token="[см. Secret_Privat/domains.md]"
export CF_Email="gin@volny.cz"

/.acme.sh/acme.sh --set-default-ca --server letsencrypt

/.acme.sh/acme.sh --issue \
  --dns dns_cf \
  -d timan-kuchyne.cz \
  -d www.timan-kuchyne.cz \
  --force --log
```

**Процесс DNS-01 challenge:**
1. acme.sh добавляет TXT-запись `_acme-challenge.timan-kuchyne.cz` через Cloudflare API
2. Let's Encrypt проверяет DNS
3. acme.sh удаляет TXT-запись
4. Сертификат скачан

**Результат:** Сертификат выпущен успешно.
```
Your cert is in: /root/.acme.sh/timan-kuchyne.cz_ecc/timan-kuchyne.cz.cer
Your cert key is in: /root/.acme.sh/timan-kuchyne.cz_ecc/timan-kuchyne.cz.key
The full-chain cert is in: /root/.acme.sh/timan-kuchyne.cz_ecc/fullchain.cer
Next renewal: 2026-08-27
```

Аналогично выпущены: `eco-seo.eu`, `gincz.com`.

### Шаг 3: Установка сертификатов (--install-cert)

```bash
/.acme.sh/acme.sh --install-cert \
  -d timan-kuchyne.cz \
  --cert-file     /var/www/httpd-cert/timan-kuchyne.cz_2026-06-29.crt \
  --key-file      /var/www/httpd-cert/timan-kuchyne.cz_2026-06-29.key \
  --fullchain-file /var/www/httpd-cert/timan-kuchyne.cz_2026-06-29_fullchain.crt \
  --reloadcmd "nginx -t && systemctl reload nginx" \
  --ecc
```

**Проблема:** После `--install-cert` nginx перезагрузился (`reload`), но домен всё ещё показывал старый сертификат.

**Причина:** `systemctl reload nginx` не подхватывает новый файл если сертификат изменился — нужен полный `restart`.

**Дополнительная проблема:** nginx-конфиги для доменов FastPanel хранятся **не в стандартных директориях**:
- ❌ Искали в: `/etc/nginx/sites-enabled/`, `/etc/nginx/conf.d/`
- ✅ Реально находится: `/etc/nginx/fastpanel2-available/<user>/<domain>.conf`
- Симлинки: `/etc/nginx/fastpanel2-sites/<user>/<domain>.conf` → `fastpanel2-available/`

**Исправление:** нашли конфиги и обновили пути вручную:
```bash
CONF_TIMAN="/etc/nginx/fastpanel2-available/nata_popkova/timan-kuchyne.cz.conf"
sed -i 's|ssl_certificate ".*timan-kuchyne\.cz.*\.crt";|ssl_certificate "/var/www/httpd-cert/timan-kuchyne.cz_2026-06-29_fullchain.crt";|g' "$CONF_TIMAN"
sed -i 's|ssl_certificate_key ".*timan-kuchyne\.cz.*\.key";|ssl_certificate_key "/var/www/httpd-cert/timan-kuchyne.cz_2026-06-29.key";|g' "$CONF_TIMAN"
```

**Проблема:** После reload nginx — сертификаты всё ещё старые.

**Решение:** Полный рестарт:
```bash
systemctl stop nginx
sleep 2
systemctl start nginx
```

**Финальная проверка** (напрямую к IP, минуя Cloudflare):
```bash
echo | openssl s_client -connect 152.53.182.222:443 -servername timan-kuchyne.cz 2>/dev/null \
  | openssl x509 -noout -enddate
```
```
notAfter=Sep 27 10:04:55 2026 GMT  ✅ (89 дней)
```

### Шаг 4: Создание скрипта автодеплоя

Создан `/root/acme-deploy-fastpanel.sh` — вызывается acme.sh после каждого обновления:

```bash
#!/bin/bash
# Аргумент $1 — домен
DOMAIN="$1"
DATE=$(date +%Y-%m-%d)

# Найти nginx конфиг FastPanel
CONF=$(grep -rl "$DOMAIN" /etc/nginx/fastpanel2-available/ 2>/dev/null \
  | grep -v ".bak" | grep "${DOMAIN}.conf" | head -1)

# Обновить пути сертификатов
sed -i "s|ssl_certificate \".*${DOMAIN}.*\.crt\";|ssl_certificate \"/var/www/httpd-cert/${DOMAIN}_${DATE}_fullchain.crt\";|g" "$CONF"
sed -i "s|ssl_certificate_key \".*${DOMAIN}.*\.key\";|ssl_certificate_key \"/var/www/httpd-cert/${DOMAIN}_${DATE}.key\";|g" "$CONF"

# Полный рестарт (не reload!)
nginx -t 2>/dev/null && systemctl restart nginx
echo "[$(date)] nginx restarted OK" >> /var/log/acme-deploy.log
```

### Шаг 5: Переназначить reloadcmd для всех трёх доменов

```bash
for DOMAIN in timan-kuchyne.cz eco-seo.eu gincz.com; do
  /.acme.sh/acme.sh --install-cert \
    -d "$DOMAIN" \
    --cert-file      "/var/www/httpd-cert/${DOMAIN}_$(date +%Y-%m-%d).crt" \
    --key-file       "/var/www/httpd-cert/${DOMAIN}_$(date +%Y-%m-%d).key" \
    --fullchain-file "/var/www/httpd-cert/${DOMAIN}_$(date +%Y-%m-%d)_fullchain.crt" \
    --reloadcmd      "bash /root/acme-deploy-fastpanel.sh ${DOMAIN}" \
    --ecc
done
```

### Шаг 6: Сохранить CF_Token в acme.sh account.conf

```bash
grep -q "CF_Token" ~/.acme.sh/account.conf \
  || echo 'CF_Token="[см. Secret_Privat/domains.md]"' >> ~/.acme.sh/account.conf
grep -q "CF_Email" ~/.acme.sh/account.conf \
  || echo 'CF_Email="gin@volny.cz"' >> ~/.acme.sh/account.conf
```

**Результат:** `SAVED_CF_Token` сохранён в `~/.acme.sh/account.conf`.

---

## Итоговое состояние — Сервер 222

### Зарегистрированные домены в acme.sh

| Domain | CA | Created | Renew |
|--------|----|---------|-------|
| `eco-seo.eu` | LetsEncrypt | 2026-06-29 | 2026-08-28 |
| `gincz.com` | LetsEncrypt | 2026-06-29 | 2026-08-28 |
| `kk-med.cz` | LetsEncrypt | 2026-06-29 | 2026-08-27 |
| `timan-kuchyne.cz` | LetsEncrypt | 2026-06-29 | 2026-08-27 |

### Cron

```
15 16 * * * "/.acme.sh"/acme.sh --cron --home "/.acme.sh" > /dev/null
```

### SSL-статус (проверка напрямую к IP)

| Домен | Истекает | Дней |
|-------|----------|------|
| `timan-kuchyne.cz` | Sep 27 2026 | 89 ✅ |
| `eco-seo.eu` | Sep 27 2026 | 89 ✅ |
| `gincz.com` | Sep 27 2026 | 89 ✅ |
| Остальные 47 | 25–89 дней | ✅ |

---

## Проверка — Сервер 109

### Диагностика

```bash
/.acme.sh/acme.sh --version   # v3.1.4
/.acme.sh/acme.sh --list      # пустой — доменов не зарегистрировано
crontab -l                    # 41 3 * * * acme.sh --cron
```

**Отличия от сервера 222:**
- Нет Cloudflare — HTTP-01 challenge работает напрямую
- FastPanel сама обновляет все сертификаты через HTTP-challenge
- acme.sh установлен, cron настроен, но доменов не зарегистрировано (всё делает FastPanel)

### Результат скана SSL (23 домена)

Все 23 домена ✅ OK, минимальный срок — 30 дней:

| Срок | Домены |
|------|--------|
| 89 дн | andrey-maiorov.ru, nail-space-ekb.ru, ver7.ru, 4ton-96.ru |
| 88 дн | comfort-eng.ru, geodesia-ekb.ru, natal-karta.ru, news-port.ru, novorr-art.ru, prodvig-saita.ru, stomatolog-belchikov.ru, stuba-dom.ru, tri-sure.ru, ugfp.ru |
| 41–42 дн | ne-son.ru, palantins.ru, stassinhouse.ru |
| 30 дн | lvo-endo.ru, mariela.ru, mtek-expert.ru, shapkioptom.ru, stanok-ural.ru, tatra-ural.ru |

**Вывод:** Сервер 109 в норме, дополнительных действий не требуется.
FastPanel на 109 работает корректно — обновляет сертификаты сама через HTTP-challenge (нет Cloudflare = нет препятствий).

---

## Почему проблема возникла только на 222?

| Фактор | Сервер 222 | Сервер 109 |
|--------|-----------|-----------|
| CDN | Cloudflare ✅ | Нет |
| HTTP-challenge | Ненадёжно через CF | Работает напрямую |
| Выпуск сертификатов | FastPanel (свой механизм) | FastPanel (свой механизм) |
| Автообновление | ❌ Сломано (CF блокировал) | ✅ Работает |
| Решение | acme.sh + DNS-01 via CF API | Ничего не нужно |

---

## Архитектура автообновления (сервер 222) — финальная

```
┌─────────────────────────────────────────────────────────────────┐
│  cron: 15 16 * * *  →  acme.sh --cron                          │
│                                │                                │
│           За 30 дней до истечения:                              │
│                                ▼                                │
│         acme.sh --issue --dns dns_cf                            │
│                                │                                │
│         CF API: добавить TXT _acme-challenge                    │
│         Let's Encrypt: проверить DNS                            │
│         CF API: удалить TXT                                     │
│         Скачать новый сертификат                                │
│                                │                                │
│         acme-deploy-fastpanel.sh <domain>                       │
│                                │                                │
│         sed → обновить путь в nginx conf                        │
│         systemctl restart nginx                                 │
│         >> /var/log/acme-deploy.log                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Важные замечания для будущего

1. **`systemctl reload nginx` НЕ достаточно** для подхвата нового файла сертификата — нужен `restart`
2. **FastPanel хранит nginx-конфиги** в `/etc/nginx/fastpanel2-available/<user>/`, а не в стандартных директориях
3. **Новые домены на сервере 222** при добавлении нужно регистрировать в acme.sh через DNS-01:
   ```bash
   export CF_Token="[см. Secret_Privat/domains.md]"
   /.acme.sh/acme.sh --issue --dns dns_cf -d <domain> -d www.<domain> --ecc
   /.acme.sh/acme.sh --install-cert -d <domain> \
     --fullchain-file /var/www/httpd-cert/<domain>_$(date +%Y-%m-%d)_fullchain.crt \
     --key-file /var/www/httpd-cert/<domain>_$(date +%Y-%m-%d).key \
     --reloadcmd "bash /root/acme-deploy-fastpanel.sh <domain>" --ecc
   ```
4. **Остальные 47 доменов** на сервере 222 обновляются FastPanel через HTTP-challenge. Если в будущем какой-то снова истечёт — переводить на DNS-01 по той же схеме.
5. **Сервер 109** — трогать не нужно, FastPanel справляется сама.

---

## Файлы созданные/изменённые

| Файл | Сервер | Действие |
|------|--------|----------|
| `/root/acme-deploy-fastpanel.sh` | 222 | Создан — скрипт автодеплоя |
| `/var/log/acme-deploy.log` | 222 | Создан автоматически при первом запуске |
| `~/.acme.sh/account.conf` | 222 | Добавлен CF_Token + CF_Email |
| `/etc/nginx/fastpanel2-available/nata_popkova/timan-kuchyne.cz.conf` | 222 | Обновлены пути ssl_certificate |
| `/etc/nginx/fastpanel2-available/gincz/eco-seo.eu.conf` | 222 | Обновлены пути ssl_certificate |
| `/etc/nginx/fastpanel2-available/gincz/gincz.com.conf` | 222 | Обновлены пути ssl_certificate |

---

> _= Rooted by VladiMIR + AI | v.2026.06.29 | github.com/GinCz =_
