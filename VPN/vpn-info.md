# 🔐 VPN Nodes

## AmneziaVPN
- Running on both 222 and 109 servers
- Stats command: `aw`
- Protocol: AmneziaWG (WireGuard variant)

## VPN-only Servers
- Lightweight Ubuntu nodes
- No FastPanel
- Aliases: `sos`, `sos120`, `aw`
- Setup: same `setup.sh` bootstrap, hostname detection sets VPN mode

## Adding New VPN Node
```bash
# Set hostname to anything NOT containing 222 or 109
hostnamectl set-hostname vpn-node-01
curl -sSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/setup.sh | bash
```

## Git Clone — always use SSH, never HTTPS
```bash
# CORRECT (no password prompt):
git clone git@github.com:GinCz/Linux_Server_Public.git

# WRONG (asks password every time):
# git clone https://github.com/GinCz/Linux_Server_Public.git
```
