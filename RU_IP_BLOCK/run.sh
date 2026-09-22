#!/usr/bin/env bash
set -euo pipefail

for tool in curl python3 mktemp; do
    command -v "$tool" >/dev/null 2>&1 || { printf 'Required command not found: %s\n' "$tool" >&2; exit 2; }
done
python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 2)' || { printf 'Python 3.8+ is required.\n' >&2; exit 2; }
umask 077
work_dir="$(mktemp -d)"
trap 'rm -rf -- "$work_dir"' EXIT
curl --proto '=https' --tlsv1.2 -fsSL --connect-timeout 10 --max-time 60 \
    https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/RU_IP_BLOCK/monitor.py \
    -o "$work_dir/monitor.py"

python3 "$work_dir/monitor.py" "$@"
