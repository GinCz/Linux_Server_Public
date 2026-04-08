# 🐳 Docker — Backup & Restore Guide

> **Server:** 109-RU-FastVDS | IP: ...109  
> **Version:** v2026-04-08  
> **Author:** Ing. VladiMIR Bulantsev  
> = Rooted by VladiMIR | AI =

---

## ⚠️ Статус

Контейнеры на этом сервере пока **не выяснены**.

Выполнить диагностику (с сервера `.222`):
```bash
ssh root@212.109.223.109 "docker ps"
```

Или локально на сервере `.109`:
```bash
docker ps
```

---

## 🔑 Алиасы (добавить на сервере `.109`)

| Алиас | Команда | Описание |
|---|---|---|
| `f5bot` | `bash /root/docker_backup.sh` | Бэкап всех Docker |
| `f9bot` | `bash /root/Linux_Server_Public/109/Dockers/f9bot_restore.sh` | Восстановление Docker |

---

## 📁 Расположение файлов

```
109/Dockers/
├── README.md              ← этот файл
└── f9bot_restore.sh       ← будет добавлен после диагностики
```

---

## ℹ️ Как узнать какие докеры есть на сервере `.109`

```bash
# С сервера .222:
ssh root@212.109.223.109 "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"
```

---

> = Rooted by VladiMIR | AI =
