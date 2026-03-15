#!/usr/bin/env bash
set -euo pipefail
G='\033[1;32m'; C='\033[1;36m'; Y='\033[1;33m'; R='\033[1;31m'; M='\033[1;35m'; X='\033[0m';
H=$(hostname); I=$(ip addr show|grep 'inet '|grep -v '127.0.0.1'|awk '{print $2}'|cut -d/ -f1|head -n1);
P=$(host "$I" 2>/dev/null|awk '/pointer/{print $NF}'|sed 's/\.$//'|head -n1); [ -z "$P" ]&&P="not set";
V=$(dmidecode -s system-manufacturer 2>/dev/null||echo "Unknown"); [ "$V" == "QEMU" ]&&V="KVM/QEMU";
U=$(uptime -p); CORES=$(nproc);
FREQ=$(lscpu | grep -i "CPU MHz" | awk '{print $3}' | cut -d. -f1 | head -n1); [ -z "$FREQ" ] && FREQ=$(lscpu | grep -i "Model name" | grep -oP '\d+(\.\d+)?GHz' | head -n1); [ -z "$FREQ" ] && FREQ="N/A";
f_v(){ if command -v "$1" >/dev/null 2>&1; then case "$1" in nginx) nginx -v 2>&1|cut -d/ -f2;; php) php -r "echo PHP_VERSION;" 2>/dev/null;; mysql|mariadb) "$1" -V 2>/dev/null|grep -oP '(?<=Distrib )([0-9.]+)'|head -n1;; psql) psql --version 2>/dev/null|awk '{print $3}';; sqlite3) sqlite3 --version 2>/dev/null|awk '{print $1}';; exim) exim -bV 2>/dev/null|head -n1|awk '{print $3}';; dovecot) dovecot --version 2>/dev/null|awk '{print $1}';; named) named -v 2>/dev/null|awk '{print $2}';; *) echo "yes";; esac; else echo "no"; fi; };
f_p(){ [ -f "$1" ] && echo -e "${G}Found${X}" || echo -e "${R}Missing${X}"; };
f_num(){ VAL=$(echo "$1" | tr -d '()'); printf "%'d\n" ${VAL%.*} | tr ',' '.'; };
echo -e "${Y}==================== SYSTEM INFORMATION ====================${X}";
echo -e "${C}Access:${X}    $H / ${G}IP: $I${X}";
echo -e "${C}Network:${X}   PTR: ${G}$P${X} / IPv6: $(ip -6 addr show scope global|grep inet6|awk '{print $2}'|cut -d/ -f1|head -n1||echo None)";
echo -e "${C}Provider:${X}  $V / ${C}Uptime:${X} $U";
echo -e "${Y}------------------------------------------------------------${X}";
echo -e "${C}CPU:${X}       $CORES vCore $(cat /proc/cpuinfo|grep "model name"|uniq|cut -d: -f2|xargs) @ ${G}$FREQ${X}";
echo -e "${C}RAM:${X}       ${G}$(free -h|grep Mem:|awk '{print $3"/"$2}')${X}";
echo -e "${C}Disk:${X}      ${G}$(df -h /|grep /|head -n1|awk '{print $3"/"$2" ("$5")"}')${X} (Total: $(lsblk -dn -o SIZE /dev/vda 2>/dev/null||lsblk -dn -o SIZE /dev/sda 2>/dev/null||echo N/A))${X}";
echo -e "${C}Software:${X}  $(grep PRETTY_NAME /etc/os-release|cut -d= -f2|tr -d '"') / ${Y}$([ -d /usr/local/fastpanel2 ]&&echo FASTPANEL||echo None)${X}";
echo -e "${C}Web/DNS:${X}   Nginx: $(f_v nginx) / PHP: $(f_v php) / BIND9: $(f_v named)";
echo -e "${C}Mail:${X}      Exim4: $(f_v exim) / Dovecot: $(f_v dovecot)";
echo -e "${C}Databases:${X} My/Maria: $(f_v mysql) / Postgre: $(f_v psql) / SQLite: $(f_v sqlite3)";
echo -e "${C}Crit Path:${X} DB List: $(f_p /root/structure_databases.txt) / DNS: $(f_p /root/structure_dns.txt) / Schema: $(f_p /root/db_schema.txt)";
echo -e "\n${Y}===================== BENCHMARK TEST =======================${X}";
command -v sysbench &>/dev/null || { echo -e "${Y}Installing sysbench...${X}"; apt update -qq && apt install -y sysbench -qq >/dev/null 2>&1; };
echo -ne "${M}CPU Speed:${X}   "; CPU_R=$(sysbench cpu --threads="${CORES}" --cpu-max-prime=10000 --time=5 run 2>/dev/null | grep "events per second" | awk '{print $4}'); echo -e "${G}$(f_num "$CPU_R") ev/s${X}";
echo -ne "${M}RAM Speed:${X}   "; RAM_R=$(sysbench memory --memory-block-size=1M --memory-total-size=10G run 2>/dev/null | grep "MiB/s" | awk '{print $4}'); echo -e "${G}$(f_num "$RAM_R") MB/s${X}";
TEST_FILE="$(mktemp /tmp/disk_test_file.XXXXXX)"; trap 'rm -f "$TEST_FILE"' EXIT INT TERM
echo -ne "${M}Disk I/O:${X}    "; D_W=$(dd if=/dev/zero of="$TEST_FILE" bs=64k count=16k conv=fdatasync 2>&1 | grep -oP '[0-9.]+ [MG]B/s' | tail -n1); sync; echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true; D_R=$(dd if="$TEST_FILE" of=/dev/null bs=64k 2>&1 | grep -oP '[0-9.]+ [MG]B/s' | tail -n1); echo -e "Write: ${G}${D_W}${X} / Read: ${G}${D_R}${X}";
echo -e "${Y}========================= COMPLETE =========================${X}";
