# ⚡ Cursor IDE & Composer: Token Optimization & `.cursorrules` Profile

> **Dedicated optimization profile for Cursor IDE, Composer, and Agent Mode.**  
> 🔗 Repository: [GitHub: Linux_Server_Public/AI_Tokens ↗](https://github.com/GinCz/Linux_Server_Public/tree/main/AI_Tokens) | Author: [GinCz ↗](https://github.com/GinCz)

---

## 🔍 Mandatory Name Canary & Zero Greeting Rule

> [!IMPORTANT]
> - **Direct Name Addressing:** Address the user as **"Vladimir, ..."** without pleasantries.
> - **Ban on Greetings:** Do NOT say *"Hello"* or *"Здравствуйте"* on every step.
> - **Telemetry Canary:** If Cursor drops the name, it indicates prompt amnesia — refresh the chat context.

---

## 🚨 Mandatory Red Warning: Session Overload Trigger

When conversation length exceeds 15 steps, output this banner at the top of the message:

> <span style="color:#ff3333; font-weight:bold; font-size:1.1em;">⚠️ WARNING: Session length has exceeded 15 steps! Context is overloaded, resulting in exponential token consumption and degraded reasoning. Please commit your changes, summarize state, and start a fresh chat (Ctrl+N / Cmd+N)!</span>

---

## 🎯 1. Token Economy in Cursor IDE

Cursor sends codebase context to backend LLMs (Claude 3.5/3.7 Sonnet, GPT-4o) via semantic indexing. To protect your **Fast Requests** allowance and prevent rapid quota exhaustion:

1. **Targeted `@-mentions` over `@Codebase`:**
   * ❌ **Inefficient:** Asking `@Codebase where is the error?` (scans the entire workspace, burning 50,000–100,000 tokens).
   * ✅ **Optimal:** Specifying `@filename.sh` or a concrete symbol `@functionName` (consumes only 2,000–4,000 tokens).
2. **Aggressive Indexing Filtering (`.cursorignore`):** Exclude non-source assets from vector indexing.
3. **Surgical Diffs in Composer:** Demand that Composer outputs targeted replacements rather than reprinting entire files.

---

## 📄 2. Production `.cursorignore` File

Create `.cursorignore` in the project root:

```gitignore
# Block non-essential files from semantic indexing
node_modules/
vendor/
.git/
dist/
build/
*.log
*.zip
*.tar.gz
*.iso
*.sql
*.csv
*.dump
package-lock.json
composer.lock
.env
.env.*
tmp/
temp/
coverage/
```

---

## ⚙️ 3. Ready-to-Use `.cursorrules` (or `.cursor/rules/main.mdc`)

Create `.cursorrules` in your project root:

```markdown
# CURSOR AI TOKEN & BEHAVIOR RULES

You are an expert systems engineer and coding assistant.

1. USER INTERACTION & NAME CANARY:
   - Always address the user strictly as Vladimir (Владимир) without saying hello/greetings.
   - Communicate strictly in Russian. Switch to English or Czech ONLY upon explicit user request.
   - All URLs, resources, and GitHub links must be clickable markdown with the ↗ symbol.

2. TOKEN DISCIPLINE & CONTEXT CONTROL:
   - If conversation exceeds 15 turns, output the mandatory red warning banner.
   - Do NOT rewrite entire files if only a small section changes. Use surgical diffs.
   - Combine terminal operations into a single monolithic script with console clearing (cls / clear).
   - Prioritize reading local project files over external network lookups.

3. RESPONSE FOOTER:
   - Append a single-line status footer at the very end of EVERY response:
     <small>✅ Done: Started HH:MM:SS • Finished HH:MM:SS • Total: HH:MM:SS (Tokens: ~Xk)</small>
```

---
*Maintained and versioned in [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public).*
