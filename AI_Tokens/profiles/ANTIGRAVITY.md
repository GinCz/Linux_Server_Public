# 🤖 Google Antigravity: Token Optimization Profile (Home & Infrastructure)

> **Dedicated optimization profile for Google Antigravity autonomous multi-agent environment (Scenario A).**  
> Tailored for personal workstations (Windows 10) managing complex infrastructure: Cloudflare, SSH (Master Node DE-222), AWS, and Oracle Cloud.  
> *Note: This profile does NOT connect to corporate Jira or Confluence. See CHATGPT_CODEX.md for enterprise MCP setups.*  
> 🔗 Repository: [GitHub: Linux_Server_Public/AI_Tokens ↗](https://github.com/GinCz/Linux_Server_Public/tree/main/AI_Tokens) | Author: [GinCz ↗](https://github.com/GinCz)

---

## 🔍 Mandatory Name Canary & Zero Greeting Rule

> [!IMPORTANT]
> - **Address By Name:** Start every response directly by addressing the user by name: **"Vladimir, ..."**.
> - **Strict Ban on Repetitive Greetings:** NEVER say *"Hello"*, *"Здравствуйте"*, or conversational pleasantries on each turn. Jump straight into the technical response.
> - **Telemetry Canary:** Это критический индикатор здоровья сессии. Если агент забывает обратиться по имени, это означает переполнение контекста (context fatigue) и риск галлюцинаций — немедленно зафиксируй логи и начни новый чат (`Ctrl+N`).

---

## 🚨 Dynamic Session Guard: Anti-Premature Completion & F4 Protection

Antigravity uses a specific UI interaction model where pressing `F4` (Voice Input) instantly interrupts the agent and cancels background tasks (`manage_task kill`).

> [!WARNING] 
> **Anti-Premature Completion Protocol:**  
> The agent MUST NEVER say "Done" or output the final `✅ Done` footer while long-running background tasks (SSH commands, AWS provisions, Cloudflare syncs) are still executing. If the user sees "Done" and presses `F4` to reply, all pending tasks will be forcefully cancelled. The agent MUST wait for task completion, verify logs, and ONLY THEN output the final status.

---

## 🎯 1. Local Infrastructure Knowledge Base (Cache-First)

Even without Jira or Confluence, the Antigravity agent requires a local cache to save tokens on repetitive infrastructure queries.

### What is Cached Locally (`D:\AI\knowledge\infra_cache\`):
1. **Cloudflare:** Zone IDs, DNS records dumps, WAF rulesets.
2. **AWS / Oracle:** Instance IDs, VPC layouts, security group rules.
3. **SSH / Servers:** Master Node DE-222 configurations, IPs, active services on RU-109, VPN node states.

### The Workflow:
* **Never Scrape Repeatedly:** Do not run `aws ec2 describe-instances` or massive Cloudflare API queries on every chat.
* **Read from Cache:** The agent first reads the local JSON/MD cache. 
* **Refresh Script:** A specific script (e.g., `sync-infra.ps1`) is used to poll AWS/Oracle/Cloudflare APIs and update the local cache only when the user explicitly requests a state refresh.

---

## ⚡ 2. Global Token Economy & Git Worklog Architecture

1. **Persistent Git Worklog (`WORKLOG.md`):** All actions, SSH configuration changes, and AWS/Oracle updates are continuously written to `WORKLOG.md` in `D:\AI\GitHub\Secret_Privat`. In a new chat (`Ctrl+N`), reading the last 50 lines (~500 tokens) restores 100% of context instantly.
2. **"One Task Per Chat" (Ctrl+N):** Once an AWS server is configured or a Cloudflare rule is deployed, commit changes and start a new session. This cuts token expenditure by **90–95%**.
3. **Zero-Bloat Chat Discipline:** Never dump massive Nginx configs, Base64 blocks, or verbose SSH `journalctl` outputs into the chat stream. Save logs directly to `C:\UTIL\` or `D:\AI\`.

---

## 🛠️ 3. Tool Execution Optimization

| Antigravity Tool | Forbidden (Token Burn) | Enforced (Zero-Waste) |
| :--- | :--- | :--- |
| `run_command` | Interactive SSH execution without `-o BatchMode=yes` | **Always** use non-interactive SSH with timeout: `ssh -o BatchMode=yes -o ConnectTimeout=5 -i C:\Users\USER\.ssh\id_ed25519 root@<IP> "cmd"` |
| `run_command` | Short sequential commands | Consolidate into a **single monolithic script** starting with `cls` / `clear`. |
| `view_file` | Reading entire files > 100 lines | Use `StartLine` and `EndLine` slices (50–100 line windows) |
| `grep_search` | Unfiltered root searches | Always supply strict file masks in `Includes` (e.g., `*.conf`) |

---

## ⚙️ 4. System Prompts & Configurations (`GEMINI.md`)

When updating `GEMINI.md` for the Home profile, strictly enforce the Infrastructure Cache and Non-Interactive SSH rules to prevent hangs and token leaks.

---
*Maintained and versioned in [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public).*
