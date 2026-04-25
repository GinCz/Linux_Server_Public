# Xray VLESS Reality Setup (v2026-04-25)

## Overview
Production-ready Xray config using VLESS + Reality (anti-DPI)

## Server Setup
- OS: Ubuntu 24
- Panel: x-ui
- Port: 443
- Transport: TCP
- Security: Reality

## Reality Settings
- Dest: www.github.com:443
- SNI: www.github.com
- ShortID: 02
- Fingerprint: chrome

## Important Notes
- DO NOT enable PROXY protocol
- DO NOT use Cloudflare proxy
- Port 443 must be open
- Use global domains (GitHub, Bing, etc)

## Client Setup (Hiddify / v2rayNG)
- Import via QR or URL
- Transport: TCP
- Security: Reality

## Troubleshooting
1. Check port:
   ufw status

2. Check listening:
   ss -tulnp | grep 443

3. Restart panel:
   systemctl restart x-ui

## Security
Never expose:
- PrivateKey
- UUID
- Full connection URL

