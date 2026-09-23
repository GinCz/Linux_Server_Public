# 🛡️ Universal Master Rules for All AI Engines (Antigravity, Claude, Codex)
> **Master Rules: Mandatory 3-Month Local Cache, Token Economy, Autonomy, and English Code Standards**
> *Owner:* Vladimir Bulantsev (GinCz)

---

## 💎 THE FOUR CARDINAL PILLARS (HIGHEST PRIORITY)

### 🥇 Pillar 1: Mandatory Local Caching of Everything (3 Months Minimum Retention)
1. **Cache Every Retrieved Resource Locally:**
   - ANY external data accessed (Jira tickets, Confluence articles, GitHub files/repos, website content, server logs, API responses) MUST be immediately saved to the local drive (`C:\CANCOM\tickets\`, `C:\CANCOM\knowledge\`, `C:\CANCOM\projects\`, local repositories).
2. **Minimum Cache Retention — 3 Months (90 Days):**
   - All cached local data MUST be preserved and considered valid for at least **3 months**.
3. **Strict Ban on Re-Reading from Remote Sources:**
   - NEVER make repeated network requests to Confluence, GitHub, websites, or remote SSH servers for previously retrieved data. Always read from the local cache to achieve maximum token savings and zero latency.

---

### 🥈 Pillar 2: Maximum Token Economy (Cache-First & Fast Index)
1. **Fast-Router Navigation:** Always read the lightweight root index `C:\CANCOM\INDEX.md` (< 50 lines) first for instant context with minimal token overhead.
2. **Strict Append-Only Policy:** It is strictly prohibited to delete any files or data from `C:\CANCOM\`. All updates are strictly additive.
3. **Pure Text Format:** Store all documentation and tickets as clean text/markdown (`.md` / `.txt`) without binary bloat.

---

### 🥉 Pillar 3: Maximum Autonomy & Proactive Access Resolution
1. **Autonomous Task Execution:**
   - Solve tasks, fix issues, test implementations, and execute workflows 100% autonomously without stopping to ask trivial questions or seeking obvious confirmations.
2. **Proactive Credential Discovery in GitHub:**
   - If credentials, API keys, hostnames, passwords, SSH keys, or access details are required, **proactively search for them first in the private GitHub repository** (`Secret_Privat`, `PASS_KEYS/`, `AWS_Amazon/`, `Oracle/`, `VPN/`, `TELEGRAM_BOT_CONTROL_CENTER.md`) or KeePass paths. Almost all operational access details are already documented in GitHub.

---

### 🏅 Pillar 4: Fallback to Complete, Ready-to-Run Monolithic English Code
1. **Immediate Delivery of Complete Monolithic Code:**
   - If a task cannot be executed directly or requires manual execution by Vladimir, immediately generate a **single monolithic code block** ready for single-paste execution (never split into fragmented steps).
2. **Strict English-Only Code & Comments:**
   - All executable code (PowerShell, Bash, Python, CMD, SQL, JSON, YAML) and ALL comments within the code MUST be written strictly in **English** to guarantee zero character encoding/corruption issues across Windows and Linux terminals.
3. **Mandatory Standardized Header on Every Code Block:**
   - Every executable script or block MUST start with an exact English header comment:
     * `Execution Context :` (e.g. `PowerShell (Run as Administrator)`, `Bash (SSH root)`)
     * `Target Server     :` (Host name and exact IP address, e.g. `AWS 82 (IP: 3.67.43.82)`, `DE-222 (IP: 152.53.182.222)`, `Local PC`)
     * `Description       :` (Concise summary of the task and operations performed)
   - Immediately following the header, the very first executable command MUST be `clear` (PowerShell/Bash) or `cls` (CMD).

```powershell
# =============================================================================
# Execution Context : PowerShell (Run as Administrator)
# Target Server     : AWS 82 (IP: 3.67.43.82)
# Description       : Deep system cleanup, telemetry removal and volume trim
# =============================================================================
clear
```
```bash
# =============================================================================
# Execution Context : Bash (SSH root)
# Target Server     : DE-222 (IP: 152.53.182.222)
# Description       : Backup verification and log maintenance
# =============================================================================
clear
```

---

## 🌐 Communication & Language Standard
* **Dialogue Language:** Always respond and communicate with Vladimir in **Russian** (unless English or Czech is explicitly requested).
* **Code & Comments:** Always strictly in **English**.
