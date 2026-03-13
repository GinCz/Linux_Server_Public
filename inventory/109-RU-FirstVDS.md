# Audit Report for 109-RU-FirstVDS
Generated: Thu Mar 12 07:30:05 PM MSK 2026
---
## 🔍 Hidden Triggers (SSH/PAM)
## 📅 Cron Jobs
    0 * * * * /usr/local/bin/crowdsec_hourly_report.sh >/dev/null 2>&1
    0 * * * * /usr/local/bin/run_wp_cron_all_phpcli.sh >/dev/null 2>&1
    0 1 * * * flock -n /var/lock/backup.cron.lock /usr/local/bin/backup > /dev/null 2>&1
    0 21 * * * flock -n /var/lock/fight.cron.lock /usr/local/bin/fight > /dev/null 2>&1
    15 21 * * * flock -n /var/lock/domains.cron.lock /usr/local/bin/domains > /dev/null 2>&1
    0 3 * * * bash /root/scripts/core/threat_hunter.sh > /dev/null 2>&1
    */10 * * * * bash /root/scripts/core/apply_bans.sh > /dev/null 2>&1
## 📂 Custom Scripts (/usr/local/bin)
    lrwxrwxrwx 1 root root      37 Mar 12 19:30 audit -> /root/scripts/scripts/server_audit.sh
    -rwxr-xr-x 1 root root     364 Mar  5 03:14 crowdsec_hourly_report.sh
    lrwxrwxrwx 1 root root      38 Mar 12 18:40 domains -> /root/scripts/scripts/domains_check.sh
    -rwxr-xr-x 1 root root     942 Mar  9 11:36 domains_check.sh
    -rwxr-xr-x 1 root root     637 Mar  5 03:28 run_wp_cron_all_local.sh
    -rwxr-xr-x 1 root root     707 Mar  5 03:21 run_wp_cron_all_local.sh.bak.2026-03-05-032336
    -rwxr-xr-x 1 root root    1146 Mar  5 03:23 run_wp_cron_all_local.sh.bak.2026-03-05-032709
    -rwxr-xr-x 1 root root    1100 Mar  5 03:27 run_wp_cron_all_local.sh.bak.2026-03-05-032802
    -rwxr-xr-x 1 root root    1100 Mar  5 03:28 run_wp_cron_all_local.sh.bak.2026-03-05-032844
    -rwxr-xr-x 1 root root     637 Mar  5 03:28 run_wp_cron_all_local.sh.bak.2026-03-05-032859
    -rwxr-xr-x 1 root root     573 Mar  5 03:32 run_wp_cron_all_phpcli.sh
    -rwxr-xr-x 1 root root     553 Mar  5 03:29 run_wp_cron_all_phpcli.sh.bak.2026-03-05-033236
    -rwxr-xr-x 1 root root    1845 Mar  9 11:36 server_audit.sh
    -rwxr-xr-x 1 root root    1751 Feb 26 19:09 server_check.sh
    -rwxr-xr-x 1 root root    1111 Mar  1 18:07 server_monitor.sh
    -rwxr-xr-x 1 root root     474 Mar  6 23:35 tg_service_problem.sh
## 🖥️ Resources
    Disk: 56% full
    RAM: 4.8Gi/7.7Gi
## 🌐 Active Services (Samba/VPN)
    tcp   LISTEN 0      50                                     0.0.0.0:445        0.0.0.0:*    users:(("smbd",pid=1264,fd=31))                                                                                                                                                                                                                                                                                                                                    
    tcp   LISTEN 0      50                                        [::]:445           [::]:*    users:(("smbd",pid=1264,fd=29))                                                                                                                                                                                                                                                                                                                                    
