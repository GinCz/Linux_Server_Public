#!/usr/bin/env bash
# ==========================================================================================
#  fix_samba_global.sh — Enable unrestricted Samba access with SMB3 compatibility
# ==========================================================================================
set -euo pipefail

fix_samba_node() {
  echo "--> Configuring Samba and Firewall on local node..."
  if [ -f /etc/samba/smb.conf ]; then
    sed -i 's/server min protocol = SMB3_11/server min protocol = SMB3/g' /etc/samba/smb.conf
    sed -i 's/smb encrypt = required/smb encrypt = desired/g' /etc/samba/smb.conf
    sed -i 's/server signing = mandatory/server signing = auto/g' /etc/samba/smb.conf
    systemctl restart smbd nmbd 2>/dev/null || true
  fi

  # Clean any DROP or restricted IP rules for port 445 and 139 in iptables
  iptables-save | grep -v -- '--dport 445' | grep -v -- '--dport 139' > /tmp/iptables.clean || true
  iptables -F
  iptables-restore < /tmp/iptables.clean
  iptables -I INPUT 1 -p tcp --dport 445 -j ACCEPT
  iptables -I INPUT 2 -p tcp --dport 139 -j ACCEPT
  iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
  echo "✅ Done local."
}

if [ "${1:-}" = "--local" ]; then
  fix_samba_node
  exit 0
fi

echo "=== [1/3] Fixing Server 222 ==="
fix_samba_node

ALL_SERVERS=(
  "212.109.223.109"
  "212.34.148.51"
  "144.124.228.237"
  "144.124.232.9"
  "144.124.228.227"
  "144.124.239.24"
  "195.63.138.33"
  "146.103.110.176"
  "144.124.233.38"
  "18.195.117.12"
  "82.223.116.38"
)

echo "=== [2/3] Fixing Server 109 and all VPN Nodes ==="
for s in "${ALL_SERVERS[@]}"; do
  echo "--> Processing $s..."
  scp -o BatchMode=yes -o ConnectTimeout=5 /usr/local/bin/fix_samba_global.sh root@$s:/tmp/fix_samba.sh || continue
  ssh -o BatchMode=yes -o ConnectTimeout=5 root@$s "bash /tmp/fix_samba.sh --local && rm -f /tmp/fix_samba.sh" || echo "Warning on $s"
done

echo "=== [3/3] Verification on 222 ==="
iptables -L INPUT -n -v | head -n 6
testparm -s 2>/dev/null | grep -E 'server min protocol|smb encrypt|server signing' || true
