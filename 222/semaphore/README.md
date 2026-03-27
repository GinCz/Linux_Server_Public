# Semaphore — Ansible UI on server 222

**Version:** v2026-03-27  
**Server:** xxx.xxx.xxx.222 (NetCup DE, Ubuntu 24, FASTPANEL)  
**Domain:** https://sem.gincz.com  
**Port (internal):** 3000 (Docker → Nginx proxy)  
*= Rooted by VladiMIR | AI =*

---

## What is Semaphore?

Semaphore is a lightweight open-source AWX/Ansible Tower replacement.  
~200MB RAM, clean UI, Docker-based, no Kubernetes needed.

## Files in this folder

| File | Description |
|------|-------------|
| `install_semaphore_v2026-03-27.sh` | **Main install script** — run this on server 222 |
| `docker-compose.semaphore.yml` | Reference docker-compose (script generates actual one) |
| `sem.gincz.com.conf` | Nginx vhost config template |

## Quick Install (on server 222)

```bash
clear
cd /root
wget https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/222/semaphore/install_semaphore_v2026-03-27.sh
chmod +x install_semaphore_v2026-03-27.sh
bash install_semaphore_v2026-03-27.sh
```

## After install

1. Add `sem.gincz.com` domain in FASTPANEL
2. Enable SSL in FASTPANEL (or run certbot)
3. Open https://sem.gincz.com
4. Login: `admin` / `***REMOVED***`
5. **Change password immediately!**

## Management

```bash
# Status
docker ps --filter name=semaphore

# Logs
docker compose -f /root/semaphore/docker-compose.yml logs -f

# Restart
docker compose -f /root/semaphore/docker-compose.yml restart

# Stop
docker compose -f /root/semaphore/docker-compose.yml down

# Update to latest version
docker compose -f /root/semaphore/docker-compose.yml pull
docker compose -f /root/semaphore/docker-compose.yml up -d
```

## DNS

```
sem.gincz.com  A  xxx.xxx.xxx.222  (DNS Only — Cloudflare)
```

## Architecture

```
Cloudflare (DNS Only)
        ↓
  sem.gincz.com:443
        ↓
  Nginx (FASTPANEL)
        ↓
  127.0.0.1:3000
        ↓
  Docker: semaphore
        ↓
  BoltDB (embedded, no external DB!)
```
