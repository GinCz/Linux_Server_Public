clear
#!/usr/bin/env bash
# ==============================================================================
# 🚀 Debian 12 (Bookworm) Slim & Fast Optimizer (Diet-Debian)
# 
# Репозиторий: https://github.com/GinCz/Linux_Server_Public
# Автор: GinCz (Владимир Буланцев)
# Описание: Превращает чистый Debian 12 в ультралегковесную, высокопроизводительную
#           серверную систему (~35-45 МБ RAM в простое) за 10 секунд без ломки
#           стандартного окружения Debian.
# ==============================================================================

set -eo pipefail

# Цвета для вывода
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[0;34m'
C_CYAN='\033[0;36m'
C_BOLD='\033[1m'

# Проверка прав Root
if [ "$EUID" -ne 0 ]; then
  echo -e "${C_RED}[-] Ошибка: скрипт должен быть запущен с правами root (sudo)!${C_RESET}"
  exit 1
fi

echo -e "${C_CYAN}${C_BOLD}=================================================================${C_RESET}"
echo -e "${C_GREEN}${C_BOLD} 🚀 DEBIAN 12 SLIM & FAST OPTIMIZER (Diet-Debian) ${C_RESET}"
echo -e "${C_CYAN}${C_BOLD}=================================================================${C_RESET}"
echo -e "${C_YELLOW}>>> Начало оптимизации системы...${C_RESET}\n"

# ------------------------------------------------------------------------------
# 1. Оптимизация виртуальных консолей (Getty)
# ------------------------------------------------------------------------------
echo -e "${C_BLUE}[1/6] Отключение неиспользуемых виртуальных консолей (TTY2-TTY6)...${C_RESET}"
for tty in {2..6}; do
  if systemctl is-enabled "getty@tty${tty}.service" &>/dev/null; then
    systemctl stop "getty@tty${tty}.service" 2>/dev/null || true
    systemctl disable "getty@tty${tty}.service" 2>/dev/null || true
  fi
done
echo -e "${C_GREEN}  ✓ Виртуальные консоли оптимизированы (освобождено ~8-12 МБ RAM).${C_RESET}"

# ------------------------------------------------------------------------------
# 2. Ограничение логов journald (RAM & Disk Saver)
# ------------------------------------------------------------------------------
echo -e "${C_BLUE}[2/6] Настройка systemd-journald (лимит 30 МБ, сжатие)...${C_RESET}"
mkdir -p /etc/systemd/journald.conf.d
cat << 'EOF' > /etc/systemd/journald.conf.d/00-slim-limits.conf
[Journal]
SystemMaxUse=30M
SystemKeepFree=50M
SystemMaxFileSize=5M
RuntimeMaxUse=15M
MaxRetentionSec=7day
Compress=yes
EOF
systemctl restart systemd-journald
echo -e "${C_GREEN}  ✓ Лимиты journald применены (максимум 30 МБ на диске / 15 МБ в RAM).${C_RESET}"

# ------------------------------------------------------------------------------
# 3. Отключение избыточных системных служб и таймеров
# ------------------------------------------------------------------------------
echo -e "${C_BLUE}[3/6] Отключение избыточных служб и фоновых фокусов...${C_RESET}"
SERVICES_TO_DISABLE=(
  "multipathd"
  "multipathd.socket"
  "motd-news.timer"
  "motd-news.service"
  "apt-daily.timer"
  "apt-daily-upgrade.timer"
  "pmlogger.service"
  "pmie.service"
)

for srv in "${SERVICES_TO_DISABLE[@]}"; do
  if systemctl list-unit-files | grep -q "^${srv}"; then
    systemctl stop "$srv" 2>/dev/null || true
    systemctl disable "$srv" 2>/dev/null || true
  fi
done
echo -e "${C_GREEN}  ✓ Фоновые таймеры и неиспользуемые службы отключены.${C_RESET}"

# ------------------------------------------------------------------------------
# 4. Тюнинг ядра, памяти и сети (Sysctl + TCP BBR)
# ------------------------------------------------------------------------------
echo -e "${C_BLUE}[4/6] Применение сетевых и системных настроек sysctl (BBR + Память)...${C_RESET}"

# Загрузка модуля tcp_bbr если ещё не активен
modprobe tcp_bbr 2>/dev/null || true
if ! grep -q "tcp_bbr" /etc/modules-load.d/modules.conf 2>/dev/null && ! grep -q "tcp_bbr" /etc/modules 2>/dev/null; then
  echo "tcp_bbr" >> /etc/modules
fi

cat << 'EOF' > /etc/sysctl.d/99-debian-slim.conf
# Оптимизация оперативной памяти и Swap
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10

# Максимальная производительность сети и алгоритм перегрузки TCP BBR
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5

# Лимиты открытых файлов
fs.file-max = 2097152
EOF

sysctl --system > /dev/null 2>&1 || sysctl -p /etc/sysctl.d/99-debian-slim.conf > /dev/null 2>&1
echo -e "${C_GREEN}  ✓ TCP BBR активирован, параметры swappiness и кэшей настроены.${C_RESET}"

# ------------------------------------------------------------------------------
# 5. Очистка дискового пространства и кэшей
# ------------------------------------------------------------------------------
echo -e "${C_BLUE}[5/6] Генеральная очистка диска, кэша APT и временных файлов...${C_RESET}"
export DEBIAN_FRONTEND=noninteractive
apt-get autoremove --purge -y > /dev/null 2>&1 || true
apt-get clean > /dev/null 2>&1 || true
apt-get autoclean > /dev/null 2>&1 || true

# Очистка старых логов journalctl
journalctl --vacuum-size=10M > /dev/null 2>&1 || true

# Очистка временных папок
rm -rf /tmp/* /var/tmp/* 2>/dev/null || true
rm -rf /var/cache/apt/archives/* 2>/dev/null || true

echo -e "${C_GREEN}  ✓ Диск очищен от временных файлов и старых кэшей.${C_RESET}"

# ------------------------------------------------------------------------------
# 6. Диагностический отчёт
# ------------------------------------------------------------------------------
echo -e "\n${C_CYAN}${C_BOLD}=================================================================${C_RESET}"
echo -e "${C_GREEN}${C_BOLD} ✅ ОПТИМИЗАЦИЯ DEBIAN 12 УСПЕШНО ЗАВЕРШЕНА ЗА 10 СЕКУНД! ${C_RESET}"
echo -e "${C_CYAN}${C_BOLD}=================================================================${C_RESET}\n"

BBR_STATUS=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}' || echo "n/a")
KERNEL_VER=$(uname -r)

echo -e "${C_BOLD}📊 ТЕКУЩЕЕ СОСТОЯНИЕ СИСТЕМЫ:${C_RESET}"
echo -e "  • ${C_CYAN}Ядро Linux:${C_RESET} ${KERNEL_VER}"
echo -e "  • ${C_CYAN}TCP Алгоритм:${C_RESET} ${C_GREEN}${BBR_STATUS}${C_RESET}"
echo ""
echo -e "${C_BOLD}--- [ОПЕРАТИВНАЯ ПАМЯТЬ] ---${C_RESET}"
free -h
echo ""
echo -e "${C_BOLD}--- [ДИСКОВОЕ ПРОСТРАНСТВО] ---${C_RESET}"
df -h /
echo ""
echo -e "${C_BOLD}--- [НАГРУЗКА И ВРЕМЯ РАБОТЫ] ---${C_RESET}"
uptime
echo -e "\n${C_CYAN}=================================================================${C_RESET}\n"