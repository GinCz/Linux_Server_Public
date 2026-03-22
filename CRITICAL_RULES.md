# CRITICAL OPERATIONAL RULES

**Valid for all servers: 222 / 109 / VPN**

---

## Rule 1 — Persistent alias after every script install

Add the alias to `/opt/server_tools/scripts/shared_aliases.sh`.
Never use `alias` directly in terminal — it will be lost after reboot.

## Rule 2 — Midnight Commander F2 menu

Add every new script to `~/.config/mc/menu` so it is accessible via F2.

A script installation is NOT complete until both Rule 1 and Rule 2 are done.

---

## Rule 3 — Dated backup before editing any config file

Before editing any important configuration file, always create a dated
backup copy first:

    cp /path/to/file.conf /path/to/file.conf.bak.$(date +%Y-%m-%d-%H%M%S)

Mandatory for:
- /etc/nginx/
- /etc/php/
- /etc/mysql/
- /etc/crowdsec/
- /etc/systemd/
- Any file in /opt/server_tools/

A config change is NOT safe without a dated backup copy first.

---

## Current aliases (server_audit.sh)

| Alias  | Command                      | Description     |
|--------|------------------------------|-----------------|
| sos    | server_audit.sh 24h          | SOS default 24h |
| sos1   | server_audit.sh 1h           | SOS 1 hour      |
| sos3   | server_audit.sh 3h           | SOS 3 hours     |
| sos24  | server_audit.sh 24h          | SOS 24 hours    |
| sos120 | server_audit.sh 120h         | SOS 120 hours   |

---

## Alias method

All aliases stored in:
    /opt/server_tools/scripts/shared_aliases.sh

Must be sourced in ~/.bashrc on every server:
    source /opt/server_tools/scripts/shared_aliases.sh

## MC F2 Menu file

    ~/.config/mc/menu

## Perplexity AI — правила работы с репо
- Perplexity ЧИТАЕТ репо (скрипты, конфиги, алиасы) перед ответом
- Perplexity НЕ ЗАЛИВАЕТ в репо — заливка глючит
- Все изменения файлов Perplexity даёт как код → выполняешь с сервера сам
