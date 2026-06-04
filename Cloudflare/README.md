# Cloudflare Security Scripts

> Rooted by VladiMIR + AI | github.com/GinCz

Автоматическая 3-слойная защита Cloudflare для всех доменов аккаунта.

## Запуск

```bash
export CF_TOKEN="cfat_..."
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Cloudflare/<имя_скрипта>.sh)
```

Токен хранится в `Secret_Privat/api_keys.md`.

---

## Варианты скриптов

| Файл | Назначение | Правило 37 (Firewall) |
|---|---|---|
| `cloudflare-wp-batch.sh` | ВСЕ домены — WordPress (эталон) | WP пути + базовые атаки |
| `cf-all-domains-wp.sh` | ВСЕ домены — WordPress расширенный | WP пути + плохие UA + сканеры |
| `cf-all-domains-wp-woo.sh` | ВСЕ домены — WordPress + WooCommerce | WP + WooCommerce пути |
| `cf-all-domains-wp-ads.sh` | ВСЕ домены — WordPress + Объявления | WP + доски объявлений |

---

## Архитектура защиты (все варианты)

```
Rule 27 — Whitelist Skip       14 доверенных IP → bypass ALL CF правил
Rule 37 — WP Firewall          Атаки → Turnstile CAPTCHA (managed_challenge)
Rule 47 — Rate Limit           100 req/10s → Block 429
```

### Rule 27 — Whitelist (14 IP)

```
152.53.182.222   DE server 222
212.109.223.109  RU server 109
109.234.38.47    VPN ALEX_47
144.124.228.237  VPN 4TON_237
144.124.232.9    VPN TATRA_9
144.124.228.227  VPN SHAHIN_227
144.124.239.24   VPN STOLB_24
91.84.118.178    VPN PILIK_178
146.103.110.176  VPN ILYA_176
144.124.233.38   VPN SO_38
185.100.197.16   Home IP
185.14.233.235   Home IP
185.14.232.0     Home IP
90.181.133.10    Work IP
```

---

## Отличия вариантов Rule 37

### cf-all-domains-wp.sh — WordPress расширенный
Всё из эталона + блокировка плохих User-Agent (пустые UA, сканеры, curl-боты)

### cf-all-domains-wp-woo.sh — WordPress + WooCommerce
Всё из WP расширенного + защита WooCommerce:
- `/wc-api/` — Rate Limit abuse
- `/wp-json/wc/` — REST API несанкционированный доступ
- `/?wc-ajax=` — AJAX флуд
- `/checkout/` — carding-атаки
- `/my-account/` — brute force аккаунтов
- `/cart/` — cart flooding

### cf-all-domains-wp-ads.sh — WordPress + Объявления
Всё из WP расширенного + защита досок объявлений:
- `/add-listing/`, `/post-ad/`, `/submit/` — спам объявлений
- `/contact-seller/`, `/send-message/` — спам сообщений
- `/wp-json/` широкий — REST API злоупотребление
- Блокировка массового парсинга объявлений
