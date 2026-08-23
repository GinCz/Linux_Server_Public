# ⚡ AI Token Economy: Practical DevOps Engineering Guide

> **Production engineering patterns for context optimization and 90%+ token reduction across autonomous AI coding agents and LLMs (Cursor, Google Antigravity, Claude Code, OpenAI Codex, GitHub Copilot, Google Gemini).**  
> 🔗 Repository: [GitHub: Linux_Server_Public/AI_Tokens ↗](https://github.com/GinCz/Linux_Server_Public/tree/main/AI_Tokens) | Author: [GinCz ↗](https://github.com/GinCz)

---

## 🏛️ 1. Architecture: Git-Synced Worklog vs. Monolithic Sessions

In all Large Language Models, **every new message re-transmits the complete conversation history**. Keeping a single multi-turn session active over multiple tasks causes quadratic context growth, resulting in severe rate throttling, high token costs, and attention drift.

The foundational solution is decoupling persistent project memory from transient chat context using a **locally synchronized Git repository and structured worklog (`WORKLOG.md`)**.

```
┌────────────────────────────────────────────────────────────────────────────────┐
│               MONOLITHIC CHAT vs. GIT-SYNCED WORKLOG ARCHITECTURE              │
├──────────────────────────────────────────────────┬─────────────────────────────┤
│ ❌ MONOLITHIC CHAT (Single multi-turn session)   │ ✅ GIT WORKLOG ARCHITECTURE │
├──────────────────────────────────────────────────┼─────────────────────────────┤
│ • Turn 1:  5k tokens                             │ • Chat 1 (Task A): 5k       │
│ • Turn 5:  25k tokens                            │   ➔ Commit to WORKLOG.md    │
│ • Turn 10: 65k tokens                            │ • Chat 2 (Task B, Ctrl+N):  │
│ • Turn 15: 110k tokens                           │   ➔ Reads last 50 log lines │
│ • Turn 20: 170k tokens                           │     (~500 tokens overhead!) │
│ • Turn 25: 250k tokens (Quadratic growth)        │   ➔ Executes Task B (5k)    │
│                                                  │   ➔ Commit to WORKLOG.md    │
│ 💸 Total Session Payload: ~625,000 tokens        │ 💰 Total Series Tokens: ~12k│
│ 📉 Outcome: Context dilution, rate throttling    │ 📈 Outcome: 100% precision  │
└──────────────────────────────────────────────────┴─────────────────────────────┘
```

---

## 🚨 2. Operational Guard: Dual-Trigger Session Alerts

To enforce task isolation and prevent silent context bloat, the AI assistant is configured to evaluate session weight continuously and output a standardized alert when either threshold is reached:

1. **Volume Threshold:** Cumulative session context approaches or exceeds **25,000 tokens** (e.g., following heavy script generation, large file inspections, or verbose terminal logs).
2. **Turn Threshold:**
   - Active coding / terminal execution mode: session reaches **8–10 turns**.
   - General technical discussion mode: session reaches **12–15 turns**.

```markdown
> ⚠️ **SESSION OVERLOAD ALERT:** Context size has exceeded safe operating limits (>25k tokens / >8 active turns). Commit current state to Git (WORKLOG.md) and initialize a fresh session (`Ctrl+N` / `Cmd+N`) to prevent exponential token consumption and context drift.
```

---

## ⚡ 3. 10 DevOps Engineering Guidelines for Token Efficiency

1. **"One Task — One Session" (`Ctrl+N` / `Cmd+N`):**
   * Commit work at milestone completion and start a fresh chat session. Eliminates 90–95% of cumulative token overhead.
2. **Persistent Git Worklog (`WORKLOG.md`):**
   * Maintain a running Markdown journal of architectural changes, configurations, and fixes. New sessions re-hydrate technical context in ~500 tokens instead of 50k+ tokens of conversational history.
3. **Local-First Knowledge Access:**
   * Store infrastructure maps, server lists, and reference cards in a local synchronized repository. Reading a local file costs ~100 tokens with zero latency versus 15,000+ tokens for web or remote API scraping.
4. **Name Canary (Context Telemetry):**
   * Enforce addressing the user directly by name on every turn without conversational pleasantries ("Hello", "Greetings"). Dropping the user's name signals context fatigue (attention dilution) and indicates it is time to cycle the session.
5. **Zero-Bloat Chat Discipline:**
   * Prohibit streaming large source code files, Base64 dumps, or raw terminal logs into the conversation stream. Write assets directly to disk and return concise diffs and target paths.
6. **Slice-Only File Reading:**
   * Avoid full-file reads on files exceeding 100 lines. Enforce bounded line slices (`StartLine`/`EndLine` in 50–100 line blocks) or targeted `ripgrep` / `grep` queries.
7. **Monolithic Command Execution:**
   * Combine multi-command shell routines into a single consolidated script starting with terminal clearing (`clear` / `cls`). Avoid interactive one-by-one round-trips.
8. **Anti-Hang and Decoupled Background Daemons:**
   * Ban polling loops in the chat interface. For operations exceeding 2 minutes, decouple execution into standalone background services/daemons with asynchronous notifications (e.g., Telegram / Webhook).
9. **Strict Workspace Ignore Filters:**
   * Exclude `.git/`, `node_modules/`, `vendor/`, `dist/`, `build/`, `*.log`, `*.zip`, and binary dumps from AI indexing and search scopes.
10. **Corporate Data Masking (Confluence, Jira, Microsoft 365):**
    * Query enterprise knowledge systems with strict metadata masks (`limit=3..5`, key, summary, status). Prohibit raw attachment ingestion and multi-comment thread scraping.

---

## 📁 4. Model Optimization Profiles

| AI Engine / Environment | Profile Document | Primary Focus |
| :--- | :--- | :--- |
| **Google Antigravity** | [ANTIGRAVITY.md ↗](ANTIGRAVITY.md) | Home + CANCOM Enterprise, 90-day KB Cache, Subagent Budgeting, Name Canary |
| **OpenAI Codex & ChatGPT** | [CHATGPT_CODEX.md ↗](CHATGPT_CODEX.md) | Windows Zero-Waste Spec, `config.toml`, `sync-kb.ps1`, Custom Instructions |
| **Google Gemini & Studio** | [GOOGLE_GEMINI.md ↗](GOOGLE_GEMINI.md) | Context Caching (90% discount), `thinking_budget` limit (1024), System Prompts |
| **Cursor IDE & Composer** | [CURSOR.md ↗](CURSOR.md) | `.cursorrules`, `.cursorignore`, `@-mentions` vs `@Codebase`, Surgical Diffs |
| **VS Code & Copilot** | [VSCODE_COPILOT.md ↗](VSCODE_COPILOT.md) | `copilot-instructions.md`, `.clinerules`, Continue.dev token budgeting |
| **Claude & Anthropic** | [CLAUDE_DEV.md ↗](CLAUDE_DEV.md) | `CLAUDE.md`, Ephemeral Prompt Caching, `--max-thinking-tokens`, 5-hour window |
| **Perplexity AI** | [PERPLEXITY.md ↗](PERPLEXITY.md) | Focus modes (Writing/Code), domain filters, citation bloat elimination |

---
*Maintained and versioned in [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public).*
