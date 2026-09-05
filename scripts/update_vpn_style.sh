#!/usr/bin/env bash
# ==========================================================================================
#  update_vpn_style.sh — Update load & style on all VPN Servers
# ==========================================================================================
# Description : Performs 'load' (git pull latest repo & style binary) then applies 'style'
#               with profile=VPN(1), Header=Sky Blue(1), PS1=Bright Green(3), Mode=UPDATE(2)
# = Rooted by VladiMIR | AI =
# ==========================================================================================
set -u

VPN_NODES=(
  "212.34.148.51:ALEX_51"
  "144.124.228.237:4TON_237"
  "144.124.232.9:TATRA_9"
  "144.124.228.227:SHAHIN_227"
  "144.124.239.24:STOLB_24"
  "195.63.138.33:PILIK_33"
  "146.103.110.176:ILYA_176"
  "144.124.233.38:SO_38"
  "18.195.117.12:AWS_12"
  "82.223.116.38:IONOS_38"
)

SSH_OPTS="-o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no"

echo "================================================================="
echo "   UPDATING LOAD & STYLE ON ALL VPN NODES"
echo "   Settings: Profile=VPN | Header=Sky Blue | Prompt=Bright Green"
echo "================================================================="
echo

SUCCESS_COUNT=0
FAIL_COUNT=0

for entry in "${VPN_NODES[@]}"; do
  IP="${entry%%:*}"
  NAME="${entry##*:}"

  echo "-----------------------------------------------------------------"
  echo ">>> Processing [${NAME}] (${IP})..."

  # Check SSH connectivity
  if ! ssh ${SSH_OPTS} "root@${IP}" "hostname" >/dev/null 2>&1; then
    echo "❌ SSH connection failed to ${NAME} (${IP})"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    continue
  fi

  HN=$(ssh ${SSH_OPTS} "root@${IP}" "hostname" 2>/dev/null)
  echo "    Connected: Hostname='${HN}'"

  # Step 1: LOAD (git pull / clone, update binaries)
  echo "    [1/2] Running LOAD (updating repository and binaries)..."
  ssh ${SSH_OPTS} "root@${IP}" "bash -s" << 'LOAD_CMD'
    if [ ! -d /root/Linux_Server_Public/.git ]; then
      git clone https://github.com/GinCz/Linux_Server_Public.git /root/Linux_Server_Public >/dev/null 2>&1
    else
      cd /root/Linux_Server_Public && git fetch origin main >/dev/null 2>&1 && git reset --hard origin/main >/dev/null 2>&1
    fi

    # Update style & theme binary
    cat << 'STYLEEOF' > /usr/local/bin/style
#!/usr/bin/env bash
if [ -f /root/Linux_Server_Public/scripts/new_server_install.sh ]; then
    bash /root/Linux_Server_Public/scripts/new_server_install.sh "$@"
else
    bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh) "$@"
fi
STYLEEOF
    chmod +x /usr/local/bin/style
    ln -sf /usr/local/bin/style /usr/local/bin/theme

    # Update load & sos
    [ -f /root/Linux_Server_Public/scripts/load.sh ] && cp -f /root/Linux_Server_Public/scripts/load.sh /usr/local/bin/load && chmod +x /usr/local/bin/load
    [ -f /root/Linux_Server_Public/scripts/sos.sh ] && cp -f /root/Linux_Server_Public/scripts/sos.sh /usr/local/bin/sos && chmod +x /usr/local/bin/sos
LOAD_CMD

  # Step 2: STYLE (apply new_server_install with inputs: Name=enter, Profile=1, Hdr=1, PS1=3, Mode=2, OK=y)
  echo "    [2/2] Applying STYLE (Profile: 1, Header: Sky Blue, Prompt: Bright Green, Mode: UPDATE)..."
  ssh ${SSH_OPTS} "root@${IP}" "bash -s" << 'STYLE_CMD'
    printf "\n1\n1\n3\n2\ny\n" | bash /root/Linux_Server_Public/scripts/new_server_install.sh >/tmp/style_apply.log 2>&1
STYLE_CMD

  # Verification
  CHECK_STYLE=$(ssh ${SSH_OPTS} "root@${IP}" "grep -q 'alias style' /root/.bashrc && echo 'OK' || echo 'FAIL'")
  CHECK_BIN=$(ssh ${SSH_OPTS} "root@${IP}" "[ -x /usr/local/bin/style ] && echo 'OK' || echo 'FAIL'")

  if [[ "$CHECK_STYLE" == "OK" && "$CHECK_BIN" == "OK" ]]; then
    echo "    ✅ ${NAME} successfully updated and verified (style & theme alias active)!"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  else
    echo "    ⚠️ ${NAME} applied with warnings (bashrc alias: ${CHECK_STYLE}, binary: ${CHECK_BIN})"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  fi
done

echo
echo "================================================================="
echo "   SUMMARY: Updated ${SUCCESS_COUNT} servers | Failed: ${FAIL_COUNT}"
echo "================================================================="
