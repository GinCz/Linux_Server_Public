# Telegram конфиг — /root/.tg_config

> ⚠️ Этот файл — документация. Сами токены здесь НЕ хранятся.

## Структура файла на каждом сервере

Файл `/root/.tg_config` существует на **всех 10 серверах** (задеплоен 2026-06-15).

```bash
# /root/.tg_config
# chmod 600 /root/.tg_config
TG_TOKEN="<bot_token>"
TG_CHAT="<chat_id>"
```

> 🔑 Реальные значения хранятся в приватном репозитории **GinCz/Secret_Privat**

## Как использовать в любом скрипте

```bash
# Всегда добавляй эту строку в начало скрипта — и токен подхватится автоматически
source /root/.tg_config 2>/dev/null || { echo "ERROR: /root/.tg_config not found"; exit 1; }
T="$TG_TOKEN"
C="$TG_CHAT"
```

Затем отправка:
```bash
tg() {
    curl -s -X POST "https://api.telegram.org/bot${T}/sendMessage" \
        -d "chat_id=${C}" \
        -d "parse_mode=HTML" \
        -d "disable_notification=true" \
        -d "text=$1" >/dev/null 2>&1 || true
}
```

## Если добавляется новый сервер

```bash
# Скопировать .tg_config с 222 на новый сервер
scp /root/.tg_config root@NEW_SERVER_IP:/root/.tg_config
ssh root@NEW_SERVER_IP 'chmod 600 /root/.tg_config'
```

## Серверы где задеплоен файл

| IP | Имя | Статус |
|---|---|---|
| 152.53.182.222 | 222-DE-NetCup | ✅ |
| 212.109.223.109 | 109-RU | ✅ |
| 109.234.38.47 | VPN ALEX_47 | ✅ |
| 144.124.228.237 | VPN 4TON_237 | ✅ |
| 144.124.232.9 | VPN TATRA_9 | ✅ |
| 144.124.228.227 | VPN SHAHIN_227 | ✅ |
| 144.124.239.24 | VPN STOLB_24 | ✅ |
| 91.84.118.178 | VPN PILIK_178 | ✅ |
| 146.103.110.176 | VPN ILYA_176 | ✅ |
| 144.124.233.38 | VPN SO_38 | ✅ |
