#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 4 ]]; then
    echo "Usage: $0 DOMAIN WEB_ROOT SITE_OWNER SITE_GROUP" >&2
    exit 2
fi

DOMAIN="$1"
WEB_ROOT="$2"
SITE_OWNER="$3"
SITE_GROUP="$4"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CANONICAL_DIR="/usr/local/share/gin-ip-speedtest"
CANONICAL_FILE="$CANONICAL_DIR/index.php"
CONFIG_FILE="/etc/gin-ip-speedtest-guard.conf"

for required_file in index.php gin-ip-speedtest-guard.sh test-guard.sh gin-ip-speedtest-guard.service gin-ip-speedtest-guard.timer; do
    if [[ ! -f "$SCRIPT_DIR/$required_file" ]]; then
        echo "ERROR: Staged file is missing: $required_file" >&2
        exit 1
    fi
done

php -l "$SCRIPT_DIR/index.php" >/dev/null
expected_hash="$(sha256sum "$SCRIPT_DIR/index.php" | awk '{print $1}')"

install -d -o root -g root -m 0755 "$CANONICAL_DIR"
install -o root -g root -m 0644 "$SCRIPT_DIR/index.php" "$CANONICAL_FILE"
install -o root -g root -m 0755 "$SCRIPT_DIR/gin-ip-speedtest-guard.sh" /usr/local/sbin/gin-ip-speedtest-guard
install -o root -g root -m 0755 "$SCRIPT_DIR/test-guard.sh" /usr/local/sbin/gin-ip-speedtest-guard-self-test
install -o root -g root -m 0644 "$SCRIPT_DIR/gin-ip-speedtest-guard.service" /etc/systemd/system/gin-ip-speedtest-guard.service
install -o root -g root -m 0644 "$SCRIPT_DIR/gin-ip-speedtest-guard.timer" /etc/systemd/system/gin-ip-speedtest-guard.timer

cat >"$CONFIG_FILE" <<EOF
DOMAIN="$DOMAIN"
WEB_ROOT="$WEB_ROOT"
SITE_OWNER="$SITE_OWNER"
SITE_GROUP="$SITE_GROUP"
CANONICAL_FILE="$CANONICAL_FILE"
EXPECTED_SHA256="$expected_hash"
EOF
chown root:root "$CONFIG_FILE"
chmod 0644 "$CONFIG_FILE"

systemctl daemon-reload
systemctl enable --now gin-ip-speedtest-guard.timer
systemctl start gin-ip-speedtest-guard.service
if [[ "$(systemctl show gin-ip-speedtest-guard.service --property=Result --value)" != "success" ]]; then
    systemctl --no-pager --full status gin-ip-speedtest-guard.service >&2 || true
    exit 1
fi
systemctl is-enabled gin-ip-speedtest-guard.timer
systemctl is-active gin-ip-speedtest-guard.timer
systemctl show gin-ip-speedtest-guard.service --property=Result --property=ExecMainStatus --no-pager
systemctl --no-pager --full list-timers gin-ip-speedtest-guard.timer
