# SSL / acme.sh / FastPanel — Complete Guide

> **Server:** 222-DE-NetCup (152.53.182.222)
> **Updated:** 2026-06-29
> **Problem solved after:** ~4 hours of pain. Read this first.

---

## ⚡ TL;DR — Quick Summary

| Question | Answer |
|---|---|
| How does FastPanel update SSL? | HTTP-01 challenge via Let's Encrypt |
| Why does it break? | Cloudflare proxy (🟠) blocks `.well-known/acme-challenge/` |
| Our solution | acme.sh with **DNS-01 challenge via Cloudflare API** |
| Where certificates are stored | `/var/www/httpd-cert/<domain>_<date>.{crt,key,_fullchain.crt}` |
| How they are applied to nginx | `/root/acme-deploy-fastpanel.sh` — patches nginx config + restart |
| Auto-renew | `domains.sh` in cron every Saturday at 02:15, threshold <15 days |
| "Renew certificate" button in FastPanel | ❌ DO NOT CLICK — it will overwrite our paths |

---

## 🔴 Problem: Why Certificates Break

FastPanel updates SSL using the standard **HTTP-01 challenge**:
1. Let's Encrypt asks to place a file in `/.well-known/acme-challenge/`
2. FastPanel places it
3. Let's Encrypt checks the domain via HTTP

**This breaks when the domain is behind Cloudflare with proxy enabled (🟠 orange cloud):**
- Cloudflare intercepts the request
- Let's Encrypt sees Cloudflare's IP instead of our server
- Challenge fails → certificate not issued → site breaks with `NET::ERR_CERT_DATE_INVALID`

**Additionally:** FastPanel stores certificate paths in nginx config as:
```
ssl_certificate /var/www/httpd-cert/domain.tld_DATE.crt;
```
The date is embedded in the filename! Each new certificate gets a new name,
and FastPanel does not update this automatically — nginx keeps reading the old file.

---

## ✅ Solution: acme.sh + DNS-01 + deploy script

### Architecture

```
[acme.sh --cron / --renew]
       ↓
  DNS-01 challenge
  (creates TXT record _acme-challenge.domain.tld via Cloudflare API)
       ↓
  Let's Encrypt issues the certificate
       ↓
  acme.sh copies files:
    /var/www/httpd-cert/<domain>_<date>.crt
    /var/www/httpd-cert/<domain>_<date>.key
    /var/www/httpd-cert/<domain>_<date>_fullchain.crt
       ↓
  reloadcmd: bash /root/acme-deploy-fastpanel.sh <domain>
       ↓
  deploy script patches nginx config in /etc/nginx/fastpanel2-available/
  with new paths + systemctl restart nginx
```

### Key Files

| File | Purpose |
|---|---|
| `/.acme.sh/acme.sh` | Let's Encrypt client |
| `/.acme.sh/account.conf` | Cloudflare API Token + Email |
| `/.acme.sh/<domain>/<domain>.conf` | Domain config (reloadcmd etc.) |
| `/root/acme-deploy-fastpanel.sh` | Deploy script (patches nginx + restart) |
| `/var/www/httpd-cert/` | FastPanel certificate directory |
| `/var/log/acme-deploy.log` | Log of all deploy operations |

---

## 🔧 Initial Setup (on fresh server install)

### 1. Install acme.sh
```bash
curl https://get.acme.sh | sh
source ~/.bashrc
```

### 2. Set Cloudflare API Token in `~/.acme.sh/account.conf`
```bash
export CF_Token="cfat_XXXXXXXXXXXXXXXXX"
export CF_Email="gin@volny.cz"
# Store token ONLY in ~/.acme.sh/account.conf — never in the repository!
```

### 3. Create deploy script `/root/acme-deploy-fastpanel.sh`
```bash
cat > /root/acme-deploy-fastpanel.sh << 'EOF'
#!/bin/bash
# Deploy script: copies new certificates and restarts nginx
# Called automatically by acme.sh after each certificate issuance

DOMAIN="$1"
LOG="/var/log/acme-deploy.log"

if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 <domain>" | tee -a $LOG
    exit 1
fi

DATE=$(date +%Y-%m-%d)
CERT_DIR="/var/www/httpd-cert"
ACME_DIR="/.acme.sh/${DOMAIN}_ecc"

# If no ECC directory exists — try RSA
[ ! -d "$ACME_DIR" ] && ACME_DIR="/.acme.sh/${DOMAIN}"

CRT="${CERT_DIR}/${DOMAIN}_${DATE}.crt"
KEY="${CERT_DIR}/${DOMAIN}_${DATE}.key"
FULLCHAIN="${CERT_DIR}/${DOMAIN}_${DATE}_fullchain.crt"

echo "[$(date)] Deploying ${DOMAIN} → ${CRT}" >> $LOG

cp "${ACME_DIR}/${DOMAIN}.cer" "$CRT"
cp "${ACME_DIR}/${DOMAIN}.key" "$KEY"
cp "${ACME_DIR}/fullchain.cer" "$FULLCHAIN"

# Patch FastPanel nginx config
NGINX_CONF=$(grep -rl "ssl_certificate.*${DOMAIN}" /etc/nginx/fastpanel2-available/ 2>/dev/null | head -1)
if [ -n "$NGINX_CONF" ]; then
    sed -i "s|ssl_certificate .*${DOMAIN}.*\.crt;|ssl_certificate ${CRT};|" "$NGINX_CONF"
    sed -i "s|ssl_certificate_key .*${DOMAIN}.*\.key;|ssl_certificate_key ${KEY};|" "$NGINX_CONF"
    sed -i "s|ssl_trusted_certificate .*${DOMAIN}.*\.crt;|ssl_trusted_certificate ${FULLCHAIN};|" "$NGINX_CONF"
    echo "[$(date)] Patched: $NGINX_CONF" >> $LOG
else
    echo "[$(date)] WARNING: nginx config not found for ${DOMAIN}" >> $LOG
fi

# Restart nginx (not reload — to ensure new files are picked up)
systemctl restart nginx
echo "[$(date)] nginx restarted OK" >> $LOG
EOF
chmod +x /root/acme-deploy-fastpanel.sh
```

### 4. Issue certificate for a domain
```bash
# For domain behind Cloudflare proxy
/.acme.sh/acme.sh --issue \
  --dns dns_cf \
  -d example.com \
  -d www.example.com \
  --keylength ec-256

# Install (first time — sets reloadcmd)
/.acme.sh/acme.sh --install-cert -d example.com \
  --cert-file /var/www/httpd-cert/example.com_$(date +%Y-%m-%d).crt \
  --key-file /var/www/httpd-cert/example.com_$(date +%Y-%m-%d).key \
  --fullchain-file /var/www/httpd-cert/example.com_$(date +%Y-%m-%d)_fullchain.crt \
  --reloadcmd "bash /root/acme-deploy-fastpanel.sh example.com"
```

### 5. Verify domain list in acme.sh
```bash
/.acme.sh/acme.sh --list
```

---

## 📅 Cron Schedule

```bash
crontab -l
```

**Current schedule:**
```
# SSL check + auto-renew <15 days — every Saturday at 02:15
15 2 * * 6  bash /root/Linux_Server_Public/222/domains.sh >> /var/log/acme-deploy.log 2>&1
```

> **Why not daily?**
> acme.sh auto-renews 30 days before expiry. The weekly check via `domains.sh`
> is a safety net: if acme.sh failed for any reason, we catch it
> at least 15 days before expiry and force re-issue.

**Set up cron:**
```bash
(crontab -l 2>/dev/null | grep -v 'acme.sh\|domains.sh'; \
 echo '15 2 * * 6  bash /root/Linux_Server_Public/222/domains.sh >> /var/log/acme-deploy.log 2>&1') \
 | crontab -
```

---

## 🌍 Domains Managed by acme.sh (as of 2026-06-29)

| Domain | Method | CA | Next renew |
|---|---|---|---|
| timan-kuchyne.cz | DNS-01 / Cloudflare | Let's Encrypt | ~2026-08-28 |
| eco-seo.eu | DNS-01 / Cloudflare | Let's Encrypt | ~2026-08-28 |
| gincz.com | DNS-01 / Cloudflare | Let's Encrypt | ~2026-08-28 |
| kk-med.cz | DNS-01 / Cloudflare | Let's Encrypt | ~2026-08-27 |

> All other domains on the server are updated via FastPanel (HTTP-01).
> If they develop issues — migrate to acme.sh using the scheme above.

---

## 🚫 What NOT to Do

1. **Click "Renew certificate" in FastPanel** for the domains in the table above.
   FastPanel will overwrite the nginx config with its own paths → certificates become stale.

2. **Disable Cloudflare proxy (grey cloud)** on these domains.
   This exposes the real server IP. Our DNS-01 method works with any proxy state.

3. **Delete acme-deploy-fastpanel.sh** — this breaks reloadcmd for all acme.sh domains.

---

## 🔍 Diagnostics / Common Issues

### Certificate expired, site unreachable
```bash
# 1. Check which file nginx is reading
nginx -T | grep -A3 "server_name.*DOMAIN"

# 2. Check certificate file date
ls -la /var/www/httpd-cert/ | grep DOMAIN
openssl x509 -in /var/www/httpd-cert/DOMAIN_*.crt -noout -dates

# 3. Force re-issue
/.acme.sh/acme.sh --renew -d DOMAIN -d www.DOMAIN --force

# 4. Check log
tail -50 /var/log/acme-deploy.log
```

### New domain — register in acme.sh
```bash
# 1. Add domain (if behind CF proxy)
/.acme.sh/acme.sh --issue --dns dns_cf -d NEW.DOMAIN -d www.NEW.DOMAIN --keylength ec-256

# 2. Run install-cert
/.acme.sh/acme.sh --install-cert -d NEW.DOMAIN \
  --cert-file /var/www/httpd-cert/NEW.DOMAIN_$(date +%Y-%m-%d).crt \
  --key-file /var/www/httpd-cert/NEW.DOMAIN_$(date +%Y-%m-%d).key \
  --fullchain-file /var/www/httpd-cert/NEW.DOMAIN_$(date +%Y-%m-%d)_fullchain.crt \
  --reloadcmd "bash /root/acme-deploy-fastpanel.sh NEW.DOMAIN"

# 3. Verify list
/.acme.sh/acme.sh --list
```

### Check SSL status of all domains right now
```bash
domains   # alias → domains.sh — shows days to expiry for each domain
```

### View current cron
```bash
crontab -l
```

---

## 📋 History

| Date | Event |
|---|---|
| 2026-06-29 | 4 domains (timan-kuchyne.cz, eco-seo.eu, gincz.com, kk-med.cz) migrated to acme.sh + DNS-01. Written acme-deploy-fastpanel.sh. Set up weekly cron via domains.sh. |

---

*= Rooted by VladiMIR + AI | v.2026.07.11 | github.com/GinCz =*
