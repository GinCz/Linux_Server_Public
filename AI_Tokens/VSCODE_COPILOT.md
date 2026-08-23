# 💻 VS Code, GitHub Copilot & Cline: Token Optimization Profile

> **Dedicated optimization profile for VS Code, GitHub Copilot, Cline, Roo-Code, and Continue.dev.**  
> 🔗 Repository: [GitHub: Linux_Server_Public/AI_Tokens ↗](https://github.com/GinCz/Linux_Server_Public/tree/main/AI_Tokens) | Author: [GinCz ↗](https://github.com/GinCz)

---

## 🚨 Mandatory Red Warning: Session Overload Trigger

When conversation length exceeds 15 steps, output this banner at the top of the message:

> <span style="color:#ff3333; font-weight:bold; font-size:1.1em;">⚠️ WARNING: Session length has exceeded 15 steps! Context is overloaded, resulting in exponential token consumption and degraded reasoning. Please commit your changes, summarize state, and start a fresh chat (Ctrl+N / Cmd+N)!</span>

---

## 🎯 1. Context Optimization in VS Code Agent Extensions

Autonomous extensions (Cline, Roo-Code, Copilot Chat) automatically ingest open tabs, active editor views, and terminal histories:

1. **Close Inactive Editor Tabs:** Every open tab can be injected into the context window as auxiliary context.
2. **Terminal Scrollback Hygiene:** Avoid holding 10,000 lines of terminal logs. Clear the terminal before running agent tasks.
3. **Inline Suggestions Throttle:** Increasing autocomplete debounce delay prevents sending micro-prompts on every single keystroke.

---

## 📂 2. GitHub Copilot Instructions (`.github/copilot-instructions.md`)

Place this file in `.github/copilot-instructions.md`:

```markdown
# GitHub Copilot Custom Instructions

- Always address the user strictly as Vladimir (Владимир).
- Default Language: Russian only (use English or Czech only when explicitly requested).
- Format all URLs and GitHub links as clickable markdown with the ↗ symbol.
- Token Optimization:
  - If conversation exceeds 15 turns, output the mandatory red warning banner.
  - Provide production-ready, concise code and monolithic scripts with `cls` / `clear`.
  - Never reprint large unchanged files.
- Response Footer:
  - Append the single-line status footer:
    <small>✅ Done: Started HH:MM:SS • Finished HH:MM:SS • Total: HH:MM:SS (Tokens: ~Xk)</small>
```

---

## 🤖 3. Cline / Roo-Code Rules (`.clinerules`)

Place this file in `.clinerules` in your workspace root:

```markdown
# CLINE / ROO-CODE EXECUTION & TOKEN RULES

1. Address the user as Vladimir (Владимир).
2. Language: Russian by default.
3. Token Budget Discipline:
   - If session length exceeds 15 steps, display the red warning banner.
   - Use targeted file reads with line numbers (e.g., lines 20-80 instead of 500 lines).
   - Use ripgrep with specific filetype filters to minimize search payload.
   - Do NOT run looping background checks that consume API tokens on every iteration.
   - Complete tasks in minimum iterations, then report completion.
4. Always conclude with:
   <small>✅ Done: Started HH:MM:SS • Finished HH:MM:SS • Total: HH:MM:SS (Tokens: ~Xk)</small>
```

---
*Maintained and versioned in [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public).*
