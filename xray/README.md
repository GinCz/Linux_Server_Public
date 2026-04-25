# Xray (VLESS + Reality) — Adding New Users (v2026-04-25)

This guide explains exactly how to add a new user in x-ui panel with correct settings.

-----------------------------------------
STEP 1 — Open Panel
-----------------------------------------
Login to your x-ui panel:
http://SERVER_IP:PORT/PATH

-----------------------------------------
STEP 2 — Open Inbound
-----------------------------------------
Go to:
Inbounds → Edit (your inbound)

-----------------------------------------
STEP 3 — Add New User
-----------------------------------------
Scroll to:
Number of Clients → Click "+"

Fill fields:

Email:
(any name, for example user1)

ID (UUID):
Click generate OR use:
cat /proc/sys/kernel/random/uuid

Flow:
(empty)

-----------------------------------------
STEP 4 — IMPORTANT SETTINGS
-----------------------------------------

Protocol:
VLESS

Port:
443

Transmission:
TCP (RAW)

Security:
Reality

-----------------------------------------
REALITY SETTINGS (CRITICAL)
-----------------------------------------

Dest:
www.github.com:443

SNI:
www.github.com

Short ID:
02

uTLS (Fingerprint):
chrome

-----------------------------------------
MUST BE DISABLED
-----------------------------------------

PROXY Protocol:
OFF

HTTP Obfuscation:
OFF

TLS:
OFF

mldsa / post-quantum:
EMPTY (disabled)

-----------------------------------------
STEP 5 — SAVE
-----------------------------------------
Click:
Save

-----------------------------------------
STEP 6 — GET LINK
-----------------------------------------
Open user → Click:
QR code or Copy URL

Example format:

vless://UUID@SERVER_IP:443?type=tcp&encryption=none&security=reality&pbk=PUBLIC_KEY&fp=chrome&sni=www.github.com&sid=02&spx=%2F#NAME

-----------------------------------------
CLIENT APPS
-----------------------------------------

Android:
- Hiddify
- v2rayNG

iPhone:
- Shadowrocket
- Streisand

-----------------------------------------
TROUBLESHOOTING
-----------------------------------------

If NOT working:

1. Check port:
ufw status

2. Check Xray:
ss -tulnp | grep 443

3. Restart panel:
systemctl restart x-ui

4. Make sure:
- sid matches (02)
- SNI = Dest
- fingerprint = chrome

-----------------------------------------
SECURITY WARNING
-----------------------------------------

NEVER share:
- Private Key
- Full panel access
- Server root access

-----------------------------------------
Author:
Rooted by VladiMIR | AI
v2026-04-25
-----------------------------------------
