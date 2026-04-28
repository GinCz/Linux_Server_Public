# AmneziaWG - Backup, Restore and Troubleshooting Guide
# v2026-04-14
# = Rooted by VladiMIR | AI =

## Overview

Written after full recovery of TATRA_9 on 2026-04-14.
Covers how AmneziaWG works inside Docker, what must be backed up,
what went wrong, how it was fixed, and what must never be done again.

---

## How AmneziaWG works

AmneziaWG runs as a single Docker container.
The Windows app (AmneziaVPN) manages the server EXCLUSIVELY over SSH.
It connects, enters the container, reads and writes config files directly.
There is NO HTTP API, NO REST endpoint, NO management daemon.

The startup script /opt/amnezia/start.sh only does:
  - awg-quick up wg0.conf
  - iptables rules for forwarding
  - tail -f /dev/null to keep container alive

Nothing else. No API server, no backend process.

---

## Interface name

The interface is named: amnezia-wg0
NOT wg0, NOT awg0.

Verify: ip link show | grep -E "wg0|awg0|amnezia"

---

## Critical files to back up

Docker image alone is NOT enough. Live state is in mounted host directories.

1. /opt/amnezia/awg/wg0.conf
   - server private key
   - VPN subnet and listening port
   - obfuscation params: Jc, Jmin, Jmax, S1, S2, H1-H4
   - all peer definitions: public keys, preshared keys, allowed IPs
   If lost: private key changes, ALL client configs become invalid,
   every client needs a new QR code.

2. /opt/amnezia/awg/clientsTable
   - maps peer IPs to human-readable names
   - ONLY source for client names, nowhere else
   If lost: all clients appear as Client_5, Client_6 etc.

3. /opt/amnezia/start.sh
   Container startup script.

4. Docker image .tar.gz
   Needed to recreate container, but does NOT contain live client state.

CORRECT backup = image + wg0.conf + clientsTable + start.sh

---

## File permissions - critical

Both files MUST be writable:
  -rw------- 1 root root  wg0.conf
  -rw------- 1 root root  clientsTable

If read-only: Windows app cannot write peers, creates broken N/A entries.

Fix:
  chmod 600 /opt/amnezia/awg/wg0.conf
  chmod 600 /opt/amnezia/awg/clientsTable

NEVER use chattr +i on these files. Breaks client creation completely.

---

## What went wrong during TATRA_9 recovery

PROBLEM 1: clientsTable not in old backups
  Old script used docker save only. clientsTable is in bind-mount, not in image.
  Result: all 16 client names lost after restore.
  Fix: updated backup script to extract clientsTable with docker cp.

PROBLEM 2: broken peers with empty PresharedKey
  Failed client creation left invalid blocks:
    [Peer]
    PublicKey = xxx
    PresharedKey =
    AllowedIPs = 10.8.1.23/32
  Empty PresharedKey causes parser to fail. Container loops: start -> fail -> restart.
  Fix: remove all peer blocks with empty PresharedKey using Python regex script.

PROBLEM 3: wrong port in restore script
  Script had -p 51820:51820/udp hardcoded.
  Correct: -p 123:42430/udp
  All servers use port 123 (external) to avoid blocking in Russia.

PROBLEM 4: N/A entries in clientsTable
  Every failed client creation leaves record with empty allowedIps.
  Clean with:
    python3 -c "
    import json; path='/opt/amnezia/awg/clientsTable'
    with open(path) as f: data=json.load(f)
    data=[e for e in data if e.get('userData',{}).get('allowedIps','')]
    with open(path,'w') as f: json.dump(data,f,ensure_ascii=False,indent=2)
    print('done')"

PROBLEM 5: files became read-only
  After cleanup attempts files had r-------t permissions.
  Windows app writes directly over SSH. Read-only silently blocked all writes.
  Fix: chmod 600 on both files.

PROBLEM 6: all 16 client names lost
  Server recreated before backup fix. No clientsTable backup existed.
  Windows app backup = only admin's own config, not the full server list.
  Recovery: found client list in conversation export (PDF).
  Saved to: VPN/TATRA_9_clients_recovered_v2026-04-14.md

---

## RULES - what must NEVER be done

- Never chattr +i on wg0.conf or clientsTable
- Never leave peer blocks with empty PresharedKey = in wg0.conf
- Never restore from Docker image alone without the mounted config files
- Never hardcode port 51820 in restore script - always use 123:42430
- Never add clients while wg0 is not up and peers not loaded
- Never click "Clean server from Amnezia protocols" in Windows app
  THIS CREATES NEW PRIVATE KEY AND DISCONNECTS ALL CLIENTS PERMANENTLY
- Never delete clientsTable - no other source exists for client names

---

## Checklist before adding a new client

  # Interface must exist
  ip link show | grep amnezia

  # wg0 must be up
  docker exec amnezia-awg awg show wg0 | head -5

  # Peers must be loaded
  docker exec amnezia-awg awg show wg0 | grep -c "allowed ips"

  # Files must be writable
  ls -la /opt/amnezia/awg/

  # No N/A entries
  grep -c '"allowedIps": ""' /opt/amnezia/awg/clientsTable || echo "clean"

Only after all checks pass - open Windows app and add the client.

---

## Correct docker run for TATRA_9

  docker stop amnezia-awg && docker rm amnezia-awg
  docker run -d \
    --name amnezia-awg --restart unless-stopped --privileged \
    --cap-add NET_ADMIN --cap-add SYS_MODULE --network bridge \
    --sysctl net.ipv4.ip_forward=1 \
    --sysctl net.ipv4.conf.all.src_valid_mark=1 \
    -p 123:42430/udp \
    -p 127.0.0.1:80:80/tcp \
    -v /lib/modules:/lib/modules \
    -v /opt/amnezia/awg:/opt/amnezia/awg \
    -v /opt/amnezia/start.sh:/opt/amnezia/start.sh \
    amnezia-awg:latest

---

## Key insight

The Docker container is disposable. The private key and client mapping are not.

If wg0.conf is preserved with the original PrivateKey:
  -> all existing clients keep working after restore, no new QR codes needed

If PrivateKey is lost or changed:
  -> every single client needs a new QR code
