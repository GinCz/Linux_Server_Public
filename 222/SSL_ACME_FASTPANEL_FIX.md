# SSL / acme.sh / FastPanel — Полный гайд

> **Сервер:** 222-DE-NetCup (152.53.182.222)  
> **Обновлено:** 2026-06-29  
> **Проблема решена после:** ~4 часов боли. Читай это сначала.

---

## ⚡ TL;DR — Коротко о главном

| Вопрос | Ответ |
|---|---|
| Как FastPanel обновляет SSL? | HTTP-01 challenge через Let's Encrypt |
| Почему это ломается? | Cloudflare-прокси (🟠) блокирует `.well-known/acme-challenge/` |
| Наше решение | acme.sh с **DNS-01 challenge через Cloudflare API** |
| Где хранятся сертификаты | `/var/www/httpd-cert/<domain>_<date>.{crt,key,_fullchain.crt}` |
| Как применяются к nginx | `/root/acme-deploy-fastpanel.sh` — патчит nginx-конфиг + restart |
| Авторенью | `domains.sh` в cron каждую субботу 02:15, порог <15 дней |
| Кнопка «Обновить сертификат» в FastPanel | ❌ НЕ НАЖИМАТЬ — перезапишет наши пути своими |

---

## 🔴 Проблема: почему ломаются сертификаты

FastPanel обновляет SSL стандартным **HTTP-01 challenge**:
1. Let's Encrypt просит положить файл в `/.well-known/acme-challenge/`
2. FastPanel кладёт его
3. Let's Encrypt стучится по HTTP на домен для проверки

**Это ломается когда домен за Cloudflare с включённым прокси (🟠 оранжевый облачко):**
- Cloudflare перехватывает запрос
- Let's Encrypt видит IP Cloudflare, а не наш сервер
- Challenge падает → сертификат не выпускается → сайт падает с `NET::ERR_CERT_DATE_INVALID`

**Дополнительно:** FastPanel хранит пути к сертификатам в nginx-конфиге как:
```
ssl_certificate /var/www/httpd-cert/domain.tld_ДАТА.crt;
```
Дата вшита в имя файла! При каждом выпуске нового сертификата имя меняется,  
и FastPanel это не обновляет автоматически — nginx продолжает читать старый файл.

---

## ✅ Решение: acme.sh + DNS-01 + deploy-скрипт

### Архитектура

```
[acme.sh --cron / --renew]
       ↓
  DNS-01 challenge
  (создаёт TXT-запись _acme-challenge.domain.tld через Cloudflare API)
       ↓
  Let's Encrypt выпускает сертификат
       ↓
  acme.sh копирует файлы:
    /var/www/httpd-cert/<domain>_<дата>.crt
    /var/www/httpd-cert/<domain>_<дата>.key
    /var/www/httpd-cert/<domain>_<дата>_fullchain.crt
       ↓
  reloadcmd: bash /root/acme-deploy-fastpanel.sh <domain>
       ↓
  deploy-скрипт патчит nginx-конфиг в /etc/nginx/fastpanel2-available/
  с новыми путями + systemctl restart nginx
```

### Ключевые файлы

| Файл | Назначение |
|---|---|
| `/.acme.sh/acme.sh` | Клиент Let's Encrypt |
| `/.acme.sh/account.conf` | Cloudflare API Token + Email |
| `/.acme.sh/<domain>/<domain>.conf` | Конфиг домена (reloadcmd и пр.) |
| `/root/acme-deploy-fastpanel.sh` | Deploy-скрипт (патчит nginx + restart) |
| `/var/www/httpd-cert/` | Директория сертификатов FastPanel |
| `/var/log/acme-deploy.log` | Лог всех deploy-операций |

---

## 🔧 Первоначальная настройка (при переустановке сервера)

### 1. Установить acme.sh
```bash
curl https://get.acme.sh | sh
source ~/.bashrc
```

### 2. Прописать Cloudflare API Token в `~/.acme.sh/account.conf`
```bash
export CF_Token="cfat_XXXXXXXXXXXXXXXXX"
export CF_Email="gin@volny.cz"
# Токен хранить ТОЛЬКО в ~/.acme.sh/account.conf — не в репозитории!
```

### 3. Создать deploy-скрипт `/root/acme-deploy-fastpanel.sh`
```bash
cat > /root/acme-deploy-fastpanel.sh << 'EOF'
#!/bin/bash
# Deploy-скрипт: копирует новые сертификаты и перезапускает nginx
# Вызывается автоматически acme.sh после выпуска каждого сертификата

DOMAIN="$1"
LOG="/var/log/acme-deploy.log"

if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 <domain>" | tee -a $LOG
    exit 1
fi

DATE=$(date +%Y-%m-%d)
CERT_DIR="/var/www/httpd-cert"
ACME_DIR="/.acme.sh/${DOMAIN}_ecc"

# Если нет ECC — пробуем RSA
[ ! -d "$ACME_DIR" ] && ACME_DIR="/.acme.sh/${DOMAIN}"

CRT="${CERT_DIR}/${DOMAIN}_${DATE}.crt"
KEY="${CERT_DIR}/${DOMAIN}_${DATE}.key"
FULLCHAIN="${CERT_DIR}/${DOMAIN}_${DATE}_fullchain.crt"

echo "[$(date)] Deploying ${DOMAIN} → ${CRT}" >> $LOG

cp "${ACME_DIR}/${DOMAIN}.cer" "$CRT"
cp "${ACME_DIR}/${DOMAIN}.key" "$KEY"
cp "${ACME_DIR}/fullchain.cer" "$FULLCHAIN"

# Патчим nginx-конфиг FastPanel
NGINX_CONF=$(grep -rl "ssl_certificate.*${DOMAIN}" /etc/nginx/fastpanel2-available/ 2>/dev/null | head -1)
if [ -n "$NGINX_CONF" ]; then
    sed -i "s|ssl_certificate .*${DOMAIN}.*\.crt;|ssl_certificate ${CRT};|" "$NGINX_CONF"
    sed -i "s|ssl_certificate_key .*${DOMAIN}.*\.key;|ssl_certificate_key ${KEY};|" "$NGINX_CONF"
    sed -i "s|ssl_trusted_certificate .*${DOMAIN}.*\.crt;|ssl_trusted_certificate ${FULLCHAIN};|" "$NGINX_CONF"
    echo "[$(date)] Patched: $NGINX_CONF" >> $LOG
else
    echo "[$(date)] WARNING: nginx config not found for ${DOMAIN}" >> $LOG
fi

# Restart nginx (не reload — чтобы новые файлы точно подхватились)
systemctl restart nginx
echo "[$(date)] nginx restarted OK" >> $LOG
EOF
chmod +x /root/acme-deploy-fastpanel.sh
```

### 4. Выпустить сертификат для домена
```bash
# Для домена за Cloudflare (прокси включён)
/.acme.sh/acme.sh --issue \
  --dns dns_cf \
  -d example.com \
  -d www.example.com \
  --keylength ec-256

# Установить (первый раз — задаёт reloadcmd)
/.acme.sh/acme.sh --install-cert -d example.com \
  --cert-file /var/www/httpd-cert/example.com_$(date +%Y-%m-%d).crt \
  --key-file /var/www/httpd-cert/example.com_$(date +%Y-%m-%d).key \
  --fullchain-file /var/www/httpd-cert/example.com_$(date +%Y-%m-%d)_fullchain.crt \
  --reloadcmd "bash /root/acme-deploy-fastpanel.sh example.com"
```

### 5. Проверить список доменов в acme.sh
```bash
/.acme.sh/acme.sh --list
```

---

## 📅 Cron — расписание

```bash
crontab -l
```

**Текущее расписание:**
```
# SSL check + авторенью <15 дней — каждую субботу в 02:15
15 2 * * 6  bash /root/Linux_Server_Public/222/domains.sh >> /var/log/acme-deploy.log 2>&1
```

> **Почему не ежедневно?**  
> acme.sh сам обновляет за 30 дней до истечения. Еженедельная проверка через `domains.sh`  
> служит страховкой: если acme.sh по какой-то причине не сработал, мы видим это  
> минимум за 15 дней и принудительно перевыпускаем.

**Установить cron:**
```bash
(crontab -l 2>/dev/null | grep -v 'acme.sh\|domains.sh'; \
 echo '15 2 * * 6  bash /root/Linux_Server_Public/222/domains.sh >> /var/log/acme-deploy.log 2>&1') \
 | crontab -
```

---

## 🌍 Домены под управлением acme.sh (на 2026-06-29)

| Домен | Метод | CA | Следующий renew |
|---|---|---|---|
| timan-kuchyne.cz | DNS-01 / Cloudflare | Let's Encrypt | ~2026-08-28 |
| eco-seo.eu | DNS-01 / Cloudflare | Let's Encrypt | ~2026-08-28 |
| gincz.com | DNS-01 / Cloudflare | Let's Encrypt | ~2026-08-28 |
| kk-med.cz | DNS-01 / Cloudflare | Let's Encrypt | ~2026-08-27 |

> Остальные домены на сервере обновляются через FastPanel (HTTP-01).  
> Если у них появится проблема — переводить на acme.sh по схеме выше.

---

## 🚫 Что НЕЛЬЗЯ делать

1. **Нажимать «Обновить сертификат» в FastPanel** для доменов из таблицы выше.  
   FastPanel перепишет nginx-конфиг своими путями → сертификаты станут неактуальными.

2. **Отключать Cloudflare прокси (серое облачко)** на этих доменах.  
   Это откроет реальный IP сервера. Наш DNS-01 метод работает с любым состоянием прокси.

3. **Удалять acme-deploy-fastpanel.sh** — это сломает reloadcmd во всех доменах acme.sh.

---

## 🔍 Диагностика / Частые проблемы

### Сертификат истёк, сайт не открывается
```bash
# 1. Проверить что nginx читает нужный файл
nginx -T | grep -A3 "server_name.*ДОМЕН"

# 2. Проверить дату файла сертификата
ls -la /var/www/httpd-cert/ | grep ДОМЕН
openssl x509 -in /var/www/httpd-cert/ДОМЕН_*.crt -noout -dates

# 3. Принудительный перевыпуск
/.acme.sh/acme.sh --renew -d ДОМЕН -d www.ДОМЕН --force

# 4. Посмотреть лог
tail -50 /var/log/acme-deploy.log
```

### Новый домен — зарегистрировать в acme.sh
```bash
# 1. Добавить домен (если за CF-прокси)
/.acme.sh/acme.sh --issue --dns dns_cf -d НОВЫЙ.ДОМЕН -d www.НОВЫЙ.ДОМЕН --keylength ec-256

# 2. Запустить install-cert
/.acme.sh/acme.sh --install-cert -d НОВЫЙ.ДОМЕН \
  --cert-file /var/www/httpd-cert/НОВЫЙ.ДОМЕН_$(date +%Y-%m-%d).crt \
  --key-file /var/www/httpd-cert/НОВЫЙ.ДОМЕН_$(date +%Y-%m-%d).key \
  --fullchain-file /var/www/httpd-cert/НОВЫЙ.ДОМЕН_$(date +%Y-%m-%d)_fullchain.crt \
  --reloadcmd "bash /root/acme-deploy-fastpanel.sh НОВЫЙ.ДОМЕН"

# 3. Проверить список
/.acme.sh/acme.sh --list
```

### Проверить статус SSL всех доменов прямо сейчас
```bash
domains   # alias → domains.sh — покажет дни до истечения для каждого домена
```

### Посмотреть текущий cron
```bash
crontab -l
```

---

## 📋 История

| Дата | Событие |
|---|---|
| 2026-06-29 | 4 домена (timan-kuchyne.cz, eco-seo.eu, gincz.com, kk-med.cz) переведены на acme.sh + DNS-01. Написан acme-deploy-fastpanel.sh. Настроен еженедельный cron через domains.sh. |
