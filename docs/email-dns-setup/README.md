# 📧 Email DNS Setup: DKIM, DMARC, SPF — полная документация

> **Результат:** 10/10 на mail-tester.com ✅  
> **Домен:** stanok-ural.ru  
> **Сервер:** 212.109.223.109 (FastPanel, Ubuntu 24 LTS)  
> **DNS-провайдер:** Cloudflare  
> **Дата:** 2026-06-10

---

## 🗂️ Содержание

1. [Что настраивали и зачем](#1-что-настраивали-и-зачем)
2. [Итоговые DNS-записи](#2-итоговые-dns-записи)
3. [Что не получалось и как решили](#3-что-не-получалось-и-как-решили)
4. [Правильный порядок настройки](#4-правильный-порядок-настройки)
5. [Проверка результата](#5-проверка-результата)
6. [Настройка на сервере 222](#6-настройка-на-сервере-222)
7. [Полезные команды диагностики](#7-полезные-команды-диагностики)

---

## 1. Что настраивали и зачем

**Задача:** обеспечить корректную доставку писем с WordPress-сайта stanok-ural.ru через почтовый сервер FastPanel. Письма должны проходить спам-фильтры и получить оценку 10/10 на mail-tester.com.

### Три кита email-аутентификации

| Запись | Расшифровка | Задача |
|--------|-------------|--------|
| **SPF** | Sender Policy Framework | Указывает, с каких IP разрешено отправлять почту от имени домена |
| **DKIM** | DomainKeys Identified Mail | Цифровая подпись письма — получатель проверяет, что письмо не подделано |
| **DMARC** | Domain-based Message Authentication | Политика: что делать, если SPF/DKIM не прошли, куда слать отчёты |

---

## 2. Итоговые DNS-записи

Все записи в Cloudflare, тип прокси: **DNS only** (серое облако ☁️).

### A-записи
```
mail.stanok-ural.ru    A    212.109.223.109
stanok-ural.ru         A    212.109.223.109
www.stanok-ural.ru     A    212.109.223.109
```

### MX-запись
```
stanok-ural.ru    MX    emx.mail.ru    Priority: 10
```
> ⚠️ Приоритет MX оставить по умолчанию (обычно 10).

### TXT — SPF
```
stanok-ural.ru    TXT    "v=spf1 ip4:212.109.223.109 include:_spf.mail.ru ~all"
```
> Разрешает отправку с нашего IP + через mail.ru инфраструктуру. `~all` = мягкий отказ.

### TXT — DMARC
```
_dmarc.stanok-ural.ru    TXT    "v=DMARC1; p=quarantine; pct=100; sp=quarantine; adkim=r; aspf=r; fo=0; rf=afrf; ri=86400; np=quarantine"
```

| Параметр | Значение | Описание |
|----------|----------|----------|
| `p=quarantine` | | Письма без аутентификации → спам (не отклонять сразу) |
| `pct=100` | | Применять политику к 100% писем |
| `adkim=r` | relaxed | DKIM: допускается subdomain |
| `aspf=r` | relaxed | SPF: допускается subdomain |
| `ri=86400` | 24 часа | Интервал отчётов |

### TXT — DKIM (основной, FastPanel)
```
dkim._domainkey.stanok-ural.ru    TXT    "v=DKIM1; k=rsa; p=MIIBIjAN...IDAQAB"
```
> 🔑 **Важно:** публичный ключ берётся из FastPanel → Почта → DKIM → Показать публичный ключ. Приватный ключ хранится **только на сервере**, никуда не копировать!

### TXT — DKIM (mail.ru)
```
mailru._domainkey.stanok-ural.ru    TXT    "v=DKIM1; k=rsa; p=MIGfMA0GCS..."
```
> Нужен, если mail.ru используется как relay. Оба ключа в DNS — это нормально.

### TXT — Google Site Verification
```
stanok-ural.ru    TXT    "google-site-verification=XqZ62iPV4HIU8fCQDUkkmLp0eZ7JEqr1oUZFRVgJ3bA"
```

---

## 3. Что не получалось и как решили

### ❌ Проблема 1: DKIM-ключ обрезался

**Симптом:** mail-tester показывал ошибку DKIM signature, хотя запись в Cloudflare была создана.

**Причина:** При копировании длинного DKIM-ключа (2048 bit) последние символы обрезались. Cloudflare иногда показывает значение с `...` в конце в режиме просмотра.

**Как проверяли:**  
Открывали запись в Cloudflare на редактирование и смотрели в конце значения — должно заканчиваться на `...wIDAQAB"` (или другой валидный base64-символ перед закрывающей кавычкой).

**Решение:**
```bash
# На сервере FastPanel: берём полный ключ
cat /etc/opendkim/keys/stanok-ural.ru/default.txt

# Или через FastPanel UI:
# Почта → Домены → stanok-ural.ru → DKIM → Показать публичный ключ
# Копируем ПОЛНОСТЬЮ, включая последний символ
```
После исправления — DKIM прошёл.

---

### ❌ Проблема 2: SPF не включал IP сервера

**Симптом:** SPF fail — письма отклонялись или уходили в спам.

**Причина:** Запись SPF содержала только `include:_spf.mail.ru`, без явного IP сервера.

**Решение:** Добавить `ip4:212.109.223.109` явно:
```
"v=spf1 ip4:212.109.223.109 include:_spf.mail.ru ~all"
```

---

### ❌ Проблема 3: Proxy включён на почтовых записях

**Симптом:** Почта не доходила / SMTP не работал.

**Причина:** Записи `mail.*` и MX были с оранжевым облаком (проксирование включено). Cloudflare **не проксирует SMTP-трафик** (порты 25/465/587).

**Решение:** Все почтовые записи переключить в **DNS only** (серое облако ☁️):
- `mail.stanok-ural.ru` → DNS only
- MX-запись → DNS only (по умолчанию)
- TXT-записи (SPF, DKIM, DMARC) → DNS only

---

### ❌ Проблема 4: Два DKIM-ключа — нормально ли?

**Ситуация:** В DNS два DKIM-ключа:
- `dkim._domainkey` — от FastPanel (наш сервер)
- `mailru._domainkey` — от mail.ru (relay)

**Это нормально** — оба должны быть в DNS. WordPress отправляет через наш сервер → подписывает ключом `dkim._domainkey`.

---

## 4. Правильный порядок настройки

### Шаг 1: Настройка сервера (FastPanel)

```
1. FastPanel → Почта → Настройки SMTP → убедиться, что включён
2. FastPanel → Почта → Домены → stanok-ural.ru → DKIM → Включить
3. FastPanel → Почта → Домены → stanok-ural.ru → DKIM → Показать публичный ключ
4. Скопировать значение p=.... (без кавычек вокруг p=, только содержимое)
```

### Шаг 2: Создание DNS-записей в Cloudflare

```
1. Войти в Cloudflare → выбрать домен
2. DNS → Records → Add record

Порядок создания:
  1. SPF  (TXT для @)
  2. DKIM (TXT для dkim._domainkey)
  3. DMARC (TXT для _dmarc)
  4. MX — проверить, что уже есть

Для КАЖДОЙ записи:
  - Proxy status: DNS only (☁️ серое)
  - TTL: Auto
```

### Шаг 3: Настройка WordPress

```
1. Установить плагин WP Mail SMTP (или аналог)
2. Настройки → WP Mail SMTP → Settings:
   - From Email: noreply@stanok-ural.ru
   - Mailer: Other SMTP
   - SMTP Host: mail.stanok-ural.ru (или localhost)
   - SMTP Port: 587 (STARTTLS) или 465 (SSL)
   - Username: почтовый ящик
   - Password: пароль ящика
3. Tools → Test Email → отправить тест
```

### Шаг 4: Тестирование

```bash
# Проверка DNS через командную строку
dig +short TXT stanok-ural.ru          # SPF
dig +short TXT dkim._domainkey.stanok-ural.ru  # DKIM
dig +short TXT _dmarc.stanok-ural.ru   # DMARC

# Онлайн-проверка:
# https://www.mail-tester.com  → получить адрес → отправить тест → результат
# https://mxtoolbox.com/SuperTool.aspx → SPF/DKIM/DMARC lookup
```

---

## 5. Проверка результата

### mail-tester.com — 10/10 ✅

Все проверки пройдены:
- ✅ SPF проходит
- ✅ DKIM подпись верна
- ✅ DMARC настроен
- ✅ Reverse DNS (PTR) настроен
- ✅ Домен не в блок-листах
- ✅ HTML письма валидный
- ✅ Нет спам-слов в теме/теле

### Команды проверки с сервера

```bash
# Проверка SPF
dig +short TXT stanok-ural.ru

# Проверка DKIM
dig +short TXT dkim._domainkey.stanok-ural.ru

# Проверка DMARC
dig +short TXT _dmarc.stanok-ural.ru

# MX
dig +short MX stanok-ural.ru

# Reverse DNS (PTR) — важно для репутации
dig -x 212.109.223.109

# Тестовая отправка письма
echo "Test body" | mail -s "Test subject" your@email.com

# Проверка очереди Postfix
mailq

# Логи отправки
tail -50 /var/log/mail.log

# Проверка конфига DKIM (OpenDKIM)
opendkim-testkey -d stanok-ural.ru -s dkim -vvv
```

### Как читать заголовки письма

В Gmail: три точки → Показать оригинал. Искать строки:
```
Authentication-Results: mx.google.com;
   dkim=pass header.i=@stanok-ural.ru;
   spf=pass smtp.mailfrom=stanok-ural.ru;
   dmarc=pass (p=QUARANTINE)
```

---

## 6. Настройка на сервере 222

> **TODO:** Повторить настройку для второго сервера.

### Исходные данные (заполнить)

```
IP сервера:     2XX.XXX.XXX.222
Домен:          [ДОМЕН]
Панель:         FastPanel
DNS:            Cloudflare
```

### Чеклист настройки

```
□ FastPanel: включить DKIM для домена
□ Скопировать публичный DKIM-ключ из FastPanel
□ Cloudflare: создать/проверить A-запись для mail.[ДОМЕН]
□ Cloudflare: создать/проверить MX-запись
□ Cloudflare: создать SPF-запись с новым IP
□ Cloudflare: создать DKIM-запись (ключ из FastPanel сервера 222)
□ Cloudflare: создать DMARC-запись
□ Все записи: DNS only (серое облако)
□ Подождать TTL (1-5 минут при Auto TTL в Cloudflare)
□ Проверить dig для всех записей
□ Настроить WP Mail SMTP в WordPress
□ Отправить тест через mail-tester.com
□ Результат: 10/10 ✅
```

### SPF для сервера 222

```
[ДОМЕН]    TXT    "v=spf1 ip4:2XX.XXX.XXX.222 include:_spf.mail.ru ~all"
```

> ⚠️ **Важно:** Если один домен используется на двух серверах (нежелательно), SPF может содержать оба IP:
> ```
> "v=spf1 ip4:212.109.223.109 ip4:2XX.XXX.XXX.222 include:_spf.mail.ru ~all"
> ```
> Но лучше — каждый домен на своём сервере.

### DKIM для сервера 222

Ключ будет **отличаться** от сервера 109 — каждый сервер генерирует свой ключ:
```
dkim._domainkey.[ДОМЕН]    TXT    "v=DKIM1; k=rsa; p=[КЛЮЧ ИЗ FASTPANEL СЕРВЕРА 222]"
```

---

## 7. Полезные команды диагностики

```bash
# ==== DNS ПРОВЕРКИ ====

# SPF
dig +short TXT stanok-ural.ru

# DKIM  
dig +short TXT dkim._domainkey.stanok-ural.ru

# DMARC
dig +short TXT _dmarc.stanok-ural.ru

# MX
dig +short MX stanok-ural.ru

# Reverse DNS (PTR)
dig -x 212.109.223.109


# ==== POSTFIX ====

# Статус
systemctl status postfix

# Очередь
mailq

# Логи (последние 50 строк)
tail -50 /var/log/mail.log

# Тестовая отправка
echo "Test body" | mail -s "Test" recipient@gmail.com

# Принудительная отправка очереди
postqueue -f

# Проверка конфига DKIM
opendkim-testkey -d stanok-ural.ru -s dkim -vvv


# ==== EXIM (если используется) ====

# Статус
systemctl status exim4

# Логи
tail -50 /var/log/exim4/mainlog

# Тест конфига
exim -bV


# ==== ОНЛАЙН ИНСТРУМЕНТЫ ====
# mail-tester.com       — комплексный тест 10/10
# mxtoolbox.com         — DNS lookup, blacklist check
# dmarcian.com          — DMARC inspector
# dkimvalidator.com     — DKIM проверка
# learndmarc.com        — визуализация DMARC
# google.com/postmaster — Google Postmaster Tools (репутация домена)
```

---

## 📌 Ключевые выводы

1. **Все почтовые DNS-записи должны быть DNS only** (серое облако в Cloudflare) — Cloudflare не проксирует SMTP
2. **DKIM-ключ берётся из FastPanel** для конкретного сервера — не с другого сервера
3. **При копировании DKIM-ключа** проверяй последний символ — часто обрезается
4. **SPF должен содержать реальный IP сервера** + include для relay-сервисов
5. **DMARC = p=quarantine** безопаснее чем p=none, но мягче чем p=reject
6. **Порядок отладки:** сначала SPF, потом DKIM, потом DMARC
7. **mail-tester.com** — лучший инструмент финальной проверки

---

*Документация создана: 2026-06-10 | Автор: VladiMIR Bulantsev (GinCz)*
