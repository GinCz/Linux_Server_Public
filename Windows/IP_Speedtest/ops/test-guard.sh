#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${1:-/etc/gin-ip-speedtest-guard.conf}"

if [[ ! -r "$CONFIG_PATH" ]]; then
    echo "ERROR: Guard configuration is not readable: $CONFIG_PATH" >&2
    exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_PATH"

TARGET_FILE="${WEB_ROOT%/}/ip/index.php"
BACKUP_FILE="${TARGET_FILE}.guard-test-backup"

if [[ ! -f "$TARGET_FILE" ]]; then
    echo "ERROR: Live target is missing before the self-healing test" >&2
    exit 1
fi

cleanup() {
    if [[ ! -f "$TARGET_FILE" && -f "$BACKUP_FILE" ]]; then
        mv "$BACKUP_FILE" "$TARGET_FILE"
    fi
}
trap cleanup EXIT

rm -f "$BACKUP_FILE"
mv "$TARGET_FILE" "$BACKUP_FILE"
systemctl start gin-ip-speedtest-guard.service

if [[ ! -f "$TARGET_FILE" ]]; then
    echo "ERROR: Guard did not restore the live target" >&2
    exit 1
fi

restored_hash="$(sha256sum "$TARGET_FILE" | awk '{print $1}')"
if [[ "$restored_hash" != "$EXPECTED_SHA256" ]]; then
    echo "ERROR: Restored file hash mismatch" >&2
    exit 1
fi

rm -f "$BACKUP_FILE"
trap - EXIT

echo "OK: Self-healing restored $TARGET_FILE with hash $restored_hash"
