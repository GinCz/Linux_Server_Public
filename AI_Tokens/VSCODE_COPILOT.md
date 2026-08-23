# 💻 VS Code, GitHub Copilot & Cline: Правила оптимизации токенов

> **Специализированный профиль для VS Code, GitHub Copilot, Cline, Roo-Code и Continue.dev.**  
> 🔗 Репозиторий: [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public) | Автор: [GinCz ↗](https://github.com/GinCz)

---

## 🎯 1. Оптимизация контекста в расширениях VS Code

Расширения автономных агентов (Cline, Roo-Code, Copilot Workspace) отправляют огромный массив контекста (список открытых вкладок, терминал, активные файлы). Для экономии токенов:

1. **Закрывайте неиспользуемые вкладки:** Каждая открытая вкладка в VS Code может автоматически добавляться в контекст агента как сопутствующий файл.
2. **Ограничение истории терминала:** Не держите в терминале логи на 5 000 строк. Очищайте терминал командой `clear` / `cls`.
3. **Настройка автодополнения (Copilot Inline Suggestions):** Увеличение задержки подсказок предотвращает отправку сотен микрозапросов при быстром наборе текста.

---

## 📂 2. Готовый файл `.github/copilot-instructions.md`

Создайте файл `.github/copilot-instructions.md` в корне репозитория:

```markdown
# GitHub Copilot Custom Instructions

- Always address the user strictly as Vladimir (Владимир).
- Default Language: Russian only (use English/Czech only when explicitly asked).
- Always format links as clickable markdown with the ↗ symbol.
- Token Optimization:
  - Provide production-ready, concise code and monolithic scripts.
  - Always add console clearing (`clear` or `cls`) at the start of any multi-command snippet.
  - Do not reprint large unchanged code files.
- Response Footer:
  - Append the mandatory single-line status footer:
    <small>✅ Done: Started HH:MM:SS • Finished HH:MM:SS • Total: HH:MM:SS (Tokens: ~Xk)</small>
```

---

## 🤖 3. Конфигурация для Cline / Roo-Code (`.clinerules`)

Создайте файл `.clinerules` в корне рабочей папки:

```markdown
# CLINE / ROO-CODE EXECUTION & TOKEN RULES

1. Address the user as Vladimir (Владимир).
2. Language: Russian.
3. Token Budget Discipline:
   - Use targeted file reads with line numbers (e.g., read lines 20-80 instead of 500 lines).
   - Use ripgrep / grep with specific filetype filters to minimize search payload.
   - Do NOT run looping background checks that consume API tokens on every iteration.
   - Complete tasks in minimum iterations, then report completion.
4. Always conclude with:
   <small>✅ Done: Started HH:MM:SS • Finished HH:MM:SS • Total: HH:MM:SS (Tokens: ~Xk)</small>
```

---
*Документация поддерживается и актуализируется в репозитории [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public).*
