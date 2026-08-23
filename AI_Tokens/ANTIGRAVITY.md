# 🤖 Google Antigravity: Token Optimization Profile (Home & Enterprise CANCOM)

> **Dedicated optimization profile for Google Antigravity autonomous multi-agent environment.**  
> Includes unified configurations for personal workstations (Home) and corporate environments (CANCOM: Confluence, Jira, Microsoft 365, Entra ID).  
> 🔗 Repository: [GitHub: Linux_Server_Public/AI_Tokens ↗](https://github.com/GinCz/Linux_Server_Public/tree/main/AI_Tokens) | Author: [GinCz ↗](https://github.com/GinCz)

---

## 🔍 Mandatory Name Canary & Zero Greeting Rule

> [!IMPORTANT]
> - **Address By Name:** Start every response directly by addressing the user by name: **"Vladimir, ..."**.
> - **Strict Ban on Repetitive Greetings:** NEVER say *"Hello"*, *"Здравствуйте"*, or conversational pleasantries on each turn. Jump straight into the technical response.
> - **Amnesia Detection:** If the agent ever drops the name, it indicates prompt attention dilution (context fatigue) — immediately start a fresh chat (`Ctrl+N`).

---

## 🚨 Mandatory Red Warning: Dual-Trigger Session Guard

When EITHER condition is met: (1) context approaches **25k tokens**, OR (2) conversational turns reach **8–10 steps in active coding mode** (or 12–15 in discussion), the agent MUST output this alert at the beginning of the response:

> <span style="color:#ff3333; font-weight:bold; font-size:1.1em;">⚠️ WARNING: Session context is overloaded (>25k tokens / >8 active steps)! To prevent exponential token waste and context drift, commit changes to Git (WORKLOG.md) and start a fresh chat (Ctrl+N / Cmd+N)!</span>

---

## 🎯 1. Global Token Economy & Git Worklog Architecture

Antigravity operates as an autonomous agentic loop. Each execution cycle passes: system instructions, tool call schemas, environment state, read files, and conversational history. To minimize overhead, the agent adheres to strict directives:

1. **Persistent Git Worklog & Local-First Repository Sync:** Maintain a dedicated Git repository (e.g. `Secret_Privat`) synced to a local directory. All actions, configuration changes, server updates, and debugging steps are continuously written to `WORKLOG.md`. In a new chat (`Ctrl+N`), reading just 50 lines of the local log (~500 tokens) restores 100% of context instantly without re-ingesting 50k–100k tokens of previous chat history.
2. **"One Task Per Chat" (Ctrl+N):** Once a functional milestone is achieved, changes are committed and a new session is started. This cuts per-session token expenditure by **90–95%**.
3. **Zero-Bloat Chat Discipline:** Never dump massive code listings, Base64 blocks, or verbose multi-page terminal outputs into the chat stream. Save code directly into files (`C:\UTIL\` or `D:\AI\`), outputting only brief diffs and target paths.
4. **Anti-Polling / Anti-Hang Protocol:** The agent is strictly forbidden from executing looping status checks (`manage_task status` in a loop). Tasks taking > 2 minutes are immediately decoupled into standalone system daemons with Telegram notifications, allowing the agent to exit cleanly.

---

## 🏢 2. Corporate Enterprise Protocol (CANCOM / Confluence / Microsoft Tickets)

> ⚠️ **Corporate Data Masking Rules:** When interacting with enterprise knowledge bases (Confluence Wiki, Jira Service Management, Microsoft Graph API, Entra ID, ServiceNow):

### [RULE: Confluence & SharePoint Documentation Queries]
* **Ban on Full Page Ingestion:** Never fetch full multi-megabyte enterprise wiki pages with rich HTML markup and embedded tables.
* **Metadata-First Discovery:** Always query with `limit=3` or `limit=5`, requesting only `Title`, `ID`, `URL`, and a concise excerpt (up to 200 characters).
* **Local Knowledge Card Caching (90-day TTL):** Save extracted summaries to `%USERPROFILE%\knowledge\.cache\` with `cached_at` and `expires_at` metadata. Expire after 90 days.

### [RULE: Microsoft 365, Jira & ServiceNow Tickets]
* **Ban on Full Thread Scraping:** Never ingest 50+ back-and-forth ticket comment histories.
* **Field Masking:** Restrict query payloads strictly to: `key`, `summary`, `status`, `last_comment`.
* **Ban on Raw Attachment Processing:** Never automatically download or parse memory dumps, screenshots, large PDFs, or raw database extracts unless explicitly requested with a specific filename.

---

## 👥 3. Subagent Budgeting & Model Hierarchy

When invoking subagents via `invoke_subagent`, adhere to this model tiering:
* **`flash_lite`:** Initial file discovery, path verification, environment existence checks.
* **`flash` (Default):** Script execution, focused refactoring, codebase search, log analysis.
* **`pro`:** Reserved strictly for complex cross-system architectural planning, multi-component debugging, and ambiguity resolution.

---

## 🛠️ 4. Tool Execution Optimization

| Antigravity Tool | Forbidden (Token Burn) | Enforced (Zero-Waste) |
| :--- | :--- | :--- |
| `view_file` | Reading entire files > 200 lines | Use `StartLine` and `EndLine` slices (50–100 line windows) |
| `grep_search` | Unfiltered root searches across all files | Always supply strict file masks in `Includes` (e.g., `*.sh`, `*.md`) |
| `find_by_name` | Deep recursive directory traversal | Set `MaxDepth: 2` or `3` and specific `SearchDirectory` |
| `run_command` | Interactive one-line trial-and-error commands | Consolidate into a **single monolithic script** starting with `cls` / `clear` |
| `manage_task` | Looping `status` polling in a `while` loop | Use sufficient `WaitMsBeforeAsync` (up to 10000ms) or background daemon |

---

## ⚙️ 5. Copy-Paste Rules Configuration (`GEMINI.md` / Master Rules)

Add this block to `C:\Users\USER\.gemini\config\rules\GEMINI.md` or inject into system prompt:

```markdown
# TOKEN OPTIMIZATION & AGENT CONTEXT DISCIPLINE

1. USER & NAME CANARY:
   - Always address the user strictly as Vladimir (Владимир) at the start of every response.
   - DO NOT use repetitive greetings ("Hello", "Здравствуйте"). Jump directly into the answer.
   - Language: Russian by default (switch to English/Czech ONLY upon explicit request).

2. PERSISTENT GIT WORKLOG & LOCAL-FIRST ACCESS:
   - Maintain a local-synced Git repo (e.g. D:\AI\GitHub\Secret_Privat). Log all actions into WORKLOG.md.
   - Re-hydrate context in fresh chats by reading the local log (500 tokens), avoiding massive chat replay.
   - Practice "One Task Per Chat": Start fresh sessions (Ctrl+N) to avoid context explosion.

3. DUAL-TRIGGER SESSION GUARD:
   - Trigger the red warning banner when context reaches 25k tokens OR turns reach 8–10 in code mode.
   - Zero-Bloat Chat: Never output giant code/Base64 in chat text. Write directly to files (C:\UTIL\, D:\AI\).
   - Range-Based File Reading: Never read entire large files; use view_file with StartLine/EndLine slices.
   - Corporate Data Masking: Query Confluence/Jira/Microsoft APIs with limit=5 and fetch metadata only.
   - Subagent Budgeting: Use flash/flash_lite for subagent research tasks.

4. EXECUTION DISCIPLINE:
   - Monolithic Scripting: Combine multiple shell steps into a single executable script starting with clear / cls.
   - Anti-Polling / Anti-Hang: Never poll background tasks in a loop. Decouple long tasks (>2 min) into daemons.

5. FOOTER STATUS:
   - Append a single-line status footer at the very end of EVERY response:
     <small>✅ Done: Started HH:MM:SS • Finished HH:MM:SS • Total: HH:MM:SS (Tokens: ~Xk)</small>
```

---
*Maintained and versioned in [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public).*
