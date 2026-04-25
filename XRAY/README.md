# Xray (VLESS + Reality) — Full Setup & User Guide v2026-04-25

## IMPORTANT FIX (CRITICAL)
After installing x-ui, Xray binary path is:

/usr/local/x-ui/bin/xray-linux-amd64

NOT:
/usr/local/x-ui/bin/xray

If you use wrong path — setup will FAIL.

---

## SERVER CONFIG (WORKING TEMPLATE)

Protocol: VLESS  
Port: 443  
Transmission: TCP  
Security: Reality  

Reality Settings:
Dest: www.github.com:443  
SNI: www.github.com  
ShortID: 02  
Fingerprint: chrome  

Encryption: none  
Flow: empty  

---

## ADD NEW USER (STEP-BY-STEP)

1. Open panel  
2. Inbounds → Edit  
3. Add client  

Fill:

Email: any  
ID: generate UUID  
Flow: empty  

---

## MUST MATCH SETTINGS

Dest = SNI = www.github.com  
ShortID = 02  
Fingerprint = chrome  

---

## MUST BE DISABLED

PROXY Protocol: OFF  
HTTP Obfuscation: OFF  
TLS: OFF  
mldsa: OFF  

---

## CLIENT APPS

Android:
- Hiddify
- v2rayNG

iOS:
- Shadowrocket

---

## TROUBLESHOOTING

Check port:
ufw status

Check Xray:
ss -tulnp | grep 443

Restart:
systemctl restart x-ui

---

## SECURITY

DO NOT SHARE:
- PrivateKey
- Panel access
- Root access

---

## AUTHOR
Rooted by VladiMIR | AI  
v2026-04-25
