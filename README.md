# 🖥️ Linux Server Public — VladiMIR

> Public configuration files, scripts, and documentation for production servers.  
> **All secrets, passwords, API keys and FULL IP addresses are stored in a separate PRIVATE repository.**

---

## ⚡ Quick Install One-Liners

> Run these on any fresh server to get up and running fast.

### 🆕 New Server Setup (full bootstrap)
```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh)
```

### 📊 Install SOS (server health monitor)
```bash
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh \
  -o /usr/local/bin/sos && chmod +x /usr/local/bin/sos && sos
```

### 🗂️ Install Samba (any server)
```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/samba_setup.sh)
```

### 🚀 VPN Node — Aliases + MOTD setup
```bash
bash <(curl -s https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/VPN/setup_aliases_and_motd.sh)
```

---

## 🤖 HOW TO WORK WITH AI (Mandatory Rules)

> These rules apply to every session. The AI must follow them **without exception**.

### 1. 🔍 AI must ALWAYS read the repository first

Before answering ANY question — the AI must:
1. Read the root `README.md` (this file)
2. Read the relevant server folder `README.md` (e.g. `222/README.md` or `VPN/README.md`)
3. Read `CHANGELOG.md` to understand recent changes
4. **Read the actual script file** before deciding what to do with it
5. Only THEN answer, based on actual repo contents — not assumptions

> **If you are not sure what a script does — READ IT FIRST. Every time. No exceptions.**
> **Do NOT ask the server questions that can be answered by reading the repo.**

---

### 2. 📝 EVERYTHING must be recorded in the repository

Every change, no matter how small, must be saved to the repo. This includes:
- New scripts or config files
- Any changes to existing scripts
- New cron jobs or systemd units
- Every problem encountered and how it was solved
- Installation steps for any software
- Backup configurations
- Test results

> **If it was done on a server — it must exist in the repo. No exceptions.**

---

### 3. 💬 Language rules

| Where | Language | Notes |
|---|---|---|
| **AI ↔ VladiMIR (chat)** | 🇷🇺 **Russian only** | Always communicate in Russian in chat |
| **This PUBLIC repo** (`Linux_Server_Public`) | 🇬🇧 **English only** | All `.md` files, all comments inside scripts, all descriptions |
| **Private repo** (`Secret_Privat`) | 🇷🇺 **Russian** | Descriptions, notes and comments in Russian |
| **Crypto bot repo** (`crypto-docker` / private) | 🇷🇺 **Russian** | Descriptions, notes and comments in Russian |

**Summary:**
- Chat with AI → always Russian
- Public GitHub repo → always English (code comments, README, all docs)
- Private / secret repos → Russian

---

### 4. 💻 Code blocks — execution rules

When the AI sends code, it **must always clearly mark** one of these:

```
📋 INFO ONLY — do not run this
```
```
🚀 RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)
```
```
🚀 RUN ON SERVER: xxx.xxx.xxx.109 (109-RU-FastVDS)
```
```
🚀 RUN ON SERVER: xxx.xxx.xxx.47 (VPN-EU-Alex-47)
```
```
🚀 RUN ON ALL SERVERS
```

- Every executable code block must specify the **exact server IP** where it should run
- If multiple code blocks are needed for the same task → **merge them into one script**
- Every script must start with `clear` to clear the terminal before output
- Do NOT send 10 separate snippets when one combined script will do

---

### 5. 🔐 Security rules for this repo

| ✅ Allowed in PUBLIC repo | ❌ NEVER in PUBLIC repo |
|---|---|
| Template placeholders `<VALUE>` | Real passwords |
| IP format: `xxx.xxx.xxx.222` | Full IP addresses |
| Script logic and structure | API keys / tokens |
| Config templates | SSH private keys |
| Documentation | WireGuard private keys |
| Masked IPs (last octet only visible) | Telegram Bot tokens |
| | SSH public keys (even public keys reveal infrastructure) |

**IP masking format:** only the last octet is shown. Examples:
- `152.53.182.222` → `xxx.xxx.xxx.222`
- `212.109.223.109` → `xxx.xxx.xxx.109`
- `109.234.38.47` → `xxx.xxx.xxx.47`

**Full IPs, passwords and keys → stored ONLY in the private `Secret_Privat` repository.**

---

### 6. ⚙️ Server Configuration Philosophy (CRITICAL)

> **All configuration must be done at the SERVER level — never per-account or per-domain.**

#### The rule:
- PHP settings (`memory_limit`, `max_execution_time`, `opcache`, etc.) → set **globally** in `php.ini` or `www.conf`
- Nginx settings (timeouts, buffers, limits) → set **globally** in `nginx.conf` or `conf.d/`
- MariaDB settings → set **globally** in `my.cnf`
- CrowdSec rules → applied **globally** to all sites automatically
- PHP-FPM pool parameters → use a **global template** applied to all pools equally

#### Why:
- Individual per-site tuning creates inconsistency and technical debt
- If one site needs more resources, the **server** needs upgrading — not that one site's config
- All hosted sites are equal — no site gets special treatment at config level
- Easier maintenance: one change fixes all sites at once

#### What to do when a specific site misbehaves:
If a site shows errors, high CPU, memory issues, or behaves differently from others — **do NOT edit its config files directly**. Instead:

1. **Check if WordPress is up to date** — log into the site's WP Admin and update all plugins, themes, and WordPress core
2. **Check if a CAPTCHA plugin is installed and working** — every WP site must have an active, up-to-date CAPTCHA (e.g. Cloudflare Turnstile, hCaptcha, or similar)
3. **Check for outdated or abandoned plugins** — deactivate anything not updated in 12+ months
4. **If the problem persists** — investigate at the server level (PHP-FPM pool stats, error logs, CrowdSec decisions)

> **The AI must notify VladiMIR** when a specific domain behaves differently from others:  
> _"Domain `example.cz` is generating errors — please log into WP Admin, update all plugins/themes/core, and verify that a CAPTCHA plugin is installed and active."_

---

### 7. 🧠 AI must think critically — not just agree

> **This rule was added on 2026-06-03 at VladiMIR's direct request.**

The AI must **always evaluate both sides** of any proposal before responding — not just confirm what VladiMIR suggests.

#### The rule:
- Every idea, script approach, or architectural decision must be assessed for **both advantages AND risks**
- If VladiMIR's proposal has a real downside — **say so clearly**, even if it means disagreeing
- Do NOT give answers designed to please — give answers that are **technically correct**
- Flattery and blind agreement are **forbidden**. They waste time and cause real problems on production servers.

#### What this looks like in practice:

❌ **Wrong (AI just agrees):**
> VladiMIR: "Let's apply this rule to ALL domains in the account automatically."
> AI: "Great idea! I'll implement it right away."

✅ **Correct (AI evaluates both sides):**
> VladiMIR: "Let's apply this rule to ALL domains in the account automatically."
> AI: "**Advantage:** no need to maintain a domain list, new domains are covered automatically.
> **Risk:** if the account contains non-WordPress domains (landing pages, redirect-only zones, API endpoints), applying WordPress-specific WAF rules to them could block legitimate traffic or break functionality. 
> **Recommendation:** add a domain-type flag or exclusion list if mixed domain types exist. In your case, all domains appear to be WordPress — so this approach is justified."

#### The principle:
> **A good engineer challenges bad ideas before they reach production. An AI that only agrees is useless.**

---

### 8. 🛡️ Blacklist & Whitelist — Fully Automatic System

> **This rule was added on 2026-06-09. The AI must NEVER manually ban or unban IPs that belong to the whitelist below.**

#### How the blacklist system works:

The blacklist system is **100% automatic** — no manual intervention is ever needed for normal operation.

| Component | Location | What it does |
|---|---|---|
| **CrowdSec** | All servers | Auto-detects attacks, auto-bans IPs via bouncer |
| **iptables + ipset** | All servers | Hardware-level DROP for vladblacklist IPs |
| `vladblacklist` ipset | All servers | ~157 IPs/subnets, auto-deployed every 3h via cron |
| `blacklist/collect-blacklist.sh` | 222 server | Collects new bad IPs every 3h |
| `blacklist/deploy-blacklist.sh` | All servers | Pulls and applies the list every 3h |
| `blacklist/collect-from-vpn.sh` | 222 server | Collects IPs from VPN nodes every 3h |

**Cron schedule (on 222):**
```
0  */3 * * *  collect-blacklist.sh   — collect new bad IPs
30 */3 * * *  deploy-blacklist.sh    — push to all servers
55 */3 * * *  collect-from-vpn.sh   — gather VPN node data
```

#### ⚠️ WHITELIST — These IPs must NEVER be banned

The following IPs belong to the infrastructure and must always be whitelisted in **CrowdSec, iptables, Fail2ban, and Samba** on ALL servers.

> **Before banning any IP — check this table first.**  
> **When installing CrowdSec or configuring any firewall — add all these IPs to the whitelist.**

| IP Address | Name / Role | Services |
|---|---|---|
| `xxx.xxx.xxx.222` | **222-DE-NetCup** (main web server) | FastPanel + Cloudflare + Samba + XRAY VPN + CryptoBot |
| `xxx.xxx.xxx.109` | **109-RU-FastVDS** (Russian sites server) | FastPanel + Samba + XRAY VPN |
| `xxx.xxx.xxx.47` | **VPN ALEX_47** | XRAY VPN + Samba |
| `xxx.xxx.xxx.237` | **VPN 4TON_237** | XRAY VPN + Samba |
| `xxx.xxx.xxx.9` | **VPN TATRA_9** | XRAY VPN + Samba + Monitoring Kuma |
| `xxx.xxx.xxx.227` | **VPN SHAHIN_227** | AmneziaWG + Samba |
| `xxx.xxx.xxx.24` | **VPN STOLB_24** | XRAY VPN + Samba + AdGuard Home |
| `xxx.xxx.xxx.178` | **VPN PILIK_178** | AmneziaWG + Samba |
| `xxx.xxx.xxx.176` | **VPN ILYA_176** | AmneziaWG + Samba |
| `xxx.xxx.xxx.38` | **VPN SO_38** | XRAY VPN + Samba |
| `xxx.xxx.xxx.38` | **IONOS-38** (additional server) | IONOS server |
| `xxx.xxx.xxx.42` | **AWS VPN XRAY** | AWS VPN node |
| `xxx.xxx.xxx.16` | **Home IP** (primary) | Admin access |
| `xxx.xxx.xxx.235` | **Home IP** (secondary) | Admin access |
| `xxx.xxx.xxx.0` | **Home IP** (tertiary) | Admin access |
| `xxx.xxx.xxx.10` | **Work IP** | Admin access |

#### How to add to CrowdSec whitelist (on any server):

```bash
# Add all infrastructure IPs to CrowdSec whitelist
cscli decisions delete --ip xxx.xxx.xxx.222 2>/dev/null
cscli decisions delete --ip xxx.xxx.xxx.109 2>/dev/null
# Permanent whitelist — edit /etc/crowdsec/parsers/s02-enrich/my_whitelist.yaml
```

Whitelist config file: `/etc/crowdsec/parsers/s02-enrich/my_whitelist.yaml`
```yaml
name: my_whitelist
description: "Trusted IPs - servers, VPN clients, admin. v2026-06-10"
whitelist:
  reason: "Trusted admin, VPN clients, monitoring and partner servers"
  ip:
    # --- OWN SERVERS ---
    - "xxx.xxx.xxx.222"   # DE-NetCup 222 (WEB+VPN+CryptoBot)
    - "xxx.xxx.xxx.109"   # RU-FastVDS 109 (WEB+VPN)
    - "xxx.xxx.xxx.38"    # IONOS-38 (our server)
    - "xxx.xxx.xxx.42"    # AWS VPN XRAY
    # --- VPN NODES ---
    - "xxx.xxx.xxx.47"    # ALEX_47
    - "xxx.xxx.xxx.237"   # 4TON_237
    - "xxx.xxx.xxx.9"     # TATRA_9 (Kuma Monitoring)
    - "xxx.xxx.xxx.227"   # SHAHIN_227
    - "xxx.xxx.xxx.24"    # STOLB_24 (AdGuard Home)
    - "xxx.xxx.xxx.178"   # PILIK_178
    - "xxx.xxx.xxx.176"   # ILYA_176
    - "xxx.xxx.xxx.38"    # SO_38
    # --- HOME / WORK ---
    - "xxx.xxx.xxx.16"    # Home IP VladiMIR
    - "xxx.xxx.xxx.235"   # Home IP VladiMIR 2
    - "xxx.xxx.xxx.0"     # Home IP VladiMIR 3
    - "xxx.xxx.xxx.10"    # Work IP VladiMIR
```

#### The rule for the AI:
- **NEVER suggest banning** any IP from the whitelist above
- **BEFORE writing any firewall command** — check if the target IP is in this table
- **When setting up a new server** — always add all whitelist IPs to CrowdSec, iptables, and Samba before anything else
- The blacklist system runs **automatically** — do not interfere with its cron jobs

---

## ⚠️ AI LESSONS LEARNED — WHAT WENT WRONG AND HOW TO AVOID IT

> **This section was written after a painful 1-hour session on May 22, 2026.**  
> Every mistake described here actually happened. Read carefully — do NOT repeat.

### The incident (May 22, 2026 — VPN node xxx.xxx.xxx.47)

VladiMIR asked: "There's a script — maybe it's a VPN installer, maybe it's aliases setup. Read it and tell me what it does **before** I run it on a production server with active Xray VPN users."

**What the AI did wrong — step by step:**

1. **Did NOT read the script first.** Jumped to conclusions based on the filename alone. This is the core mistake. The AI assumed instead of reading.

2. **Wrote new code without being asked.** VladiMIR asked "what does this script do?" — the AI started writing a new installer. Nobody asked for that.

3. **Confused two completely different scripts:**
   - `motd_vpn.sh` — this IS the MOTD banner script. It runs on SSH login and displays the banner. It does NOT install anything.
   - `setup_aliases_and_motd.sh` — this IS the installer. It copies files, installs packages, configures system.
   - The AI kept swapping them, offering the wrong one each time.

4. **Broke a working server** by uploading a new script to the repo without confirmation, and that script overwrote the correct MOTD with a "Modded" version that VladiMIR did not want.

5. **Sent multiple separate code blocks** instead of one clean command. VladiMIR's rule is: one task = one `clear`-prefixed command.

6. **Did not stop and ask the ONE key question** that would have resolved everything in 30 seconds: "Which file exactly are you asking about — show me the path or name."

### The correct approach — what should have happened:

```
VladiMIR: "There's a script, I think it sets up VPN. Read it before I run it."

AI step 1: Read README.md → understand the repo structure
AI step 2: Read VPN/README.md → understand VPN node architecture  
AI step 3: Read the actual script file (motd_vpn.sh or setup_aliases_and_motd.sh)
AI step 4: Report what it does IN PLAIN LANGUAGE
AI step 5: Say "this is safe / NOT safe to run on a production server"
AI step 6: If installation needed → one clean command starting with clear
```

Total time if done correctly: **2 minutes.**  
Actual time because of mistakes: **1 hour.**

### Rules that prevent this from happening again:

#### Rule A: READ THE SCRIPT BEFORE DOING ANYTHING
```
User mentions a script → AI reads it → AI reports what it does → AI asks "should I run it?"
NEVER: User mentions a script → AI writes new code
```

#### Rule B: PRODUCTION SERVERS HAVE REAL USERS
> Server xxx.xxx.xxx.47 (EU-Alex-47) has active Xray VPN users connected 24/7.  
> Server xxx.xxx.xxx.237 (EU-4Ton-237) has active Xray VPN users connected 24/7.  
> **Any mistake that restarts Xray, UFW, or the server = users lose their VPN = real problem.**

Before running ANYTHING on a VPN node, the AI must verify:
- Does this command restart Xray? → warn VladiMIR first
- Does this command restart UFW / networking? → warn VladiMIR first
- Does this command reboot the server? → STOP, ask for explicit confirmation
- Does this command upgrade packages (`apt upgrade`)? → warn, do not run silently

#### Rule C: UNDERSTAND THE DIFFERENCE BETWEEN BANNER AND INSTALLER

| File | What it IS | What it DOES | Safe on production? |
|---|---|---|---|
| `VPN/motd_vpn.sh` | **The banner itself** | Displays MOTD on SSH login | ✅ Read-only, safe |
| `VPN/motd_server.sh` | **The banner itself** | Same — newer universal version | ✅ Read-only, safe |
| `VPN/setup_aliases_and_motd.sh` | **The installer** | Copies files, configures system | ⚠️ Modifies system |
| `scripts/new_server_install.sh` | **Full bootstrap** | apt upgrade, UFW, CrowdSec, etc. | ❌ ONLY on fresh servers |

**The banner file** (`motd_vpn.sh` / `motd_server.sh`) just runs and prints text. It is NOT an installer.  
**To deploy the banner**, it must be copied to `/etc/profile.d/` — that is the install step.

Correct one-liner to deploy MOTD on a VPN node:
```bash
🚀 RUN ON SERVER: xxx.xxx.xxx.47 (VPN-EU-Alex-47)
clear
cd /root/Linux_Server_Public && git pull origin main --no-rebase --no-edit \
  && rm -f /etc/profile.d/motd_banner.sh /etc/profile.d/motd_custom.sh \
  && cp VPN/motd_vpn.sh /etc/profile.d/motd_vpn.sh \
  && chmod +x /etc/profile.d/motd_vpn.sh \
  && chmod -x /etc/update-motd.d/* 2>/dev/null \
  && echo "Done. Re-login to verify."
```

#### Rule D: ONE COMMAND, ONE TASK
- Every answer that requires running something on a server = **exactly one code block**
- That block starts with `clear`
- That block is labeled with the exact server IP
- No "first run this, then run that" — merge into one

#### Rule E: WHEN IN DOUBT — ASK ONE QUESTION
If the AI doesn't know which script, which server, which version, or what the goal is:  
→ Ask **one** specific question  
→ Wait for the answer  
→ Then act  

Do NOT guess. Do NOT write code based on assumptions.

---

## 📜 Coding Standards (Mandatory for ALL scripts)

Every script committed to this repository **must** follow these rules:

### 1. 🌈 Colour Output — MANDATORY PALETTE

**These are the ONLY three colours used in ALL scripts. No other colours allowed.**

```bash
CYN='\033[1;36m'   # Bright Cyan  — section headers, info blocks, labels
GRN='\033[1;32m'   # Bright Green — success messages, OK status, borders/dividers
YEL='\033[1;33m'   # Bright Yellow — warnings, detected values, highlights
NC='\033[0m'        # Reset colour — always used after every coloured echo
```

> ⚠️ **Important:** Use `\033[1;XX m` (bold/bright variants), NOT `\033[0;XXm` (dark variants).
> - `\033[1;32m` = **Bright Green** ✅ — correct
> - `\033[0;32m` = Dark Green ❌ — do NOT use
> - `\033[1;36m` = **Bright Cyan** ✅ — correct
> - `\033[0;36m` = Dark Cyan ❌ — do NOT use

**Colour usage rules:**
- `GRN` — success lines, "OK" messages, horizontal divider lines in headers
- `YEL` — warnings, detected config values, items that need attention
- `CYN` — section headings, info labels, structural text

**No RED for errors.** If something is wrong, use `YEL` with a ⚠️ prefix.  
RED is not part of this colour scheme and must not appear in any script output.

---

### 2. 📐 Script Header — MANDATORY FORMAT

Every script **must** start with a bright green horizontal border of **exactly 90 `=` characters**, followed by the header block, followed by another 90-character border. **Only horizontal lines — no vertical bars or side borders.**

```bash
#!/bin/bash
clear
# ==========================================================================================
# Script:      script_name.sh
# Version:     v2026-MM-DD
# Location:    folder/script_name.sh
# Server:      [e.g. ALL | 222-DE-NetCup xxx.xxx.xxx.222 | VPN nodes]
# Alias:       [alias name if defined, e.g. "save" | "none"]
# Run from repo (curl one-liner):
#   bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/folder/script_name.sh)
# Description: What this script does (2-4 sentences).
# Dependencies: [tools required, e.g. docker, pigz, curl | none]
# WARNING:     [side effects if any, e.g. restarts nginx | none]
# = Rooted by VladiMIR + AI | vYYYY.MM.DD | github.com/GinCz =
# ==========================================================================================
```

The **printed** (runtime) header that appears in the terminal uses colour and must look like this:

```bash
GRN='\033[1;32m'
CYN='\033[1;36m'
YEL='\033[1;33m'
NC='\033[0m'

echo -e "${GRN}==========================================================================================${NC}"
echo -e "${CYN}  Script Name — short description                              v2026-MM-DD${NC}"
echo -e "${GRN}==========================================================================================${NC}"
```

**Rules:**
- The `==` border line must be **exactly 90 characters** wide
- Border lines are `GRN` (Bright Green) — horizontal only, no vertical characters
- The title line between borders is `CYN` (Bright Cyan)
- `clear` must be the **first executable line** (after `#!/bin/bash`)
- The `curl` one-liner in the comment header allows running the script on any server without cloning the repo
- `Location:` shows the path relative to repo root
- `Alias:` shows the bash alias that runs this script (if any), or `none`
- `Server:` shows where this script is intended to run
- The signature line `= Rooted by VladiMIR + AI | vYYYY.MM.DD | github.com/GinCz =` must match the script version date

---

### 3. 📍 Version (date-based, INSIDE script only)
```bash
# Version: v2026-MM-DD
```

> ⚠️ **The version must NEVER appear in the filename.**  
> Correct: `backup_clean.sh`  
> Wrong: `backup_clean_v2026-04-28.sh`  
>
> Version history is tracked by **Git** — every commit has a date, author and SHA.  
> To recover an older version: `git log -- 222/backup_clean.sh` then `git show <sha>:222/backup_clean.sh`

---

### 4. 🔒 No Secrets — Ever
- ✅ Templates with `<PLACEHOLDER>` — allowed
- ✅ Masked IPs `xxx.xxx.xxx.222` — allowed
- ❌ Passwords, API keys, tokens, private keys — **NEVER** in this repo
- ❌ Full IP addresses — **NEVER** in this repo
- ❌ SSH public keys — **NEVER** in this repo (reveals infrastructure)
- Real credentials and IPs → private `Secret_Privat` repo only

### 5. 📂 File Placement Rules
| Location | Purpose |
|---|---|
| `222/` | Scripts/configs for NetCup Germany server |
| `109/` | Scripts/configs for FastVDS Russia server |
| `VPN/` | Scripts/configs for X-ray / x-ui VPN nodes (AmneziaWG + Xray) |
| `XRAY/` | x-ui / Xray **installer** scripts |
| `scripts/` | Shared across ALL servers (including `sos.sh`, `infooo.sh`) |

### 6. 📋 Script Naming Convention

**Rule: filename = clean name only. Version inside the script, not in the filename.**

```
description.sh
```

Examples:
- ✅ `backup_clean.sh` — correct
- ✅ `setup_aliases_and_motd.sh` — correct
- ✅ `sos.sh` — correct
- ❌ `backup_clean_v2026-04-28.sh` — wrong, version in filename
- ❌ `setup_aliases_and_motd_vpn_v2026-04-25.sh` — wrong

Numbered utility scripts (legacy exception):
```
NN_servername_description.sh
```
Example: `01_222_clean_vpn_reports.sh`

---

## 🗂️ Repository Structure

```
LinuxServerPublic/
├── 222/          → Server 222-DE-NetCup   (xxx.xxx.xxx.222)  — NetCup.com, Germany
│                  Ubuntu 24 / FASTPANEL / Cloudflare / CZ+EU sites
│                  4 vCore AMD EPYC-Genoa / 8 GB DDR5 ECC / 256 GB NVMe
│                  Tariff: VPS 1000 G12 (2026) — 8.60 €/mo
│                  Key files: setup_aliases_and_motd.sh, SSH-Cursor-Setup.md
│                  📖 Full docs: 222/README.md
│
├── 109/          → Server 109-RU-FastVDS  (xxx.xxx.xxx.109) — FastVDS.ru, Russia
│                  Ubuntu 24 / FASTPANEL / No Cloudflare / RU sites
│                  4 vCore AMD EPYC 7763 / 8 GB RAM / 80 GB NVMe
│                  Tariff: VDS-KVM-NVMe-Otriv-10.0 — 13 €/mo
│                  Key files: setup_aliases_and_motd.sh
│                  📖 Full docs: 109/README.md
│
├── VPN/          → VPN infrastructure (x-ui / Xray VLESS+Reality + AmneziaWG)
│                  8 VPN nodes — all running Xray 26.5.9
│                  SHAHIN_227 + PILIK_178: AmneziaWG via Docker (active) + Xray
│                  Automated backup system: x-ui archives
│                  Key files: motd_vpn.sh (banner), setup_aliases_and_motd.sh (installer)
│                  📖 Full docs: VPN/README.md
│
├── XRAY/         → x-ui / Xray installer scripts
│                  Safe / Clean / Full-clean installers
│
├── scripts/      → Shared scripts used by ALL servers
│                  sos.sh               — universal server health monitor (ALL servers)
│                  shared_aliases.sh    — common aliases (save, load, aw, mc...)
│                  new_server_install.sh — full bootstrap for fresh servers ONLY
│                  samba_setup.sh       — Samba installer for any server
│                  apply_aliases.sh     — universal aliases+MOTD+MC setup (all server types)
│                  infooo.sh            — legacy server info script
│
├── CHANGELOG.md  → Full history of all changes
├── OPERATIONS.md → Operational procedures and runbooks
├── domains.md    → Domain list and DNS configuration
└── README.md     → This file — AI rules, standards, quick reference
```

---

## 🖥️ Server Overview

| Name | IP (masked) | Provider | Location | Panel | Cloudflare | Monthly |
|---|---|---|---|---|---|---|
| 222-DE-NetCup | xxx.xxx.xxx.222 | NetCup.com | Germany | FASTPANEL | ✅ Yes | 8.60 € |
| 109-RU-FastVDS | xxx.xxx.xxx.109 | FastVDS.ru | Russia | FASTPANEL | ❌ No | 13 € |
| IONOS-38 | xxx.xxx.xxx.38 | IONOS | — | — | ❌ No | — |
| AWS-VPN | xxx.xxx.xxx.42 | AWS | — | — | ❌ No | — |

**Hardware (222 + 109):** 4 vCore AMD EPYC / 8 GB RAM / 80–256 GB NVMe / Ubuntu 24 LTS

---

## 🌐 VPN Node Infrastructure

All 8 nodes are running **x-ui / Xray v26.5.9** (VLESS + Reality protocol).  
SHAHIN_227 and PILIK_178 additionally run **AmneziaWG via Docker** (active, UDP ports).

| Node Name | IP (masked) | Xray | Xray Port | AmneziaWG | AWG UDP Port | Extra Services | Active Users |
|---|---|---|---|---|---|---|---|
| ALEX_47 | xxx.xxx.xxx.47 | ✅ 26.5.9 | **443** | ❌ | — | Samba | ⚠️ YES — live users 24/7 |
| 4TON_237 | xxx.xxx.xxx.237 | ✅ 26.5.9 | **443** | ❌ | — | Samba, Prometheus | ⚠️ YES — live users 24/7 |
| TATRA_9 | xxx.xxx.xxx.9 | ✅ 26.5.9 | **443** | ❌ | — | Samba, Uptime Kuma | ⚠️ YES — live users 24/7 |
| SHAHIN_227 | xxx.xxx.xxx.227 | ✅ 26.5.9 | **2096** | ✅ Docker | **35628** | Samba, Prometheus | ⚠️ YES — live users 24/7 |
| STOLB_24 | xxx.xxx.xxx.24 | ✅ 26.5.9 | **8443** | ❌ | — | Samba, AdGuard Home | ⚠️ YES — live users 24/7 |
| PILIK_178 | xxx.xxx.xxx.178 | ✅ 26.5.9 | **2096** | ✅ Docker | **39339** | Samba, Prometheus | ⚠️ YES — live users 24/7 |
| ILYA_176 | xxx.xxx.xxx.176 | ✅ 26.5.9 | **443** | ❌ | — | Samba | ⚠️ YES — live users 24/7 |
| SO_38 | xxx.xxx.xxx.38 | ✅ 26.5.9 | **443** | ❌ | — | Samba | ⚠️ YES — live users 24/7 |

> ✅ All 8 nodes: x-ui / Xray v26.5.9 — VLESS + Reality protocol  
> ✅ SHAHIN_227: AmneziaWG Docker container `amnezia-awg` — Up, UDP :35628 — confirmed active (2026-05-31)  
> ✅ PILIK_178: AmneziaWG Docker container `amnezia-awg` — Up, UDP :39339 — confirmed active (2026-05-31)  
> ⚠️ SHAHIN_227 + PILIK_178: `amneziawg` binary not in PATH inside container — this is normal for `amneziavpn/amnezia-wg` image (VPN works via kernel module, not CLI binary)  
> ⚠️ STOLB_24: port 8443 because AdGuard Home occupies port 443  
> ⚠️ ALL VPN nodes have real users connected — **NEVER restart Xray/UFW/networking without warning**  
> Full IPs, keys and configs → private `Secret_Privat` repository only.

### AmneziaWG Notes (SHAHIN_227 + PILIK_178)

| Item | Value |
|---|---|
| Docker image | `amneziavpn/amnezia-wg:latest` (21.2 MB) |
| Container name | `amnezia-awg` |
| Status | Up 44+ hours (confirmed 2026-05-31) |
| SHAHIN UDP port | **35628** |
| PILIK UDP port | **39339** |
| `amneziawg` in PATH | ❌ Not found — **this is normal**, the image does not expose this binary |
| How to check status | `docker ps` + `ss -ulnp \| grep docker-proxy` |
| How to check AWG peers | `docker exec amnezia-awg wg show` |

---

## 🔑 VPN Node — File Architecture (CRITICAL)

> Understanding which file does what PREVENTS running the wrong script on a live server.

### Two completely different types of files — do NOT confuse them:

| File | Type | What it does | Safe to run on live server? |
|---|---|---|---|
| `VPN/motd_vpn.sh` | **Banner script** | Prints the SSH welcome banner — that's it | ✅ Safe, read-only |
| `VPN/motd_server.sh` | **Banner script** | Same, newer universal version | ✅ Safe, read-only |
| `VPN/.bashrc` | **Shell config** | Defines aliases for the VPN node | ✅ Safe to copy |
| `VPN/setup_aliases_and_motd.sh` | **Installer** | Copies .bashrc + MOTD to system paths | ⚠️ Modifies files |
| `scripts/new_server_install.sh` | **Full bootstrap** | apt upgrade + UFW + CrowdSec + everything | ❌ ONLY fresh servers |
| `VPN/crowdsec_install_vpn.sh` | **CrowdSec installer** | Installs CrowdSec from scratch | ⚠️ Do NOT run if already installed |
| `VPN/vpn_hard_shield.sh` | **Firewall hardening** | Rewrites ALL iptables rules | ❌ NEVER on live VPN node |

### How the MOTD system works on VPN nodes:

```
SSH login to VPN node
  └── Linux runs: /etc/profile.d/*.sh  (all files in alphabetical order)
          └── /etc/profile.d/motd_vpn.sh   ← this IS the banner
                  ├── detects Xray status
                  ├── detects AmneziaWG (Docker)
                  ├── detects CrowdSec + ban count
                  ├── shows RAM / CPU / uptime
                  └── prints the alias menu
```

**The banner is NOT installed automatically.** To deploy it, copy it to `/etc/profile.d/`:
```bash
cp /root/Linux_Server_Public/VPN/motd_vpn.sh /etc/profile.d/motd_vpn.sh
chmod +x /etc/profile.d/motd_vpn.sh
```

### How aliases work on VPN nodes:

```
SSH login
  └── Bash loads: /root/.bashrc
          └── This file is copied from: VPN/.bashrc
                  └── Defines: xray_st, xray_log, sos, sos24, banlist, save, load, 00, etc.
```

To deploy/update aliases on a VPN node:
```bash
cp /root/Linux_Server_Public/VPN/.bashrc /root/.bashrc
source /root/.bashrc
```

### How to update MOTD or aliases on a live VPN node (safe workflow):

🚀 **RUN ON SERVER: xxx.xxx.xxx.47 (VPN-EU-Alex-47)**
```bash
clear
cd /root/Linux_Server_Public && git pull origin main --no-rebase --no-edit \
  && cp VPN/.bashrc /root/.bashrc \
  && source /root/.bashrc \
  && cp VPN/motd_vpn.sh /etc/profile.d/motd_vpn.sh \
  && chmod +x /etc/profile.d/motd_vpn.sh \
  && echo "Done — re-login to verify banner"
```

This command:
- ✅ Pulls latest from repo
- ✅ Updates aliases
- ✅ Updates MOTD banner
- ✅ Does NOT touch Xray, UFW, CrowdSec, or any service
- ✅ Does NOT restart anything
- ✅ Safe on a live server with active users

---

## 🏗️ MOTD + .bashrc Architecture (IMPORTANT — read before editing)

> Understanding this prevents the double MOTD display bug.

### How shell startup works on these servers

When you SSH into a server, Linux runs two separate chains:

```
SSH login
├── 1. LOGIN SHELL chain:  /etc/profile → /etc/profile.d/*.sh
│       └── /etc/profile.d/motd_server.sh  ← MOTD shown here (1st)
│
└── 2. INTERACTIVE BASH:  /root/.bashrc
        └── source /root/Linux_Server_Public/222/.bashrc
                └── source scripts/shared_aliases.sh
```

If `motd_server.sh` has no guard, it fires on **both** chains → MOTD shown **twice**.

### The fix (v2026-04-28)

All `motd_server.sh` files now have a 2-line guard at the top:

```bash
shopt -q login_shell || return 0 2>/dev/null || exit 0
[ -n "$SSH_CONNECTION" ] || return 0 2>/dev/null || exit 0
```

- `shopt -q login_shell` — true only for a login shell (SSH), false for `source .bashrc`
- `$SSH_CONNECTION` — set only for real remote SSH sessions, empty for local/cron

Result: MOTD fires **exactly once** — on SSH login only.

### .bashrc source chain (222)

```
/root/.bashrc
  └── source /root/Linux_Server_Public/222/.bashrc   ← server-specific aliases
          └── source /root/Linux_Server_Public/scripts/shared_aliases.sh  ← shared aliases
```

| File | Purpose | On server | In repo |
|---|---|---|---|
| `/root/.bashrc` | Entry point, loads repo .bashrc | `/root/.bashrc` | `222/.bashrc` |
| `222/.bashrc` | Server-specific aliases + PS1 | sourced by above | `222/.bashrc` |
| `scripts/shared_aliases.sh` | Aliases shared by ALL servers | sourced by 222/.bashrc | `scripts/shared_aliases.sh` |
| `/etc/profile.d/motd_server.sh` | MOTD banner (login only) | auto-run at SSH login | `222/motd_server.sh` |

### Key rule: `alias load` is defined in `222/.bashrc`, NOT in `shared_aliases.sh`

Because `load` must `source /root/Linux_Server_Public/222/.bashrc` — the path is server-specific.  
If `load` were in `shared_aliases.sh`, it would be wrong on every other server.

### MOTD setup script — three server variants

The script `setup_aliases_and_motd.sh` exists in three versions, one per environment:

| File | Server | Deploys |
|---|---|---|
| `222/setup_aliases_and_motd.sh` | 222-DE-NetCup | MOTD + aliases + MC F2 menu for 222 |
| `109/setup_aliases_and_motd.sh` | 109-RU-FastVDS | MOTD + aliases + MC F2 menu for 109 |
| `VPN/setup_aliases_and_motd.sh` | VPN nodes | MOTD + aliases + MC F2 menu for VPN |

> **Note:** Version is stored **inside** the script only (`# Version: vYYYY-MM-DD`).  
> The filename never contains a version — only `setup_aliases_and_motd.sh`.

---

## 🗂️ Midnight Commander (mc) — F2 User Menu

> ⚠️ **This section was written after 2 full days of debugging. Read carefully — do NOT repeat this.**

### How mc searches for the F2 User Menu (priority order)

mc checks these locations **in order** and uses the FIRST one it finds:

| Priority | Path | Notes |
|---|---|---|
| **1st** ⚠️ | `~/.mc.menu` | Hidden file in `/root/` — **THIS IS THE TRAP** |
| **2nd** | `~/.config/mc/menu` | Correct user menu location |
| **3rd** | `~/.config/mc/mc.menu` | Also checked — causes confusion if both exist |
| **4th** | `/etc/mc/mc.menu` | System-wide fallback |

### ⚠️ THE ROOT CAUSE (2 days of debugging — April 2026)

**Problem:** F2 showed a broken menu with contents like:
```
panel.1.directory=/root/Linux_Server_Public/222
panel.1.left
panel.2.directory=/root/Linux_Server_Public/scripts
user_menu=1
```

**Root cause:** File `/root/.mc.menu` existed (233 bytes, created Mar 24).  
This is an **old ini-style config fragment** that mc was reading as the User Menu.  
mc always checks `~/.mc.menu` FIRST — before `~/.config/mc/menu`.

**Fix:**
```bash
# Check if the trap file exists
ls -la /root/.mc.menu

# Delete it
rm /root/.mc.menu

# Verify correct menu is in place
head -3 ~/.config/mc/menu
```

### Correct setup for mc F2 menu

The correct menu file must be at `~/.config/mc/menu`:

```bash
# Deploy correct menu from repo (222 server)
cp /root/Linux_Server_Public/222/mc.menu ~/.config/mc/menu
chmod 644 ~/.config/mc/menu

# Verify
head -5 ~/.config/mc/menu
# Should start with: # mc.menu for 222-DE-NetCup
```

### mc ini settings (important)

File: `~/.config/mc/ini`

```ini
auto_save_setup=false   ← MUST be false — if true, mc overwrites menu on exit
auto_menu=false         ← MUST be false — if true, mc opens menu automatically on start
```

Check and fix:
```bash
grep "auto_save_setup\|auto_menu" ~/.config/mc/ini
sed -i 's/auto_save_setup=true/auto_save_setup=false/' ~/.config/mc/ini
```

### Files involved per server

| Server | Repo source | Deploy target |
|---|---|---|
| 222-DE-NetCup | `222/mc.menu` | `~/.config/mc/menu` |
| 109-RU-FastVDS | `109/mc.menu` | `~/.config/mc/menu` |

### Quick diagnostic (run when F2 is broken)

🚀 **RUN ON SERVER where F2 is broken**
```bash
clear
echo "=== TRAP FILE ===" && ls -la /root/.mc.menu 2>/dev/null || echo "OK — not present"
echo "=== CORRECT MENU ===" && head -3 ~/.config/mc/menu 2>/dev/null || echo "MISSING"
echo "=== ALL mc menu files ===" && find / -name "menu" -path "*/mc/*" 2>/dev/null
echo "=== INI auto_save ===" && grep "auto_save_setup\|auto_menu" ~/.config/mc/ini
echo "=== ALIAS mc ===" && alias | grep "alias mc"
echo "=== DONE ==="
```

Expected output:
```
=== TRAP FILE ===
OK — not present
=== CORRECT MENU ===
# mc.menu for 222-DE-NetCup — auto-generated by server_222.sh --install
```

### Full fix in one command

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
rm -f /root/.mc.menu
cp /root/Linux_Server_Public/222/mc.menu ~/.config/mc/menu
chmod 644 ~/.config/mc/menu
sed -i 's/auto_save_setup=true/auto_save_setup=false/' ~/.config/mc/ini
echo "=== MC F2 menu fixed ===" && head -3 ~/.config/mc/menu
```

🚀 **RUN ON SERVER: xxx.xxx.xxx.109 (109-RU-FastVDS)**
```bash
clear
rm -f /root/.mc.menu
cp /root/Linux_Server_Public/109/mc.menu ~/.config/mc/menu
chmod 644 ~/.config/mc/menu
sed -i 's/auto_save_setup=true/auto_save_setup=false/' ~/.config/mc/ini
echo "=== MC F2 menu fixed ===" && head -3 ~/.config/mc/menu
```

---

## ✏️ How to Edit MOTD Banner (login screen)

> **MOTD** = the banner you see every time you SSH into the server.

### Where is the file?
| Server | File on server | File in repo |
|---|---|---|
| 222-DE-NetCup | `/etc/profile.d/motd_server.sh` | `222/motd_server.sh` |
| 109-RU-FastVDS | `/etc/profile.d/motd_server.sh` | `109/motd_server.sh` |
| VPN nodes | `/etc/profile.d/motd_vpn.sh` | `VPN/motd_vpn.sh` |

### How to add/remove an alias from the MOTD menu:

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
nano /etc/profile.d/motd_server.sh
# Find the block: # Row 1 (SCAN/SERVER/WORDPRESS) or # Row 2 (BOT/GIT/TOOLS)
# Each line format:
# echo -e "  ${G}aliasname${X}(description)   ${G}alias2${X}(desc)"
# Column width: ~26 chars per column (use spaces to align)
# Test immediately:
bash /etc/profile.d/motd_server.sh
# Save to repo:
cd /root/Linux_Server_Public
cp /etc/profile.d/motd_server.sh 222/motd_server.sh
save
```

---

## ✏️ How to Edit Aliases (.bashrc)

### Where is the file?
| Server | File on server | File in repo |
|---|---|---|
| 222-DE-NetCup | `/root/.bashrc` | `222/.bashrc` |
| 109-RU-FastVDS | `/root/.bashrc` | `109/.bashrc` |
| VPN nodes | `/root/.bashrc` | `VPN/.bashrc` |
| ALL servers (shared) | sourced from `.bashrc` | `scripts/shared_aliases.sh` |

### How to add an alias:

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
nano /root/.bashrc
# Add line: alias myalias='command'
source /root/.bashrc          # apply without re-login
# Also add it to MOTD menu (motd_server.sh) so it shows in the banner!
# Save to repo:
cd /root/Linux_Server_Public
cp /root/.bashrc 222/.bashrc
save
```

---

## 🔄 Standard Update Workflow

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
# Pull latest from repo and install on server:
cd /root/Linux_Server_Public && git pull
cp 222/motd_server.sh /etc/profile.d/motd_server.sh
cp 222/.bashrc /root/.bashrc
source /root/.bashrc
bash /etc/profile.d/motd_server.sh

# After editing files on server — push back to repo:
cd /root/Linux_Server_Public
cp /etc/profile.d/motd_server.sh 222/motd_server.sh
cp /root/.bashrc 222/.bashrc
save
```

---

## 🔐 SSH Key Management

### Generate a new SSH key pair (on your LOCAL machine — do NOT run on server):

📋 **INFO ONLY — run on your LOCAL machine**
```bash
ssh-keygen -t ed25519 -C "yourname@server" -f ~/.ssh/id_ed25519_servername
```

### Add public key to server:

📋 **INFO ONLY — adjust IP before running**
```bash
ssh-copy-id -i ~/.ssh/id_ed25519_servername.pub root@SERVER_IP
# OR manually:
cat ~/.ssh/id_ed25519_servername.pub >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
```

### Cursor IDE / SSH config (`~/.ssh/config` on Windows):

See full setup guide: `222/SSH-Cursor-Setup.md`

```
Host netcup
    HostName <FULL_IP_FROM_SECRET_REPO>
    User root
    Port 2222
    IdentityFile C:\\Users\\USER\\.ssh\\id_ed25519_win

Host fastvds alex47 4ton237 tatra9 shahin227 stolb24 pilik178 ilya176 so38
    User root
    Port 22
    IdentityFile C:\\Users\\USER\\.ssh\\id_ed25519_win
    ProxyJump netcup
```

---

## 🔒 CrowdSec — Fix Engine INACTIVE

🚀 **RUN ON SERVER where CrowdSec is broken**
```bash
clear
mkdir -p /etc/crowdsec/hub
cscli hub update
cscli hub upgrade
systemctl restart crowdsec
systemctl status crowdsec --no-pager | head -5
```

---

## 🚨 PHP-FPM Watchdog — Telegram Alert

If you receive a Telegram alert:
```
⚠️ 222-DE-NetCup
PHP-FPM pool kk-med.eu
CPU=103% for 29min → php-fpm restarted automatically
```
This means the **watchdog** (`php_fpm_watchdog.sh`) detected a runaway PHP-FPM pool and restarted it.  
This is **normal auto-recovery** — no manual action needed unless it repeats.

To investigate:

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
watchdog          # check current PHP-FPM state
sos               # check recent nginx/php errors
wphealth          # check WordPress sites health
```

---

## 💾 Backup System

### ALL Servers — Universal Backup (configs + Docker)
- **Script:** `scripts/backup_all_servers_v2026-04-28.sh`
- **Alias:** `f5backup`
- **What:** Backs up ALL 10 servers in one run:
  - Configs: nginx, php, mysql, crowdsec, fail2ban, ufw, cron, systemd, bashrc, ssh keys
  - Docker image archives for: crypto-bot, semaphore (222), amnezia-awg2 (109)
  - x-ui / Xray dirs for: ALEX, 4TON, TATRA, STOLB, SO, SHAHIN, PILIK, ILYA nodes
- **Schedule:** Wednesday 03:00 + Saturday 03:00 via cron on 222
- **Keeps:** last 10 date-folders per server (~5 weeks)
- **Storage:** `/BACKUP/<SERVER_LABEL>/<YYYY-MM-DD>/`
- **Telegram:** sends summary after completion

### VPN — x-ui / Xray Backup (all nodes)
- **Script:** `VPN/xray_backup_all_nodes.sh`
- **Alias:** `f5xray`
- **What:** Archives `/usr/local/x-ui`, `/etc/x-ui`, `/usr/local/share/xray`, `/root/cert`, `/etc/xray` from each node
- **Nodes backed up:** ALL 8 VPN nodes
- **Schedule:** Sunday 03:00 via cron
- **Keeps:** last 8 archives per node (~2 months history)
- **Storage:** `/BACKUP/vpn/<NODE>/xray/`
- **Archive size:** ~47 MB per node

### Server Backup (222 / 109)
- **Script:** `222/backup_clean.sh` and `109/backup_clean.sh`
- Backs up all WordPress sites, databases, and configs
- Full docs: `222/README.md`

---

## 🚀 Key Scripts Reference

### PHP-FPM Limits (per-site CPU/RAM cap)

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
bash /root/Linux_Server_Public/222/set_php_fpm_limits.sh
```

🚀 **RUN ON SERVER: xxx.xxx.xxx.109 (109-RU-FastVDS)**
```bash
clear
bash /root/Linux_Server_Public/109/set_php_fpm_limits.sh
```

| Parameter | Value | Effect |
|---|---|---|
| `pm.max_children` | ≤8 (calc from RAM) | Limits concurrent PHP processes |
| `pm.max_requests` | 500 | Prevents memory leaks |
| `CPUQuota` | 320% (4 cores × 80%) | Hard CPU cap via systemd |
| `MemoryMax` | ~6.8 GB (85% of 8 GB) | Hard RAM cap via systemd |
| `OOMScoreAdjust` | 300 | OOM killer priority |

### VPN Backups

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
# x-ui / Xray backup (ALL 8 VPN nodes)
f5xray
```

### AmneziaWG VPN Node Statistics

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
bash /root/Linux_Server_Public/VPN/amnezia_stat.sh
```

---

## 🔗 Quick Links

- 📁 [222/ folder (NetCup DE)](222/README.md)
- 📁 [109/ folder (FastVDS RU)](109/README.md)
- 📁 [VPN/ folder (x-ui / Xray)](VPN/README.md)
- 📁 [XRAY/ folder (installers)](XRAY/)
- 📁 [scripts/ folder (shared)](scripts/)
- 🔑 [Cursor SSH Setup](222/SSH-Cursor-Setup.md)
- 📋 [CHANGELOG](CHANGELOG.md)
- 📋 [OPERATIONS](OPERATIONS.md)
- 🌐 [Domain List](domains.md)

---

## 🚀 XRAY + x-ui Installers

### 1. Safe Installer (adds to existing services)
```bash
bash <(curl -s https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/XRAY/xray_safe_installer.sh)
```

### 2. Clean Installer (removes old Xray only)
```bash
bash <(curl -s https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/XRAY/xray_clean_installer.sh)
```

### 3. Full Clean Installer (for fresh servers ONLY — destroys existing config)
```bash
bash <(curl -s https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/XRAY/xray_installer.sh)
```

---

*= Rooted by VladiMIR + AI | v2026.06.10 | github.com/GinCz =*
