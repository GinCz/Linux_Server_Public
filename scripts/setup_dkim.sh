#!/bin/bash
# = Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =
# UNIVERSAL EXIM4 DKIM SETUP FOR ALL DOMAINS
# Usage: bash setup_dkim.sh [primary_hostname]
# Example: bash setup_dkim.sh mail.stanok-ural.ru
# Works on: RU-SO-109 (212.109.223.109) and DE-EU-222 (152.53.182.222)
#
# What it does:
#   1. Finds all domains via nginx configs
#   2. Generates DKIM keys for each domain (skips if exists)
#   3. Creates /etc/exim4/dkim/keymap.txt
#   4. Creates /etc/exim4/conf.d/main/00_local_dkim (CORRECT for split config)
#   5. Sets primary_hostname in conf.d/main/01_primary_hostname
#   6. Rebuilds and restarts Exim4
#   7. Prints DNS records to add in Cloudflare
#
# NOTE: Does NOT use localmacros — that file is IGNORED in split config mode!

set -e

DKIM_DIR="/etc/exim4/dkim"
MACRO_FILE="/etc/exim4/conf.d/main/00_local_dkim"
HOSTNAME_FILE="/etc/exim4/conf.d/main/01_primary_hostname"
KEYMAP="$DKIM_DIR/keymap.txt"
PRIMARY_HOSTNAME="${1:-mail.$(hostname -f 2>/dev/null | grep -oP '[^.]+\.[^.]+$' || echo 'example.com')}"

echo "================================================================"
echo "  DKIM UNIVERSAL SETUP  |  = Rooted by VladiMIR + AI ="
echo "  primary_hostname = $PRIMARY_HOSTNAME"
echo "================================================================"
echo ""

# --- Step 1: Collect all domains from nginx ---
echo "=== Step 1: Collecting domains from nginx ==="
DOMAINS=()
while IFS= read -r line; do
    DOMAINS+=("$line")
done < <(
    grep -rh "server_name" /etc/nginx/conf.d/ /etc/nginx/sites-enabled/ 2>/dev/null \
    | grep -v "default_server\|localhost\|_\|127\.\|^#" \
    | awk '{for(i=2;i<=NF;i++) if($i~/\.[a-z]{2,}$/ && $i !~ /^\*/) print $i}' \
    | sed 's/;//g' \
    | grep -v '^$' \
    | sort -u
)

if [ ${#DOMAINS[@]} -eq 0 ]; then
    echo "  No domains via nginx — trying /etc/exim4/update-exim4.conf.conf"
    FALLBACK=$(grep "dc_other_hostnames" /etc/exim4/update-exim4.conf.conf 2>/dev/null | cut -d"'" -f2 | tr ':' '\n')
    for d in $FALLBACK; do
        [ -n "$d" ] && DOMAINS+=("$d")
    done
fi

if [ ${#DOMAINS[@]} -eq 0 ]; then
    echo "  [ERROR] No domains found! Add them manually to $KEYMAP after setup."
else
    echo "  Found ${#DOMAINS[@]} domain(s): ${DOMAINS[*]}"
fi

# --- Step 2: Create DKIM dir and generate keys ---
echo ""
echo "=== Step 2: Generating DKIM keys (selector: dkim) ==="
mkdir -p "$DKIM_DIR"
chmod 750 "$DKIM_DIR"

DNS_RECORDS=""
for DOMAIN in "${DOMAINS[@]}"; do
    KEY_FILE="$DKIM_DIR/${DOMAIN}-private.pem"
    PUB_FILE="$DKIM_DIR/${DOMAIN}-public.pem"

    if [ -f "$KEY_FILE" ]; then
        echo "  [SKIP] Key already exists: $KEY_FILE"
    else
        echo "  [GEN]  Generating 2048-bit RSA key for: $DOMAIN"
        openssl genrsa -out "$KEY_FILE" 2048 2>/dev/null
        openssl rsa -in "$KEY_FILE" -out "$PUB_FILE" -pubout 2>/dev/null
    fi

    chmod 640 "$KEY_FILE" "$PUB_FILE" 2>/dev/null || true
    chown root:Debian-exim "$KEY_FILE" 2>/dev/null || true

    # Regenerate public from private (ensure it's current)
    openssl rsa -in "$KEY_FILE" -out "$PUB_FILE" -pubout 2>/dev/null || true
    PUBKEY=$(grep -v "BEGIN\|END" "$PUB_FILE" 2>/dev/null | tr -d '\n')
    DNS_RECORDS+="  TXT  dkim._domainkey.${DOMAIN}\n  =>  v=DKIM1; k=rsa; p=${PUBKEY}\n\n"
done

# --- Step 3: Create keymap.txt ---
echo ""
echo "=== Step 3: Writing $KEYMAP ==="
if [ -f "$KEYMAP" ]; then
    cp "$KEYMAP" "${KEYMAP}.bak.$(date +%Y%m%d%H%M%S)"
    echo "  [BAK] Old keymap backed up"
fi

{ echo "# DKIM keymap: domain -> private key path"
  echo "# = Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz ="
  echo "# Format: domain<TAB>/path/to/private.pem"
  echo ""
  for DOMAIN in "${DOMAINS[@]}"; do
      echo "${DOMAIN}    $DKIM_DIR/${DOMAIN}-private.pem"
  done
} > "$KEYMAP"
chmod 640 "$KEYMAP"
echo "  [OK] keymap.txt written (${#DOMAINS[@]} entries)"

# --- Step 4: Write DKIM macros (conf.d/main — CORRECT for split config) ---
echo ""
echo "=== Step 4: Writing Exim4 DKIM macros to $MACRO_FILE ==="
cat > "$MACRO_FILE" << 'EOF'
# DKIM macros for multi-domain signing via keymap lookup
# = Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =
#
# IMPORTANT: This file must be in conf.d/main/ — NOT in localmacros!
# localmacros is IGNORED in split-config mode (FastPanel default).

DKIM_CANON = relaxed
DKIM_SELECTOR = dkim
DKIM_DOMAIN = ${lookup{${lc:${domain:$h_from:}}}lsearch{/etc/exim4/dkim/keymap.txt}{${lc:${domain:$h_from:}}}{}}
DKIM_PRIVATE_KEY = ${lookup{${lc:${domain:$h_from:}}}lsearch{/etc/exim4/dkim/keymap.txt}{$value}{0}}
DKIM_STRICT = 0
EOF
echo "  [OK] $MACRO_FILE written"

# --- Step 5: Set primary_hostname ---
echo ""
echo "=== Step 5: Setting primary_hostname = $PRIMARY_HOSTNAME ==="
cat > "$HOSTNAME_FILE" << EOF
# Override SMTP HELO hostname for Exim only.
# System hostname stays as-is — NOT changed.
# = Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =
primary_hostname = $PRIMARY_HOSTNAME
EOF
echo "  [OK] $HOSTNAME_FILE written"

# --- Step 6: Rebuild and restart ---
echo ""
echo "=== Step 6: Rebuild and restart Exim4 ==="
update-exim4.conf
systemctl restart exim4
sleep 2
if systemctl is-active --quiet exim4; then
    echo "  [OK] Exim4 running"
else
    echo "  [FAIL] Exim4 failed!"
    journalctl -u exim4 -n 20 --no-pager
    exit 1
fi

# --- Step 7: Verify macros are visible ---
echo ""
echo "=== Step 7: Verify DKIM macros ==="
exim4 -bP macro DKIM_DOMAIN 2>/dev/null && echo "  [OK] DKIM_DOMAIN macro visible" || echo "  [WARN] DKIM_DOMAIN not found"
exim4 -bP macro DKIM_PRIVATE_KEY 2>/dev/null && echo "  [OK] DKIM_PRIVATE_KEY macro visible" || echo "  [WARN] DKIM_PRIVATE_KEY not found"

# --- Step 8: Print DNS records ---
echo ""
echo "================================================================"
echo "  ADD THESE DNS RECORDS IN CLOUDFLARE / DNS:"
echo "================================================================"
echo ""
echo "  1) A-record (for PTR/rDNS match):"
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
echo "     Type: A | Name: $PRIMARY_HOSTNAME | Value: $SERVER_IP"
echo ""
echo "  2) DKIM TXT records (one per domain):"
echo -e "$DNS_RECORDS"
echo "  3) SPF (if not already set):"
echo "     Type: TXT | Name: @ | v=spf1 ip4:$SERVER_IP include:_spf.mail.ru ~all"
echo ""
echo "================================================================"
echo ""
echo "After DNS propagation (~1-5 min on Cloudflare), test with:"
echo "  echo 'Test' | mail -s 'DKIM Test' <your-mail-tester-address>"
echo "  https://www.mail-tester.com"
echo ""
echo "IMPORTANT — Cloudflare DNS tips:"
echo "  - Paste the key as ONE string, no spaces"
echo "  - Key must end with ...IDAQAB (last 6 chars of RSA-2048 pubkey)"
echo "  - Cloudflare may split into chunks — that's OK, but check no spaces added"
echo ""
echo "= Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz ="
