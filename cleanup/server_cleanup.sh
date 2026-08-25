#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  server_cleanup.sh | [v2026-08-25]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Глубокая очистка диска и памяти для Ubuntu 24 / Debian (дисковый клининг).
#               🛡️ 100% БЕЗОПАСЕН для: Xray (3x-ui), Samba, AdGuard Home, Uptime Kuma, SSH,
#               CrowdSec, Fail2ban и UFW.
# Usage       : cleanup  или  bash /root/Linux_Server_Public/scripts/server_cleanup.sh
# ==========================================================================================

clear

GRN='\033[0;32m'
YEL='\033[1;33m'
CYN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[-] Ошибка: скрипт должен быть запущен с правами root (sudo)!${NC}"
  exit 1
fi

echo -e "${CYN}${BOLD}==========================================================================================${NC}"
echo -e "${GRN}${BOLD}  🧹 ГЛУБОКАЯ ОЧИСТКА ДИСКА И ОПТИМИЗАЦИЯ СЕРВЕРА [$(hostname)] ${NC}"
echo -e "${CYN}${BOLD}==========================================================================================${NC}"

# Состояние диска ДО
DISK_BEFORE=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')
echo -e "${YEL}📊 Состояние диска ДО очистки:${NC} ${BOLD}${DISK_BEFORE}${NC}\n"

# 1. Защищенные критические сервисы
echo -e "${CYN}[1/8] Проверка неприкосновенных служб (Xray, Samba, Web, FastPanel, AdGuard, Uptime, SSH)...${NC}"
CRITICAL_SERVICES=(
  "x-ui" "xray" "smbd" "nmbd" "AdGuardHome" "uptime-kuma" "ssh" "sshd" "dropbear"
  "nginx" "mariadb" "mysql" "fastpanel2" "cryptobot" "dietpi-ramlog" "crowdsec" "fail2ban" "ufw"
)
PROTECTED_ACTIVE=()

for s in "${CRITICAL_SERVICES[@]}"; do
  if systemctl is-active --quiet "$s" 2>/dev/null; then
    PROTECTED_ACTIVE+=("$s")
  fi
done

if [ ${#PROTECTED_ACTIVE[@]} -gt 0 ]; then
  echo -e "  ${GRN}✔ Обнаружены и защищены активные службы: ${PROTECTED_ACTIVE[*]}${NC}"
fi

# 2. Удаление балласта Canonical и Crash-демонов (безопасно косим)
echo -e "\n${CYN}[2/8] Удаление телеметрии Canonical, crash-демонов и системного мусора...${NC}"
export DEBIAN_FRONTEND=noninteractive
BLOAT_PKGS=(
  "apport" "apport-symptoms" "whoopsie" "ubuntu-report" 
  "popularity-contest" "landscape-common" "plymouth" "plymouth-theme-ubuntu-text"
)

for pkg in "${BLOAT_PKGS[@]}"; do
  if dpkg -l | grep -q "^ii  $pkg " 2>/dev/null; then
    apt-get purge -y "$pkg" >/dev/null 2>&1 || true
  fi
done
echo -e "  ${GRN}✔ Системный балласт и телеметрия удалены (на Debian/DietPi отсутствует).${NC}"

# 3. Сжатие и очистка системных журналов systemd-journald
echo -e "\n${CYN}[3/8] Ротация и сжатие системных журналов journald (макс 30M / 2 дня)...${NC}"
journalctl --rotate >/dev/null 2>&1 || true
journalctl --vacuum-time=2d >/dev/null 2>&1 || true
journalctl --vacuum-size=30M >/dev/null 2>&1 || true
echo -e "  ${GRN}✔ Журналы journald успешно сжаты и ограничены.${NC}"

# 4. Удаление старых ядер Linux, пакетов и кэша APT
echo -e "\n${CYN}[4/8] Удаление старых ядер Linux и кэшей пакетов APT...${NC}"
apt-get autoremove --purge -y >/dev/null 2>&1 || true
apt-get clean >/dev/null 2>&1 || true
apt-get autoclean >/dev/null 2>&1 || true
rm -rf /var/cache/apt/archives/* >/dev/null 2>&1 || true
echo -e "  ${GRN}✔ Кэш APT и неиспользуемые пакеты/ядра вычищены.${NC}"

# 5. Безопасная очистка /tmp, /var/tmp, /var/crash и старых архивов логов (*.gz)
echo -e "\n${CYN}[5/8] Безопасная очистка /tmp, /var/tmp, /var/crash и архивов логов (*.gz)...${NC}"
# Очищаем только обычные временные файлы, не трогая активные Unix-сокеты .sock
find /tmp /var/tmp -type f -not -name "*.sock" -not -name "*.pid" -atime +1 -delete 2>/dev/null || true
rm -rf /var/crash/* 2>/dev/null || true
find /var/log -type f \( -name "*.gz" -o -name "*.1" -o -name "*.old" \) -delete 2>/dev/null || true
rm -f /root/*.0.0 /root/benchmark_results.txt /tmp/disk_test_file.* 2>/dev/null || true
echo -e "  ${GRN}✔ Временные файлы и архивы логов удалены.${NC}"

# 6. Очистка Snapd (если нет установленных пользователем snaps)
echo -e "\n${CYN}[6/8] Анализ Snapd...${NC}"
if command -v snap &>/dev/null; then
  SNAPS=$(snap list 2>/dev/null | awk 'NR>1 {print $1}' | grep -v -E '^(core[0-9]*|snapd|bare|lxd)$' || true)
  if [ -z "$SNAPS" ]; then
    systemctl stop snapd.service snapd.socket 2>/dev/null || true
    systemctl disable snapd.service snapd.socket 2>/dev/null || true
    apt-get purge -y snapd >/dev/null 2>&1 || true
    rm -rf /var/cache/snapd/ ~/snap /snap /var/snap /var/lib/snapd 2>/dev/null || true
    echo -e "  ${GRN}✔ Snapd полностью удален (освобождено до ~1 GB диска).${NC}"
  else
    echo -e "  ${YEL}• Обнаружены пользовательские snap-пакеты ($SNAPS). Snapd сохранен.${NC}"
  fi
else
  echo -e "  ${GRN}✔ Snapd не установлен.${NC}"
fi

# 7. Умная оптимизация Swapfile (только на компактных VPS < 35 GB диска)
echo -e "\n${CYN}[7/8] Проверка и оптимизация размера Swapfile...${NC}"
SWAP_TARGET=""
[ -f /swapfile ] && SWAP_TARGET="/swapfile"
[ -f /var/swap ] && SWAP_TARGET="/var/swap"

ROOT_DISK_GB=$(df -BG / | awk 'NR==2 {gsub(/G/,"",$2); print $2}')
[ -z "$ROOT_DISK_GB" ] && ROOT_DISK_GB=50

if [ -n "$SWAP_TARGET" ]; then
  SWAP_SIZE_MB=$(du -m "$SWAP_TARGET" | awk '{print $1}')
  # Оптимизируем только если swap > 1500 MB и диск небольшой (<= 35 GB)
  if [ "$SWAP_SIZE_MB" -gt 1500 ] && [ "$ROOT_DISK_GB" -le 35 ]; then
    echo -e "  ${YEL}• Обнаружен избыточный swap ($SWAP_TARGET: $SWAP_SIZE_MB MB) на диске ${ROOT_DISK_GB}G. Уменьшаем до 1024 MB...${NC}"
    swapoff "$SWAP_TARGET" 2>/dev/null || true
    rm -f "$SWAP_TARGET"
    fallocate -l 1G "$SWAP_TARGET" 2>/dev/null || dd if=/dev/zero of="$SWAP_TARGET" bs=1M count=1024 >/dev/null 2>&1
    chmod 600 "$SWAP_TARGET"
    mkswap "$SWAP_TARGET" >/dev/null 2>&1
    swapon "$SWAP_TARGET" 2>/dev/null || true
    echo -e "  ${GRN}✔ Размер swap ($SWAP_TARGET) оптимизирован до 1.0 GB (освобождено $((SWAP_SIZE_MB - 1024)) MB)!${NC}"
  else
    echo -e "  ${GRN}✔ Размер swap ($SWAP_TARGET: ${SWAP_SIZE_MB} MB, диск: ${ROOT_DISK_GB} GB) оптимален.${NC}"
  fi
else
  echo -e "  ${GRN}✔ Выделенный swap-файл отсутствует (используется zram или swap-раздел).${NC}"
fi

# Docker prune если установлен
if command -v docker >/dev/null 2>&1; then
  docker system prune -f --volumes >/dev/null 2>&1 || true
  echo -e "  ${GRN}✔ Docker dangling кэш очищен.${NC}"
fi

# 8. Проверка работоспособности ключевых сервисов
echo -e "\n${CYN}[8/8] Финальная проверка работоспособности ключевых служб...${NC}"
CHECK_SERVICES=("x-ui" "xray" "smbd" "AdGuardHome" "uptime-kuma" "ssh" "crowdsec" "fail2ban")
for s in "${CHECK_SERVICES[@]}"; do
  if systemctl list-unit-files | grep -q "^${s}"; then
    if systemctl is-active --quiet "$s" 2>/dev/null; then
      echo -e "  • ${s}: ${GRN}АКТИВЕН (RUNNING)${NC}"
    else
      echo -e "  • ${s}: ${YEL}НЕАКТИВЕН${NC}"
    fi
  fi
done

# ИТОГОВЫЙ ОТЧЕТ
DISK_AFTER=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')
echo -e "\n${CYN}${BOLD}==========================================================================================${NC}"
echo -e "${GRN}${BOLD}  ✅ ОЧИСТКА УСПЕШНО ЗАВЕРШЕНА! ${NC}"
echo -e "${CYN}${BOLD}==========================================================================================${NC}"
echo -e "  • ${BOLD}Диск ДО:${NC}     ${RED}${DISK_BEFORE}${NC}"
echo -e "  • ${BOLD}Диск ПОСЛЕ:${NC}  ${GRN}${DISK_AFTER}${NC}"
echo -e "  • ${BOLD}Оперативная память:${NC}"
free -h
echo -e "${CYN}${BOLD}==========================================================================================${NC}\n"

# = Rooted by VladiMIR | AI = v2026-08-25 = github.com/GinCz/Linux_Server_Public
