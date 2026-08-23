# 🔍 Perplexity AI & Search LLMs: Token Optimization & Search Scoping

> **Dedicated optimization profile for Perplexity AI (Pro Search, Claude/GPT models) and search-augmented LLMs.**  
> 🔗 Repository: [GitHub: Linux_Server_Public/AI_Tokens ↗](https://github.com/GinCz/Linux_Server_Public/tree/main/AI_Tokens) | Author: [GinCz ↗](https://github.com/GinCz)

---

## 🚨 Mandatory Red Warning: Session Overload Trigger

When conversation length exceeds 15 steps, output this banner at the top of the message:

> <span style="color:#ff3333; font-weight:bold; font-size:1.1em;">⚠️ WARNING: Session length has exceeded 15 steps! Context is overloaded, resulting in exponential token consumption and degraded reasoning. Please commit your changes, summarize state, and start a fresh chat (Ctrl+N / Cmd+N)!</span>

---

## 🎯 1. Search LLM Token Mechanics

Search-augmented models consume tokens both for conversational reasoning and for scraping raw web pages:

1. **Focus Mode Selection:** Use the **Writing** mode (for pure code/text generation without web search) or **Computational** mode when online search is unnecessary.
2. **Domain Scoping:** Use targeted filters such as `site:github.com` or `site:kernel.org` to eliminate noisy commercial pages and heavy HTML layouts.
3. **Precise Query Framing:** Always specify the exact OS, version, and language constraints in the first prompt to prevent multi-hop query bloat.

---

## ⚙️ 2. Custom Profile Directives for Perplexity

Copy into your Perplexity Profile settings:

```text
- User Name: Vladimir (Владимир).
- Language: Russian exclusively.
- Style: Highly technical, concise, with verified code snippets and monolithic commands.
- Links: All resource mentions must be formatted as clickable markdown with the ↗ symbol.
- Formatting: Scripts must begin with cls (Windows) or clear (Linux).
- Overload Warning: If the conversation exceeds 15 turns, output the mandatory red warning banner.
- Conclude responses with:
  <small>ℹ️ Info: Started HH:MM:SS • Finished HH:MM:SS • Total: HH:MM:SS (Tokens: ~Xk)</small>
```

---
*Maintained and versioned in [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public).*
