# CrowdSec — Security Setup & Attack Analysis

> = Rooted by VladiMIR | AI =  
> v2026-04-10

This directory documents the full CrowdSec configuration, attack investigation, and custom scenarios deployed on the **222-DE-NetCup** server (Germany, NetCup, IP: `152.53.182.222`) and the **VPN-EU-Tatra-9** node (IP: `144.124.232.9`).

---

## 📁 Structure

```
VPN/crowdsec/
├── README.md                          # This file — full session log & explanation
├── scenarios/
│   ├── custom-wp-login-bf-any.yaml    # WP-login brute force (any HTTP status)
│   └── custom-slow-scanner.yaml      # Slow backup/config file scanner
└── parsers/
    └── my_whitelist.yaml              # Trusted IPs whitelist
```

---

## 🖥️ Server Overview

| Parameter | 222-DE-NetCup | VPN-EU-Tatra-9 |
|-----------|--------------|----------------|
| IP | `152.53.182.222` | `144.124.232.9` |
| Provider | NetCup.com (Germany) | (VPN node) |
| OS | Ubuntu 24 / FASTPANEL | Ubuntu 22 (Jammy) |
| Role | Main web server | VPN / monitoring node |
| CrowdSec | Pre-installed | Installed 2026-04-10 |

---

## 🔍 Investigation Summary (2026-04-10)

### Problem

CrowdSec was running on 222-DE-NetCup but several active attackers were **not being banned automatically**:

| IP | Attack Type | Requests | Root Cause |
|----|------------|----------|------------|
| `141.98.11.120` | WP-login brute force | 1,033 × HTTP 404 | Scenario only matched HTTP 200 |
| `34.186.187.208` | Backup/config scanner | 500+ requests | Worked too slowly to trigger threshold |
| `91.234.25.245` | WP-login (HTTP 200) | 27 requests | Same scenario issue |
| `178.219.56.117` | WP-login (HTTP 200) | 35 requests | Same scenario issue |
| `45.32.149.252` | WP-login (HTTP 200) | 25 requests | Same scenario issue |

### Root Causes Found

1. **`crowdsecurity/http-bf-wordpress_bf`** — filter was `evt.Meta.http_status == '200'` only. Attackers receiving 404 were completely invisible to CrowdSec.
2. **`crowdsecurity/http-sensitive-files`** — threshold of 5 requests per 5 seconds. The scanner at `34.186.187.208` worked slowly (1 req per few seconds), bypassing the threshold.
3. **VPN-EU-Tatra-9** had **NO CrowdSec installed** — 5,561 SSH brute force attempts per day were completely unprotected.

### Additional Findings

- `185.177.72.12` — already auto-banned by CrowdSec (`http-crawl-non_statics`, 721 req/hour) ✅
- `2.57.122.196` / `2.57.121.112` — appeared in SSH connections on Tatra9; confirmed as brute-forcers, auto-banned within seconds after CrowdSec install ✅
- `144.124.232.9` was in the **whitelist as a trusted VPN node** — all its traffic was whitelisted. Confirmed legitimate (Uptime Kuma monitoring). No action needed.

---

## ✅ Actions Taken

### On 222-DE-NetCup

1. Created `custom/wp-login-bf-any` scenario — catches WP-login brute force regardless of HTTP status
2. Created `custom/slow-scanner` scenario — catches slow backup/config scanners (3 requests per 2 minutes)
3. Manually banned 5 active attacking IPs (48h ban)
4. Reloaded CrowdSec — all 3 custom scenarios confirmed active

### On VPN-EU-Tatra-9

1. Installed CrowdSec `1.7.7` + `crowdsec-firewall-bouncer-iptables 0.0.34`
2. Installed collections: `crowdsecurity/linux`, `crowdsecurity/nginx`, `crowdsecurity/http-cve`
3. Copied whitelist from 222-DE-NetCup
4. Copied both custom scenarios
5. **Result: 8 IPs auto-banned within 10 seconds of startup**

### Auto-ban Configuration

Both servers use `profiles.yaml` with:
```yaml
decisions:
  - type: ban
    duration: 168h   # 7 days
```

Bouncer: `cs-firewall-bouncer` — bans applied via **iptables/nftables** directly, no Nginx restart needed.

---

## 📊 CrowdSec Metrics (222-DE-NetCup, 2026-04-10)

Top traffic sources by lines read:

| Site | Lines Read | Poured to Bucket |
|------|-----------|------------------|
| `ekaterinburg-sro.eu` (frontend) | 5,570 | 1,290 |
| `ekaterinburg-sro.eu` (backend) | 5,570 | 193 |
| `crypto.gincz.com` (frontend) | 59 | 48 |
| `czechtoday.eu` (frontend) | 49 | 45 |
| `svetaform.eu` (frontend) | 71 | 131 |

> Note: `Lines poured to bucket > Lines read` for `svetaform.eu` is normal — one HTTP request can trigger multiple scenario buckets.

---

## 🔐 Active Decisions (sample, 2026-04-10)

| IP | Country | Reason | Duration |
|----|---------|--------|----------|
| `2.57.122.196` | RO (Unmanaged Ltd) | ssh-bf | auto 168h |
| `141.98.11.120` | — | WP-login 1033×404 | manual 48h |
| `34.186.187.208` | — | Backup scanner 500+ | manual 48h |
| `91.234.25.245` | — | WP-login HTTP200 | manual 48h |
| `185.177.72.12` | FR | http-crawl-non_statics | auto 168h |
| `176.227.240.94` | IN | http-admin-interface-probing | auto 168h |
