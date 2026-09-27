#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${1:-/etc/gin-ip-speedtest-guard.conf}"

if [[ ! -r "$CONFIG_PATH" ]]; then
    echo "ERROR: Guard configuration is not readable: $CONFIG_PATH" >&2
    exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_PATH"

required_vars=(DOMAIN WEB_ROOT SITE_OWNER SITE_GROUP CANONICAL_FILE EXPECTED_SHA256)
for var_name in "${required_vars[@]}"; do
    if [[ -z "${!var_name:-}" ]]; then
        echo "ERROR: Required variable is missing: $var_name" >&2
        exit 1
    fi
done

TARGET_DIR="${WEB_ROOT%/}/ip"
TARGET_FILE="$TARGET_DIR/index.php"
CACHE_DIR="$TARGET_DIR/cache"

if [[ ! -f "$CANONICAL_FILE" ]]; then
    echo "ERROR: Protected canonical file is missing: $CANONICAL_FILE" >&2
    exit 1
fi

canonical_hash="$(sha256sum "$CANONICAL_FILE" | awk '{print $1}')"
if [[ "$canonical_hash" != "$EXPECTED_SHA256" ]]; then
    echo "ERROR: Protected canonical file hash mismatch" >&2
    exit 1
fi

php -l "$CANONICAL_FILE" >/dev/null
mkdir -p "$CACHE_DIR"
chown "$SITE_OWNER:$SITE_GROUP" "$TARGET_DIR" "$CACHE_DIR"
chmod 0755 "$TARGET_DIR" "$CACHE_DIR"

current_hash="missing"
if [[ -f "$TARGET_FILE" ]]; then
    current_hash="$(sha256sum "$TARGET_FILE" | awk '{print $1}')"
fi

action="verified"
if [[ "$current_hash" != "$EXPECTED_SHA256" ]]; then
    staging_file="$TARGET_DIR/.index.php.guard-new"
    install -o "$SITE_OWNER" -g "$SITE_GROUP" -m 0644 "$CANONICAL_FILE" "$staging_file"
    mv -f "$staging_file" "$TARGET_FILE"
    action="restored"
fi

php -l "$TARGET_FILE" >/dev/null
installed_hash="$(sha256sum "$TARGET_FILE" | awk '{print $1}')"
if [[ "$installed_hash" != "$EXPECTED_SHA256" ]]; then
    echo "ERROR: Installed file hash mismatch after $action" >&2
    exit 1
fi

page_body="$(curl --silent --show-error --location --max-time 20 "https://$DOMAIN/ip/")"
page_code="$(curl --silent --show-error --location --max-time 20 --output /dev/null --write-out '%{http_code}' "https://$DOMAIN/ip/")"
ping_body="$(curl --silent --show-error --max-time 10 "https://$DOMAIN/ip/?action=ping")"

if [[ "$page_code" != "200" ]]; then
    echo "ERROR: Public endpoint returned HTTP $page_code" >&2
    exit 1
fi

if [[ "$page_body" != *"IP &amp; Speed Test"* ]] || [[ "$ping_body" != *'"status":"ok"'* ]]; then
    echo "ERROR: Public endpoint content or ping API verification failed" >&2
    exit 1
fi

logger -t gin-ip-speedtest-guard "domain=$DOMAIN action=$action hash=$installed_hash http=$page_code ping=ok"
echo "OK: domain=$DOMAIN action=$action hash=$installed_hash http=$page_code ping=ok"
