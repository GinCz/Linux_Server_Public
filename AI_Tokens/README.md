# ⚡ AI Token Economy: Practical DevOps Engineering Guide

> **Production engineering guidelines for optimizing context and reducing LLM/agent token consumption by 90%+ (Cursor, Google Antigravity, Claude Code, OpenAI Codex, GitHub Copilot, Google Gemini).**  
> 🔗 Repository: [GitHub: Linux_Server_Public/AI_Tokens ↗](https://github.com/GinCz/Linux_Server_Public/tree/main/AI_Tokens) | Author: [GinCz ↗](https://github.com/GinCz)

---

## 🚨 1. Preventive Guard: Dual-Trigger Session Shield

The AI assistant **MUST** render a red warning banner at the very start of its response when **EITHER** trigger condition is reached:

1. **Context Volume Trigger:** Cumulative session context approaches or exceeds **25,000 tokens** (or after executing 2+ heavy scripts, large file reads, or console dumps).
2. **Turn Count Trigger:**
   - Active coding / terminal execution mode: session exceeds **8–10 turns**.
   - General technical discussion mode: session exceeds **12–15 turns**.

```markdown
> <span style="color:#ff3333; font-weight:bold; font-size:1.1em;">⚠️ WARNING: Session context is overloaded (>25k tokens / >8 active steps)! To avoid exponential token waste and context drift, commit changes to Git (WORKLOG.md) and start a fresh chat (Ctrl+N / Cmd+N)!</span>
```

> 💡 **Why this is critical:** LLMs resend the entire conversation history on every interaction. A 25-turn monolithic session consumes 10x to 15x more tokens per single interaction than a clean, task-isolated session.

---

## 🏛️ 2. Architecture: Git Worklog vs. Monolithic Chat Bloat

Decoupling long-term project memory from short-term chat context using a **locally synchronized Git repository**:

```
┌────────────────────────────────────────────────────────────────────────────────┐
│               MONOLITHIC CHAT vs. GIT-SYNCED WORKLOG ARCHITECTURE              │
├──────────────────────────────────────────────────┬─────────────────────────────┤
│ ❌ MONOLITHIC CHAT (Single multi-day session)    │ ✅ GIT WORKLOG ARCHITECTURE │
├──────────────────────────────────────────────────┼─────────────────────────────┤
│ • Turn 1: 5k tokens                              │ • Chat 1 (Task A): 5k       │
│ • Turn 5: 25k tokens                             │   ➔ Commit to WORKLOG.md    │
│ • Turn 10: 65k tokens                            │ • Chat 2 (Task B, Ctrl+N):  │
│ • Turn 15: 110k tokens                           │   ➔ Read 50 lines of log    │
│ • Turn 20: 170k tokens                           │     (~500 tokens context!)  │
│ • Turn 25: 250k tokens (Quadratic growth!)       │   ➔ Execute Task B (5k)     │
│                                                  │   ➔ Commit to WORKLOG.md    │
│ 💸 Total Session Tokens: ~625,000                │ 💰 Total Series Tokens: ~12k│
│ 📉 Result: Context dilution, drift & rate limits │ 📈 Result: 100% precision   │
└──────────────────────────────────────────────────┴─────────────────────────────┘
```

---

## ⚡ 3. 10 DevOps Engineering Guidelines for Token Economy

1. **"One Task — One Session" Principle (`Ctrl+N` / `Cmd+N`):**
   * Complete milestone ➔ Commit changes to Git ➔ Start a fresh session. Reduces total token consumption by 90–95%.
2. **Persistent Git Worklog (`WORKLOG.md`):**
   * Continuously record all actions, configurations, decisions, and fixes into a Markdown journal. A fresh session re-hydrates full technical context from the local log in ~500 tokens instead of 50k+ tokens of chat history.
3. **Local-First Knowledge Access:**
   * Keep infrastructure maps, credentials, and reference documentation in a local synchronized repository. Reading a local file costs ~100 tokens with zero latency, compared to 15,000+ tokens for web/API scraping.
4. **Name Canary (Context Drift Detection):**
   * Enforce addressing the user directly by name on every turn without conversational pleasantries ("Hello", "Greetings"). If the model drops the name, it serves as a visual indicator of attention dilution and context fatigue.
5. **Zero-Bloat Chat Discipline:**
   * Prohibit streaming large code listings, Base64 blocks, or multi-page command outputs into the chat stream. Write directly to files on disk and return only brief diffs and target file paths.
6. **Slice-Only File Reading:**
   * Never ingest entire files exceeding 100 lines. Enforce line range windows (`StartLine`/`EndLine` 50–100 lines) and targeted `grep` / `ripgrep` queries.
7. **Monolithic Command Execution:**
   * Combine multi-step shell commands into a single executable script starting with console clearing (`clear` / `cls`). Avoid interactive line-by-line round-trips.
8. **Anti-Hang and Anti-Polling Protocol:**
   * Never execute status polling loops in the chat interface. For operations exceeding 2 minutes, decouple immediately into background system daemons with automated alerts (e.g. Telegram / Webhook).
9. **Strict Workspace Ignore Filters:**
   * Exclude `.git/`, `node_modules/`, `vendor/`, `dist/`, `build/`, `*.log`, `*.zip`, and binary archives from codebase indexing and search scopes.
10. **Corporate Data Masking (Confluence, Jira, Microsoft 365):**
    * Query enterprise APIs with metadata limits (`limit=3..5`, key, summary, status). Ban raw attachment downloads and multi-comment thread scraping.

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
