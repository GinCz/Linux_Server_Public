# 🧠 Claude & Anthropic Agents: Правила оптимизации токенов и `CLAUDE.md`

> **Специализированный профиль для Claude 3.5 / 3.7 Sonnet, Claude Code CLI, Claude Projects и агентских расширений.**  
> 🔗 Репозиторий: [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public) | Автор: [GinCz ↗](https://github.com/GinCz)

---

## 💎 1. Anthropic Prompt Caching и 5-часовые лимиты

Anthropic использует передовую технологию **Prompt Caching** через маркеры `cache_control: {"type": "ephemeral"}`:
* **Экономия 90%:** Чтение кэшированного блока стоит **10%** от базовой стоимости input-токенов.
* **Срок жизни кэша:** 5 минут (обновляется при каждом последующем запросе).
* **5-часовые окна:** Лимиты Claude Pro/Team сбрасываются по скользящему 5-часовому окну. Соблюдение правил кэширования позволяет делать в 5–8 раз больше запросов без блокировки.

---

## ⚙️ 2. Оптимизация Claude Code CLI и Claude 3.7 Thinking

При использовании CLI-утилиты Claude Code применяются параметры управления бюджетом:

1. **Контроль бюджета рассуждений (`--max-thinking-tokens`):**
   ```bash
   claude --max-thinking-tokens 2048
   ```
   Ограничивает скрытые токены размышлений, сохраняя глубокую логику без сжигания 15k токенов на шаг.
2. **Команда `/compact` в CLI:**
   При достижении 40k+ токенов в сессии команда `/compact` суммирует ключевые договоренности и сбрасывает устаревшие шаги из активной памяти.
3. **Ограничение глубины субагентов:**
   Запрещать бесконечную рекурсию субагентов (максимальная глубина `max_subagent_depth = 1`).

---

## 📜 3. Готовый файл `CLAUDE.md`

Создайте файл `CLAUDE.md` в корне репозитория (Claude считывает его автоматически при запуске):

```markdown
# CLAUDE PROJECT RULES & TOKEN OPTIMIZATION

## Identity & Communication
- User Name: Vladimir (Владимир).
- Language: Russian exclusively. Switch to English or Czech ONLY upon explicit user request.
- Formatting: All links must be clickable markdown with the ↗ symbol.

## Token Economy & Zero-Waste
- Local-First Architecture: Prioritize local configuration files in D:\AI\GitHub\ over remote requests.
- Surgical Edits: Provide targeted diffs or monolithic ready-to-run scripts instead of printing large unchanged files.
- Console Cleaning: Multi-command scripts must start with `cls` (Windows) or `clear` (Linux).
- Prompt Cache Preservation: Keep instructions and tool schemas strictly deterministic to maximize cache hit rates (90% discount).
- Knowledge Cache: Cache retrieved documentation with 90-day expiration metadata.
- Context Limits: If conversation exceeds 15 turns, execute `/compact` or recommend starting a new chat (Ctrl+N).

## Response Footer
- Conclude every response with the mandatory single-line status footer:
  <small>✅ Done: Started HH:MM:SS • Finished HH:MM:SS • Total: HH:MM:SS (Tokens: ~Xk)</small>
```

---
*Документация поддерживается и актуализируется в репозитории [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public).*
