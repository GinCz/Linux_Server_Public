# 📨 Telegram Config — /root/.tg_config

> ⚠️ This file is **documentation only**. Real tokens are NOT stored here.

---

## File structure on each server

The file `/root/.tg_config` exists on **all servers** (deployed 2026-06-15).

```bash
# /root/.tg_config
# chmod 600 /root/.tg_config
TG_TOKEN="<bot_token>"
TG_CHAT="<chat_id>"
```

> 🔑 Real values are stored in the private repository **GinCz/Secret_Privat**

---

## How to use in any script

```bash
# Always add this line at the top of your script — the token will be loaded automatically
source /root/.tg_config 2>/dev/null || { echo "ERROR: /root/.tg_config not found"; exit 1; }
T="$TG_TOKEN"
C="$TG_CHAT"
```

Then send a message:
```bash
tg() {
    curl -s -X POST "https://api.telegram.org/bot${T}/sendMessage" \
        -d "chat_id=${C}" \
        -d "parse_mode=HTML" \
        -d "disable_notification=true" \
        -d "text=$1" >/dev/null 2>&1 || true
}
```

---

## Adding a new server

```bash
# Copy .tg_config from 222 to the new server
scp /root/.tg_config root@NEW_SERVER_IP:/root/.tg_config
ssh root@NEW_SERVER_IP 'chmod 600 /root/.tg_config'
```

---

## 📊 Deployment status per server

| IP | Name | .tg_config | night_update.sh |
|---|---|---|---|
| 152.53.182.222 | 222-DE-NetCup | ✅ | ✅ |
| 212.109.223.109 | 109-RU | ✅ | ✅ |
| 212.34.148.51 | VPN ALEX_51 | ✅ | ✅ |
| 144.124.228.237 | VPN 4TON_237 | ✅ | ✅ |
| 144.124.232.9 | VPN TATRA_9 | ✅ | ✅ |
| 144.124.228.227 | VPN SHAHIN_227 | ✅ | ✅ |
| 144.124.239.24 | VPN STOLB_24 | ✅ | ✅ |
| 195.63.138.33 | VPN PILIK_33 | ✅ | ❌ offline 2026-06-15 |
| 146.103.110.176 | VPN ILYA_176 | ✅ | ✅ |
| 144.124.233.38 | VPN SO_38 | ✅ | ✅ |

> ⚠️ **PILIK_33** (195.63.138.33) — when back online, update manually:
> ```bash
> ssh root@195.63.138.33 "curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/night_update.sh -o /root/night_update.sh && chmod +x /root/night_update.sh && echo '✅ PILIK_33 updated'"
> ```

---

*= Rooted by VladiMIR + AI | v2026.07.11 | github.com/GinCz =*
