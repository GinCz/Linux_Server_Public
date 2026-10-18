# 🚨 INCIDENT POSTMORTEM: Nginx Crash on DE-222 (Cloudflare 521)
> **Target Server:** `DE-222` (`152.53.182.222`, NetCup Germany, Ubuntu 24.04 LTS)  
> **Date & Time:** Saturday, 2026-10-17 02:00:56 CEST – 08:49:53 CEST (Downtime: ~6 hours 49 minutes)  
> **Severity:** Critical (All web sites hosted on DE-222 down with Cloudflare Error 521)  
> **Author:** Anti-Gravity 157 | Vladimir Bulantsev  

---

## 1. Incident Summary
At 02:00:56 CEST on Saturday, October 17, 2026, all websites hosted on server **DE-222** became unavailable via Cloudflare, returning **HTTP 521 (Web Server Is Down)**.

Affected domains included:
- `wowflow.cz`
- `abl-metal.com`
- `autoservis-praha.eu`
- `autoservis-rychlik.cz`
- `balance-b2b.eu`
- `car-chip.eu`
- `doska-ua.ru`
- and all other vhosts hosted on DE-222.

The monitoring bot `My_WWW_bot` (powered by Uptime Kuma) raised alerts:
```text
Kuma: [wowflow.cz] [🔴 Down] Request failed with status code 521
Kuma: [abl-metal.com] [🔴 Down] Request failed with status code 521
Kuma: [autoservis-praha.eu] [🔴 Down] Request failed with status code 521
...
```

---

## 2. Root Cause Analysis (RCA)

### Chain of Events:
1. **2026-10-15 03:49:06 CEST (SSL Reissue in FastPanel):**
   - FastPanel executed automatic SSL certificate renewal for `doska-ua.ru`.
   - The new certificate and key were written to `/var/www/httpd-cert/doska-ua.ru_2026-10-15-034906.{crt,key}`.
   - The obsolete certificate `/var/www/httpd-cert/doska-ua.ru_2026-02-25-10-56_50.crt` was purged from disk.
   - **Crucial bug/failure:** The main vhost configuration file `/etc/nginx/fastpanel2-available/doski/doska-ua.ru.conf` contained customized security directives (`limit_req_zone`, `xmlrpc.php`, `wp-login.php` blocks). FastPanel was unable to cleanly overwrite the configuration file, writing the rendered template into an orphaned temporary file `/etc/nginx/fastpanel2-available/doski/doska-ua.ru.conf43819462-060d-4eb1-85fc-1b366305192e`.
   - As a result, the active vhost configuration retained references to the **deleted** certificate `doska-ua.ru_2026-02-25-10-56_50.crt`.

2. **2026-10-15 to 2026-10-17 02:00 CEST (Dormant State):**
   - Nginx continued serving traffic without interruption because the master and worker processes retained the existing certificate in memory.

3. **2026-10-17 02:00:25 CEST (Weekly Automated Maintenance):**
   - The weekly cron job executed at 02:00 every Saturday:
     ```bash
     0 2 * * 6 apt-get update -qq && apt-get upgrade -y -qq -o Dpkg::Options::="--force-confold" && apt-get autoremove -y -qq && apt-get autoclean -qq && journalctl --vacuum-time=7d >> /var/log/auto-upgrade.log 2>&1
     ```
   - Package upgrades triggered a restart of `nginx.service` at **02:00:56 CEST**.

4. **2026-10-17 02:00:58 CEST (Service Failure):**
   - On startup, Nginx ran syntax tests and immediately failed:
     ```text
     nginx: [emerg] cannot load certificate "/var/www/httpd-cert/doska-ua.ru_2026-02-25-10-56_50.crt": BIO_new_file() failed (SSL: error:80000002:system library::No such file or directory:calling fopen(/var/www/httpd-cert/doska-ua.ru_2026-02-25-10-56_50.crt, r) error:10000080:BIO routines::no such file)
     nginx: configuration file /etc/nginx/nginx.conf test failed
     ```
   - Systemd initiated an auto-restart loop every 30 seconds (`restart counter reached 57+`).
   - All inbound HTTPS/HTTP connections were refused, triggering Cloudflare 521 across all sites.

---

## 3. Resolution and Recovery Actions

1. **Identification:**
   - Logged into DE-222 via SSH from ORACLE_157.
   - Identified Nginx service status (`activating auto-restart (Result: exit-code)`).
   - Executed `nginx -t` to locate the failing file: `/etc/nginx/fastpanel2-available/doski/doska-ua.ru.conf`.

2. **Remediation:**
   - Created emergency backup:
     ```bash
     cp /etc/nginx/fastpanel2-available/doski/doska-ua.ru.conf /etc/nginx/fastpanel2-available/doski/doska-ua.ru.conf.bak.emergency_2026-10-17
     ```
   - Updated the certificate paths to the newly issued certificate:
     ```bash
     sed -i "s/doska-ua.ru_2026-02-25-10-56_50/doska-ua.ru_2026-10-15-034906/g" /etc/nginx/fastpanel2-available/doski/doska-ua.ru.conf
     ```
   - Removed orphaned FastPanel temp file:
     ```bash
     rm -f /etc/nginx/fastpanel2-available/doski/doska-ua.ru.conf43819462-060d-4eb1-85fc-1b366305192e
     ```
   - Verified configuration syntax:
     ```bash
     nginx -t
     # syntax is ok
     # test is successful
     ```
   - Restarted Nginx:
     ```bash
     systemctl restart nginx
     ```
   - Verified service state: `active (running)`.

3. **Verification:**
   - Queried all key domains directly and via Cloudflare CDN:
     - `https://wowflow.cz` -> HTTP 200 OK
     - `https://abl-metal.com` -> HTTP 200 OK
     - `https://autoservis-praha.eu` -> HTTP 302/200 OK
     - `https://autoservis-rychlik.cz` -> HTTP 301/200 OK
     - `https://balance-b2b.eu` -> HTTP 200 OK
     - `https://car-chip.eu` -> HTTP 200 OK
     - `https://doska-ua.ru` -> HTTP 200 OK
   - Uptime Kuma monitors transitioned back to Green.

---

## 4. Preventive Measures
1. **FastPanel Customizations Separation:**
   Custom server blocks and rate limiting must be placed exclusively inside `/etc/nginx/fastpanel2-sites/<user>/<domain>.includes` or `/etc/nginx/conf.d/` rather than modifying `/etc/nginx/fastpanel2-available/<user>/<domain>.conf` directly. This prevents FastPanel certificate actualizer from getting confused or leaving temporary unapplied configuration files.
2. **ACME / FastPanel Log Monitoring:**
   Add a periodic check to detect orphaned temporary files matching `/etc/nginx/fastpanel2-available/*/*.conf[0-9a-f-]*` and alert if an SSL renewal left unapplied configs.
