# 📧 Email DNS Setup: DKIM, DMARC, SPF — Complete Documentation

> **Result:** 10/10 on mail-tester.com ✅
> **Domain:** stanok-ural.ru
> **Server:** 212.109.223.109 (FastPanel, Ubuntu 24 LTS)
> **DNS provider:** Cloudflare
> **Date:** 2026-06-10

---

## 🗂️ Contents

1. [What we configured and why](#1-what-we-configured-and-why)
2. [Final DNS records](#2-final-dns-records)
3. [What didn't work and how we fixed it](#3-what-didnt-work-and-how-we-fixed-it)
4. [Correct setup order](#4-correct-setup-order)
5. [Verification](#5-verification)
6. [Setup on server 222](#6-setup-on-server-222)
7. [Useful diagnostic commands](#7-useful-diagnostic-commands)

---

## 1. What we configured and why

**Goal:** ensure correct email delivery from the WordPress site stanok-ural.ru via the FastPanel mail server. Emails must pass spam filters and achieve a score of 10/10 on mail-tester.com.

### Three pillars of email authentication

| Record | Full name | Purpose |
|--------|-----------|--------|
| **SPF** | Sender Policy Framework | Specifies which IPs are allowed to send mail on behalf of the domain |
| **DKIM** | DomainKeys Identified Mail | Digital signature of the email — recipient verifies the message is not forged |
| **DMARC** | Domain-based Message Authentication | Policy: what to do if SPF/DKIM fail, where to send reports |

---

## 2. Final DNS records

All records in Cloudflare, proxy status: **DNS only** (grey cloud ☁️).

### A records
```
mail.stanok-ural.ru    A    212.109.223.109
stanok-ural.ru         A    212.109.223.109
www.stanok-ural.ru     A    212.109.223.109
```

### MX record
```
stanok-ural.ru    MX    emx.mail.ru    Priority: 10
```
> ⚠️ Leave MX priority at default (usually 10).

### TXT — SPF
```
stanok-ural.ru    TXT    "v=spf1 ip4:212.109.223.109 include:_spf.mail.ru ~all"
```
> Allows sending from our IP + via mail.ru infrastructure. `~all` = soft fail.

### TXT — DMARC
```
_dmarc.stanok-ural.ru    TXT    "v=DMARC1; p=quarantine; pct=100; sp=quarantine; adkim=r; aspf=r; fo=0; rf=afrf; ri=86400; np=quarantine"
```

| Parameter | Value | Description |
|----------|-------|-------------|
| `p=quarantine` | | Unauthenticated emails → spam (not rejected immediately) |
| `pct=100` | | Apply policy to 100% of emails |
| `adkim=r` | relaxed | DKIM: subdomain match allowed |
| `aspf=r` | relaxed | SPF: subdomain match allowed |
| `ri=86400` | 24 hours | Report interval |

### TXT — DKIM (primary, FastPanel)
```
dkim._domainkey.stanok-ural.ru    TXT    "v=DKIM1; k=rsa; p=MIIBIjAN...IDAQAB"
```
> 🔑 **Important:** the public key is taken from FastPanel → Mail → DKIM → Show public key. The private key stays **on the server only** — never copy it!

### TXT — DKIM (mail.ru)
```
mailru._domainkey.stanok-ural.ru    TXT    "v=DKIM1; k=rsa; p=MIGfMA0GCS..."
```
> Needed if mail.ru is used as a relay. Having both keys in DNS is normal.

### TXT — Google Site Verification
```
stanok-ural.ru    TXT    "google-site-verification=XqZ62iPV4HIU8fCQDUkkmLp0eZ7JEqr1oUZFRVgJ3bA"
```

---

## 3. What didn't work and how we fixed it

### ❌ Problem 1: DKIM key was truncated

**Symptom:** mail-tester showed DKIM signature error, even though the record was created in Cloudflare.

**Cause:** When copying a long DKIM key (2048 bit), the last characters were cut off. Cloudflare sometimes shows the value with `...` at the end in view mode.

**How we checked:**
Opened the record in Cloudflare for editing and checked the end of the value — it must end with `...wIDAQAB"` (or another valid base64 character before the closing quote).

**Solution:**
```bash
# On the FastPanel server: get the full key
cat /etc/opendkim/keys/stanok-ural.ru/default.txt

# Or via FastPanel UI:
# Mail → Domains → stanok-ural.ru → DKIM → Show public key
# Copy COMPLETELY, including the last character
```
After the fix — DKIM passed.

---

### ❌ Problem 2: SPF did not include server IP

**Symptom:** SPF fail — emails were rejected or went to spam.

**Cause:** The SPF record contained only `include:_spf.mail.ru`, without the explicit server IP.

**Solution:** Add `ip4:212.109.223.109` explicitly:
```
"v=spf1 ip4:212.109.223.109 include:_spf.mail.ru ~all"
```

---

### ❌ Problem 3: Proxy enabled on mail records

**Symptom:** Mail was not delivered / SMTP was not working.

**Cause:** Records `mail.*` and MX had the orange cloud (proxy enabled). Cloudflare **does not proxy SMTP traffic** (ports 25/465/587).

**Solution:** Switch all mail records to **DNS only** (grey cloud ☁️):
- `mail.stanok-ural.ru` → DNS only
- MX record → DNS only (default)
- TXT records (SPF, DKIM, DMARC) → DNS only

---

### ❌ Problem 4: Two DKIM keys — is that normal?

**Situation:** Two DKIM keys in DNS:
- `dkim._domainkey` — from FastPanel (our server)
- `mailru._domainkey` — from mail.ru (relay)

**This is normal** — both must be in DNS. WordPress sends via our server → signs with `dkim._domainkey` key.

---

## 4. Correct setup order

### Step 1: Server setup (FastPanel)

```
1. FastPanel → Mail → SMTP Settings → ensure it is enabled
2. FastPanel → Mail → Domains → stanok-ural.ru → DKIM → Enable
3. FastPanel → Mail → Domains → stanok-ural.ru → DKIM → Show public key
4. Copy the value of p=.... (without quotes around p=, only the content)
```

### Step 2: Create DNS records in Cloudflare

```
1. Log in to Cloudflare → select domain
2. DNS → Records → Add record

Creation order:
  1. SPF  (TXT for @)
  2. DKIM (TXT for dkim._domainkey)
  3. DMARC (TXT for _dmarc)
  4. MX — verify it already exists

For EACH record:
  - Proxy status: DNS only (☁️ grey)
  - TTL: Auto
```

### Step 3: WordPress setup

```
1. Install WP Mail SMTP plugin (or equivalent)
2. Settings → WP Mail SMTP → Settings:
   - From Email: noreply@stanok-ural.ru
   - Mailer: Other SMTP
   - SMTP Host: mail.stanok-ural.ru (or localhost)
   - SMTP Port: 587 (STARTTLS) or 465 (SSL)
   - Username: mailbox address
   - Password: mailbox password
3. Tools → Test Email → send test
```

### Step 4: Testing

```bash
# DNS check via command line
dig +short TXT stanok-ural.ru          # SPF
dig +short TXT dkim._domainkey.stanok-ural.ru  # DKIM
dig +short TXT _dmarc.stanok-ural.ru   # DMARC

# Online check:
# https://www.mail-tester.com  → get address → send test → result
# https://mxtoolbox.com/SuperTool.aspx → SPF/DKIM/DMARC lookup
```

---

## 5. Verification

### mail-tester.com — 10/10 ✅

All checks passed:
- ✅ SPF passes
- ✅ DKIM signature is valid
- ✅ DMARC configured
- ✅ Reverse DNS (PTR) configured
- ✅ Domain not in blocklists
- ✅ Email HTML is valid
- ✅ No spam words in subject/body

### Verification commands from server

```bash
# Check SPF
dig +short TXT stanok-ural.ru

# Check DKIM
dig +short TXT dkim._domainkey.stanok-ural.ru

# Check DMARC
dig +short TXT _dmarc.stanok-ural.ru

# MX
dig +short MX stanok-ural.ru

# Reverse DNS (PTR) — important for reputation
dig -x 212.109.223.109

# Send test email
echo "Test body" | mail -s "Test subject" your@email.com

# Check Postfix queue
mailq

# Sending logs
tail -50 /var/log/mail.log

# Check DKIM config (OpenDKIM)
opendkim-testkey -d stanok-ural.ru -s dkim -vvv
```

### How to read email headers

In Gmail: three dots → Show original. Look for:
```
Authentication-Results: mx.google.com;
   dkim=pass header.i=@stanok-ural.ru;
   spf=pass smtp.mailfrom=stanok-ural.ru;
   dmarc=pass (p=QUARANTINE)
```

---

## 6. Setup on server 222

> **TODO:** Repeat setup for the second server.

### Initial data (fill in)

```
Server IP:      2XX.XXX.XXX.222
Domain:         [DOMAIN]
Panel:          FastPanel
DNS:            Cloudflare
```

### Setup checklist

```
□ FastPanel: enable DKIM for domain
□ Copy public DKIM key from FastPanel
□ Cloudflare: create/verify A record for mail.[DOMAIN]
□ Cloudflare: create/verify MX record
□ Cloudflare: create SPF record with new IP
□ Cloudflare: create DKIM record (key from FastPanel server 222)
□ Cloudflare: create DMARC record
□ All records: DNS only (grey cloud)
□ Wait for TTL (1-5 minutes with Auto TTL in Cloudflare)
□ Verify dig for all records
□ Configure WP Mail SMTP in WordPress
□ Send test via mail-tester.com
□ Result: 10/10 ✅
```

### SPF for server 222

```
[DOMAIN]    TXT    "v=spf1 ip4:2XX.XXX.XXX.222 include:_spf.mail.ru ~all"
```

> ⚠️ **Important:** If one domain is used on two servers (not recommended), SPF can contain both IPs:
> ```
> "v=spf1 ip4:212.109.223.109 ip4:2XX.XXX.XXX.222 include:_spf.mail.ru ~all"
> ```
> But it is better to have each domain on its own server.

### DKIM for server 222

The key will **differ** from server 109 — each server generates its own key:
```
dkim._domainkey.[DOMAIN]    TXT    "v=DKIM1; k=rsa; p=[KEY FROM FASTPANEL SERVER 222]"
```

---

## 7. Useful diagnostic commands

```bash
# ==== DNS CHECKS ====

# SPF
dig +short TXT stanok-ural.ru

# DKIM
dig +short TXT dkim._domainkey.stanok-ural.ru

# DMARC
dig +short TXT _dmarc.stanok-ural.ru

# MX
dig +short MX stanok-ural.ru

# Reverse DNS (PTR)
dig -x 212.109.223.109


# ==== POSTFIX ====

# Status
systemctl status postfix

# Queue
mailq

# Logs (last 50 lines)
tail -50 /var/log/mail.log

# Test send
echo "Test body" | mail -s "Test" recipient@gmail.com

# Force queue flush
postqueue -f

# Check DKIM config
opendkim-testkey -d stanok-ural.ru -s dkim -vvv


# ==== EXIM (if used) ====

# Status
systemctl status exim4

# Logs
tail -50 /var/log/exim4/mainlog

# Config test
exim -bV


# ==== ONLINE TOOLS ====
# mail-tester.com       — comprehensive 10/10 test
# mxtoolbox.com         — DNS lookup, blacklist check
# dmarcian.com          — DMARC inspector
# dkimvalidator.com     — DKIM check
# learndmarc.com        — DMARC visualization
# google.com/postmaster — Google Postmaster Tools (domain reputation)
```

---

## 📌 Key takeaways

1. **All mail DNS records must be DNS only** (grey cloud in Cloudflare) — Cloudflare does not proxy SMTP
2. **DKIM key is taken from FastPanel** for the specific server — not from another server
3. **When copying DKIM key** check the last character — it is often truncated
4. **SPF must contain the real server IP** + include for relay services
5. **DMARC = p=quarantine** is safer than p=none, but softer than p=reject
6. **Debug order:** first SPF, then DKIM, then DMARC
7. **mail-tester.com** — best tool for final verification

---

*Documentation created: 2026-06-10 | Author: VladiMIR Bulantsev (GinCz)*
