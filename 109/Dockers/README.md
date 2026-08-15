# 🐳 Docker — Backup & Restore Guide

> **Server:** 109-RU-FastVDS | IP: 212.109.223.109  
> **Version:** v2026-04-08  
> **Author:** Ing. VladiMIR Bulantsev  
> **GitHub:** https://github.com/GinCz/Linux_Server_Public

---

## ⚠️ Status

Containers running on this server:

Run diagnostics (from server `.222`):
```bash
ssh root@212.109.223.109 "docker ps"
```

Or locally on server `.109`:
```bash
docker ps
```

---

## 🔑 Aliases (Configure on server `.109`)

| Alias | Command | Description |
|---|---|---|
| `f5bot` | `bash /root/docker_backup.sh` | Backup all Docker containers |
| `f9bot` | `bash /root/Linux_Server_Public/109/Dockers/f9bot_restore.sh` | Restore Docker containers |

---

## 📁 File Structure

```
109/Dockers/
├── README.md              ← this documentation
└── f9bot_restore.sh       ← container restore tool
```

---

## ℹ️ Inspect Active Containers on Server `.109`

```bash
# From server .222:
ssh root@212.109.223.109 "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"
```

---

> = Rooted by VladiMIR | AI = v2026-04-08 = github.com/GinCz/Linux_Server_Public
