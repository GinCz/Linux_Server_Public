# DEVLOG — Журнал разработки

## Сессия 2026-06-10 (VladiMIR + AI)

> Работа велась совместно: VladiMIR Bulantsev (GinCz) + Perplexity AI  
> Репозиторий: https://github.com/GinCz/Linux_Server_Public  
> Затронутые файлы: `scripts/new_server_install.sh`, `scripts/upd.sh`, `scripts/night_update.sh`, `scripts/motd_vpn.sh`, `scripts/motd_222.sh`, `scripts/motd_109.sh`

---

### 1. `upd.sh` — рефакторинг + ночное автообновление

**Проблема:** скрипт `upd` (алиас для `apt upgrade`) запускал обновление напрямую, без контроля — без логов, без проверки сервисов после перезагрузки.

**Что сделали:**

- Добавили **меню при запуске**: `1) Run now` / `2) Install scheduler`
- Режим `Install scheduler`:
  - разворачивает `night_update.sh` в `/usr/local/bin/`
  - устанавливает cron: обновление в **3:00 ночи**, плюс `@reboot`-хук
  - после установки выводит читаемую сводку расписания
- Задержка перед reboot изменена с `sleep 3` → `sleep 30` (чтобы успеть прочитать вывод)

**Коммиты:**
- [`71932cd`](https://github.com/GinCz/Linux_Server_Public/commit/71932cdf4e8e4390d002f9443a46bdf8293f4c4b) — full logic rework — run vs install menu
- [`e5b9bf5`](https://github.com/GinCz/Linux_Server_Public/commit/e5b9bf5b115a8957d9ab47ce4cedf69c7bf4ba18) — deploy night_update.sh + @reboot cron in install mode
- [`7bbff97`](https://github.com/GinCz/Linux_Server_Public/commit/7bbff97bf4c73c0c8372839638c3f288ba347331) — show readable crontab summary after install
- [`5ced82e`](https://github.com/GinCz/Linux_Server_Public/commit/5ced82eea591c9a4680fe4ed021608f2525de31f) — sleep 3→30 before reboot

---

### 2. `night_update.sh` — новый скрипт ночного обновления

**Что делает:**
- Запускается автоматически в 3:00 по cron
- Выполняет `apt update && apt upgrade -y && autoremove`
- Пишет лог в `/var/log/night_update.log`
- Проверяет, нужна ли перезагрузка (`/var/run/reboot-required`)
- Если нужна — делает reboot
- После `@reboot` ждёт 90 секунд и запускает `sos 1h` — аудит после перезагрузки
- Проверяет упавшие сервисы (`systemctl --failed`), фильтрует строки с символом `●`

**Коммиты:**
- [`d31c89a`](https://github.com/GinCz/Linux_Server_Public/commit/d31c89ad58227e32422b7eecd817fd04e3ae04bb) — add to repo, fix sleep 30→90 in post-reboot audit
- [`5ced82e`](https://github.com/GinCz/Linux_Server_Public/commit/5ced82eea591c9a4680fe4ed021608f2525de31f) — fix systemctl failed units parsing (skip ● bullet)

---

### 3. MOTD — объединение строк Type + CrowdSec в одну

**Проблема:** MOTD VPN-сервера показывал две отдельные строки:
```
  Type: VPN / XRay / AmneziaWG / AdGuard / Semaphore
  CrowdSec: ● ACTIVE | bans: 4
```
Это занимало лишнее место и было избыточно.

**Решение:** объединены в одну строку `CS_LINE`:
```
  Type: VPN   CrowdSec: ● ACTIVE | bans: 4
```

Для серверов 222 и 109 аналогично: строки Xray + CrowdSec Engine + Firewall объединены в `CS_LINE`.

**Коммиты:**
- [`c8a971c`](https://github.com/GinCz/Linux_Server_Public/commit/c8a971c4c3971d14e996ea6a5a35f837c6f734ba) — motd_vpn.sh: объединить AWG/Type и CrowdSec в одну строку
- [`bad2f9d`](https://github.com/GinCz/Linux_Server_Public/commit/bad2f9d3fc69bc187b22c0a6c8df477fe696d760) — MOTD types 2&3: merge Xray+CrowdSec into single CS_LINE

---

### 4. MOTD — отдельные cheatsheet для 222 и 109

**Проблема:** серверы 222 (Cloudflare) и 109 (без Cloudflare) показывали одинаковый cheatsheet, хотя наборы алиасов у них разные. Присутствовали тестовые алиасы `aws-test`.

**Решение:** разделены cheatsheet в MOTD — каждый тип показывает только свои команды. Убраны `aws-test` из всех типов.

**Коммит:**
- [`d7dbe52`](https://github.com/GinCz/Linux_Server_Public/commit/d7dbe520a77f2b160b3e23488bcdcaea7b3b328f) — separate MOTD cheatsheets for 222/109, remove aws-test everywhere

---

### 5. MOTD — иконка 🖥 заменена на `[S]` ASCII

**Проблема:** emoji `🖥` (U+1F5A5, компьютер) рендерится как двойная ширина в большинстве SSH-терминалов, что ломало выравнивание `printf`. Попытки компенсировать через лишние пробелы и `echo -n` не дали стабильного результата.

**Решение:** заменили на ASCII-строку `[S]` во всех трёх типах MOTD — ширина всегда предсказуема.

**Коммиты (итерации):**
- [`dcb96df`](https://github.com/GinCz/Linux_Server_Public/commit/dcb96dff85697c45c64ddcc1421e37eb0714b938) — replace broken lock emoji with computer icon (U+1F5A5)
- [`96e759e`](https://github.com/GinCz/Linux_Server_Public/commit/96e759ede814346240627dc16e30ad2fb4db2307) — add extra space after emoji
- [`8dc26b2`](https://github.com/GinCz/Linux_Server_Public/commit/8dc26b275fe29314b9e0c9cb70e8a52039490614) — print emoji separately via echo -n
- [`e140ba8`](https://github.com/GinCz/Linux_Server_Public/commit/e140ba87e84fdef37d08097e8b688a3f55b9acff) — emoji inside printf like VPN/motd_server.sh
- [`737dce7`](https://github.com/GinCz/Linux_Server_Public/commit/737dce759ab2964795b006a6cc4468be69dcc7fe) — globe for 222/109, key for VPN
- [`345cc99`](https://github.com/GinCz/Linux_Server_Public/commit/345cc99685ac117754028daac36950443728c608) — **финальный фикс: replace 🖥 with [S] ASCII in all MOTD types**

---

### 6. `sos` — новая секция OPEN PORTS (секция 27)

**Проблема:** раздел открытых портов в `sos` давал 20+ дублирующих строк для `named:53` — по одной на каждый IPv6-адрес интерфейса.

**Что сделали:**
- Дедупликация по паре `port+procname` через `awk match()` с правильным парсингом формата `users:(("name",pid=N,fd=N))`
- Адреса показываются в cyan, имя процесса в green с кавычками
- Сортировка по номеру порта
- IPv6-адреса группируются (не дублируются)
- Добавлена таблица Key Ports: 22, 25, 53, 80, 443, 445, 3000, 8080, 51820
- Отдельный `ports.sh` удалён — логика перенесена внутрь `sos`

**Коммиты:**
- [`7ef799a`](https://github.com/GinCz/Linux_Server_Public/commit/7ef799a4fb28d1f233a86fde1ec7ef52b0cf2afd) — add full ports section (dedup, key ports table)
- [`911c0f7`](https://github.com/GinCz/Linux_Server_Public/commit/911c0f70c1407e1e9554718539bd261793f7a89c) — proper dedup + colored output
- [`ce85a69`](https://github.com/GinCz/Linux_Server_Public/commit/ce85a69194a3108396afa0b1ef8d5ba1889f31df) — дедупликация named/fe80, IPv6-группировка, удалён отдельный ports.sh

---

### 7. `new_server_install.sh` STEP 1 — убрать SSH-баннер

**Проблема:** при каждом SSH-логине отображались системные строки:
```
Using username "root".
Last login: Wed Jun 10 00:21:50 2026 from 185.100.197.16
```
Эти строки нельзя убрать из MOTD — они генерируются SSH-демоном и PAM до вывода любых скриптов.

**Решение:** в STEP 1 установки добавлен блок:
```bash
sed -i 's/^#\?PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config
grep -q '^PrintLastLog' /etc/ssh/sshd_config || echo 'PrintLastLog no' >> /etc/ssh/sshd_config
sed -i 's/^#\?PrintMotd.*/PrintMotd no/'  /etc/ssh/sshd_config
grep -q '^PrintMotd'    /etc/ssh/sshd_config || echo 'PrintMotd no' >> /etc/ssh/sshd_config
systemctl reload ssh
```

- `PrintLastLog no` — убирает строку `Last login: ...`
- `PrintMotd no` — отключает PAM-вывод `/etc/motd` (предотвращает дублирование нашего кастомного MOTD)

Вошло в состав `new_server_install.sh` начиная с `v2026.06.10k`.

---

### 8. Blacklist — обновления

Автоматические и ручные обновления blacklist-файлов:
- [`c808cbb`](https://github.com/GinCz/Linux_Server_Public/commit/c808cbbe2d1278d455cd3a261b6b8ce2fc059ef3) — 27 IPs from 222-DE-NetCup
- [`f6f2728`](https://github.com/GinCz/Linux_Server_Public/commit/f6f27289dcb3d3ab7b26cb8522d82d83105837d6) — all-nodes update, 109 unique IPs

---

## Применение на существующем сервере (без переустановки)

```bash
# 1. Подтянуть всё из репозитория
load

# 2. Убрать SSH-баннер "Last login" и "Using username"
sed -i 's/^#\?PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config
grep -q '^PrintLastLog' /etc/ssh/sshd_config || echo 'PrintLastLog no' >> /etc/ssh/sshd_config
sed -i 's/^#\?PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config
grep -q '^PrintMotd' /etc/ssh/sshd_config || echo 'PrintMotd no' >> /etc/ssh/sshd_config
systemctl reload ssh && echo "OK: SSH banner disabled"

# 3. Обновить MOTD (для VPN-сервера)
cp /root/Linux_Server_Public/scripts/motd_vpn.sh /etc/profile.d/motd_server.sh
chmod +x /etc/profile.d/motd_server.sh
echo "OK: MOTD updated"

# 4. Проверить MOTD прямо сейчас (без переподключения)
bash /etc/profile.d/motd_server.sh
```

> После этого при следующем SSH-подключении строки `Using username` и `Last login` исчезнут, MOTD будет показывать объединённую строку `Type: VPN | CrowdSec: ● ACTIVE | bans: N`.

---

*Лог ведётся с: 2026-06-10 | = Rooted by VladiMIR + AI | github.com/GinCz =*
