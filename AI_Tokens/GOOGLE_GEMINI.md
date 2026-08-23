# 🌐 Google Gemini & AI Studio: Token Optimization & Rate Limit Architecture

> **Dedicated optimization profile for Google Gemini models (Flash, Pro, Ultra, Thinking) in Google AI Studio, Gemini API, and IDE extensions.**  
> 🔗 Repository: [GitHub: Linux_Server_Public/AI_Tokens ↗](https://github.com/GinCz/Linux_Server_Public/tree/main/AI_Tokens) | Author: [GinCz ↗](https://github.com/GinCz)

---

## 🚨 Mandatory Red Warning: Session Overload Trigger

When conversation length exceeds 15 steps, output this banner at the top of the message:

> <span style="color:#ff3333; font-weight:bold; font-size:1.1em;">⚠️ WARNING: Session length has exceeded 15 steps! Context is overloaded, resulting in exponential token consumption and degraded reasoning. Please commit your changes, summarize state, and start a fresh chat (Ctrl+N / Cmd+N)!</span>

---

## ⚡ 1. Gemini Architecture & Throughput Allocation

Gemini features massive context windows (1M to 2M+ tokens), but sustainable high-speed engineering requires disciplined quota management:

* **Gemini Flash (High Throughput / Low Cost):** Designed for routine coding, parsing, quick scripts, and tool executions. Up to **4,000,000 TPM** (Tokens Per Minute).
* **Gemini Pro (Deep Reasoning):** Best suited for complex architectural design, multi-repository debugging, and security auditing.
* **Thinking Budget Controls (Gemini 2.0 / 3.0 / 3.7):** Reasoning models produce internal "Thinking Tokens". Capping this budget prevents trivial questions from burning 10,000+ reasoning tokens.

### Configuration Payload for API / AI Studio:
```json
{
  "generationConfig": {
    "temperature": 0.2,
    "topP": 0.95,
    "thinking_config": {
      "thinking_budget": 1024
    }
  }
}
```

---

## 💎 2. Explicit Context Caching (Up to 90% Discount)

The Gemini API provides native **Explicit Context Caching**:

```
[Static Prefix (Cached Once in GPU RAM)]  ───►  75% - 90% Discount on Input Tokens
├── System Instructions & Rules
├── Function Calling Tool Schemas
└── Architecture Maps & DB Schemas
───────────────────────────────────────────────────────────────────────────────
[Dynamic Segment (Billed at standard rate)]
└── Current Turn User Prompt + Tool Results
```

### Best Practices to Maintain Cache Hits:
1. **Deterministic Order:** Never insert dynamic timestamps, session IDs, or random numbers into the system instructions or static prefix.
2. **Cache Activation Threshold:** Context caching activates automatically or explicitly once the static block exceeds **32,768 tokens**.

---

## 🛠️ 3. Function Calling & Tool Optimization

Tool definitions are re-sent to the model on **every interaction cycle**:
* **Compact Descriptions:** Limit tool parameter descriptions to one concise sentence.
* **Strict Parameter Typing:** Declare `enum` and `required` fields explicitly to prevent invalid arguments and wasted retry loops.

---

## 📝 4. Ready-to-Use System Instructions

Copy into the **System Instructions** field:

```markdown
You are a highly efficient, token-conscious engineering assistant.

CORE DIRECTIVES:
1. User Name: Address the user strictly as Vladimir (Владимир).
2. Primary Language: Russian. Switch to English or Czech ONLY upon explicit request.
3. Token Discipline:
   - Output production-ready, concise code without verbose conversational filler.
   - For multi-command tasks, provide a monolithic script starting with clear / cls.
   - Assume Local-First architecture: prioritize local configuration files over web requests.
   - If conversation exceeds 15 turns, output the mandatory red overload warning.
4. Response Footer:
   - Conclude every response with:
     <small>✅ Done: Started HH:MM:SS • Finished HH:MM:SS • Total: HH:MM:SS (Tokens: ~Xk)</small>
```

---
*Maintained and versioned in [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public).*
