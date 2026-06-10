# DKIM Setup Guide — Exim4 Multi-Domain (FastPanel)

> = Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =  
> Результат: **10/10** на mail-tester.com ✅  
> Дата: 10 June 2026  
> Применимо: **RU-SO-109** (212.109.223.109) и **DE-EU-222** (152.53.182.222)

---

## Введение

Exim4 на FastPanel использует **split config** (`/etc/exim4/conf.d/`).  
Это важно — `localmacros` файл в split-config режиме **не работает**.

---

## Архитектура решения

```
/etc/exim4/
├── conf.d/
│   ├── main/
│   │   ├── 00_local_dkim          ← наш файл макросов DKIM
│   │   └── 01_primary_hostname    ← override HELO hostname для Exim
│   └── transport/
│       └── 30_exim4-config_remote_smtp  ← уже содержит DKIM_ переменные (стандарт Debian)
└── dkim/
    ├── keymap.txt                 ← маппинг domain → path_to_key
    ├── stanok-ural.ru-private.pem
    ├── stanok-ural.ru-public.pem
    └── <другие домены>.pem
```

---

## Шаг 1 — Генерация ключей для каждого домена

```bash
mkdir -p /etc/exim4/dkim
chmod 750 /etc/exim4/dkim

# Для каждого домена:
DOMAIN="stanok-ural.ru"
openssl genrsa -out /etc/exim4/dkim/${DOMAIN}-private.pem 2048
openssl rsa -in /etc/exim4/dkim/${DOMAIN}-private.pem \
  -out /etc/exim4/dkim/${DOMAIN}-public.pem -pubout

chmod 640 /etc/exim4/dkim/${DOMAIN}-private.pem
chown root:Debian-exim /etc/exim4/dkim/${DOMAIN}-private.pem
```

---

## Шаг 2 — Создать keymap.txt

Файл-маппинг: каждая строка = `domain    /path/to/private.pem`

```bash
cat > /etc/exim4/dkim/keymap.txt << 'EOF'
stanok-ural.ru    /etc/exim4/dkim/stanok-ural.ru-private.pem
# Добавлять новые домены сюда:
# example.com    /etc/exim4/dkim/example.com-private.pem
EOF
```

---

## Шаг 3 — Создать файл макросов DKIM

> ⚠️ ВАЖНО: НЕ использовать `/etc/exim4/exim4.conf.localmacros`  
> В split-config режиме он **игнорируется**. Только `conf.d/main/`!

```bash
cat > /etc/exim4/conf.d/main/00_local_dkim << 'EOF'
# DKIM macros for multi-domain signing via keymap lookup
# = Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =

DKIM_CANON = relaxed
DKIM_SELECTOR = dkim
DKIM_DOMAIN = ${lookup{${lc:${domain:$h_from:}}}lsearch{/etc/exim4/dkim/keymap.txt}{${lc:${domain:$h_from:}}}{}}
DKIM_PRIVATE_KEY = ${lookup{${lc:${domain:$h_from:}}}lsearch{/etc/exim4/dkim/keymap.txt}{$value}{0}}
DKIM_STRICT = 0
EOF
```

---

## Шаг 4 — Установить primary_hostname (только для Exim)

Системный hostname (`RU-SO-109`, `DE-EU-222`) **не меняем**.  
Exim получает свой hostname для SMTP HELO:

```bash
# Для сервера 109:
cat > /etc/exim4/conf.d/main/01_primary_hostname << 'EOF'
# Override SMTP HELO hostname for Exim only.
# System hostname stays RU-SO-109 / DE-EU-222 — NOT changed.
# = Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =
primary_hostname = mail.stanok-ural.ru
EOF

# Для сервера 222 — заменить на нужный домен:
# primary_hostname = mail.gincz.eu
```

---

## Шаг 5 — Пересборка и перезапуск Exim4

```bash
update-exim4.conf
systemctl restart exim4
systemctl is-active exim4

# Проверить что макросы видны:
exim4 -bP macro DKIM_DOMAIN
exim4 -bP macro DKIM_PRIVATE_KEY
```

Ожидаемый вывод:
```
DKIM_DOMAIN=${lookup{${lc:${domain:$h_from:}}}lsearch{...}
DKIM_PRIVATE_KEY=${lookup{${lc:${domain:$h_from:}}}lsearch{...}
```

---

## Шаг 6 — DNS записи (Cloudflare)

Получить публичный ключ с сервера:

```bash
DOMAIN="stanok-ural.ru"
openssl rsa -in /etc/exim4/dkim/${DOMAIN}-private.pem -pubout 2>/dev/null \
  | grep -v "BEGIN\|END" | tr -d '\n'
echo
```

**Добавить в Cloudflare DNS:**

| Type | Name | Content |
|---|---|---|
| A | `mail.stanok-ural.ru` | `212.109.223.109` |
| TXT | `dkim._domainkey.stanok-ural.ru` | `v=DKIM1; k=rsa; p=<ключ>` |
| TXT | `stanok-ural.ru` (SPF уже есть) | `v=spf1 ip4:212.109.223.109 include:_spf.mail.ru ~all` |

> ⚠️ Cloudflare РАЗБИВАЕТ длинный ключ на два чанка при отображении — это НОРМАЛЬНО.  
> Но иногда при копировании/вставке добавляется пробел или обрезается хвост.  
> Ключ должен заканчиваться на `...IDAQAB` (последние 6 символов RSA-2048 публичного ключа).

---

## Шаг 7 — Проверка

```bash
# Сравнить ключ на сервере с ключом в DNS:
SERVER=$(openssl rsa -in /etc/exim4/dkim/stanok-ural.ru-private.pem \
  -pubout 2>/dev/null | grep -v "BEGIN\|END" | tr -d '\n')
DNS=$(dig TXT dkim._domainkey.stanok-ural.ru +short | tr -d '"' | grep -oP 'p=\K[^;]+')

[ "$SERVER" = "$DNS" ] && echo "[OK] СОВПАДАЮТ" || echo "[FAIL] НЕ СОВПАДАЮТ"

# Отправить тестовое письмо:
echo 'Test DKIM' | mail -s 'DKIM Test' test@mail-tester.com
```

Цель: **10/10** на [mail-tester.com](https://www.mail-tester.com)

---

## ❌ Что НЕ работало (и почему)

### 1. localmacros — игнорируется в split config

```bash
# НЕ РАБОТАЕТ:
/etc/exim4/exim4.conf.localmacros
```
Файл `localmacros` читается только при **монолитной** конфигурации (`/etc/exim4/exim4.conf`).  
FastPanel использует split config — этот файл **полностью игнорируется**.  
**Решение:** `conf.d/main/00_local_dkim`

### 2. Пробел и обрезанный ключ в Cloudflare DNS

При ручном копировании публичного ключа в Cloudflare:
- Cloudflare разбил ключ на два чанка (это нормально — RFC 4408 допускает)
- НО при редактировании добавился пробел в середине: `...bF wbJU...`
- И в конце отсутствовало `AB` (ключ обрезан: `...IDAQ` вместо `...IDAQAB`)

Результат: `DKIM_INVALID` при проверке — подпись есть, но невалидна.  
**Решение:** Вставлять ключ одной строкой, без пробелов, убедиться что конец `...IDAQAB`.

### 3. DKIM_DOMAIN через $h_from: vs прямое значение

Первый вариант макроса использовал прямое значение домена:
```
DKIM_DOMAIN = stanok-ural.ru
```
Это работает только для одного домена. При multi-domain (много сайтов) нужен lookup по From-заголовку:
```
DKIM_DOMAIN = ${lookup{${lc:${domain:$h_from:}}}lsearch{/etc/exim4/dkim/keymap.txt}{...}}
```

---

## ✅ Результат

| Проверка | Статус |
|---|---|
| SPF | ✅ Pass |
| DKIM | ✅ Valid |
| DMARC | ✅ Pass |
| PTR / rDНС | ✅ mail.stanok-ural.ru |
| Blacklists | ✅ Чисто |
| **mail-tester.com** | **🏆 10/10** |

---

## 📋 Чеклист для нового домена

```bash
# 1. Генерируем ключ:
DOMAIN="newdomain.ru"
openssl genrsa -out /etc/exim4/dkim/${DOMAIN}-private.pem 2048
openssl rsa -in /etc/exim4/dkim/${DOMAIN}-private.pem \
  -out /etc/exim4/dkim/${DOMAIN}-public.pem -pubout
chmod 640 /etc/exim4/dkim/${DOMAIN}-private.pem
chown root:Debian-exim /etc/exim4/dkim/${DOMAIN}-private.pem

# 2. Добавляем в keymap:
echo "${DOMAIN}    /etc/exim4/dkim/${DOMAIN}-private.pem" >> /etc/exim4/dkim/keymap.txt

# 3. Получаем публичный ключ для DNS:
openssl rsa -in /etc/exim4/dkim/${DOMAIN}-private.pem -pubout 2>/dev/null \
  | grep -v "BEGIN\|END" | tr -d '\n' && echo

# 4. Добавить в DNS Cloudflare:
#    TXT  dkim._domainkey.${DOMAIN}  =>  "v=DKIM1; k=rsa; p=<ключ>"

# 5. Перезапустить НЕ НУЖНО — keymap читается динамически при отправке
```

---

## 🖥️ Универсальный скрипт автонастройки

См. `scripts/setup_dkim.sh` — находит все домены через nginx, генерирует ключи,  
заполняет keymap.txt, создаёт conf.d/main/00_local_dkim, выводит DNS-записи.

---

*= Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz/Linux_Server_Public =*
