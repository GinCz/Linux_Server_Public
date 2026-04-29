# Xray (VLESS + Reality) — Full Setup & User Guide v2026-04-30

## IMPORTANT FIX (CRITICAL)
After installing x-ui, Xray binary path is:

/usr/local/x-ui/bin/xray-linux-amd64

NOT:
/usr/local/x-ui/bin/xray

If you use wrong path — setup will FAIL.

---

## TIMEZONE & TIME SYNC (Set before configuring inbound)

Xray Reality requires accurate server time. Set timezone to Europe/Prague:

```
timedatectl set-timezone Europe/Prague
```

Verify:

```
timedatectl
```

Expected output:

```
               Local time: Thu 2026-04-30 01:00:00 CEST
           Universal time: Wed 2026-04-29 23:00:00 UTC
                 RTC time: Wed 2026-04-29 23:00:00
                Time zone: Europe/Prague (CEST, +0200)
System clock synchronized: yes
              NTP service: active
```

If NTP is not active:

```
apt install -y systemd-timesyncd
systemctl enable --now systemd-timesyncd
timedatectl set-ntp true
```

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
v2026-04-30
