# AdGuard Home — Setup, Configuration and Troubleshooting

Node: EU-Stolb-AG-24 (xxx.xxx.xxx.24)
Installed: /opt/AdGuardHome/
Web UI: http://xxx.xxx.xxx.24:8080
DNS hostname: dns.gincz.com

---

## What Is AdGuard Home

AdGuard Home is a network-wide DNS server with ad/tracker blocking.
Runs on a dedicated VPN node and serves DNS to all devices via:
- Plain DNS: port 53 (UDP + TCP)
- DNS-over-TLS (DoT): port 853 — used by Android Private DNS
- DNS-over-HTTPS (DoH): port 443 or 8443
- Web UI: port 8080 (HTTP) or 8443 (HTTPS)

---

## Android Private DNS Setup

Settings -> Connections -> More connection settings -> Private DNS

Set hostname: dns.gincz.com

Android uses DoT (port 853) for Private DNS.
Port 853 must be open in UFW — see firewall section below.

---

## SSL Certificate

Certificate managed by Certbot (Lets Encrypt).

    certbot certificates
    certbot renew --dry-run
    certbot renew

Current cert: dns.gincz.com — expires ~43 days from 2026-05-01 (auto-renews via cron).

Certificate files used by AdGuard (Settings -> Encryption in Web UI):
    Certificate: /etc/letsencrypt/live/dns.gincz.com/fullchain.pem
    Private key:  /etc/letsencrypt/live/dns.gincz.com/privkey.pem

---

## UFW Firewall Rules (Required)

WARNING — This was the exact bug encountered on 2026-05-01.
AdGuard was running, Web UI opened fine, but Android showed No Internet
because UFW was blocking ports 53 and 853 from external access.

All required UFW rules for AdGuard:

    ufw allow 53/udp  comment AdGuard DNS
    ufw allow 53/tcp  comment AdGuard DNS
    ufw allow 853/tcp comment AdGuard DoT
    ufw allow 853/udp comment AdGuard DoT QUIC
    ufw allow 8080/tcp comment AdGuard Web UI HTTP
    ufw allow 8443/tcp comment AdGuard Web UI HTTPS
    ufw reload

Verify rules are in place:
    ufw status numbered | grep -E 53|853|8080|8443

Expected output must include:
    53/udp   ALLOW IN  Anywhere  # AdGuard DNS
    53/tcp   ALLOW IN  Anywhere  # AdGuard DNS
    853/tcp  ALLOW IN  Anywhere  # AdGuard DoT
    853/udp  ALLOW IN  Anywhere  # AdGuard DoT QUIC

---

## Service Management

    systemctl status AdGuardHome
    systemctl restart AdGuardHome
    journalctl -u AdGuardHome -n 50 --no-pager
    /opt/AdGuardHome/AdGuardHome --version

---

## Quick DNS Test (from any server)

    dig @xxx.xxx.xxx.24 google.com +short
    dig @xxx.xxx.xxx.24 google.com +short +timeout=3

---

## Ports Reference

Port 53  UDP+TCP  Plain DNS                         UFW required: YES
Port 853 TCP+UDP  DNS-over-TLS (Android Private DNS) UFW required: YES
Port 443 TCP      DNS-over-HTTPS                    UFW required: YES
Port 8080 TCP     Web UI HTTP                       UFW required: YES
Port 8443 TCP     Web UI HTTPS                      UFW required: YES

---

## INCIDENT 2026-05-01 — Android No Internet via Private DNS

SYMPTOMS:
- AdGuard Web UI opened fine in browser
- systemctl status showed active
- dig @localhost google.com returned IP
- Android Private DNS set to dns.gincz.com -> No Internet

ROOT CAUSE:
UFW was missing port 53 and port 853 rules.
AdGuard was listening internally but firewall was silently dropping
all incoming DNS traffic from external devices (phones, clients).

WHY EASY TO MISS:
- systemctl status shows active
- Local DNS test (dig @127.0.0.1) passes
- Web UI loads fine on 8080/8443 which DID have UFW rules
- sos shows DNS local test: OK — but that test is LOCAL only
- Only external queries from phone are blocked

FIX APPLIED:
    ufw allow 53/udp  comment AdGuard DNS
    ufw allow 53/tcp  comment AdGuard DNS
    ufw allow 853/tcp comment AdGuard DoT
    ufw allow 853/udp comment AdGuard DoT QUIC
    ufw reload

PREVENTION:
When installing AdGuard on any new node — always add all 4 DNS port
rules to UFW BEFORE testing from a phone.
Do not rely on local DNS test alone — it bypasses the firewall.

---

## Config File

/opt/AdGuardHome/AdGuardHome.yaml

Backup:
    cp /opt/AdGuardHome/AdGuardHome.yaml /root/Linux_Server_Public/AdGuard/AdGuardHome.yaml.backup

Do NOT commit real config to public repo if it contains credentials.
Store real config in private Secret_Privat repository only.

---

## Reading sos Output for AdGuard

When sos runs the AdGuard section shows:

  Service:    active
  DNS port 53:  UDP=OK  TCP=OK   <- LOCAL test only, does NOT verify UFW
  UFW rules (AdGuard):           <- CHECK THIS — must include 53 and 853
    8443/tcp   ALLOW   Anywhere
    8080/tcp   ALLOW   Anywhere
  DNS local test: OK -> 216.58.198.46

If UFW rules section shows ONLY 8080 and 8443 and is missing 53 and 853
-> external DNS is blocked even though service looks healthy.
