# 🗓️ WORKLOG — 2026-04-12 / 2026-04-13

> **= Rooted by VladiMIR | AI =**  
> Сессия: вечер 12 апреля → ночь 13 апреля 2026  
> Затронуты: сервер **222-DE-NetCup** (152.53.182.222) и **109-RU-FastVDS** (212.109.223.109)

---

## 📋 Краткое резюме сессии

1. Был обновлён скрипт `sos.sh` с цветным выводом и поддержкой параметров (`1h`, `3h`, `24h`, `120h`)
2. На **222** алиас `sos1` уже был — ничего делать не надо
3. На **109** алиас `sos1` отсутствовал — добавлен в `.bashrc`
4. Документация `ALIASES.md` обновлена в обеих папках

---

## 💻 Сервер 222-DE-NetCup

### 1. `222/.bashrc` — без изменений

> **Версия до:** v2026-04-12 | **Версия после:** v2026-04-12 (без изменений)

Алиас `sos1` был уже присутствовал в этом файле на момент проверки. Файл не трогался.

**Полный список sos-алиасов на 222:**
```bash
alias sos='bash /root/Linux_Server_Public/222/sos.sh 1h'
alias sos1='bash /root/Linux_Server_Public/222/sos.sh 1h'
alias sos3='bash /root/Linux_Server_Public/222/sos.sh 3h'
alias sos24='bash /root/Linux_Server_Public/222/sos.sh 24h'
alias sos120='bash /root/Linux_Server_Public/222/sos.sh 120h'
```

---

### 2. `222/ALIASES.md` — обновлен

> **Версия до:** без `sos1` | **Версия после:** v2026-04-13

Изменения:
- Добавлена строка `sos1` в таблицу SOS
- Секция SOS перенесена наверх (сразу после "How to restore")
- Добавлено предупреждение о регистрозависимости:

```
✅ Правильные команды: sos  sos1  sos3  sos24  sos120
❌ Неправильно: SOS 1  SOS1  — bash алиасы регистрозависимы!
```

---

## 💻 Сервер 109-RU-FastVDS

### 1. `109/.bashrc` — обновлён

> **Версия до:** v2026-04-10 | **Версия после:** v2026-04-13

**Проблема:** алиас `sos1` отсутствовал. При вводе `sos1` сервер выполнял старый код скрипта (не установленного файла или старой копии).

**Решение:** добавлен алиас `sos1` в блок SOS рядом с `sos`.

**Полный список sos-алиасов на 109:**
```bash
alias sos='bash /root/Linux_Server_Public/109/sos.sh 1h'
alias sos1='bash /root/Linux_Server_Public/109/sos.sh 1h'
alias sos3='bash /root/Linux_Server_Public/109/sos.sh 3h'
alias sos24='bash /root/Linux_Server_Public/109/sos.sh 24h'
alias sos120='bash /root/Linux_Server_Public/109/sos.sh 120h'
```

**Коммит:** [`Add alias sos1 to 109/.bashrc v2026-04-13`](https://github.com/GinCz/Linux_Server_Public/commit/f6486a25fcdf35ea7c51a1d20d443627e37c37f0)

---

### 2. `109/ALIASES.md` — обновлен

> **Версия до:** без `sos1` | **Версия после:** v2026-04-13

Изменения идентичны 222/ALIASES.md:
- Добавлена строка `sos1` в таблицу SOS
- Секция SOS перенесена наверх
- Добавлено предупреждение о регистрозависимости

**Коммит:** [`Add sos1 alias to ALIASES.md on both 222 and 109 v2026-04-13`](https://github.com/GinCz/Linux_Server_Public/commit/f0be4c5439263b497e1634b32e7a8717735e0085)

---

## ⚠️ Важное правило: SOS-алиасы

**bash алиасы регистрозависимы.** Используем только строчные буквы:

| Команда | Скрипт | Период | Оба сервера |
|---|---|---|---|
| `sos` | `sos.sh 1h` | 1 час | ✅ 222 и 109 |
| `sos1` | `sos.sh 1h` | 1 час | ✅ 222 и 109 |
| `sos3` | `sos.sh 3h` | 3 часа | ✅ 222 и 109 |
| `sos24` | `sos.sh 24h` | 24 часа | ✅ 222 и 109 |
| `sos120` | `sos.sh 120h` | 120 часов | ✅ 222 и 109 |
| ~~`SOS`~~ | — | — | ❌ НЕТ такого алиаса! |
| ~~`SOS 1`~~ | — | — | ❌ НЕТ такого алиаса! |
| ~~`SOS1`~~ | — | — | ❌ НЕТ такого алиаса! |

---

## 📂 Измененные файлы

| Файл | Что изменилось | Коммит |
|---|---|---|
| `109/.bashrc` | Добавлен `alias sos1=...`, версия обновлена до v2026-04-13 | [f6486a2](https://github.com/GinCz/Linux_Server_Public/commit/f6486a25fcdf35ea7c51a1d20d443627e37c37f0) |
| `109/ALIASES.md` | Добавлена `sos1` в SOS-таблицу, секция перенесена наверх | [f0be4c5](https://github.com/GinCz/Linux_Server_Public/commit/f0be4c5439263b497e1634b32e7a8717735e0085) |
| `222/ALIASES.md` | Добавлена `sos1` в SOS-таблицу, секция перенесена наверх | [f0be4c5](https://github.com/GinCz/Linux_Server_Public/commit/f0be4c5439263b497e1634b32e7a8717735e0085) |
| `222/.bashrc` | Не трогался — `sos1` уже был присутствен | — |

---

*= Rooted by VladiMIR | AI = | GitHub: https://github.com/GinCz/Linux_Server_Public*
