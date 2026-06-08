clear
# = Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz =

SERVERS=(
  "144.124.239.24"   # VPN STOLB_24
  "91.84.118.178"    # VPN PILIK_178
  "146.103.110.176"  # VPN ILYA_176
  "144.124.228.227"  # VPN SHAHIN_227
  "144.124.232.9"    # VPN TATRA_9
  "144.124.228.237"  # VPN 4TON_237
  "109.234.38.47"    # VPN ALEX_47
  "144.124.233.38"   # VPN SO_38
)

SWAP_SIZE="512M"

for SERVER in "${SERVERS[@]}"; do
  echo "============================================"
  echo ">>> $SERVER"
  echo "============================================"

  ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@$SERVER bash << 'REMOTE'

    # 1. Journald лимит 100MB / 7 дней
    if ! grep -q "SystemMaxUse" /etc/systemd/journald.conf; then
      echo -e "[Journal]\nSystemMaxUse=100M\nMaxRetentionSec=7day" >> /etc/systemd/journald.conf
      systemctl restart systemd-journald
      journalctl --vacuum-size=100M
      echo "[OK] journald ограничен до 100MB"
    else
      echo "[SKIP] journald уже настроен"
    fi

    # Чистим btmp если большой
    BTMP_SIZE=$(du -sm /var/log/btmp 2>/dev/null | awk '{print $1}')
    if [ "${BTMP_SIZE:-0}" -gt 50 ]; then
      truncate -s 0 /var/log/btmp
      truncate -s 0 /var/log/btmp.1 2>/dev/null
      echo "[OK] btmp очищен (был ${BTMP_SIZE}MB)"
    fi

    # 2. Swap — только если нет
    if swapon --show | grep -q swap; then
      echo "[SKIP] Swap уже настроен: $(swapon --show | grep -v NAME)"
    else
      fallocate -l 512M /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=512
      chmod 600 /swapfile
      mkswap /swapfile
      swapon /swapfile
      if ! grep -q "/swapfile" /etc/fstab; then
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
      fi
      echo "[OK] Swap 512MB создан и активирован"
    fi

    # Статус
    echo "--- Disk: $(df -h / | tail -1 | awk '{print $3" used / "$2" total ("$5")"}')"
    echo "--- Swap: $(swapon --show 2>/dev/null | tail -1 || echo 'none')"

REMOTE

  echo ""
done

echo "============================================"
echo "ГОТОВО на всех серверах"
echo "============================================"
