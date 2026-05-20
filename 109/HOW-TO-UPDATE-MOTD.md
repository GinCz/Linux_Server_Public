# Как устроен запуск оболочки на сервере 109

> Server: 109-RU-FastVDS | IP: 212.109.223.109 | Ubuntu 24 / FASTPANEL
> = Rooted by VladiMIR + AI | v.2026.05.21 | github.com/GinCz =

---

## Архитектура — цепочка загрузки

```
SSH LOGIN
  └─► ~/.bash_profile
        ├─ [1] MOTD_SHOWN=? → если пусто → показать баннер ОДИН РАЗ
        │        └─ bash /etc/profile.d/motd_server.sh
        │                 └─ вызывает _motd_109() из server_109.sh
        └─ [2] source server_109.sh → загружает алиасы (_aliases_109)

bash / screen / su (не login-shell)
  └─► ~/.bashrc
        └─ source server_109.sh → загружает алиасы (_aliases_109)
             (MOTD_SHOWN уже = 1 → баннер не дублируется)
```

**Правило:** MOTD показывается ровно один раз — через флаг `MOTD_SHOWN`.

---

## Файлы и их роли

| Файл | Где живёт | Роль |
|------|-----------|------|
| `.bash_profile` | `/root/` | Login-shell: MOTD + алиасы |
| `.bashrc` | `/root/` | Non-login-shell: только алиасы |
| `server_109.sh` | `/root/Linux_Server_Public/109/` | Главный файл: MOTD + алиасы + MC меню |
| `motd_server.sh` | `/etc/profile.d/` | Копия server_109.sh, установленная через --install |
| `shared_aliases.sh` | `/root/Linux_Server_Public/scripts/` | Общие алиасы (save, aw, grep, ls, mc) |

---

## Почему НЕТ дубликатов

1. **MOTD:** флаг `MOTD_SHOWN` — экспортируется при первом показе. При каждом следующем вызове `.bashrc` или `source server_109.sh` флаг уже установлен → баннер не показывается.
2. **Алиасы:** `server_109.sh` при sourcing всегда вызывает только `_aliases_109()`. Функция `_motd_109()` вызывается ТОЛЬКО из `motd_server.sh` (который стоит в `/etc/profile.d/`).
3. **MC меню:** устанавливается один раз командой `load` или `bash server_109.sh --install`. Само меню НЕ вызывает nano и НЕ запрашивает редактор — оно пишется через `cat > file << 'HEREDOC'`.

---

## Как работает `server_109.sh` — три блока

```bash
# ENTRY POINT логика:
if [[ "${1}" == "--install" ]]; then
    # Копирует себя в /etc/profile.d/motd_server.sh
    # Устанавливает MC меню
elif [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Запущен через source → загружает только алиасы
    _aliases_109
else
    # Запущен напрямую bash server_109.sh → показывает MOTD
    _motd_109
fi
```

---

## MC меню — как устроено

Файл меню: `/root/.config/mc/menu`

- Открывается клавишей **F2** в Midnight Commander
- Каждый пункт — отдельный скрипт с `clear` + `read -n 1` в конце
- MC меню НЕ вызывает редактор автоматически — оно просто запускает команды
- Установка: `bash /root/Linux_Server_Public/109/server_109.sh --install` или алиас `load`

### Правило отсутствия дубликатов в MC меню

MC меню устанавливается через `_install_mc_menu_109()` используя `heredoc`:
```bash
cat > "$MC_MENU" << 'MCMENU'
...содержимое...
MCMENU
```
Это перезаписывает файл целиком — дублей быть не может.

---

## Команды для применения

### Первичная установка (один раз):
```bash
cp /root/Linux_Server_Public/109/.bash_profile /root/.bash_profile
cp /root/Linux_Server_Public/109/.bashrc /root/.bashrc
bash /root/Linux_Server_Public/109/server_109.sh --install
source /root/.bash_profile
```

### После git pull (обновление):
```bash
load
# или вручную:
cd /root/Linux_Server_Public && git pull --rebase
bash /root/Linux_Server_Public/109/server_109.sh --install
source /root/Linux_Server_Public/109/server_109.sh
```

### Проверить что нет дубликатов:
```bash
grep -r 'motd\|MOTD\|_motd' /etc/profile.d/ ~/.bash_profile ~/.bashrc 2>/dev/null
# Должен быть только /etc/profile.d/motd_server.sh и строка в .bash_profile с флагом MOTD_SHOWN
```

### Проверить shared_aliases.sh существует:
```bash
ls -la /root/Linux_Server_Public/scripts/shared_aliases.sh
```

---

## Частые ошибки

| Симптом | Причина | Решение |
|---------|---------|--------|
| MOTD показывается 2 раза | В `.bashrc` есть вызов баннера | Убрать из `.bashrc` всё кроме `source server_109.sh` |
| `shared_aliases.sh: No such file` | Файл не скопирован в `/scripts/` | `cp /root/Linux_Server_Public/222/shared_aliases.sh /root/Linux_Server_Public/scripts/` |
| Открывается nano после login | В `/etc/profile.d/` есть лишний файл с `nano` | `grep -r nano /etc/profile.d/` |
| MC меню загружается 2 раза | `_install_mc_menu_109()` вызвана дважды | `load` перезаписывает файл — повторный вызов безопасен |
