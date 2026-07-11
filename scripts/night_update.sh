#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TG_CFG="/root/.tg_config"
LOG="/var/log/night_update.log"
STAMP="$(date '+%F %T')"
HOST_SHORT="$(hostname -s 2>/dev/null || hostname)"

# Expected file format:
#   Content: TG_TOKEN="..." TG_CHAT="..."
#   Deployed to all 10 servers — see scripts/README.md
if [[ -f "$TG_CFG" ]]; then
  # shellcheck disable=SC1090
  source "$TG_CFG"
fi

# Telegram credentials — loaded from file on server, not from repo
TG_TOKEN="${TG_TOKEN:-}"
TG_CHAT="${TG_CHAT:-}"

log() {
  printf '%s | %s\n' "$STAMP" "$*" | tee -a "$LOG"
}

tg() {
  local text="$1"
  [[ -n "$TG_TOKEN" && -n "$TG_CHAT" ]] || return 0
  curl -fsS -m 20 -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -d chat_id="$TG_CHAT" \
    --data-urlencode text="$text" \
    -d parse_mode=HTML >/dev/null || true
}

# Services that make noise but are not real errors
IGNORE_FAILED_RE='(apparmor|console-setup|keyboard-setup|networkd-dispatcher|fwupd-refresh|motd-news|ua-reboot-cmds|apt-news|esm-cache)'

failed_services() {
  systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}' | grep -Ev "$IGNORE_FAILED_RE" || true
}

needs_reboot() {
  [[ -f /var/run/reboot-required ]] && return 0
  needs-restarting -r >/dev/null 2>&1 && return 0 || true
  return 1
}

server_profile() {
  case "$HOST_SHORT" in
    *222*|*de*|*netcup*) echo "sites" ;;
    *109*|*ru*|*vds*) echo "sites" ;;
    *) echo "vpn" ;;
  esac
}

run_updates() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get -o Dpkg::Options::=--force-confold -y full-upgrade
  apt-get -y autoremove --purge
  apt-get -y autoclean
}

# Failed services — filter system noise
report_failed() {
  local failed
  failed="$(failed_services)"
  [[ -z "$failed" ]] && return 0
  log "Failed services detected: $(echo "$failed" | xargs)"
  tg "⚠️ <b>${HOST_SHORT}</b> — failed services detected: <code>$(echo "$failed" | xargs)</code>"
}

rotate_log() {
  [[ -f "$LOG" ]] || return 0
  local size
  size=$(stat -c '%s' "$LOG" 2>/dev/null || echo 0)
  # Rotate this log if > 10MB
  if (( size > 10 * 1024 * 1024 )); then
    mv "$LOG" "${LOG}.$(date +%F-%H%M%S)"
    touch "$LOG"
    chmod 600 "$LOG"
  fi
}

cleanup_tmp() {
  # Clean up tmp
  find /tmp -xdev -mindepth 1 -mtime +7 -print0 2>/dev/null | xargs -0r rm -rf --
}

cleanup_logs() {
  # Clean up logs
  journalctl --vacuum-time=14d >/dev/null 2>&1 || true
}

main() {
  mkdir -p "$(dirname "$LOG")"
  touch "$LOG"
  chmod 600 "$LOG"
  rotate_log

  local profile dow
  profile="$(server_profile)"
  dow="$(date +%u)"

  # vpn   — Wednesday (3) and Saturday (6)
  # sites — Saturday only (6)
  if [[ "$profile" == "vpn" ]]; then
    [[ "$dow" =~ ^(3|6)$ ]] || exit 0
  else
    [[ "$dow" == "6" ]] || exit 0
  fi

  log "Starting nightly maintenance on ${HOST_SHORT} (${profile})"
  run_updates
  cleanup_tmp
  cleanup_logs
  report_failed

  if needs_reboot; then
    if [[ "$profile" == "vpn" ]]; then
      # VPN — always reboot
      tg "🔄 <b>${HOST_SHORT}</b> — nightly update OK, rebooting"
      log "Reboot required, rebooting now"
      /sbin/reboot
    else
      # SITES — never reboot automatically, only TG notification if needed
      tg "🔄 <b>${HOST_SHORT}</b> — update OK, <b>manual reboot required</b>"
      log "Reboot required, manual reboot requested"
    fi
  else
    tg "✅ <b>${HOST_SHORT}</b> — nightly update OK"
    log "Nightly maintenance finished without reboot"
  fi
}

main "$@"
