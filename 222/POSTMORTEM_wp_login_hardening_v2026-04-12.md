# Postmortem: WP Login Hardening — 12.04.2026
_= Rooted by VladiMIR | AI =_

---

## 1. Что случилось (триггер)

**Дата:** 12.04.2026, ~15:00 CEST  
**Сервер:** 222-DE-NetCup (152.53.182.222, NetCup, Ubuntu 24, FASTPANEL, Nginx 1.28.3)

В логах сайта `timan-kuchyne.cz` обнаружена массовая атака bruteforce на `/wp-login.php`:

```
1113 запросов за последний час с IP 103.186.31.44 (Индонезия)
```

Топ URLs за час:
```
1113 /wp-login.php
  11 /
   8 /index.php/wp-json/wp/v2/users/me
```

Все запросы проходили с HTTP 200 — никакой блокировки не было.

---

## 2. Почему атака не блокировалась (root cause анализ)

### Причина A — timan-kuchyne.cz не проксирован через Cloudflare

Проверка:
```bash
curl -s -I https://timan-kuchyne.cz/wp-login.php | grep -i "cf-ray"
```
Результат: `cf-ray` **отсутствует** в ответе. Вместо него:
```
Server: nginx/1.28.3
X-Powered-By: PHP/8.4.12
```
Это значит домен стоял в Cloudflare DNS как **"DNS only" (серое облако)** — запросы шли напрямую на сервер, минуя Cloudflare WAF полностью. Правила Rule 20 и Rule 30 из `cloudflare_waf_rules.md` **не работали** для этого домена.

### Причина B — у timan-kuchyne.cz не было location = /wp-login.php в Nginx конфиге

В конфиге `/etc/nginx/fastpanel2-available/nata_popkova/timan-kuchyne.cz.conf` блок `location = /wp-login.php` отсутствовал полностью. Rate limit зона `wp_login_222` была объявлена, но не применялась к этому домену — некому было вызвать `limit_req`.

### Причина C — burst=10 на всех остальных сайтах был слишком высоким

Во всех сайт-конфигах стояло:
```nginx
limit_req zone=wp_login_222 burst=10 nodelay;
```
При `rate=6r/m` (1 запрос каждые 10 секунд) и `burst=10` — Nginx пропускал первые **10 запросов мгновенно** без задержки, и только потом начинал throttle. Это означало, что бот мог сделать 10 быстрых попыток входа до первого 429. Это слишком много.

---

## 3. Что пробовали и что не работало

### Попытка 1 — создать новый 00-wp-login-limit-zone.conf

Создали файл `/etc/nginx/conf.d/00-wp-login-limit-zone.conf` с зоной `wp_login_222:30m`.  
**Ошибка:**
```
nginx: [emerg] the size 20971520 of shared memory zone "wp_login_222" conflicts
with already declared size 31457280 in /etc/nginx/conf.d/01-wp-limit-zones.conf:7
```
Причина: зона `wp_login_222` уже была объявлена в `01-wp-limit-zones.conf` с размером 20m, а мы объявили 30m. Nginx не позволяет два раза объявлять одну зону с разными параметрами.

**Решение:** удалить оба старых файла и создать один мастер-файл.

### Попытка 2 — добавить limit_req_status 429 в новый файл

Добавили `limit_req_status 429;` в новый файл зон.  
**Ошибка:**
```
nginx: [emerg] "limit_req_status" directive is duplicate
in /etc/nginx/conf.d/meta_crawler_limit.conf:20
```
Причина: `limit_req_status 429` уже была объявлена в `/etc/nginx/conf.d/meta_crawler_limit.conf` (файл защиты от Meta/Facebook краулеров). Это глобальная директива — объявляется только один раз.  
**Решение:** убрать `limit_req_status` из нашего файла зон.

### Попытка 3 — создать security-wordpress.conf с location блоками

Создали `/etc/nginx/fastpanel2-includes/security-wordpress.conf` с блоком `location = /wp-login.php`.  
**Ошибка:**
```
nginx: [emerg] duplicate location "/wp-login.php"
in /etc/nginx/fastpanel2-includes/security-wordpress.conf:6
```
Причина: `fastpanel2-includes/*.conf` подключается внутри каждого `server {}` блока через:
```nginx
include /etc/nginx/fastpanel2-includes/*.conf;
```
А в каждом сайт-конфиге уже был свой `location = /wp-login.php`. Nginx не допускает два одинаковых `location =` в одном server блоке.  

**Решение:** security-wordpress.conf НЕ должен содержать `location = /wp-login.php`. Вместо этого:
- `burst=10` → `burst=3` меняем в каждом сайт-конфиге напрямую
- `timan-kuchyne.cz` добавляем `location = /wp-login.php` вручную
- В security-wordpress.conf оставляем только блоки которых нет в сайт-конфигах (user enumeration, author enumeration, sensitive files)

### Попытка 4 — sed по fastpanel2-sites/

Пытались менять файлы через `fastpanel2-sites/`, но эта директория содержит **symlinks** на `fastpanel2-available/`. sed по symlink-ам не работает так как ожидается.  
**Решение:** запускать sed напрямую по `fastpanel2-available/`.

---

## 4. Что было изменено (финальные изменения)

### 4.1 Удалены файлы

| Файл | Причина удаления |
|------|------------------|
| `/etc/nginx/conf.d/00-wp-login-limit-zone.conf` | Дублировал зону wp_login_222 |
| `/etc/nginx/conf.d/01-wp-limit-zones.conf` | Дублировал зону wp_login_222 |
| `/etc/nginx/fastpanel2-includes/security-wordpress.conf` | Создавал duplicate location в каждом сайте |

### 4.2 Создан файл

**`/etc/nginx/conf.d/00-wp-protection-zones.conf`** — единственный файл объявления зон:
```nginx
limit_req_zone $binary_remote_addr zone=wp_login_222:30m rate=6r/m;
limit_req_zone $binary_remote_addr zone=wp_admin_222:20m rate=2r/s;
limit_req_zone $binary_remote_addr zone=wp_xmlrpc_222:10m rate=1r/m;
```
Размер зоны увеличен с 20m до 30m (при большом количестве сайтов 20m могло не хватить).

### 4.3 Изменено burst во всех активных сайт-конфигах

**41 файл** в `/etc/nginx/fastpanel2-available/` изменён:
```
было:  limit_req zone=wp_login_222 burst=10 nodelay;
стало: limit_req zone=wp_login_222 burst=3 nodelay;
```

Полный список изменённых файлов:
```
detailing-alex.eu.conf, ekaterinburg-sro.eu.conf, eco-seo.cz.conf,
rail-east.uk.conf, east-vector.cz.conf, eurasia-translog.cz.conf,
vymena-motoroveho-oleje.cz.conf, car-chip.eu.conf, diamond-odtah.cz.conf,
sveta-drobot.cz.conf, bio-zahrada.eu.conf, alejandrofashion.cz.conf,
czechtoday.eu.conf, stm-services-group.cz.conf, autoservis-praha.eu.conf,
praha-autoservis.eu.conf, neonella.eu.conf, abl-metal.com.conf,
megan-consult.cz.conf, stopservis-vestec.cz.conf, kadernik-olga.eu.conf,
kk-med.eu.conf, kadernictvi-salon.eu.conf, doska-fr.ru.conf,
doska-pl.ru.conf, doska-it.ru.conf, doska-cz.ru.conf, doska-gr.ru.conf,
doska-hun.ru.conf, doska-isl.ru.conf, doska-mld.ru.conf, doska-de.ru.conf,
doska-ua.ru.conf, doska-esp.ru.conf, balance-b2b.eu.conf,
autoservis-rychlik.cz.conf, car-bus-autoservice.cz.conf, hulk-jobs.cz.conf,
lybawa.com.conf, gadanie-tel.eu.conf, wowflow.cz.conf
```

### 4.4 Добавлен location wp-login в timan-kuchyne.cz

**`/etc/nginx/fastpanel2-available/nata_popkova/timan-kuchyne.cz.conf`**  
Добавлено в оба server{} блока (HTTP и HTTPS) перед закрывающей `}`:
```nginx
location = /wp-login.php {
    limit_req zone=wp_login_222 burst=3 nodelay;
    include /etc/nginx/fastcgi_params;
    fastcgi_pass unix:/var/run/timan-kuchyne.cz.sock;
    fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
    fastcgi_param DOCUMENT_ROOT $realpath_root;
}
```

---

## 5. Архитектура Nginx на этом сервере (важно знать)

```
/etc/nginx/conf.d/                    ← глобальные директивы (зоны, map, geo)
    00-wp-protection-zones.conf       ← наш файл зон (единственный!)
    meta_crawler_limit.conf           ← защита от Meta краулеров + limit_req_status 429
    cloudflare_real_ip.conf           ← восстановление реального IP из CF заголовков

/etc/nginx/fastpanel2-includes/       ← подключается в КАЖДЫЙ server{} блок
    *.conf                            ← НЕ ДОБАВЛЯТЬ сюда location = блоки!

/etc/nginx/fastpanel2-available/      ← реальные конфиги сайтов (редактировать здесь)
    user_name/domain.conf

/etc/nginx/fastpanel2-sites/          ← symlinks на fastpanel2-available/ (не редактировать)
    domain.conf -> ../fastpanel2-available/user/domain.conf
```

**Важное правило:** если нужно изменить конфиг сайта — редактировать в `fastpanel2-available/`, не в `fastpanel2-sites/` (там symlinks).

---

## 6. Текущая политика защиты wp-login (после изменений)

| Уровень | Правило | Результат |
|---------|---------|----------|
| Cloudflare WAF | Rule 30: Managed Challenge на /wp-login.php | Боты не проходят challenge |
| Cloudflare WAF | Rule 20: Block /xmlrpc.php | Жёсткий блок |
| Nginx rate limit | rate=6r/m, burst=3 nodelay | 4-й быстрый запрос = 429 |
| CrowdSec | wordpress-scan сценарий | Бан на уровне iptables/bouncer |

**Cloudflare работает только если домен проксирован (оранжевое облако).**  
Проверка: `curl -s -I https://domain/wp-login.php | grep cf-ray`

---

## 7. Что ещё нужно сделать

- [ ] Включить оранжевое облако (proxy) для `timan-kuchyne.cz` в Cloudflare DNS
- [ ] Проверить все остальные домены — все ли проксированы через Cloudflare
- [ ] Настроить Cloudflare WAF на Account-level (чтобы новые домены автоматически получали защиту)
- [ ] Добавить `location = /wp-login.php` в конфиги сайтов которые его не имеют

---

## 8. Команды для диагностики в будущем

```bash
# Проверить топ атакующих IP за последний час
awk -v d="$(date -d '1 hour ago' '+%d/%b/%Y:%H')" '$0 ~ d' /var/log/nginx/access.log \
  | awk '{print $1}' | sort | uniq -c | sort -rn | head -10

# Проверить идёт ли домен через Cloudflare
curl -s -I https://DOMAIN/wp-login.php | grep -i "cf-ray\|server"

# Проверить текущие rate limit зоны
nginx -T 2>/dev/null | grep "limit_req_zone\|limit_req_status"

# Проверить burst во всех активных конфигах
grep -r "wp_login_222 burst=" /etc/nginx/fastpanel2-available/ | grep -v ".bak"

# Проверить активные CrowdSec баны
cscli decisions list

# Тест rate limit (должен давать 429 начиная с 4-го запроса)
for i in 1 2 3 4 5; do
  echo -n "Request $i: "
  curl -s -o /dev/null -w "%{http_code}\n" -X POST https://DOMAIN/wp-login.php \
    -d "log=test&pwd=test"
done
```

---
_= Rooted by VladiMIR | AI = 12.04.2026_
