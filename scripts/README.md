# scripts/ — Samba Management Scripts

> = Rooted by VladiMIR + AI | v2026.06.15c | github.com/GinCz =

---

## samba_setup.sh

**Текущая версия:** `v2026.06.15c`  
**Запуск:** от имени root  
**Идемпотентность:** да — безопасно запускать несколько раз на одном сервере

```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/samba_setup.sh)
```

### Что делает скрипт (шаги)

1. **Установка Samba** — `samba` + `samba-common-bin` + `python3` через apt (если ещё не установлен)
2. **Папки** — создаёт `/storage`, `/storage/soft`, `/storage/user`
3. **Миграция** — автоматически переносит файлы из `/storage/soft/user` → `/storage/user` (если старая структура ещё существует)
4. **Пользователи** — создаёт `vlad` и `usr` (no shell, no home); `usr` добавляется в группу `vlad`
5. **Права на папки** — `vlad:vlad` owner, `2770` (setgid) на `soft` и `user`, `0770` на `/storage`
6. **Пароли Samba** — запрашивает для `vlad` и `usr` (можно пропустить Enter если уже установлен)
7. **smb.conf** — записывается целиком с `[storage]` + `[soft]` + `[user]`; валидация через `testparm`; при ошибке восстанавливается backup
8. **UFW** — открывает порты 445 и 139 с rate-limit 6 подключений за 30 секунд
9. **IPGuard** — запускает `blacklist/install-ipguard.sh` — полная трёхуровневая защита

### Структура шар

```
/storage/
├── soft/          ← [soft]     vlad RW, usr RO
└── user/          ← [user]     vlad RW, usr RW
         ^-- [storage] — browse-only root (показывает soft\ и user\ в Windows)
```

### Матрица прав

| Путь           | Linux путь        | vlad        | usr         | Примечание                     |
|----------------|-------------------|-------------|-------------|-----------------------------------|
| `\\IP\storage` | `/storage`        | browse only | browse only | Корень, видны soft\ и user\   |
| `\\IP\soft`    | `/storage/soft`   | Read+Write  | Read only   | Файлы/софт                      |
| `\\IP\user`    | `/storage/user`   | Read+Write  | Read+Write  | Общая папка                    |

### Права на Linux-уровне

| Папка             | owner     | group | chmod | Причина                                    |
|-------------------|-----------|-------|-------|--------------------------------------------|
| `/storage`        | vlad:vlad | vlad  | 0770  | Корень, нельзя создавать файлы напрямую |
| `/storage/soft`   | vlad:vlad | vlad  | 2770  | setgid: новые файлы наследуют группу |
| `/storage/user`   | vlad:vlad | vlad  | 2770  | setgid: usr может писать (в группе vlad) |

> `usr` включён в группу `vlad` — это даёт ему запись в `/storage/user` на уровне Linux.
> Доступ к `/storage/soft` для `usr` ограничен на чтение через `write list = vlad` в smb.conf.

### smb.conf (ключевые параметры [global])

| Параметр                | Значение     | Назначение                                      |
|-----------------------------|-------------|--------------------------------------------------|
| `server min protocol`       | SMB2        | Запрещает SMB1 (CVE-2017-0144, EternalBlue)    |
| `ntlm auth`                 | yes         | Требуется для совместимости с Windows    |
| `map to guest`              | never       | Без анонимного/гостевого доступа          |
| `max smbd processes`        | 100         | Защита от connection flood                     |
| `log level`                 | 2           | Нужен Fail2Ban для детекции ошибок аутентификации |
| `invalid users`             | root bin... | Блокирует системных пользователей         |

### Changelog

| Версия        | Дата       | Изменения |
|---------------|------------|-----------|
| v2026.06.15c  | 2026-06-15 | Новая структура: `[storage]`+`[soft]`+`[user]`; `/storage/soft` и `/storage/user` раздельные; автомиграция; smb.conf переписывается целиком |
| v2026.06.14b  | 2026-06-14 | Старая структура: `[soft]`+`[user]`; `/storage/soft/user` внутри `soft` |

---

## samba_audit_all.sh

**Аудит и авто-фикс Samba на всех серверах через SSH.**

```bash
bash /root/Linux_Server_Public/scripts/samba_audit_all.sh
```

19 проверок на каждом сервере. Большинство проблем фиксируются автоматически.

---

## remove_samba.sh

**Полное удаление Samba и закрытие SMB-портов.**

```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/remove_samba.sh)
```

`/storage` и данные не удаляются.

---

*= Rooted by VladiMIR + AI | v2026.06.15c | github.com/GinCz =*
