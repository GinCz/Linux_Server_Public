# Operations Guide — Zero-Downtime Rules

```
= Rooted by VladiMIR | AI =
v2026-04-07
```

> ⚠️ **This document exists because of a real incident.**  
> On 2026-04-07, `systemctl restart php8.3-fpm` caused 1–3 seconds of downtime  
> across ALL 28 sites on server 109 while creating a PHP-FPM pool for ugfp.ru.  
> The correct command was `systemctl reload php8.3-fpm`.  
> **This must never happen again.**

---

## The Golden Rule

> **NEVER use `restart` for nginx or php-fpm during working hours.**  
> **ALWAYS use `reload` — it is zero-downtime, graceful, and safe.**

---

## nginx — reload vs restart

### What happens internally

| Command | What nginx does | Downtime |
|---------|----------------|----------|
| `systemctl reload nginx` | Master process re-reads config, spawns new workers, old workers finish their active requests then exit | ✅ **0 sec** |
| `nginx -s reload` | Same as above — identical to systemctl reload | ✅ **0 sec** |
| `systemctl restart nginx` | Full stop + start. All active connections are dropped. All sites return 502/504 for 1–3 sec | ❌ **1–3 sec downtime** |
| `systemctl stop nginx` | nginx stops completely. All sites go offline until started again | ❌ **Full outage** |

### When to use each

| Situation | Correct command |
|-----------|----------------|
| Changed nginx.conf | `nginx -t && systemctl reload nginx` |
| Added/modified site config in fastpanel2-sites/ | `nginx -t && systemctl reload nginx` |
| Added/modified include file in fastpanel2-includes/ | `nginx -t && systemctl reload nginx` |
| Changed SSL certificate | `nginx -t && systemctl reload nginx` |
| nginx binary updated (apt upgrade nginx) | `systemctl restart nginx` — acceptable after package update |
| nginx is completely frozen / not responding to reload | `systemctl restart nginx` — last resort |

### Correct pattern — always

```bash
# Step 1: ALWAYS test syntax before touching nginx
nginx -t

# Step 2: reload — NOT restart
nginx -t && systemctl reload nginx && echo "✅ nginx reloaded — zero downtime"
```

### How to verify reload worked

```bash
# Check nginx is running and the reload was applied
systemctl status nginx | grep -E "(Active|Main PID)"

# Check active connections are intact
ss -tlnp | grep nginx

# Verify config was actually reloaded (PID stays the same after reload — that is correct)
cat /run/nginx.pid
```

---

## PHP-FPM — reload vs restart

### What happens internally

| Command | What php-fpm does | Downtime |
|---------|-------------------|----------|
| `systemctl reload php8.3-fpm` | Master process re-reads all pool configs (`*.conf`), applies changes gracefully. Active worker processes finish current requests, then are replaced by new workers. Sockets are NOT deleted during reload. | ✅ **0 sec** |
| `kill -USR2 $(cat /run/php/php8.3-fpm.pid)` | PHP-FPM binary-safe reload (hot swap of master process). Maximum safety. | ✅ **0 sec** |
| `systemctl restart php8.3-fpm` | Sends SIGTERM to master → all workers killed → all sockets deleted → new master starts → new workers created → new sockets created. During this gap nginx gets `(2: No such file or directory)` for every socket → **502 on ALL sites simultaneously**. | ❌ **1–3 sec ALL sites** |
| `systemctl stop php8.3-fpm` | php-fpm stops completely. All PHP requests return 502. | ❌ **Full PHP outage** |

### When to use each

| Situation | Correct command |
|-----------|----------------|
| Added new pool config (e.g. new site) | `php-fpm8.3 -t && systemctl reload php8.3-fpm` |
| Modified existing pool config | `php-fpm8.3 -t && systemctl reload php8.3-fpm` |
| Changed php.ini values in pool | `php-fpm8.3 -t && systemctl reload php8.3-fpm` |
| Changed pm / pm.max_children / pm.process_idle_timeout | `php-fpm8.3 -t && systemctl reload php8.3-fpm` |
| PHP package updated (apt upgrade php8.3-fpm) | `systemctl restart php8.3-fpm` — required after binary update |
| php-fpm master process frozen / zombie | `systemctl restart php8.3-fpm` — last resort |
| Server just booted (@reboot scripts) | `systemctl restart php8.3-fpm` — acceptable, no live traffic yet |

### Correct pattern — always

```bash
# Step 1: ALWAYS test pool config syntax first
php-fpm8.3 -t

# Step 2: reload — NOT restart
php-fpm8.3 -t && systemctl reload php8.3-fpm && echo "✅ php8.3-fpm reloaded — zero downtime"
```

### How to verify reload worked

```bash
# Check master process is still running (PID stays same after reload — correct)
systemctl status php8.3-fpm | grep -E "(Active|Main PID)"

# Check new socket was created (for new pool)
ls -la /var/run/SITENAME.sock

# Check pool is in the active process list
ps aux | grep php-fpm | grep SITENAME

# Test the socket directly
curl -s -o /dev/null -w "%{http_code}" https://SITENAME/
```

---

## The Incident — 2026-04-07 (postmortem)

### What happened

When creating a missing PHP-FPM pool for `ugfp.ru`, the fix script used:

```bash
# ❌ THIS caused downtime on ALL sites:
systemctl restart php8.3-fpm
```

Server 109 has **28+ WordPress sites**. At the moment `restart` was executed:
1. php-fpm master received SIGTERM
2. All worker processes were killed immediately
3. All sockets in `/var/run/*.sock` were deleted
4. nginx received `connect() failed (2: No such file or directory)` for every `.sock`
5. nginx returned **502 Bad Gateway** on all PHP requests for 1–3 seconds
6. New master started, new workers spawned, new sockets created
7. Sites came back online

### What should have been used

```bash
# ✅ THIS is zero-downtime:
php-fpm8.3 -t && systemctl reload php8.3-fpm
```

With `reload`, the master process reads the new `ugfp.ru.conf`, creates the new socket,
and spawns a worker for ugfp.ru — while ALL existing workers for all other sites  
continue serving requests without interruption.

### Why reload works for new pools

When `reload` is triggered:
- PHP-FPM master re-reads **all** `.conf` files in `pool.d/`
- New pools → socket is created, workers spawned
- Removed pools → workers finish current requests, then exit
- Unchanged pools → workers continue running, no interruption
- **No existing socket is ever deleted during reload**

---

## Complete Safe Sequence for Any Config Change

Use this exact sequence for ANY nginx or php-fpm change on production servers.

```bash
# ============================================================
# SAFE CONFIG CHANGE SEQUENCE
# = Rooted by VladiMIR | AI = v2026-04-07
# Server: 109-RU-FastVDS | 212.109.223.109
# ============================================================

# 1. Make your changes to config files
# ...

# 2. Test PHP-FPM config (if changed)
echo ">>> Testing PHP-FPM config..."
php-fpm8.3 -t 2>&1
# Expected: "configuration file /etc/php/8.3/fpm/php-fpm.conf test is successful"
# If errors: DO NOT proceed — fix the config first

# 3. Reload PHP-FPM (zero downtime)
php-fpm8.3 -t && systemctl reload php8.3-fpm \
  && echo "✅ php8.3-fpm reloaded — zero downtime" \
  || echo "❌ php8.3-fpm reload FAILED — check logs"

# 4. Wait 2 seconds for sockets to initialize
sleep 2

# 5. Test nginx config (if changed)
echo ">>> Testing nginx config..."
nginx -t 2>&1
# Expected: "nginx: configuration file /etc/nginx/nginx.conf syntax is ok"
# If errors: DO NOT proceed — fix the config first

# 6. Reload nginx (zero downtime)
nginx -t && systemctl reload nginx \
  && echo "✅ nginx reloaded — zero downtime" \
  || echo "❌ nginx reload FAILED — check logs"

# 7. Verify sites (curl spot check)
sleep 2
echo ">>> Verifying sites..."
curl -s -o /dev/null -w "Site 1: %{http_code}\n" --max-time 8 https://YOURSITE1.ru/
curl -s -o /dev/null -w "Site 2: %{http_code}\n" --max-time 8 https://YOURSITE2.ru/
```

---

## When `restart` IS acceptable

These are the only situations where `restart` is justified:

| Service | Situation | Why restart is OK |
|---------|-----------|-------------------|
| php-fpm | After `apt upgrade php8.3-fpm` | Binary changed — reload does not pick up new binary |
| php-fpm | php-fpm master is frozen / not responding to reload | Emergency only |
| php-fpm | Server just booted, @reboot scripts | No live traffic yet |
| nginx | After `apt upgrade nginx` | Binary changed |
| nginx | nginx master is frozen / zombie | Emergency only |
| nginx | Initial server setup | No sites live yet |

> ⚠️ **Before any restart during working hours:**  
> 1. Warn that downtime of 1–3 seconds WILL occur on ALL sites  
> 2. Consider scheduling for low-traffic time (02:00–05:00 server time)  
> 3. If possible, always try `reload` first — restart only if reload fails

---

## Quick Reference Card

```
╔══════════════════════════════════════════════════════════════════╗
║         NGINX & PHP-FPM — QUICK REFERENCE CARD                  ║
║         = Rooted by VladiMIR | AI =  v2026-04-07                ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  CHANGED NGINX CONFIG?                                           ║
║    nginx -t && systemctl reload nginx              ← ✅ DO THIS ║
║    systemctl restart nginx                         ← ❌ NEVER   ║
║                                                                  ║
║  CHANGED / ADDED PHP-FPM POOL?                                   ║
║    php-fpm8.3 -t && systemctl reload php8.3-fpm    ← ✅ DO THIS ║
║    systemctl restart php8.3-fpm                    ← ❌ NEVER   ║
║                                                                  ║
║  restart = kills ALL sockets = 502 on ALL 28 sites = DOWNTIME   ║
║  reload  = graceful swap = zero downtime = correct              ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

---

```
= Rooted by VladiMIR | AI =
v2026-04-07
Server 109 — 109-RU-FastVDS | 212.109.223.109
Server 222 — 222-DE-NetCup  | 152.53.182.222
```
