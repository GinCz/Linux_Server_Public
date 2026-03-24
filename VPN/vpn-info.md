# VPN Nodes — AmneziaWG Cluster
# = Rooted by VladiMIR | AI =
# v2026-03-25

## Список VPN серверов (8 нод)

| Имя ноды       | IP               | Сервисы                              |
|----------------|------------------|--------------------------------------|
| ALEX_47        | xxx.xxx.xxx.47    | AmneziaWG + Samba                    |
| 4TON_237       | xxx.xxx.xxx.237  | AmneziaWG + Samba + Prometheus       |
| TATRA_9        | xxx.xxx.xxx.9    | AmneziaWG + Samba + Kuma Monitoring  |
| SHAHIN_227     | xxx.xxx.xxx.227  | AmneziaWG + Samba                    |
| STOLB_24       | xxx.xxx.xxx.24   | AmneziaWG + Samba + AdGuard Home     |
| PILIK_178      | xxx.xxx.xxx.178    | AmneziaWG + Samba                    |
| ILYA_176       | xxx.xxx.xxx.176  | AmneziaWG + Samba                    |
| SO_38          | xxx.xxx.xxx.38   | AmneziaWG + Samba                    |

---

## SSH доступ

- Логин: `root`
- Пароль: `sa4434` (стандарт для всех VPN нод)
- SSH порт: `22`

---

## MOTD шапка при входе (разная для каждого сервера)

Каждый сервер показывает при входе свою шапку через `/etc/motd` или скрипт `/root/infooo.sh`:

```
╔══════════════════════════════════════════╗
║  🖥  VPN-EU-XXXXXX (X.X.X.X)           ║
║  AmneziaWG  |  Samba  |  [доп сервис]   ║
║  = Rooted by VladiMIR | AI =            ║
╚══════════════════════════════════════════╝
```

Файл `/etc/motd` редактируется на каждой ноде индивидуально с указанием имени и IP.

---

## Nginx на VPN нодах

**Nginx НЕ нужен** на VPN нодах — там нет сайтов.
На нодах работает только: AmneziaWG, Samba, и на некоторых Prometheus / Kuma / AdGuard.

### Удаление nginx со всех нод (запускать с любой ноды)

```bash
apt install sshpass -y

for IP in xxx.xxx.xxx.47 xxx.xxx.xxx.237 xxx.xxx.xxx.9 xxx.xxx.xxx.227 xxx.xxx.xxx.24 xxx.xxx.xxx.178 xxx.xxx.xxx.176 xxx.xxx.xxx.38; do
    echo "--- $IP ---"
    sshpass -p 'sa4434' ssh -o StrictHostKeyChecking=no root@$IP \
    "apt remove --purge nginx nginx-common nginx-full -y > /dev/null 2>&1 && apt autoremove -y > /dev/null 2>&1 && echo 'DONE: '\$(hostname)"
done
```

> ⚠️ После удаления nginx — зайти в **Kuma на TATRA_9** и удалить мониторы nginx для всех VPN нод.

---

## Если dpkg прерван (ошибка при apt)

Если видишь:
```
E: dpkg was interrupted, you must manually run 'dpkg --configure -a'
```

Запусти:
```bash
dpkg --configure -a && apt install -f -y
```

Потом повтори нужную команду.

---

## CHANGELOG

| Дата       | Что сделано |
|------------|-------------|
| 2026-03-25 | Ночью в 00:35 упал nginx на всех 8 нодах одновременно (был лишний — не нужен на VPN) |
| 2026-03-25 | Принято решение удалить nginx со всех VPN нод |
| 2026-03-25 | Добавлен скрипт массового удаления через sshpass |
| 2026-03-25 | Обновлена документация по VPN нодам |
