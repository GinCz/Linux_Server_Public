#!/usr/bin/env bash
# Description: System information and hardware benchmark (CPU, RAM, Disk I/O)
set -u
G='\033[1;32m'; C='\033[1;36m'; Y='\033[1;33m'; R='\033[1;31m'; M='\033[1;35m'; X='\033[0m'
have(){ command -v "$1" >/dev/null 2>&1; }
safe(){ "$@" 2>/dev/null || true; }
H=$(hostname); I=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1); [ -z "${I:-}" ] && I=$(hostname -I 2>/dev/null | awk '{print $1}')
P="not set"; have host && P=$(host "$I" 2>/dev/null|awk '/pointer/{print $NF}'|sed 's/\.$//'|head -n1); [ -z "$P" ] && P="not set"
V="Unknown"; have dmidecode && V=$(dmidecode -s system-manufacturer 2>/dev/null|head -n1); [ "$V" = "QEMU" ] && V="KVM/QEMU"
U=$(uptime -p 2>/dev/null || uptime); CORES=$(nproc 2>/dev/null || echo 1)
FREQ=$(lscpu 2>/dev/null | awk -F: 'tolower($1)~/(cpu mhz)/{gsub(/ /,"",$2); print int($2); exit}'); [ -z "${FREQ:-}" ] && FREQ=$(lscpu 2>/dev/null | grep -oP '\d+(\.\d+)?GHz' | head -n1); [ -z "${FREQ:-}" ] && FREQ="N/A"
f_v(){ if have "$1"; then case "$1" in nginx) nginx -v 2>&1|cut -d/ -f2;; php) php -r "echo PHP_VERSION;" 2>/dev/null;; mysql|mariadb) "$1" -V 2>/dev/null|grep -oP '(?<=Distrib )([0-9.]+)'|head -n1;; psql) psql --version 2>/dev/null|awk '{print $3}';; sqlite3) sqlite3 --version 2>/dev/null|awk '{print $1}';; exim) exim -bV 2>/dev/null|head -n1|awk '{print $3}';; dovecot) dovecot --version 2>/dev/null|awk '{print $1}';; named) named -v 2>/dev/null|awk '{print $2}';; *) echo "yes";; esac; else echo "no"; fi; }
f_p(){ [ -f "$1" ] && echo -e "${G}Found${X}" || echo -e "${R}Missing${X}"; }
f_num(){ VAL=$(echo "${1:-0}" | tr -d '()'); printf "%'d\n" ${VAL%.*} 2>/dev/null | tr ',' '.' || echo "${1:-0}"; }
OS=$(grep PRETTY_NAME /etc/os-release 2>/dev/null|cut -d= -f2|tr -d '"' ); [ -z "${OS:-}" ] && OS="Unknown"
FP="None"; [ -d /usr/local/fastpanel2 ] && FP="FASTPANEL"

echo -e "${Y}==================== SYSTEM INFORMATION ====================${X}"
echo -e "${C}Access:${X}    $H / ${G}IP: ${I:-N/A}${X}"
echo -e "${C}Network:${X}   PTR: ${G}$P${X} / IPv6: $(ip -6 addr show scope global 2>/dev/null|awk '/inet6/{print $2}'|cut -d/ -f1|head -n1 || echo None)"
echo -e "${C}Provider:${X}  $V / ${C}Uptime:${X} $U"
echo -e "${Y}------------------------------------------------------------${X}"
echo -e "${C}CPU:${X}       $CORES vCore $(awk -F: '/model name/{print $2; exit}' /proc/cpuinfo 2>/dev/null|xargs) @ ${G}$FREQ${X}"
echo -e "${C}RAM:${X}       ${G}$(free -h 2>/dev/null|awk '/^Mem:/{print $3"/"$2}' || echo N/A)${X}"
ROOTDF=$(df -h / 2>/dev/null|awk 'NR==2{print $3"/"$2" ("$5")"}'); [ -z "${ROOTDF:-}" ] && ROOTDF="N/A"
TOTALDISK=$(lsblk -dn -o SIZE /dev/vda 2>/dev/null||lsblk -dn -o SIZE /dev/sda 2>/dev/null||echo N/A)
echo -e "${C}Disk:${X}      ${G}${ROOTDF}${X} (Total: ${TOTALDISK})${X}"
echo -e "${C}Software:${X}  ${OS} / ${Y}${FP}${X}"
echo -e "${C}Web/DNS:${X}   Nginx: $(f_v nginx) / PHP: $(f_v php) / BIND9: $(f_v named)"
echo -e "${C}Mail:${X}      Exim4: $(f_v exim) / Dovecot: $(f_v dovecot)"
echo -e "${C}Databases:${X} My/Maria: $(f_v mysql) / Postgre: $(f_v psql) / SQLite: $(f_v sqlite3)"
echo -e "${C}Crit Path:${X} DB List: $(f_p /root/structure_databases.txt) / DNS: $(f_p /root/structure_dns.txt) / Schema: $(f_p /root/db_schema.txt)"

echo -e "\n${Y}===================== BENCHMARK TEST =======================${X}"
have sysbench || { echo -e "${Y}Installing sysbench...${X}"; safe apt-get update -qq; safe apt update -qq; safe apt-get install -y sysbench -qq >/dev/null; safe apt install -y sysbench -qq >/dev/null; }
echo -ne "${M}CPU Speed:${X}   "; CPU_R=$(sysbench cpu --threads="${CORES}" --cpu-max-prime=10000 --time=5 run 2>/dev/null | awk -F: '/events per second/{gsub(/ /,"",$2); print $2; exit}'); echo -e "${G}$(f_num "$CPU_R") ev/s${X}"
echo -ne "${M}RAM Speed:${X}   "; RAM_R=$(sysbench memory --memory-block-size=1M --memory-total-size=2G run 2>/dev/null | awk '/MiB\/sec/{print $4; exit}'); echo -e "${G}$(f_num "$RAM_R") MB/s${X}"

TEST_FILE="$(mktemp /tmp/disk_test_file.XXXXXX 2>/dev/null || echo /tmp/disk_test_file.$$)"; trap 'rm -f "$TEST_FILE"' EXIT INT TERM
echo -ne "${M}Disk I/O:${X}    "
D_W=$(dd if=/dev/zero of="$TEST_FILE" bs=64k count=16k conv=fdatasync 2>&1 | awk '/copied/{print $(NF-1),$NF}' | tail -n1)
sync; echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
D_R=$(dd if="$TEST_FILE" of=/dev/null bs=64k 2>&1 | awk '/copied/{print $(NF-1),$NF}' | tail -n1)
echo -e "Write: ${G}${D_W:-N/A}${X} / Read: ${G}${D_R:-N/A}${X}"
echo -e "${Y}========================= COMPLETE =========================${X}"
