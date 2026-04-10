# SOS — Main Server Monitoring Script

> = Rooted by VladiMIR | AI =  
> v2026-04-10

This document describes the **SOS monitoring script** for the main web server **222-DE-NetCup** (Germany, NetCup, IP: `152.53.182.222`).

The script provides a real-time full-stack snapshot: system resources, top processes, PHP-FPM pools, web traffic analysis, WP-login attack detection, Nginx, MySQL, Docker, CrowdSec bans, and service status.

---

## 🖥️ Server Info

| Parameter | Value |
|-----------|-------|
| Name | 222-DE-NetCup |
| IP | `152.53.182.222` |
| Provider | NetCup.com, Germany |
| OS | Ubuntu 24 / FASTPANEL |
| Tariff | VPS 1000 G12 (2026) |
| CPU | 4 vCore AMD EPYC-Genoa |
| RAM | 8 GB DDR5 ECC |
| Disk | 256 GB NVMe |
| Cost | 8.60 Euro/mo |

---

## 📁 File Locations

```
222/
├── sos.sh        ← main monitoring script
└── SOS.md        ← this documentation
```

On the server the repository is cloned to:
```
/root/Linux_Server_Public/
```

Script is symlinked or accessed via alias from `~/.bashrc`.

---

## ⚡ Quick Usage

```bash
sos          # last 1 hour (default)
sos3         # last 3 hours
sos24        # last 24 hours
sos120       # last 120 hours (5 days)
```

Valid time windows:
```
15m   30m   1h   3h   6h   12h   24h   120h
```

Or run directly:
```bash
bash /root/Linux_Server_Public/222/sos.sh 24h
bash /root/Linux_Server_Public/222/sos.sh 15m
```

---

## 🔗 Aliases in `~/.bashrc`

```bash
alias sos='bash /root/Linux_Server_Public/222/sos.sh 1h'
alias sos3='bash /root/Linux_Server_Public/222/sos.sh 3h'
alias sos24='bash /root/Linux_Server_Public/222/sos.sh 24h'
alias sos120='bash /root/Linux_Server_Public/222/sos.sh 120h'
```

To apply:
```bash
source /root/.bashrc
```

---

## 📊 Script Sections

| Section | What it shows |
|---------|---------------|
| **⚙️ SYSTEM** | Uptime, RAM used/free, Swap |
| **💿 DISK** | All `/dev` partitions: size, used, avail, mount |
| **🔥 TOP 10 CPU%** | Top processes by CPU usage |
| **🔍 TOP 15 RAM** | Top processes by RAM usage (MB) |
| **🧠 PHP-FPM POOLS** | Per-user pool: worker count + total RAM |
| **🚀 TOP-5 TRAFFIC** | Top access logs by request count in time window |
| **🌍 TOP-10 IPs** | Top source IPs from access logs |
| **📈 HTTP STATUS** | HTTP response code distribution, color-coded |
| **🔐 WP-LOGIN ATTACKS** | IPs hitting `wp-login.php`, color by severity |
| **🔗 NGINX** | Worker count, TCP connections, nginx_status |
| **💾 MYSQL** | Connected threads, running threads, slow queries |
| **🐳 DOCKER** | All containers with status (green=Up, red=Down) |
| **❌ CRITICAL ERRORS** | Fatal/timeout errors from all site error logs |
| **🛡️ CROWDSEC** | Total active bans + recent alerts for time window |
| **🔧 SERVICES** | Status of all key services: nginx, php, mysql, etc. |

### Load Color Logic

| Load % | Color | Meaning |
|--------|-------|---------|
| < 60% | 🟢 Green | Normal |
| 60–89% | 🟡 Yellow | High |
| ≥ 90% | 🔴 Red | Critical |

---

## 📝 Full Script Code — `sos.sh`

```bash
#!/usr/bin/env bash
clear
# = Rooted by VladiMIR | AI = | v2026-04-10
# SOS — full server monitoring script for 222-DE-NetCup (152.53.182.222)
# Usage: sos [15m|30m|1h|3h|6h|12h|24h|120h]
# Aliases: sos=1h  sos3=3h  sos24=24h  sos120=120h

TW="${1:-1h}"
case "$TW" in
  15m|30m|1h|3h|6h|12h|24h|120h) ;;
  *) echo "Usage: sos [15m|30m|1h|3h|6h|12h|24h|120h]"; exit 1 ;;
esac

G='\033[1;32m';C='\033[1;36m';Y='\033[1;33m';R='\033[1;31m';W='\033[1;37m';X='\033[0m'
have(){ command -v "$1" >/dev/null 2>&1; }
H(){ echo -e "\n${Y}==================== $1 ====================${X}"; }

# Convert time window to minutes
M=60
[[ "$TW" =~ ^([0-9]+)m$ ]] && M="${BASH_REMATCH[1]}"
[[ "$TW" =~ ^([0-9]+)h$ ]] && M="$(( ${BASH_REMATCH[1]}*60 ))"

NOW=$(date '+%Y-%m-%d %H:%M:%S')
HOST=$(hostname)
IP=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
CORES=$(nproc || echo 1)
LOAD=$(awk '{print $1,$2,$3}' /proc/loadavg)
LOAD1=$(awk '{print $1}' /proc/loadavg)
LOAD_PCT=$(awk "BEGIN{printf \"%.0f\",($LOAD1/$CORES)*100}")
[ "$LOAD_PCT" -ge 90 ] && LC="$R" || { [ "$LOAD_PCT" -ge 60 ] && LC="$Y" || LC="$G"; }

echo -e "${W}\u2554\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2557
\u2551  \ud83d\udcca SOS \u2014 ${Y}${TW}${W}  |  ${G}${NOW}${W}
\u2551  ${C}${HOST}${W} | ${G}${IP}${W} | Load: ${LC}${LOAD}${W} (${LC}${LOAD_PCT}%${W}/${CORES}c)
\u255a\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u255d${X}"

H "\u2699\ufe0f  SYSTEM"
echo -e "  ${C}Uptime:${X} $(uptime -p)"
free -h | awk '/^Mem:/{printf "  \033[1;36mRAM:\033[0m  used %s / total %s (free %s)\n",$3,$2,$4}'
free -h | awk '/^Swap:/{printf "  \033[1;36mSwap:\033[0m used %s / total %s\n",$3,$2}'

H "\ud83d\udcbf DISK"
df -h --output=source,size,used,avail,pcent,target 2>/dev/null \
  | grep -E '^(Filesystem|/dev)' \
  | awk 'NR==1{printf "  %-20s %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6;next}
         {printf "  \033[1;36m%-20s\033[0m %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6}'

H "\ud83d\udd25 TOP 10 CPU%"
ps -eo pid,user,%cpu,pmem,args --sort=-%cpu 2>/dev/null \
  | head -11 | tail -10 \
  | awk '{printf "  \033[1;36m%-7s\033[0m %-10s %5s %5s  %s\n",$1,$2,$3,$4,$5}'

H "\ud83d\udd0d TOP 15 RAM"
ps -eo pid,user,%cpu,pmem,rss,args --sort=-rss 2>/dev/null \
  | head -16 | tail -15 \
  | awk '{printf "  \033[1;36m%-7s\033[0m %-10s %5s %5s  %6.1fMB  %s\n",$1,$2,$3,$4,$5/1024,$6}'

H "\ud83e\udde0 PHP-FPM POOLS"
ps -eo user,rss,args 2>/dev/null \
  | grep 'php-fpm\|php-cgi' \
  | awk '{p=$1;r=$2;c[p]++;t[p]+=r} END{for(p in c) printf "  \033[1;36m%-26s\033[0m %4d wk  %7.1fMB\n",p,c[p],t[p]/1024}' \
  | sort -k4 -rn

H "\ud83d\ude80 TOP-5 TRAFFIC (last ${TW})"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
  -exec wc -l {} + 2>/dev/null \
  | sort -rn | head -6 \
  | awk '{printf "  %7d  %s\n",$1,$2}'

H "\ud83c\udf0d TOP-10 IPs (last ${TW})"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
  -exec tail -n 2000 {} + 2>/dev/null \
  | awk '{print $1}' | sort | uniq -c | sort -rn | head -10 \
  | awk '{printf "  %6d \u2014 %s\n",$1,$2}'

H "\ud83d\udcc8 HTTP STATUS (last ${TW})"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
  -exec tail -n 2000 {} + 2>/dev/null \
  | awk '{print $9}' | grep -E '^[0-9]{3}$' | sort | uniq -c | sort -rn | head -10 \
  | awk '{if($2~/^2/)c="\033[1;32m";else if($2~/^3/)c="\033[1;36m";else if($2~/^4/)c="\033[1;33m";else c="\033[1;31m";
          printf "  %6d \u2014 %sHTTP %s\033[0m\n",$1,c,$2}'

H "\ud83d\udd10 WP-LOGIN ATTACKS (last ${TW})"
grep -h 'wp-login.php' /var/www/*/data/logs/*access.log /var/log/nginx/*.log 2>/dev/null \
  | awk '{print $1}' | sort | uniq -c | sort -rn | head -10 \
  | awk '{c=(($1>100)?"\033[1;31m":(($1>20)?"\033[1;33m":"\033[1;37m"));
          printf "  %s%5d\033[0m  %s\n",c,$1,$2}'

H "\ud83d\udd17 NGINX"
have nginx && {
  echo -e "  ${C}Workers:${X} ${G}$(pgrep -x nginx | wc -l)${X}  TCP: ${G}$(ss -tnp state established 2>/dev/null | wc -l)${X}"
  STUB=$(curl -s --max-time 2 http://127.0.0.1/nginx_status 2>/dev/null)
  [ -n "$STUB" ] && echo "$STUB" | awk '/Active/{printf "  Active: %s\n",$3}'
}

H "\ud83d\udcbe MYSQL"
have mysql && {
  mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_connected';" 2>/dev/null \
    | awk '{printf "  \033[1;36mConnected:\033[0m \033[1;32m%s\033[0m\n",$2}'
  mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_running';" 2>/dev/null \
    | awk '{printf "  \033[1;36mRunning:\033[0m   \033[1;32m%s\033[0m\n",$2}'
  mysql -N -e "SHOW GLOBAL STATUS LIKE 'Slow_queries';" 2>/dev/null \
    | awk '{printf "  \033[1;36mSlow:\033[0m      %s\n",$2}'
}

H "\ud83d\udc33 DOCKER"
have docker && docker ps -a --format "  {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null \
  | awk '{c=($2~/Up/)?"\033[1;32m":"\033[1;31m";
          printf "  \033[1;36m%-28s\033[0m %s%s\033[0m  %s\n",$1,c,$2,$3}'

H "\u274c CRITICAL ERRORS (last ${TW})"
find /var/www/*/data/logs/ -name "*error.log" -mmin "-${M}" \
  -exec grep -iE 'fatal|Out of memory|upstream timed out|connect\(\) failed|no live upstreams' {} + 2>/dev/null \
  | tail -10

H "\ud83d\udee1\ufe0f  CROWDSEC"
have cscli && {
  BANS=$(cscli decisions list 2>/dev/null | awk 'BEGIN{c=0}/^\|/{c++}END{print (c>0?c-1:0)}')
  echo -e "  ${C}Bans:${X} ${R}${BANS}${X}"
  cscli alerts list --since "$TW" -l 10 2>/dev/null | head -12 | sed 's/^/  /'
}

H "\ud83d\udd27 SERVICES"
for SVC in nginx mariadb mysql php8.1-fpm php8.2-fpm php8.3-fpm php8.4-fpm \
           crowdsec crowdsec-firewall-bouncer netdata exim4 postfix docker ssh; do
  systemctl list-units --type=service --all 2>/dev/null | grep -q "${SVC}.service" && {
    STATE=$(systemctl is-active "$SVC" 2>/dev/null)
    [ "$STATE" = "active" ] && SC="$G" || SC="$R"
    printf "  ${C}%-35s${X} %b%s${X}\n" "$SVC" "$SC" "$STATE"
  }
done

echo -e "\n${W}\u2554\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2557
\u2551  = Rooted by VladiMIR | AI =   v2026-04-10          \u2551
\u255a\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u255d${X}"
```

---

## 🚀 Installation on 222-DE-NetCup

### Step 1 — Clone repo (first time only)
```bash
cd /root
git clone https://github.com/GinCz/Linux_Server_Public.git
```

### Step 2 — Add aliases to `~/.bashrc`
```bash
cat >> /root/.bashrc << 'EOF'

# SOS monitoring aliases
alias sos='bash /root/Linux_Server_Public/222/sos.sh 1h'
alias sos3='bash /root/Linux_Server_Public/222/sos.sh 3h'
alias sos24='bash /root/Linux_Server_Public/222/sos.sh 24h'
alias sos120='bash /root/Linux_Server_Public/222/sos.sh 120h'
EOF
source /root/.bashrc
```

### Step 3 — Test
```bash
sos          # last 1h
sos24        # last 24h
sos 15m      # last 15 minutes
```

---

## 🗓️ Changelog

| Date | Change |
|------|--------|
| 2026-04-10 | Initial script created for 222-DE-NetCup |
| 2026-04-10 | Added time-window parameter: 15m / 30m / 1h / 3h / 6h / 12h / 24h / 120h |
| 2026-04-10 | Load color: green / yellow / red based on % of cores |
| 2026-04-10 | PHP-FPM pool breakdown by user + RAM |
| 2026-04-10 | WP-login attack detection with color severity |
| 2026-04-10 | HTTP status distribution color-coded by class |

---

> = Rooted by VladiMIR | AI =  
> GitHub: https://github.com/GinCz/Linux_Server_Public
