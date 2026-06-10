# MOTD — Эмодзи и SSH Баннер: Полное Руководство

> **Этот файл создан специально чтобы НЕ тратить 2 часа в следующий раз.**  
> Здесь всё: почему сломалось, как починить, какой код работает.

---

## ⚡ БЫСТРЫЙ ОТВЕТ (если всё уже сломалось)

### Убрать «Using username» и «Last login» при входе по SSH

```bash
sed -i 's/^#\?PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config
sed -i 's/^#\?PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config
systemctl reload ssh
```

### Значки для MOTD (уже проверены, работают в терминале)

```bash
# TYPE 1 — VPN серверы (4Ton и другие)
echo -e "  \U0001F511  Имя_сервера"   # 🔑

# TYPE 2 — Сервер 222-DE-NetCup (152.53.182.222)
echo -e "  \U0001F310  Имя_сервера"   # 🌐

# TYPE 3 — Сервер 109 (212.109.223.109)
echo -e "  \U0001F310  Имя_сервера"   # 🌐
```

---

## ПРОБЛЕМА 1 — SSH баннер при входе

### Симптом

При подключении по SSH (PuTTY, MobaXterm, любой клиент) **перед** нашим красивым MOTD появляются лишние строки:

```
Using username "root".
Last login: Wed Jun 10 00:21:50 2026 from 185.100.197.16
```

### Откуда это берётся

| Строка | Источник | Управляется |
|---|---|---|
| `Using username "root".` | SSH-**клиент** (PuTTY/MobaXterm) — не сервер | Настройки клиента, нельзя убрать со стороны сервера |
| `Last login: ...` | SSH-**сервер**, параметр `PrintLastLog` | `/etc/ssh/sshd_config` → `PrintLastLog no` |
| Системный `/etc/motd` | PAM-модуль `pam_motd` | `/etc/ssh/sshd_config` → `PrintMotd no` |

> **Важно:** Строка `Using username` приходит от клиента (PuTTY показывает её сам).  
> Убрать её можно только в настройках клиента. Со стороны сервера — не убирается.

### Решение

```bash
# На любом сервере (222, 109, VPN — все одинаково):
sed -i 's/^#\?PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config
grep -q '^PrintLastLog' /etc/ssh/sshd_config || echo 'PrintLastLog no' >> /etc/ssh/sshd_config

sed -i 's/^#\?PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config
grep -q '^PrintMotd' /etc/ssh/sshd_config || echo 'PrintMotd no' >> /etc/ssh/sshd_config

systemctl reload ssh
# Или если reload не работает:
systemctl reload sshd
```

### Проверка

```bash
grep -E 'PrintLastLog|PrintMotd' /etc/ssh/sshd_config
# Должно быть:
# PrintLastLog no
# PrintMotd no
```

После этого **переподключись** — строки исчезнут.

### В скрипте new_server_install.sh

Этот блок уже добавлен в **STEP 1** скрипта — при установке нового сервера всё применяется автоматически.

---

## ПРОБЛЕМА 2 — Эмодзи ломает выравнивание строки в терминале

### Симптом

Значок занимает в терминале **полторы ячейки** вместо двух (или вместо одной), из-за чего вся строка MOTD съезжает:

```
# Сломано — 🖥 рисуется не как полный wide-символ:
  🖥  222-DE-NetCup  152.53.182.222  ...
     ^^^--- пробел съехал, строка неровная
```

### Почему это происходит

Не все эмодзи одинаковые. В Unicode есть два типа:

| Тип | Диапазон | Ширина в терминале | Примеры |
|---|---|---|---|
| **Miscellaneous Symbols** | U+2600–U+26FF, U+2700–U+27BF | **1.5 ячейки** — ПРОБЛЕМНЫЙ | `🖥` (U+1F5A5), `⚡`, `☁` |
| **Emoji block** (полные эмодзи) | U+1F300–U+1FFFF | **2 ячейки** — работает корректно | `🔑` (U+1F511), `🌐` (U+1F310) |

Терминалы (PuTTY, MobaXterm, iTerm2, Windows Terminal) трактуют ширину символа **по-разному**.  
Символы из «Miscellaneous Symbols» и «Transport Symbols» особенно непредсказуемы.

### Какие значки использовать

**Проверенные — работают везде:**

| Эмодзи | Unicode | Hex escape для bash | Использование |
|---|---|---|---|
| 🔑 | U+1F511 | `\U0001F511` | VPN серверы (TYPE 1) |
| 🌐 | U+1F310 | `\U0001F310` | Web серверы 222 и 109 (TYPE 2, 3) |

**Проблемные — НЕ использовать:**

| Эмодзи | Unicode | Проблема |
|---|---|---|
| 🖥 | U+1F5A5 | Рендерится как 1.5 символа — ломает выравнивание |
| 💻 | U+1F4BB | Нестабилен в разных терминалах |
| 🖨 | U+1F5A8 | Аналогичная проблема |

### Как правильно вставлять эмодзи в bash-скрипт

**ПРАВИЛЬНО — через Unicode escape:**
```bash
echo -e "  \U0001F511  ${W}${HN}${X}  ..."
echo -e "  \U0001F310  ${W}${HN}${X}  ..."
```

**НЕПРАВИЛЬНО — вставка символа напрямую:**
```bash
echo "  🔑  ${HN}  ..."    # Может сломаться при:
                             # - передаче через curl
                             # - heredoc с неправильной кодировкой
                             # - locale не UTF-8 на сервере
```

**Почему `\U0001F511` лучше прямой вставки:**
- Работает независимо от локали сервера (`LANG=C`, `LANG=en_US.UTF-8` — не важно)
- Не ломается при `curl | bash` или `bash <(...)`
- Не зависит от того, как редактор сохранил файл
- `echo -e` с `\U` — это bash built-in, работает в bash 4.0+

---

## ПРОБЛЕМА 3 — Значок отсутствует в TYPE 2 / TYPE 3

### Симптом

После изменений в скрипте на VPN-сервере значок появился, а на 222 и 109 — нет:
```
# VPN (TYPE 1) — ОК:
  🔑  4Ton-237  144.124.228.237  ...

# Web (TYPE 2) — сломано:
  222-DE-NetCup  152.53.182.222  ...   ← нет значка
```

### Причина

В скрипте три независимых блока (`TYPE_1`, `TYPE_2`, `TYPE_3`). Изменение в одном блоке **не применяется автоматически** к другим.

### Решение

Всегда при изменении MOTD проверяй **все три блока** в `new_server_install.sh`:  
- `# === TYPE 1 — VPN ===`  
- `# === TYPE 2 — Web 222/CF ===`  
- `# === TYPE 3 — Web 109 ===`  

Каждый блок содержит свою строку заголовка MOTD. Менять нужно во всех трёх.

---

## КОД — Как это реализовано в скрипте

### Файл: `scripts/new_server_install.sh`

#### STEP 1 — SSH баннер (применяется для всех типов)

```bash
# === SSH: hide "Last login" and system motd ===
SEEKED_SSHD=/etc/ssh/sshd_config
if [ -f "$SEEKED_SSHD" ]; then
  sed -i 's/^#\?PrintLastLog.*/PrintLastLog no/'  "$SEEKED_SSHD"
  grep -q '^PrintLastLog' "$SEEKED_SSHD" || echo 'PrintLastLog no' >> "$SEEKED_SSHD"
  sed -i 's/^#\?PrintMotd.*/PrintMotd no/'        "$SEEKED_SSHD"
  grep -q '^PrintMotd'     "$SEEKED_SSHD" || echo 'PrintMotd no'     >> "$SEEKED_SSHD"
  systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true
fi
```

#### MOTD — строка заголовка для каждого типа

```bash
# TYPE 1 — VPN (4Ton и другие VPN серверы)
echo -e "  \U0001F511  ${W}${HN}${X}  ${Y}${IP}${X}  RAM:${W}${RAM_USED}/${RAM_TOTAL}MB${X}  CPU:${W}${CPU}%${X}  up ${W}${UPTIME}${X}"

# TYPE 2 — 222-DE-NetCup (FastPanel + Cloudflare)
echo -e "  \U0001F310  ${W}${HN}${X}  ${Y}${IP}${X}  RAM:${W}${RAM_USED}/${RAM_TOTAL}MB${X}  CPU:${W}${CPU}%${X}  up ${W}${UPTIME}${X}"

# TYPE 3 — 109 (212.109.223.109)
echo -e "  \U0001F310  ${W}${HN}${X}  ${Y}${IP}${X}  RAM:${W}${RAM_USED}/${RAM_TOTAL}MB${X}  CPU:${W}${CPU}%${X}  up ${W}${UPTIME}${X}"
```

#### Строка Type + CrowdSec (одна строка вместо двух)

```bash
# Переменная с кратким типом сервера
MOTD_TYPE_SHORT="VPN"        # для TYPE 1
MOTD_TYPE_SHORT="Web-222/CF" # для TYPE 2
MOTD_TYPE_SHORT="Web-109"    # для TYPE 3

# Одна строка вместо двух:
CS_LINE="  ${Y}Type:${X} ${MOTD_TYPE_SHORT}   ${Y}CrowdSec:${X} ${G}● ACTIVE${X} | bans: ${W}${BAN_COUNT}${X}"
```

---

## СЕРВЕРЫ — Применение на 222 и 109

### Сервер 222-DE-NetCup (152.53.182.222) — TYPE 2

```bash
# Полная переустановка MOTD:
cd /root/Linux_Server_Public
git pull
bash scripts/new_server_install.sh
# Выбрать: 2 (Web 222/CF)

# Только SSH баннер (без переустановки):
sed -i 's/^#\?PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config
sed -i 's/^#\?PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config
systemctl reload ssh
```

### Сервер 109 (212.109.223.109) — TYPE 3

```bash
# Полная переустановка MOTD:
cd /root/Linux_Server_Public
git pull
bash scripts/new_server_install.sh
# Выбрать: 3 (Web 109)

# Только SSH баннер:
sed -i 's/^#\?PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config
sed -i 's/^#\?PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config
systemctl reload ssh
```

---

## ПРОВЕРКА — Итоговый результат

### Как должен выглядеть вход на сервер 222

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🌐  222-DE-NetCup  152.53.182.222  RAM:4544/7935MB  CPU:8%  up 20 hours, 1 minute
  Xray: 1 enabled / 1 total    CrowdSec Engine: ● ACTIVE  Firewall: ● ACTIVE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ...
```

**НЕТ** строк `Using username` / `Last login` перед MOTD.

### Как должен выглядеть вход на VPN сервер

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔑  4Ton-237  144.124.228.237  RAM:444/961MB  CPU:9%  up 5 hours, 57 minutes
  Type: VPN   CrowdSec: ● ACTIVE | bans: 4
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## ИСТОРИЯ ПРОБЛЕМ (2026-06-10)

| Версия | Проблема | Решение |
|---|---|---|
| до v2026.06.10b | `Last login` при входе | `PrintLastLog no` в sshd_config |
| до v2026.06.10b | Type + CrowdSec = 2 строки | Объединены в одну `CS_LINE` |
| v2026.06.10m | `🖥` (U+1F5A5) ломал строку | Заменён на `\U0001F511` / `\U0001F310` |
| v2026.06.10m | Значок отсутствовал в TYPE 2/3 | Добавлен в все три блока |
| v2026.06.10m | Uptime отсутствовал в TYPE 2/3 | Переменная `UPTIME` добавлена везде |
| **v2026.06.10n** | **ФИНАЛЬНЫЙ — всё работает** | — |

---

> _= Rooted by VladiMIR + AI | github.com/GinCz/Linux_Server_Public =_
