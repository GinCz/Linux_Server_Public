# SESSION LOG — STOLB-24 | 2026-06-14

> = Rooted by VladiMIR + AI | v.2026.06.14 | github.com/GinCz

---

## Цель сессии

Найти и устранить причину периодического отказа DNS (AdGuard Home) на сервере STOLB-24 (144.124.239.24).
DNS отваливался 2-3 раза за последний месяц.

---

## Диагностика — найдены 3 критические проблемы

### Проблема 1: `netfilter-persistent` падал при каждом ребуте

**Симптом:**
```
netfilter-persistent[692]: iptables-restore v1.8.7 (nf_tables): Set doesn't exist
Error occurred at line: 50
netfilter-persistent.service: Failed with result 'exit-code'
```

**Причина:**
В `/etc/iptables/rules.v4` были сохранены ссылки на ipset `vladblacklist` и CrowdSec chains `crowdsec-blacklists-0/1`.
В `/etc/iptables/rules.v6` — ссылки на `crowdsec6-blacklists-0`.
При ребуте `netfilter-persistent` стартует раньше CrowdSec и `deploy-blacklist.sh` — ipset'ы ещё не созданы → restore падает → **все bypass-правила для DNS не загружаются**.

Дополнительно: в `rules.v4` были UFW-цепочки (`ufw-before-logging-input` и др.) — они тоже не существуют в момент загрузки netfilter-persistent, что вызывало ошибку `Chain does not exist`.

**Решение:**
Записать в `rules.v4` и `rules.v6` ТОЛЬКО минимальные bypass-правила — без ipset, без CrowdSec chain, без UFW chain. Каждый сервис добавляет свои правила сам после старта.

```
/etc/iptables/rules.v4 — итоговое содержимое:
*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p tcp --dport 22   -j ACCEPT
-A INPUT -p udp --dport 53   -j ACCEPT  # DNS bypass CrowdSec
-A INPUT -p tcp --dport 53   -j ACCEPT  # DNS bypass CrowdSec
-A INPUT -p tcp --dport 853  -j ACCEPT  # DoT bypass CrowdSec
-A INPUT -p udp --dport 853  -j ACCEPT  # DoT bypass CrowdSec
-A INPUT -p tcp --dport 443  -j ACCEPT  # AdGuard DoH bypass CrowdSec
-A INPUT -p tcp --dport 8443 -j ACCEPT  # XRAY VPN bypass CrowdSec
-A INPUT -p tcp --dport 8080 -j ACCEPT  # AdGuard Web UI bypass CrowdSec
COMMIT
```

Добавлен drop-in для правильного порядка старта:
```
/etc/systemd/system/netfilter-persistent.service.d/after-crowdsec.conf:
[Unit]
After=network-online.target crowdsec.service
Wants=crowdsec.service
```

---

### Проблема 2: Единственный upstream DNS — только Quad9

**Симптом:**
Все ошибки в логах AdGuard одного типа:
```
exchange failed upstream=https://dns10.quad9.net:443/dns-query
err="unexpected EOF"
```
При любых проблемах на стороне Quad9 DNS полностью отказывал для всех клиентов.

**Решение:**
Добавить 5 upstream серверов в параллельном режиме:
```yaml
upstream_dns:
  - https://dns10.quad9.net/dns-query
  - https://cloudflare-dns.com/dns-query
  - https://dns.google/dns-query
  - tls://1.1.1.1
  - tls://8.8.8.8
fallback_dns:
  - 1.1.1.1
  - 8.8.8.8
upstream_mode: parallel
```
Изменено через `sed` напрямую в `/opt/AdGuardHome/AdGuardHome.yaml`.

---

### Проблема 3: DNS bypass правила стояли ПОСЛЕ CrowdSec в iptables

**Симптом:**
После ребута порядок правил INPUT:
```
1  CROWDSEC_CHAIN   ← сначала CrowdSec!
2  f2b-sshd
3  ACCEPT dpt:53    ← bypass только здесь
```
Если IP забанен в CrowdSec — DNS-запросы дропались до ACCEPT по порту 53.

**Решение:**
Bypass-правила теперь в `rules.v4` — они загружаются `netfilter-persistent` первыми.
CrowdSec добавляет свой `CROWDSEC_CHAIN` позже, но наши ACCEPT по портам 53/853/443/8443 уже стоят выше.

---

### Проблема 4: `@reboot` crontab без `ip6tables-restore`

**Было:**
```
@reboot sleep 5 && ipset restore < /etc/ipset.rules 2>/dev/null; iptables-restore < /etc/iptables/rules.v4 2>/dev/null
```

**Стало:**
```
@reboot sleep 15 && ipset restore < /etc/ipset.rules 2>/dev/null; iptables-restore < /etc/iptables/rules.v4 2>/dev/null; ip6tables-restore < /etc/iptables/rules.v6 2>/dev/null
```
Увеличен sleep с 5 до 15 сек, добавлен `ip6tables-restore`.

---

## Итоговое состояние после ребута

```
netfilter-persistent: active (exited) — Finished ✓ (больше не падает!)
AdGuardHome:          active ✓
crowdsec:             active ✓
crowdsec-firewall-bouncer: active ✓
ufw:                  active ✓
x-ui:                 active ✓

DNS port 53: OK ✓ (google.com, cloudflare.com, ya.ru — все резолвятся)

iptables INPUT порядок:
1  CROWDSEC_CHAIN     (добавлен CrowdSec после старта)
2  ACCEPT lo
3  ACCEPT RELATED,ESTABLISHED
4  ACCEPT tcp dpt:22
5  ACCEPT udp dpt:53   DNS bypass
6  ACCEPT tcp dpt:53   DNS bypass
7  ACCEPT tcp dpt:853  DoT bypass
8  ACCEPT udp dpt:853  DoT bypass
9  ACCEPT tcp dpt:443  AdGuard DoH
10 ACCEPT tcp dpt:8443 XRAY VPN
11 ACCEPT tcp dpt:8080 AdGuard Web UI
```

---

## Главный вывод

**Правило для всех серверов с netfilter-persistent + UFW + CrowdSec:**

> `rules.v4` и `rules.v6` должны содержать ТОЛЬКО простые bypass-правила без ссылок на ipset и цепочки UFW/CrowdSec. Каждый сервис добавляет свои правила в iptables самостоятельно при старте.

**Правило для AdGuard Home:**

> Всегда настраивать минимум 3-5 upstream серверов в режиме `parallel`. Один upstream = единая точка отказа.

---

## Чеклист для других серверов с AdGuard Home

```bash
# 1. Проверить rules.v4 на ipset/UFW/CrowdSec ссылки
grep -E "match-set|ufw-|CROWDSEC" /etc/iptables/rules.v4

# 2. Проверить upstream в AdGuard
grep -A 8 "upstream_dns:" /opt/AdGuardHome/AdGuardHome.yaml

# 3. Проверить netfilter-persistent
systemctl status netfilter-persistent

# 4. Проверить crontab на ip6tables-restore
crontab -l | grep iptables
```
