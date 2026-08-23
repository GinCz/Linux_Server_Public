# 🧠 Claude & Anthropic Agents: Правила оптимизации токенов и `CLAUDE.md`

> **Специализированный профиль для Claude 3.5 / 3.7 Sonnet, Claude Code CLI и Claude Projects.**  
> 🔗 Репозиторий: [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public) | Автор: [GinCz ↗](https://github.com/GinCz)

---

## 💎 1. Anthropic Prompt Caching и 5-часовые лимиты

Anthropic использует передовую технологию **Prompt Caching**:
* **Экономия 90%:** Чтение кэшированного блока стоит **10%** от базовой стоимости input-токенов.
* **Срок жизни кэша:** 5 минут (обновляется при каждом последующем запросе).
* **5-часовые окна:** Лимиты Claude Pro/Team сбрасываются по скользящему 5-часовому окну. Соблюдение правил кэширования позволяет делать в 5–8 раз больше запросов без блокировки.

---

## 📜 2. Готовый файл `CLAUDE.md`

Создайте файл `CLAUDE.md` в корне репозитория (Claude считывает его автоматически):

```markdown
# CLAUDE PROJECT RULES & TOKEN OPTIMIZATION

## Identity & Communication
- User Name: Vladimir (Владимир).
- Language: Russian exclusively. Switch to English or Czech ONLY upon explicit user request.
- Formatting: All links must be clickable markdown with the ↗ symbol.

## Token Economy
- Local-First Architecture: Prioritize local configuration files over remote requests.
- Surgical Edits: Provide targeted diffs or monolithic ready-to-run scripts instead of printing large unchanged files.
- Console Cleaning: Multi-command scripts must start with `cls` (Windows) or `clear` (Linux).
- Prompt Cache Preservation: Keep instructions deterministic to maximize cache hit rates.

## Response Footer
- Conclude every response with the mandatory single-line status footer:
  <small>✅ Done: Started HH:MM:SS • Finished HH:MM:SS • Total: HH:MM:SS (Tokens: ~Xk)</small>
```

---
*Документация поддерживается и актуализируется в репозитории [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public).*
