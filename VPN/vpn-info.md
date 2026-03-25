# VPN Nodes — AmneziaWG Cluster
# = Rooted by VladiMIR | AI =
# v2026-03-25

## Карта кластера — 8 нод AmneziaWG

| # | Имя ноды   | IP               | Назначение / Роль                        | Сервисы                                    | Nginx |
|---|------------|------------------|------------------------------------------|--------------------------------------------|-------|
| 1 | ALEX_47    | xxx.xxx.xxx.47    | VPN нода + файловый доступ               | AmneziaWG, Samba                           | ❌ удалён |
| 2 | 4TON_237   | xxx.xxx.xxx.237  | VPN нода + метрики                       | AmneziaWG, Samba, Prometheus               | ❌ удалён |
| 3 | TATRA_9    | xxx.xxx.xxx.9    | VPN нода + **мониторинг всего кластера** | AmneziaWG, Samba, Kuma Monitoring          | ❌ удалён |
| 4 | SHAHIN_227 | xxx.xxx.xxx.227  | VPN нода + файловый доступ               | AmneziaWG, Samba                           | ❌ удалён |
| 5 | STOLB_24   | xxx.xxx.xxx.24   | VPN нода + **DNS фильтрация**            | AmneziaWG, Samba, AdGuard Home             | ❌ удалён |
| 6 | PILIK_178  | xxx.xxx.xxx.178    | VPN нода + файловый доступ               | AmneziaWG, Samba                           | ❌ удалён |
| 7 | ILYA_176   | xxx.xxx.xxx.176  | VPN нода + файловый доступ               | AmneziaWG, Samba                           | ❌ удалён |
| 8 | SO_38      | xxx.xxx.xxx.38   | VPN нода + файловый доступ               | AmneziaWG, Samba                           | ❌ удалён |

> **Nginx на VPN нодах НЕ нужен** — сайтов нет. Удалён со всех нод 25.03.2026.

---

## SSH доступ

- Логин: `root`
- Пароль: **индивидуальный на каждой ноде** (хранить отдельно!)
- SSH порт: `22`

---

## Быстрый запуск скрипта на любой ноде

Зайди по SSH на нужный сервер и запусти одну команду:

```bash
bash <(curl -s https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/VPN/fix_node.sh)
```

Скрипт сделает:
1. Починит dpkg если прерван
2. Починит broken пакеты
3. Удалит nginx
4. Почистит мусор

---

## Web UI панели

| Сервис | Нода | URL |
|--------|------|-----|
| Kuma Monitoring | TATRA_9 | http://xxx.xxx.xxx.9:3001 |
| AdGuard Home | STOLB_24 | http://xxx.xxx.xxx.24:3000 |
| Prometheus | 4TON_237 | http://xxx.xxx.xxx.237:9090 |

---

## MOTD шапка (при входе на каждый сервер)

Каждый сервер показывает свою шапку через `/etc/motd` или `/root/infooo.sh`:

```
╔══════════════════════════════════════════╗
║  🖥  VPN-EU-XXXXXX  (X.X.X.X)          ║
║  AmneziaWG  |  Samba  |  [доп сервис]   ║
║  = Rooted by VladiMIR | AI =            ║
╚══════════════════════════════════════════╝
```

---

## Если dpkg прерван

```
E: dpkg was interrupted, you must manually run 'dpkg --configure -a'
```

Запусти локально на сервере:
```bash
dpkg --configure -a && apt install -f -y
```

---

## CHANGELOG

| Дата       | Время | Что произошло / Что сделано |
|------------|-------|-----------------------------|
| 2026-03-25 | 00:35 | 🔴 nginx упал на всех 8 нодах одновременно — бот слал алерты в Telegram |
| 2026-03-25 | 00:35 | Выяснено: nginx не нужен на VPN нодах (нет сайтов) |
| 2026-03-25 | 01:00 | Попытка массового удаления через sshpass — не удалась (пароли разные на каждой ноде) |
| 2026-03-25 | 01:08 | ✅ Залит скрипт fix_node.sh в репозиторий |
| 2026-03-25 | 01:10 | ✅ 4TON_237 — nginx удалён, dpkg починен |
| 2026-03-25 | 01:10 | ⏳ Остальные 7 нод — нужно зайти и запустить fix_node.sh |
| 2026-03-25 | 01:05 | ⚠️ RAM 88% на 222-DE-NetCup (xxx.xxx.xxx.222) — требует внимания |
