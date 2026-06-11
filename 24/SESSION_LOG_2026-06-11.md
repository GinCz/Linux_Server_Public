# SESSION LOG — STOLB-24 | 2026-06-11

> = Rooted by VladiMIR + AI | v.2026.06.11

---

## Цель сессии

Сделать так, чтобы AdGuard Home (DNS) на STOLB-24 отвечал всем клиентам без блокировки — телефоны и роутеры с динамическими IP должны получать DNS без ограничений.
Защита сервера (SSH, панель, VPN) должна оставаться активной.

---

## Проблема 1: DNS не работал для мобильных устройств

### Симптом
Pri включённом Private DNS (`144.124.239.24`) на Android — интернет переставал работать.

### Причина
CrowdSec + UFW банят IP-адреса целиком без учёта портов. Мобильный IP `37.48.9.111` попал под бан.
Главное: порт 53 был закрыт в UFW.

### Решение

1. Открыть порт 53 в UFW:
```bash
ufw allow 53/udp comment "DNS - AdGuard Home"
ufw allow 53/tcp comment "DNS - AdGuard Home"
```

2. Добавить bypass перед CROWDSEC_CHAIN в iptables:
```bash
iptables  -I INPUT 1 -p udp --dport 53 -j ACCEPT -m comment --comment "DNS bypass CrowdSec"
iptables  -I INPUT 2 -p tcp --dport 53 -j ACCEPT -m comment --comment "DNS bypass CrowdSec"
ip6tables -I INPUT 1 -p udp --dport 53 -j ACCEPT -m comment --comment "DNS bypass CrowdSec"
ip6tables -I INPUT 2 -p tcp --dport 53 -j ACCEPT -m comment --comment "DNS bypass CrowdSec"
```

3. Удалить IP из бана CrowdSec:
```bash
cscli decisions delete --ip 37.48.9.111
```

---

## Проблема 2: Правила иптаблес не сохранились после reboot

### Симптом
После перезагрузки правила DNS bypass слетели, DNS снова перестал работать.

### Причина
`netfilter-persistent` не был установлен. `iptables-save` до перезагрузки не выполнялся — правила были только в памяти.

### Решение
```bash
apt install -y iptables-persistent
iptables-save  > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6
```

Примечание: в crontab уже был `@reboot iptables-restore < /etc/iptables/rules.v4` — поэтому важно сохранять rules.v4 до reboot.

---

## Проблема 3: DNS всё равно не работал после сохранения правил

### Симптом
UFW блокировал порт **853** (DNS-over-TLS). Телефон Android использует Private DNS — это DoT на порту 853, а не обычный DNS на 53.

### Диагностика
В `/var/log/ufw.log` обнаружены блокировки:
```
[UFW BLOCK] SRC=37.48.9.111 DPT=853
```

### Решение
```bash
ufw allow 853/tcp comment "DNS-over-TLS - AdGuard Home"
ufw allow 853/udp comment "DNS-over-TLS - AdGuard Home"
iptables  -I INPUT 1 -p tcp --dport 853 -j ACCEPT -m comment --comment "DoT bypass CrowdSec"
iptables  -I INPUT 2 -p udp --dport 853 -j ACCEPT -m comment --comment "DoT bypass CrowdSec"
ip6tables -I INPUT 1 -p tcp --dport 853 -j ACCEPT -m comment --comment "DoT bypass CrowdSec"
ip6tables -I INPUT 2 -p udp --dport 853 -j ACCEPT -m comment --comment "DoT bypass CrowdSec"
iptables-save  > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6
```

---

## Проблема 4: VPN (XRAY) не работал с мобильного телефона

### Симптом
VPN не подключался с мобильного интернета.

### Причина
UFW не пропускал порт **8443** (XRAY VPN). 
Порт 443 занят AdGuard Home (DoH), а VPN сидит на 8443.
В `/var/log/ufw.log`:
```
[UFW BLOCK] SRC=37.48.9.111 DPT=8443
```

### Решение
```bash
ufw allow 8443/tcp comment "XRAY VPN"
iptables -I INPUT 1 -p tcp --dport 8443 -j ACCEPT -m comment --comment "XRAY VPN bypass CrowdSec"
ip6tables -I INPUT 1 -p tcp --dport 8443 -j ACCEPT -m comment --comment "XRAY VPN bypass CrowdSec"
iptables-save  > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6
```

---

## Проблема 5: x-ui панель (54321) была закрыта для клиента

### Симптом
IP `83.217.9.81` (клиент) не мог открыть x-ui панель.

### Причина
UFW не пропускал `DPT=54321` для этого IP.

### Решение
Панель открыта ТОЛЬКО для доверенных IP:
```bash
ufw allow from 83.217.9.81   to any port 54321 comment "x-ui panel - моб жена"
ufw allow from 37.48.9.111   to any port 54321 comment "x-ui panel - моб VladiMIR"
ufw allow from 185.100.197.16 to any port 54321 comment "x-ui panel - home"
ufw allow from 90.181.133.10  to any port 54321 comment "x-ui panel - work"
```

---

## Итоговое состояние iptables INPUT (STOLB-24)

```
num  target   prot  source       destination
1    ACCEPT   tcp   0.0.0.0/0    0.0.0.0/0    dpt:8443  /* XRAY VPN bypass CrowdSec */
2    ACCEPT   tcp   0.0.0.0/0    0.0.0.0/0    dpt:853   /* DoT bypass CrowdSec */
3    ACCEPT   udp   0.0.0.0/0    0.0.0.0/0    dpt:853   /* DoT bypass CrowdSec */
4    ACCEPT   udp   0.0.0.0/0    0.0.0.0/0    dpt:53    /* DNS bypass CrowdSec */
5    ACCEPT   tcp   0.0.0.0/0    0.0.0.0/0    dpt:53    /* DNS bypass CrowdSec */
6    CROWDSEC_CHAIN all ...
```

---

## Whitelist обновления

Добавлены IP в `109/my_whitelist.yaml`:
- `37.48.9.111` — VladiMIR мобильный
- `89.24.41.133` — жена мобильный #1
- `83.217.9.81`  — жена мобильный #2 / клиент

---

## Главный вывод

**Android Private DNS** использует DNS-over-TLS (порт 853), а не обычный DNS (порт 53).
Поэтому на сервере с AdGuard Home нужно открывать **оба** порта: 53 и 853.

**CrowdSec банит IP целиком** — не по портам. Поэтому единственное правильное решение — добавить ACCEPT правила в iptables **ДО** CROWDSEC_CHAIN.

**Мобильные IP динамические** — не добавлять в whitelist. Правильное решение — открыть порты для всех через iptables bypass.

---

## Чеклист восстановления на новом сервере с AdGuard Home

```bash
# 1. UFW
ufw allow 53/udp comment "DNS - AdGuard Home"
ufw allow 53/tcp comment "DNS - AdGuard Home"
ufw allow 853/tcp comment "DNS-over-TLS"
ufw allow 853/udp comment "DNS-over-TLS"
ufw allow 8443/tcp comment "XRAY VPN"

# 2. iptables bypass
iptables  -I INPUT 1 -p tcp --dport 8443 -j ACCEPT -m comment --comment "XRAY VPN bypass CrowdSec"
iptables  -I INPUT 2 -p tcp --dport 853  -j ACCEPT -m comment --comment "DoT bypass CrowdSec"
iptables  -I INPUT 3 -p udp --dport 853  -j ACCEPT -m comment --comment "DoT bypass CrowdSec"
iptables  -I INPUT 4 -p udp --dport 53   -j ACCEPT -m comment --comment "DNS bypass CrowdSec"
iptables  -I INPUT 5 -p tcp --dport 53   -j ACCEPT -m comment --comment "DNS bypass CrowdSec"
ip6tables -I INPUT 1 -p tcp --dport 8443 -j ACCEPT -m comment --comment "XRAY VPN bypass CrowdSec"
ip6tables -I INPUT 2 -p tcp --dport 853  -j ACCEPT -m comment --comment "DoT bypass CrowdSec"
ip6tables -I INPUT 3 -p udp --dport 853  -j ACCEPT -m comment --comment "DoT bypass CrowdSec"
ip6tables -I INPUT 4 -p udp --dport 53   -j ACCEPT -m comment --comment "DNS bypass CrowdSec"
ip6tables -I INPUT 5 -p tcp --dport 53   -j ACCEPT -m comment --comment "DNS bypass CrowdSec"

# 3. Сохранить
aptinstall -y iptables-persistent
iptables-save  > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6
```
