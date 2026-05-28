# configs/ — Reference Configurations

> = Rooted by VladiMIR + AI | v.2026.05.29 | github.com/GinCz =

This directory contains reference configuration files that have been tested and
applied on production servers. Each file includes detailed inline comments.

---

## Files

### `mariadb-tuning.cnf`

**Purpose:** MariaDB performance tuning for 8GB RAM shared web servers.

**Applied to:**
- 109-RU-FastVDS (212.109.223.109) — FastVDS.ru, Ubuntu 24, FastPanel
- 222-DE-NetCup (152.53.182.222) — NetCup.com, Ubuntu 24, FastPanel + Cloudflare

**Key settings:**

| Parameter | Default | Tuned | Reason |
|---|---|---|---|
| `innodb_buffer_pool_size` | 128 MB | 1 GB | Default is severely undersized for 8GB RAM |
| `innodb_buffer_pool_instances` | 1 | 2 | Reduce mutex contention at 1GB pool |
| `innodb_log_file_size` | 48 MB | 256 MB | Better write throughput for WP/CMS workloads |
| `innodb_flush_log_at_trx_commit` | 1 | 2 | OS-cache fsync reduces I/O while keeping safety |
| `query_cache_type` | 1 | 0 | Query cache deprecated, causes contention |
| `query_cache_size` | 1 MB | 0 | Disabled completely |
| `max_connections` | 151 | 50 | Each idle conn ~1MB RAM; 50 safe for shared server |

**How to apply:**
```bash
cat >> /etc/mysql/my.cnf < configs/mariadb-tuning.cnf
systemctl restart mariadb
mysql -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"
```

**Result after applying:**

| Server | RAM used (before) | RAM used (after) | Buffer pool |
|---|---|---|---|
| 109-RU-FastVDS | 5.1 GB | 3.5 GB | 128 MB → 1 GB |
| 222-DE-NetCup | 3.8 GB | 2.6 GB | 128 MB → 1 GB |

---

## Important Note — MariaDB Config File Extension

> MariaDB's `!includedir` directive in `/etc/mysql/my.cnf` only loads files
> with the `.cnf` extension. Files with `.conf` extension are silently ignored.

This was discovered on 2026-05-29 when a tuning file named `vladmir-tuning.conf`
was placed in `/etc/mysql/conf.d/` and had no effect despite correct content.

**Always use `.cnf` extension** for any file placed in `/etc/mysql/conf.d/`
or `/etc/mysql/mariadb.conf.d/`, or append settings directly to `/etc/mysql/my.cnf`.

Verify which files MariaDB actually reads:
```bash
mysql --help 2>/dev/null | grep -A1 "Default options"
```

---

*= Rooted by VladiMIR + AI | v.2026.05.29 | github.com/GinCz =*
