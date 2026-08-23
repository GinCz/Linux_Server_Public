# 🧠 AI Tokens: Universal Token Economy & Context Optimization Manifesto

> **Comprehensive knowledge base, architectural patterns, and plug-and-play optimization profiles for all modern AI coding assistants, autonomous agents, and Large Language Models.**  
> 🔗 Repository: [GitHub: Linux_Server_Public/AI_Tokens ↗](https://github.com/GinCz/Linux_Server_Public/tree/main/AI_Tokens) | Author: [GinCz ↗](https://github.com/GinCz)

---

## ⚡ Quick Start: Zero-Risk AI Self-Configuration

> [!TIP]
> **How to use this repository:**  
> Simply provide the URL of this repository or any individual markdown file to your AI assistant (Cursor, OpenAI Codex, Claude Code, Google Antigravity, ChatGPT, Gemini, Cline, Copilot):  
> `https://github.com/GinCz/Linux_Server_Public/tree/main/AI_Tokens`  
> 
> **Zero Risk Guarantee:** Any modern AI agent will automatically inspect its environment, identify its model and runtime, and apply **only the non-conflicting, additive optimization rules**. It will never overwrite your personal accounts, secrets, or custom infrastructure logic.

---

## 🔍 The "Name-Check" Canary: Real-Time Context Fatigue Detection

> [!IMPORTANT]
> **Universal Telemetry Law (Addressing by Name Without Repetitive Greetings):**  
> 1. **Address by Name Every Turn:** The AI assistant MUST address the user by their exact name at the beginning of every response (e.g., **"Vladimir, ..."**).
> 2. **Strict Ban on Repetitive Greetings:** The AI must NEVER say *"Hello"*, *"Greetings"*, or *"Здравствуйте"* in every turn. Starting with repetitive pleasantries wastes tokens and breaks technical flow.
> 3. **The "Amnesia Canary" Purpose:** If the AI suddenly drops your name or reverts to generic greetings, it serves as an **immediate visual diagnostic indicator that context attention has diluted (Context Drift / Amnesia)**. The user instantly knows the model is losing track of instructions and it is time to open a fresh session (`Ctrl+N`).

---

## 🚨 Universal Red Alert: Dual-Trigger Session Guard

<span style="color:#ff3333; font-weight:bold; font-size:1.1em;">⚠️ MANDATORY AGENT PROTOCOL: The AI assistant MUST display this red warning banner at the very top of its response when EITHER of the following two conditions is met:</span>

1. **Token Volume Trigger:** Cumulative session context approaches or exceeds **25,000 tokens** (or after 2+ heavy script generations, large file reads, or extensive terminal dumps).
2. **Turn Count Trigger:**
   - Active coding / terminal execution mode: session reaches **8–10 turns**.
   - General discussion / prose mode: session reaches **12–15 turns**.

```markdown
> <span style="color:#ff3333; font-weight:bold; font-size:1.1em;">⚠️ WARNING: Session context is overloaded (>25k tokens / >8 active steps)! To prevent exponential token waste and context drift, commit changes to Git (WORKLOG.md) and start a fresh chat (Ctrl+N / Cmd+N)!</span>
```

### Why is this rule critical?
In all Large Language Models, **every new message re-sends the entire preceding chat history**. A 30-message session costs **10x to 15x more tokens per single interaction** than breaking the task into focused, independent sessions with Git checkpoints.

```
Session Length │ Input Tokens Per Single Interaction
───────────────┼────────────────────────────────────────────────────────
Turn 1         │ ██ 4k
Turn 5         │ ████████ 20k
Turn 8         │ ████████████████ 45k ⚠️ (TRIGGER DUAL-GUARD ALERT)
Turn 15        │ ████████████████████████████████████ 110k
Turn 25        │ ████████████████████████████████████████████████████████ 200k+ (EXTREME WASTE)
```

---

## 📑 Table of Contents

1. [Understanding Tokens: Mechanics and Ratios](#1-understanding-tokens-mechanics-and-ratios)
2. [Input vs Output Token Anatomy](#2-input-vs-output-token-anatomy)
3. [The Compounding Context Effect](#3-the-compounding-context-effect)
4. [Persistent Git Worklog & Local-First Repository Architecture](#4-persistent-git-worklog--local-first-repository-architecture)
5. [Rate Limits & Quota Architecture (TPM, RPM, RPD, Rolling Windows)](#5-rate-limits--quota-architecture-tpm-rpm-rpd-rolling-windows)
6. [Prompt Caching: Up to 90% Cost Reduction](#6-prompt-caching-up-to-90-cost-reduction)
7. [The 10 Immutable Laws of AI Token Optimization](#7-the-10-immutable-laws-of-ai-token-optimization)
8. [Directory of Dedicated Model Profiles](#8-directory-of-dedicated-model-profiles)

---

## 1. Understanding Tokens: Mechanics and Ratios

A **Token** is the fundamental atomic unit of text processed by a Neural Network. LLMs do not read words or characters directly; they process numerical token IDs via subword tokenizers (BPE, WordPiece, SentencePiece, Tiktoken).

### Text-to-Token Ratios:
* **English Prose:** 1 token ≈ **0.75 words** (~4 characters). *"Hello world"* = 2 tokens.
* **Non-Latin Languages (Cyrillic, Asian scripts):** Due to multi-byte UTF-8 encoding, words consume more tokens: 1 word ≈ **2–4 tokens**.
* **Source Code:** Indentations, brackets, syntax operators, camelCase, and snake_case identifiers tokenize densely: **1 line of complex code = 10–30 tokens**.

---

## 2. Input vs Output Token Anatomy

Every request consists of two fundamentally distinct token streams:

```
┌────────────────────────────────────────────────────────────────────────┐
│                          TOTAL SESSION PAYLOAD                         │
├──────────────────────────────────────────┬─────────────────────────────┤
│         INPUT TOKENS (Prompt / Context)  │    OUTPUT TOKENS (Completion)│
├──────────────────────────────────────────┼─────────────────────────────┤
│ • System Instructions & Rules            │ • Generated Answer / Text   │
│ • Tool Schemas (Function Calling)        │ • Generated Code Files      │
│ • Read Files, Logs & Environment Context │ • Hidden Thinking (CoT)     │
│ • Full Accumulated Conversation History  │ • Tool Call Invocations     │
│                                          │                             │
│ 💰 Cost: Lower base rate                 │ 💰 Cost: 3x – 5x higher     │
└──────────────────────────────────────────┴─────────────────────────────┘
```

> 💡 **Core Takeaway:** In autonomous coding agents (Antigravity, Cursor, Codex, Cline), **90–95% of token consumption is spent on Input Tokens (Context Re-feeding)**, not on the generated code itself.

---

## 3. The Compounding Context Effect

When users keep a single chat open for multiple days or tasks, token usage explodes quadratically:

* **Step 1:** Model receives: [Rules (3k)] + [Prompt 1 (1k)] = **4,000 tokens**.
* **Step 2:** Model receives: [Rules (3k)] + [Prompt 1 (1k)] + [Output 1 (2k)] + [Prompt 2 (1k)] = **7,000 tokens**.
* **Step 10:** Model re-reads all previous turns on every keystroke = **60,000 – 80,000 tokens per interaction**.
* **Step 20:** Single message payload reaches **150,000 – 200,000+ tokens**.

---

---

## 4. Persistent Git Worklog & Local-First Repository Architecture

> 💡 **The Core Architecture for 90%+ Token Reduction:**

The single most effective way to eliminate token waste is decoupling long-term project memory from short-term LLM chat history by using a **synchronized local-to-remote Git repository**.

```
┌────────────────────────────────────────────────────────────────────────────────┐
│             TRADITIONAL AI CHAT vs. GIT-SYNCED WORKLOG ARCHITECTURE            │
├──────────────────────────────────────────────────┬─────────────────────────────┤
│ ❌ TRADITIONAL MULTI-TURN CHAT (Monolithic)      │ ✅ GIT WORKLOG ARCHITECTURE │
├──────────────────────────────────────────────────┼─────────────────────────────┤
│ • Turn 1: 5k tokens                              │ • Chat 1 (Task A): 5k tokens│
│ • Turn 5: 25k tokens                             │   ➔ Commit to WORKLOG.md    │
│ • Turn 10: 65k tokens                            │ • Chat 2 (Task B, Ctrl+N):  │
│ • Turn 15: 110k tokens                           │   ➔ Read 50 lines of log    │
│ • Turn 20: 170k tokens                           │     (~500 tokens context!)  │
│ • Turn 25: 250k tokens (Quadratic growth!)       │   ➔ Complete Task B (5k)    │
│                                                  │   ➔ Commit to WORKLOG.md    │
│ 💸 Total Tokens Burned: ~625,000 tokens          │ 💰 Total Tokens: ~12,000    │
│ 📉 Quality: Attention dilution & hallucinations  │ 📈 Quality: 100% precision  │
└──────────────────────────────────────────────────┴─────────────────────────────┘
```

### 🔑 Key Operational Directives:
1. **Synchronized Local Repository:** Keep a dedicated private or project GitHub repository permanently synchronized with a local directory on your disk (e.g., `D:\AI\GitHub\Your_Project`).
2. **Continuous Step Logging (`WORKLOG.md`):** Every important action, script execution, architectural decision, server configuration, and bug fix MUST be recorded into a structured Markdown journal (`WORKLOG.md` or `session-logs/`).
3. **Local-First Instant Hydration:** When starting a fresh chat session (`Ctrl+N`), the AI agent reads only the most recent 50–100 lines of `WORKLOG.md` from the local disk (~500 tokens). This instantly restores full technical context without re-ingesting tens of thousands of past chat tokens or making slow, expensive web requests.
4. **Resilience & Traceability:** If a chat crashes, times out, or experiences context drift, 0% of progress is lost. The repository acts as the immutable single source of truth.

---

## 5. Rate Limits & Quota Architecture (TPM, RPM, RPD, Rolling Windows)

AI providers (Google Gemini, OpenAI, Anthropic, Cursor) enforce strict throughput tiers:

1. **TPM (Tokens Per Minute):** Maximum tokens processed per 60-second window (e.g., 1M–4M TPM for Gemini Flash).
2. **RPM (Requests Per Minute):** Request frequency cap (typically 15 to 1,000 RPM).
3. **RPD (Requests Per Day):** Daily quota cap (e.g., 1,500 RPD for free tiers, higher on API tiers).
4. **Rolling 5-Hour / 24-Hour Windows:** Used heavily by Claude Pro/Team, ChatGPT Plus, and Cursor Fast Requests to throttle sustained heavy usage.

---

## 6. Prompt Caching: Up to 90% Cost Reduction

Modern LLM infrastructures (Google Gemini Context Caching, Anthropic Ephemeral Caching, OpenAI Prefix Matching) store the deterministic prefix of prompts in GPU memory.

* **Cache Hit (Same prefix):** Token reading cost drops by **75% to 90%**, and latency is reduced by up to 4x.
* **Cache Miss:** Modifying even a single character at the start of the system prompt invalidates the cache, incurring full token billing.

---

## 7. The 10 Immutable Laws of AI Token Optimization

These universal laws apply to **all** AI engines:

1. 🎯 **"One Task, One Chat" Principle (Ctrl+N / Cmd+N):**
   * Complete the task or milestone ➔ Commit changes to Git (`WORKLOG.md`) ➔ Open a fresh session. Saves 90–95% of tokens.
2. 📝 **Continuous Git Worklog & Local-First Repo Sync:**
   * Keep a local-synced Git repo with a running `WORKLOG.md`. Re-hydrating context from a local log file costs 500 tokens vs 50k tokens of chat history.
3. 👤 **Name-Check Canary & Zero Greeting Bloat:**
   * Directly address user by name on every step without repetitive "hello/greetings". Absence of name signals context fatigue.
4. 🚫 **Transcript Bloat Prevention (Zero-Bloat Chat):**
   * Never dump giant source code listings, Base64 strings, or multi-page logs into chat text. Write directly to files and show only brief diffs and paths.
5. ✂️ **Range-Based File Reading (Slice-Only):**
   * Never read 2,000-line files in their entirety. Use line slice ranges (e.g., lines 40–120) or targeted `grep` / `ripgrep`.
6. 📦 **Monolithic Script Execution:**
   * Avoid multi-turn interactive command probing. Combine shell operations into a single consolidated script starting with console clearing (`cls` or `clear`).
7. 🚫 **Anti-Polling / Anti-Hang Protocol:**
   * Never run looping background checks (`manage_task status` every 3 seconds). Each poll is a fresh 20k token request. Decouple tasks > 2 min into system daemons.
8. 📂 **Local-First Knowledge Architecture:**
   * Store server maps, configs, and architectural rules in a local Git repository. Reading a local file costs 100 tokens, whereas scraping web docs costs 15,000 tokens.
9. 🛡️ **Aggressive Project Ignore Patterns:**
   * Exclude `node_modules/`, `vendor/`, `.git/`, `dist/`, `build/`, `*.log`, `*.zip`, and large binary dumps from codebase indexing.
10. 🚨 **Dual-Trigger Session Guard:**
   * Trigger red warning banner whenever session context reaches 25k tokens OR turns reach 8–10 in active coding mode.

---

## 8. Directory of Dedicated Model Profiles

| AI Engine / Environment | Profile Document | Optimization Highlights |
| :--- | :--- | :--- |
| **Google Antigravity** | [ANTIGRAVITY.md ↗](ANTIGRAVITY.md) | Home + CANCOM Enterprise, Confluence/Jira 90-day Cache, Subagent Budgeting, Name Canary |
| **OpenAI Codex & ChatGPT** | [CHATGPT_CODEX.md ↗](CHATGPT_CODEX.md) | Zero-Waste Windows Spec, `config.toml`, `sync-kb.ps1`, Custom Instructions, Name Canary |
| **Google Gemini & AI Studio** | [GOOGLE_GEMINI.md ↗](GOOGLE_GEMINI.md) | Context Caching (90% discount), `thinking_budget` limit (1024), System Prompts |
| **Cursor IDE & Composer** | [CURSOR.md ↗](CURSOR.md) | `.cursorrules`, `.cursorignore`, `@-mentions` vs `@Codebase`, Surgical Diffs |
| **VS Code, Copilot & Cline** | [VSCODE_COPILOT.md ↗](VSCODE_COPILOT.md) | `copilot-instructions.md`, `.clinerules` token budgeting, Continue.dev |
| **Claude & Anthropic Agents** | [CLAUDE_DEV.md ↗](CLAUDE_DEV.md) | `CLAUDE.md`, Ephemeral Prompt Caching, `--max-thinking-tokens`, 5h-window |
| **Perplexity AI** | [PERPLEXITY.md ↗](PERPLEXITY.md) | Focus modes (Writing/Code), domain filters, citation bloat prevention |

---
*Maintained and versioned in [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public).*
