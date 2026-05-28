# FastPanel Notes — 109-RU-FastVDS

> = Rooted by VladiMIR + AI | v.2026.05.29 | github.com/GinCz =

Operational notes for FastPanel on server 109-RU-FastVDS (212.109.223.109).

---

## PHP-FPM Pool Recovery

### Symptom
A domain shows HTTP 502 Bad Gateway even though the site exists in FastPanel.
Nginx log shows:
```
connect() to unix:/var/run/DOMAIN.sock failed (2: No such file or directory)
```

### Cause
FastPanel added the domain and created the nginx vhost config, but the corresponding
PHP-FPM pool config was never created in `/opt/php84/etc/php-fpm.d/`.
This can happen if FastPanel had an error during site creation or if the pool was
accidentally deleted.

### Detection — Find All Missing Sockets
```bash
grep -rh "fastcgi_pass unix:" /etc/nginx/fastpanel2-sites/*/*.conf 2>/dev/null \
| grep -oP 'unix:\K[^;]+' | sort -u \
| while read SOCK; do
    [ -S "$SOCK" ] || echo "MISSING: $SOCK"
  done
```

### Manual Pool Creation

Replace `DOMAIN` and `USERNAME` with actual values. The `SERVICE_PORT` must be
unique across all pools — find the last used port first:

```bash
# Find last used port
grep -h 'SERVICE_PORT' /opt/php84/etc/php-fpm.d/*.conf 2>/dev/null \
| awk '{print $3}' | tr -d '"' | sort -n | tail -1
# Add 1 to get the new port
```

Pool config template `/opt/php84/etc/php-fpm.d/DOMAIN.conf`:
```ini
[DOMAIN]
user = USERNAME
group = USERNAME
listen = /var/run/DOMAIN.sock
listen.owner = USERNAME
listen.group = www-data
listen.mode = 0660

pm = dynamic
pm.max_children = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 2
pm.max_requests = 1000

php_admin_value[date.timezone] = "Europe/Moscow"
php_admin_value[display_errors] = "off"
php_admin_value[log_errors] = "On"
php_admin_value[mail.add_x_header] = "On"
php_admin_value[max_execution_time] = "120"
php_admin_value[max_input_vars] = "10000"
php_admin_value[opcache.blacklist_filename] = "/opt/opcache-blacklists/opcache-*.blacklist"
php_admin_value[opcache.max_accelerated_files] = "100000"
php_admin_value[output_buffering] = "4096"
php_admin_value[post_max_size] = "100M"
php_admin_value[sendmail_path] = "/usr/sbin/sendmail -t -i -f 'admin@DOMAIN'"
php_admin_value[session.save_path] = "/var/www/USERNAME/data/tmp"
php_admin_value[short_open_tag] = "On"
php_admin_value[upload_max_filesize] = "100M"
php_admin_value[upload_tmp_dir] = "/var/www/USERNAME/data/tmp"

env[SERVICE_HOST] = "127.0.0.1"
env[SERVICE_PORT] = "NEW_PORT"

catch_workers_output = no
access.format = "%{REMOTE_ADDR}e - [%t] \"%m %r%Q%q %{SERVER_PROTOCOL}e\" %s %{kilo}M \"%{HTTP_REFERER}e\" \"%{HTTP_USER_AGENT}e\""
access.log = /var/www/USERNAME/data/logs/DOMAIN-backend.access.log
```

After creating the file:
```bash
systemctl reload fp2-php84-fpm
# Verify socket was created
ls -la /var/run/DOMAIN.sock
# Verify HTTP response
curl -sk -o /dev/null -w "%{http_code}\n" https://DOMAIN/
```

### Known Affected Sites

| Date | Domain | Username | Action |
|---|---|---|---|
| 2026-05-29 | reklama-white.eu | reklama-white (uid=1036) | Pool created manually, HTTP 200 restored |

---

## PHP-FPM Service Name

On FastPanel with PHP 8.4, the service name is:
```
fp2-php84-fpm
```

Not `php8.4-fpm` or `php-fpm`. Always use:
```bash
systemctl status fp2-php84-fpm
systemctl reload fp2-php84-fpm
systemctl restart fp2-php84-fpm
```

---

## User Structure

Each site on FastPanel has a dedicated system user:
- User home: `/var/www/USERNAME/`
- Web root: `/var/www/USERNAME/data/www/DOMAIN/`
- Logs: `/var/www/USERNAME/data/logs/`
- Tmp: `/var/www/USERNAME/data/tmp/`
- Groups: `USERNAME`, `fastsecure`, `fastmail`

---

*= Rooted by VladiMIR + AI | v.2026.05.29 | github.com/GinCz =*
