# đź¤– AI API Keys Live Monitor & Real-Time Balance Audit (`to`)

> **Command:** `to`  
> **Servers:** 222-DE NetCup (Ubuntu 24.04 Master Node) & all Linux nodes  
> **Format:** 100% Pure ASCII & English (Optimized for mRemoteNG, PuTTY, and OpenSSH)  
> **Security:** Zero credentials in public repositories. Private keys stored exclusively in `Secret_Privat`.

---

## đź“Ś Overview
The `to` utility performs instant real-time balance inquiries and health checks across multiple AI API gateway providers (Tooken Club, ClaudeHub, custom LLM proxies).

```text
=====================================================================================
                   AI API KEYS MONITOR & REAL-TIME BALANCE AUDIT                     
                   Master Node: DE-222 | 2026-09-08 10:52:45 UTC                     
=====================================================================================

STATUS  NAME    CURRENT TOKENS   INITIAL TOKENS   DASHBOARD                LOGIN         
-------------------------------------------------------------------------------------
[OK]    AI_01   259 726          5 000 000        tooken.club/dashboard    user5abznd    
[OK]    AI_02   1 044 751        1 050 000        tooken.club/dashboard    userp8cuvg    
[OK]    AI_03   10 000 000       10 000 000       tooken.club/dashboard    user3lcukp    
[OK]    AI_04   900 000          900 000          app.claudehub.fun        gincz         
-------------------------------------------------------------------------------------

SUMMARY (ALL TOKENS):
  * Active Keys:           4 of 4
  * Total Current Balance: 12 204 477 tokens
  * Total Initial Tokens:  16 950 000 tokens
  * Total Tokens Used:     4 745 523 tokens
=====================================================================================
```

---

## đźš€ Key Features
1. **Live Real-Time Queries (Zero Cache):**
   * Every execution sends direct lightweight `curl` requests to the respective provider's `/v1/balance` REST API.
   * Immediately reflects token consumption from agentic coding, chats, and script runs.
2. **Unified Token Metric:**
   * Converts diverse billing models (direct token counts, currency balances such as RUB/USD) into a unified integer token count.
   * Numbers are cleanly formatted with thousand space separators (`10 000 000`).
3. **Universal Terminal Compatibility:**
   * Pure standard ASCII table layout without multibyte Unicode box characters or emojis.
   * Fits standard 80-85 column terminal windows without line wrapping or text shifts in mRemoteNG.
4. **Instant Health Check:**
   * Highlights active keys with `[OK]` (green) and offline/revoked keys with `[FAIL]` (red).

---

## âš™ď¸Ź How to Run
On Server DE-222:
```bash
to
```
Or download fresh from the private repository:
```bash
bash <(curl -s -H "Authorization: token $GITHUB_TOKEN" \
     -H "Accept: application/vnd.github.v3.raw" \
     https://api.github.com/repos/GinCz/Secret_Privat/contents/scripts/ai_keys_stat.sh)
```

---

## đź”’ Configuration Template (`/root/.ai_keys.conf`)
For standalone usage without the private repo, create `/root/.ai_keys.conf`:
```bash
# Provider|Name|Login|API_Key|InitialTokens|DashboardDomain|Endpoint
tooken|AI_01|username|tc_live_YOUR_KEY_1|5000000|tooken.club/dashboard|https://tooken.club/v1/balance
tooken|AI_02|username|tc_live_YOUR_KEY_2|1050000|tooken.club/dashboard|https://tooken.club/v1/balance
tooken|AI_03|username|tc_live_YOUR_KEY_3|10000000|tooken.club/dashboard|https://tooken.club/v1/balance
claudehub|AI_04|username|sk-hub-YOUR_KEY_4|900000|app.claudehub.fun|https://api.claudehub.fun/v1/balance
```

---
*Rooted by VladiMIR + Antigravity AI | https://github.com/GinCz*