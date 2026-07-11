# DKIM Setup Guide — Exim4 Multi-Domain (FastPanel)

> = Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =
> Result: **10/10** on mail-tester.com ✅
> Date: 10 June 2026
> Applicable to: **RU-SO-109** (212.109.223.109) and **DE-EU-222** (152.53.182.222)

---

## Introduction

Exim4 on FastPanel uses **split config** (`/etc/exim4/conf.d/`).
This matters — the `localmacros` file in split-config mode **does not work**.

---

## Solution Architecture

```
/etc/exim4/
├── conf.d/
│   ├── main/
│   │   ├── 00_local_dkim          ← our DKIM macros file
│   │   └── 01_primary_hostname    ← override HELO hostname for Exim
│   └── transport/
│       └── 30_exim4-config_remote_smtp  ← already contains DKIM_ variables (Debian standard)
└── dkim/
    ├── keymap.txt                 ← domain → path_to_key mapping
    ├── stanok-ural.ru-private.pem
    ├── stanok-ural.ru-public.pem
    └── <other domains>.pem
```

---

## Step 1 — Generate keys for each domain

```bash
mkdir -p /etc/exim4/dkim
chmod 750 /etc/exim4/dkim

# For each domain:
DOMAIN="stanok-ural.ru"
openssl genrsa -out /etc/exim4/dkim/${DOMAIN}-private.pem 2048
openssl rsa -in /etc/exim4/dkim/${DOMAIN}-private.pem \
  -out /etc/exim4/dkim/${DOMAIN}-public.pem -pubout

chmod 640 /etc/exim4/dkim/${DOMAIN}-private.pem
chown root:Debian-exim /etc/exim4/dkim/${DOMAIN}-private.pem
```

---

## Step 2 — Create keymap.txt

Mapping file: each line = `domain    /path/to/private.pem`

```bash
cat > /etc/exim4/dkim/keymap.txt << 'EOF'
stanok-ural.ru    /etc/exim4/dkim/stanok-ural.ru-private.pem
# Add new domains here:
# example.com    /etc/exim4/dkim/example.com-private.pem
EOF
```

---

## Step 3 — Create DKIM macros file

> ⚠️ IMPORTANT: Do NOT use `/etc/exim4/exim4.conf.localmacros`
> In split-config mode it is **ignored**. Only `conf.d/main/`!

```bash
cat > /etc/exim4/conf.d/main/00_local_dkim << 'EOF'
# DKIM macros for multi-domain signing via keymap lookup
# = Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =

DKIM_CANON = relaxed
DKIM_SELECTOR = dkim
DKIM_DOMAIN = ${lookup{${lc:${domain:$h_from:}}}lsearch{/etc/exim4/dkim/keymap.txt}{${lc:${domain:$h_from:}}}{}}
DKIM_PRIVATE_KEY = ${lookup{${lc:${domain:$h_from:}}}lsearch{/etc/exim4/dkim/keymap.txt}{$value}{0}}
DKIM_STRICT = 0
EOF
```

---

## Step 4 — Set primary_hostname (for Exim only)

The system hostname (`RU-SO-109`, `DE-EU-222`) **is NOT changed**.
Exim gets its own hostname for SMTP HELO:

```bash
# For server 109:
cat > /etc/exim4/conf.d/main/01_primary_hostname << 'EOF'
# Override SMTP HELO hostname for Exim only.
# System hostname stays RU-SO-109 / DE-EU-222 — NOT changed.
# = Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =
primary_hostname = mail.stanok-ural.ru
EOF

# For server 222 — replace with the required domain:
# primary_hostname = mail.gincz.eu
```

---

## Step 5 — Rebuild and restart Exim4

```bash
update-exim4.conf
systemctl restart exim4
systemctl is-active exim4

# Check that macros are visible:
exim4 -bP macro DKIM_DOMAIN
exim4 -bP macro DKIM_PRIVATE_KEY
```

Expected output:
```
DKIM_DOMAIN=${lookup{${lc:${domain:$h_from:}}}lsearch{...}
DKIM_PRIVATE_KEY=${lookup{${lc:${domain:$h_from:}}}lsearch{...}
```

---

## Step 6 — DNS records (Cloudflare)

Get the public key from the server:

```bash
DOMAIN="stanok-ural.ru"
openssl rsa -in /etc/exim4/dkim/${DOMAIN}-private.pem -pubout 2>/dev/null \
  | grep -v "BEGIN\|END" | tr -d '\n'
echo
```

**Add to Cloudflare DNS:**

| Type | Name | Content |
|---|---|---|
| A | `mail.stanok-ural.ru` | `212.109.223.109` |
| TXT | `dkim._domainkey.stanok-ural.ru` | `v=DKIM1; k=rsa; p=<key>` |
| TXT | `stanok-ural.ru` (SPF already exists) | `v=spf1 ip4:212.109.223.109 include:_spf.mail.ru ~all` |

> ⚠️ Cloudflare SPLITS a long key into two chunks when displaying — this is NORMAL.
> But when copying/pasting, a space may be added in the middle or the end may be truncated.
> The key must end with `...IDAQAB` (last 6 characters of an RSA-2048 public key).

---

## Step 7 — Verification

```bash
# Compare key on server with key in DNS:
SERVER=$(openssl rsa -in /etc/exim4/dkim/stanok-ural.ru-private.pem \
  -pubout 2>/dev/null | grep -v "BEGIN\|END" | tr -d '\n')
DNS=$(dig TXT dkim._domainkey.stanok-ural.ru +short | tr -d '"' | grep -oP 'p=\K[^;]+')

[ "$SERVER" = "$DNS" ] && echo "[OK] MATCH" || echo "[FAIL] MISMATCH"

# Send a test email:
echo 'Test DKIM' | mail -s 'DKIM Test' test@mail-tester.com
```

Target: **10/10** on [mail-tester.com](https://www.mail-tester.com)

---

## ❌ What did NOT work (and why)

### 1. localmacros — ignored in split config

```bash
# DOES NOT WORK:
/etc/exim4/exim4.conf.localmacros
```
The `localmacros` file is only read with **monolithic** configuration (`/etc/exim4/exim4.conf`).
FastPanel uses split config — this file is **completely ignored**.
**Solution:** `conf.d/main/00_local_dkim`

### 2. Space and truncated key in Cloudflare DNS

When manually copying the public key to Cloudflare:
- Cloudflare split the key into two chunks (this is normal — RFC 4408 allows it)
- BUT during editing a space was added in the middle: `...bF wbJU...`
- And the end was missing `AB` (key truncated: `...IDAQ` instead of `...IDAQAB`)

Result: `DKIM_INVALID` on verification — signature is present but invalid.
**Solution:** Paste key as a single line, no spaces, ensure it ends with `...IDAQAB`.

### 3. DKIM_DOMAIN via $h_from: vs direct value

The first macro variant used a direct domain value:
```
DKIM_DOMAIN = stanok-ural.ru
```
This only works for a single domain. For multi-domain (many sites) a lookup by From header is required:
```
DKIM_DOMAIN = ${lookup{${lc:${domain:$h_from:}}}lsearch{/etc/exim4/dkim/keymap.txt}{...}}
```

---

## ✅ Result

| Check | Status |
|---|---|
| SPF | ✅ Pass |
| DKIM | ✅ Valid |
| DMARC | ✅ Pass |
| PTR / rDNS | ✅ mail.stanok-ural.ru |
| Blacklists | ✅ Clean |
| **mail-tester.com** | **🏆 10/10** |

---

## 📋 Checklist for a new domain

```bash
# 1. Generate key:
DOMAIN="newdomain.ru"
openssl genrsa -out /etc/exim4/dkim/${DOMAIN}-private.pem 2048
openssl rsa -in /etc/exim4/dkim/${DOMAIN}-private.pem \
  -out /etc/exim4/dkim/${DOMAIN}-public.pem -pubout
chmod 640 /etc/exim4/dkim/${DOMAIN}-private.pem
chown root:Debian-exim /etc/exim4/dkim/${DOMAIN}-private.pem

# 2. Add to keymap:
echo "${DOMAIN}    /etc/exim4/dkim/${DOMAIN}-private.pem" >> /etc/exim4/dkim/keymap.txt

# 3. Get public key for DNS:
openssl rsa -in /etc/exim4/dkim/${DOMAIN}-private.pem -pubout 2>/dev/null \
  | grep -v "BEGIN\|END" | tr -d '\n' && echo

# 4. Add to Cloudflare DNS:
#    TXT  dkim._domainkey.${DOMAIN}  =>  "v=DKIM1; k=rsa; p=<key>"

# 5. No restart needed — keymap is read dynamically on each send
```

---

## 🖥️ Universal auto-setup script

See `scripts/setup_dkim.sh` — finds all domains via nginx, generates keys,
fills keymap.txt, creates conf.d/main/00_local_dkim, outputs DNS records.

---

*= Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz/Linux_Server_Public =*
