# Security Audit & Protection Report ??? 2026-08-25

**Infrastructure**: VladiMIR Cluster (Master Node: 222-DE-NetCup + 10 Remote Nodes)  
**Author**: VladiMIR + AI (Antigravity) | `github.com/GinCz`  
**Date**: 2026-08-25 13:05 CEST

---

## 1. Executive Summary

A comprehensive diagnostic audit (`sos 120h`) and security enforcement was conducted across all web sites and 11 network servers.

1. **[czechtoday.eu ???](https://czechtoday.eu)**:
   - Initial state: Traffic volume remained elevated (~12,556 requests / 120h) due to persistent automated scraping by `ArachnysSpider` (1,988 requests getting HTTP 200).
   - Action applied: Implemented global Nginx crawler shield (`01-bad-bots-map.conf` + `bad_bots_block.conf`).
   - Verification: `ArachnysSpider` and aggressive scrapers now receive **HTTP 403 Forbidden** instantly without hitting PHP-FPM / database. Legitimate visitors receive **HTTP 200 OK**.

2. **[car-bus-service.cz ???](https://car-bus-service.cz) / [car-bus-autoservice.cz ???](https://car-bus-autoservice.cz)**:
   - Initial state: History had 396 HTTP 502 Bad Gateway errors.
   - Audit result: **0 errors** detected in active logs (0.0% error rate). Backend and FastCGI pools are completely stable.

3. **Cluster Protection & IPGuard / vladblacklist (11 Nodes)**:
   - All 11 servers updated with `vladblacklist` ipset (125 known attack IPs/subnets).
   - `iptables` DROP rules synchronized across all nodes directly after DNS/VPN bypass rules.
   - Fail2ban configuration on 222-DE resolved and active.
   - **Zero Impact on Russian Users & VPN Clients**: All VPN ports (443, 8443, 30452, 2222, UDP) and DNS bypass rules remain untouched and prioritized before any blacklist evaluation.

---

## 2. Web Server Protection Details (DE-222)

### Nginx Bot Shield Configuration

#### File: `/etc/nginx/conf.d/01-bad-bots-map.conf`
```nginx
# ==============================================================================
#  Bad Bots & Scrapers Map | v2026-08-25 | github.com/GinCz/Linux_Server_Public
# ==============================================================================
map $http_user_agent $is_bad_crawler {
    default 0;
    ~*ArachnysSpider 1;
    ~*Bytespider     1;
    ~*SemrushBot     1;
    ~*DotBot         1;
    ~*MJ12bot        1;
    ~*MegaIndex      1;
    ~*PetalBot       1;
    ~*AhrefsBot      1;
    ~*ZoominfoBot    1;
    ~*Barkrowler     1;
    ~*DataForSeoBot  1;
    ~*SEOkicks       1;
    ~*BLEXBot        1;
}
```

#### File: `/etc/nginx/fastpanel2-includes/bad_bots_block.conf`
```nginx
# ==============================================================================
#  Bad Bots Blocker Include | v2026-08-25 | github.com/GinCz/Linux_Server_Public
# ==============================================================================
if ($is_bad_crawler = 1) {
    return 403;
}
```

### Direct Validation
```bash
# Bot Request:
curl -s -o /dev/null -w "%{http_code}\n" -H "User-Agent: Mozilla/5.0 (compatible; ArachnysSpider; +https://crawler.arachnys.com/)" -k https://152.53.182.222/ -H "Host: czechtoday.eu"
# Output: 403

# Normal User Request:
curl -s -o /dev/null -w "%{http_code}\n" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -k https://152.53.182.222/ -H "Host: czechtoday.eu"
# Output: 200
```

---

## 3. Node Synchronization Status Matrix

| Node Name | IP Address | Role | vladblacklist ipset | iptables DROP | CrowdSec Engine | Protection Status |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: |
| **222-DE-NetCup** | `152.53.182.222` | Web Master + VPN | 125 IPs | ACTIVE | ACTIVE (25 bans) | ??? OPERATIONAL |
| **109-RU-FastVDS** | `212.109.223.109` | Web Node (RU) | 125 IPs | ACTIVE | ACTIVE (65 bans) | ??? OPERATIONAL |
| **IONOS-38** | `82.223.116.38` | VPN Node | 125 IPs | ACTIVE | ACTIVE | ??? OPERATIONAL |
| **ALEX-47** | `212.34.148.51` | VPN Node | 125 IPs | ACTIVE | ACTIVE (5 bans) | ??? OPERATIONAL |
| **4TON-237** | `144.124.228.237` | VPN Node | 125 IPs | ACTIVE | ACTIVE | ??? OPERATIONAL |
| **TATRA-9** | `144.124.232.9` | VPN Node | 125 IPs | ACTIVE | ACTIVE (2 bans) | ??? OPERATIONAL |
| **SHAHIN-227** | `144.124.228.227` | VPN Node | 125 IPs | ACTIVE | ACTIVE | ??? OPERATIONAL |
| **STOLB-24** | `144.124.239.24` | VPN Node | 125 IPs | ACTIVE | ACTIVE (5 bans) | ??? OPERATIONAL |
| **PILIK-33** | `195.63.138.33` | VPN Node | 125 IPs | ACTIVE | ACTIVE | ??? OPERATIONAL |
| **ILYA-176** | `146.103.110.176` | VPN Node | 125 IPs | ACTIVE | ACTIVE | ??? OPERATIONAL |
| **SO-38** | `144.124.233.38` | VPN Node | 125 IPs | ACTIVE | ACTIVE (14 bans) | ??? OPERATIONAL |

---

## 4. Guarantee for Russian VPN Clients

- **Bypass Priority**: On all VPN nodes, rules for DNS (port 53/853), Xray / VLESS / TLS (ports 443, 8443, 30452) and SSH are placed *before* the `vladblacklist` DROP rule in `iptables`.
- **Targeted Bot Filtering**: Scraper blocks are User-Agent specific at the HTTP level; they do not apply to VPN tunnels, TCP streams, or Russian residential IP addresses.
- **Whitelist Protection**: All private and operator subnets of the infrastructure remain whitelisted in `00-wp-protection-zones.conf` and `00-whitelist.conf`.
