#!/bin/bash
# ==========================================================
# collect-from-vpn.sh — Collect IPs from ALL 9 nodes via SSH
# Run ON SERVER 222 (152.53.182.222) — master collector
# Collects CrowdSec decisions from each node, merges, deduplicates
# Pushes unified blacklist to GitHub
#
# Cron order on 222 (correct sequence):
#   0 */3 * * *  — collect-from-vpn.sh  (collect from all nodes → push GitHub)
#   30 */3 * * * — deploy-blacklist.sh  (pull from GitHub → apply ipset locally)
#
# = Rooted by VladiMIR + AI | v.2026.06.10c | github.com/GinCz =
# ==========================================================

set -eo pipefail
clear

REPO_DIR="/root/Linux_Server_Public"
BLACKLIST_TXT="$REPO_DIR/blacklist/blacklist.txt"
BLACKLIST_CSV="$REPO_DIR/blacklist/blacklist-full.csv"
DATE=$(date +%Y-%m-%d)
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')

ALL_NODES=(
  "109-RU-FastVDS:212.109.223.109"
  "EU-Alex-47:109.234.38.47"
  "EU-4Ton-237:144.124.228.237"
  "EU-Tatra-Kuma-9:144.124.232.9"
  "VPN-EU-Shahin-227:144.124.228.227"
  "EU-Stolb-AG-24:144.124.239.24"
  "VPN-EU-Pilik-178:91.84.118.178"
  "VPN-EU-ILYA-176:146.103.110.176"
  "EU-SO-38:144.124.233.38"
)

TMP_ALL=$(mktemp)
TMP_CSV=$(mktemp)

# Remote script — runs on each node, stdout=IPs, stderr=CSV lines
REMOTE_SCRIPT=$(cat <<'REMOTE'
#!/bin/bash
HN=$(hostname)
DT=$(date +%Y-%m-%d)
if command -v cscli &>/dev/null; then
  cscli decisions list -o raw 2>/dev/null | awk -F',' -v hn="$HN" -v dt="$DT" '
    NR==1{next}
    {
      ip=$3; reason=$4; dur=$9
      gsub(/^ +| +$/,"",ip)
      gsub(/^ +| +$/,"",reason)
      gsub(/^ +| +$/,"",dur)
      sub(/^[Ii]p:/,"",ip)
      if (ip=="" || ip !~ /^[0-9]/) next
      print ip
      print ip","reason","hn","dt",crowdsec,"dur > "/tmp/_vladbl_csv"
    }
  '
  if [ -f /tmp/_vladbl_csv ]; then
    cat /tmp/_vladbl_csv >&2
    rm -f /tmp/_vladbl_csv
  fi
fi
REMOTE
)

echo "================================================"
echo " All-Nodes Blacklist Collector"
echo " Master : 222-EU-NetCup (152.53.182.222)"
echo " Date   : $DATETIME"
echo "================================================"
echo ""

# ── [1] Git pull FIRST — avoid push rejection ────────────────
cd "$REPO_DIR"
git pull --rebase 2>/dev/null || {
    echo "  ⚠ git pull failed — trying reset to remote"
    git fetch origin main 2>/dev/null || true
    git reset --hard origin/main 2>/dev/null || true
}

# ── [2] Collect from local 222 ───────────────────────────────
echo "[LOCAL] 222-EU-NetCup (152.53.182.222)"
LOCAL_TMP=$(mktemp)
LOCAL_CSV=$(mktemp)

cscli decisions list -o raw 2>/dev/null | awk -F',' -v dt="$DATE" '
  NR==1{next}
  {
    ip=$3; reason=$4; dur=$9
    gsub(/^ +| +$/,"",ip)
    gsub(/^ +| +$/,"",reason)
    gsub(/^ +| +$/,"",dur)
    sub(/^[Ii]p:/,"",ip)
    if (ip=="" || ip !~ /^[0-9]/) next
    print ip > "/dev/stdout"
    print ip","reason",222-EU-NetCup,"dt",crowdsec,"dur > "/dev/stderr"
  }
' > "$LOCAL_TMP" 2> "$LOCAL_CSV" || true

LOCAL_COUNT=$(wc -l < "$LOCAL_TMP" | tr -d ' \n')
cat "$LOCAL_TMP" >> "$TMP_ALL"
cat "$LOCAL_CSV" >> "$TMP_CSV"
rm -f "$LOCAL_TMP" "$LOCAL_CSV"
echo "        $LOCAL_COUNT IPs collected"
echo ""

# ── [3] Collect from each remote node via SSH ────────────────
for NODE in "${ALL_NODES[@]}"; do
  NAME="${NODE%%:*}"
  IP="${NODE##*:}"
  printf "[NODE] %-30s " "$NAME ($IP)"

  NODE_TMP=$(mktemp)
  NODE_CSV=$(mktemp)

  {
    ssh -o ConnectTimeout=8 \
        -o StrictHostKeyChecking=no \
        -o BatchMode=yes \
        root@"$IP" \
        "cat > /tmp/_vladbl_collect.sh && bash /tmp/_vladbl_collect.sh; rm -f /tmp/_vladbl_collect.sh" \
        <<< "$REMOTE_SCRIPT" \
        > "$NODE_TMP" \
        2> "$NODE_CSV"
  } 2>/dev/null || true

  grep -E '^[0-9]' "$NODE_CSV" > "${NODE_CSV}.clean" 2>/dev/null || true
  mv "${NODE_CSV}.clean" "$NODE_CSV"

  NODE_COUNT=$(grep -cE '^[0-9]' "$NODE_TMP" 2>/dev/null | tr -d ' \n' || echo 0)
  cat "$NODE_TMP" >> "$TMP_ALL"
  cat "$NODE_CSV" >> "$TMP_CSV"
  rm -f "$NODE_TMP" "$NODE_CSV"

  if [[ "$NODE_COUNT" -gt 0 ]]; then
    echo "$NODE_COUNT IPs"
  else
    echo "0 IPs (no CrowdSec or offline)"
  fi
done

echo ""

# ── [4] Deduplicate ──────────────────────────────────────────
TOTAL=$(sort -u "$TMP_ALL" | grep -cE '^[0-9]' | tr -d ' \n' || true)
echo "Total unique IPs from all nodes: $TOTAL"

if [[ "$TOTAL" -eq 0 ]]; then
  echo "Nothing to update."
  rm -f "$TMP_ALL" "$TMP_CSV"
  exit 0
fi

# ── [5] Write blacklist.txt ──────────────────────────────────
cat > "$BLACKLIST_TXT" << HEADER
# ==========================================================
# VladiMIR IP Blacklist — Real Attack IPs
# Sources: CrowdSec on all 10 nodes of VladiMIR infrastructure
# Updated: $DATETIME | Total: $TOTAL IPs
# Repo: github.com/GinCz/Linux_Server_Public
# = Rooted by VladiMIR + AI | v.$DATE | github.com/GinCz =
# ==========================================================
HEADER
sort -u "$TMP_ALL" | grep -E '^[0-9]' >> "$BLACKLIST_TXT"

# ── [6] Write blacklist-full.csv ─────────────────────────────
{
cat << CSVHEADER
# ==========================================================
# VladiMIR IP Blacklist — Full Database (CSV)
# Columns: ip,reason,source_server,date_added,source,duration
# Updated: $DATETIME | Total: $TOTAL entries
# = Rooted by VladiMIR + AI | v.$DATE | github.com/GinCz =
# ==========================================================
ip,reason,source_server,date_added,source,duration
CSVHEADER
sort -u "$TMP_CSV" | grep -E '^[0-9]' || true
} > "$BLACKLIST_CSV"

rm -f "$TMP_ALL" "$TMP_CSV"

# ── [7] Git commit + push ────────────────────────────────────
cd "$REPO_DIR"
git add blacklist/blacklist.txt blacklist/blacklist-full.csv

if git diff --cached --quiet; then
  echo "No changes since last update — nothing to commit."
else
  git commit -m "blacklist: all-nodes update $DATE — $TOTAL unique IPs"
  git push
  echo ""
  echo "================================================"
  echo " Pushed to GitHub! ✅"
  echo " Total IPs : $TOTAL"
  echo " Updated   : $DATETIME"
  echo " URL: https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/blacklist.txt"
  echo "================================================"
fi
# = Rooted by VladiMIR + AI | v.2026.06.10c | github.com/GinCz =
