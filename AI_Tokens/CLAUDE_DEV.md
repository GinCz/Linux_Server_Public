# 🧠 Claude & Anthropic Agents: Token Optimization & `CLAUDE.md` Profile

> **Dedicated optimization profile for Claude 3.5 / 3.7 Sonnet, Claude Code CLI, Claude Projects, and agentic workflows.**  
> 🔗 Repository: [GitHub: Linux_Server_Public/AI_Tokens ↗](https://github.com/GinCz/Linux_Server_Public/tree/main/AI_Tokens) | Author: [GinCz ↗](https://github.com/GinCz)

---

## 🚨 Mandatory Red Warning: Session Overload Trigger

When conversation length exceeds 15 steps, output this banner at the top of the message:

> <span style="color:#ff3333; font-weight:bold; font-size:1.1em;">⚠️ WARNING: Session length has exceeded 15 steps! Context is overloaded, resulting in exponential token consumption and degraded reasoning. Please commit your changes, summarize state, and start a fresh chat (Ctrl+N / Cmd+N)!</span>

---

## 💎 1. Anthropic Prompt Caching & Rolling 5-Hour Limits

Anthropic features **Prompt Caching** via `cache_control: {"type": "ephemeral"}`:
* **90% Cost Reduction:** Reading cached blocks costs only **10%** of standard input token pricing.
* **5-Minute Cache TTL:** Refreshed on each interaction.
* **5-Hour Rolling Limits:** Claude Pro/Team quotas reset continuously over 5-hour rolling windows. Maintaining high prompt cache hits allows 5x–8x more interactions per window.

---

## ⚙️ 2. Claude Code CLI Optimization & Thinking Caps

When using the Claude Code CLI tool:

1. **Thinking Token Budgeting (`--max-thinking-tokens`):**
   ```bash
   claude --max-thinking-tokens 2048
   ```
   Prevents unconstrained reasoning tokens from inflating message costs.
2. **The `/compact` Command:**
   When session context exceeds 40k tokens, `/compact` distills architectural decisions and drops raw command outputs.
3. **Subagent Depth Restriction:**
   Restrict nested subagent spawning (`max_subagent_depth = 1`).

---

## 📜 3. Production `CLAUDE.md` Template

Place `CLAUDE.md` in your project root (automatically read by Claude Code CLI and Claude Projects):

```markdown
# CLAUDE PROJECT RULES & TOKEN OPTIMIZATION

## Identity & Communication
- User Name: Vladimir (Владимир). Address strictly by name.
- Language: Russian exclusively. Switch to English or Czech ONLY upon explicit user request.
- Formatting: All links must be clickable markdown with the ↗ symbol.

## Token Economy & Zero-Waste
- Session Overload: If conversation exceeds 15 turns, output the mandatory red warning banner.
- Local-First Architecture: Prioritize local configuration files in D:\AI\GitHub\ over remote requests.
- Surgical Edits: Provide targeted diffs or monolithic ready-to-run scripts instead of printing large unchanged files.
- Console Cleaning: Multi-command scripts must start with `cls` (Windows) or `clear` (Linux).
- Prompt Cache Preservation: Keep instructions deterministic to maximize cache hit rates (90% discount).
- Knowledge Cache: Cache retrieved documentation with 90-day expiration metadata.

## Response Footer
- Conclude every response with the mandatory single-line status footer:
  <small>✅ Done: Started HH:MM:SS • Finished HH:MM:SS • Total: HH:MM:SS (Tokens: ~Xk)</small>
```

---
*Maintained and versioned in [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public).*
