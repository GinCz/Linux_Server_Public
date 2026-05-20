# 🖥️ Server 109 — RU-FastVDS (212.109.223.109)

> **Провайдер:** FastVDS.ru, Россия | Ubuntu 24 LTS / FASTPANEL  
> **Cloudflare:** НЕТ — прямой IP  
> **Назначение:** Русскоязычные сайты  
> **Hardware:** 4 vCore AMD EPYC 7763 | 8GB RAM | 80GB NVMe | 13 Euro/mo

---

## ⚡ Быстрый деплой после переустановки / смены сервера

```bash
# 1. Клонировать репо
git clone https://github.com/GinCz/Linux_Server_Public.git /root/Linux_Server_Public

# 2. Установить .bashrc (алиасы + MOTD)
cp /root/Linux_Server_Public/109/.bashrc ~/.bashrc && source ~/.bashrc

# 3. Установить MOTD
cp /root/Linux_Server_Public/109/motd_server.sh /etc/profile.d/motd_server.sh
chmod +x /etc/profile.d/motd_server.sh
```

> 💡 `.bashrc` загружает алиасы из: `~/Linux_Server_Public/scripts/shared_aliases_109.sh`

---

## 📁 Структура файлов

| Файл | Назначение |
|---|---|
| `.bashrc` | Загружает алиасы + MOTD при логине |
| `motd_server.sh` | MOTD — приветствие при SSH-входе |
| `ALIASES.md` | Полный справочник всех алиасов |
| `sos.sh` | Health monitor сервера |
| `save.sh` / `load.sh` | Git push / pull конфигов |
| `banlog.sh` | CrowdSec статистика банов |
| `wp_update_all.sh` | Обновление всех WP-сайтов |
| `system_backup.sh` | Полный бэкап сервера |
| `scan_clamav.sh` | Антивирусное сканирование |
| `domains.sh` | Список доменов сервера |
| `server_cleanup.sh` | Очистка логов и кэша |

---

## 🔑 Откуда берутся алиасы

```
~/.bashrc
  └── ~/Linux_Server_Public/scripts/shared_aliases_109.sh   ← ОСНОВНОЙ файл алиасов
  └── ~/Linux_Server_Public/109/motd_server.sh              ← MOTD при логине
```

⚠️ **Важно:** если репо не склонировано (`/root/Linux_Server_Public` не существует),  
алиасы **не загружаются** и MOTD **не показывается**. Всегда клонируй репо первым шагом.

---

## 🏃 Основные алиасы

| Алиас | Действие |
|---|---|
| `sos` / `sos24` | Health report за 1h / 24h |
| `save` | git add + commit + push |
| `load` | git pull + reload .bashrc |
| `banlog` | CrowdSec: статистика + последние 30 банов |
| `wpupd` | Обновить все WP-сайты |
| `backup` | Полный бэкап |
| `antivir` | ClamAV сканирование |
| `nginx-reload` | Тест + reload nginx (zero-downtime) |
| `cleanup` | Очистка логов / кэша |
| `00` | `clear` |

Полный список: [ALIASES.md](ALIASES.md)

---

*= Rooted by VladiMIR + AI | v.2026.05.20 | github.com/GinCz =*
