# ⚡ Cursor IDE & Composer: Правила оптимизации токенов и правил `.cursorrules`

> **Специализированный профиль для Cursor IDE, Composer и Agent Mode.**  
> 🔗 Репозиторий: [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public) | Автор: [GinCz ↗](https://github.com/GinCz)

---

## 🎯 1. Архитектура экономии токенов в Cursor

Cursor отправляет контекст вашего проекта в модели (Claude 3.5/3.7 Sonnet, GPT-4o) через умную индексацию (Codebase Indexing). Чтобы не тратить дорогостоящие **Fast Requests** и не сжигать лимиты за 20 минут:

1. **Точечные `@-упоминания` вместо `@Codebase`:**
   * ❌ **Плохо:** Спрашивать `@Codebase где ошибка в скрипте?` (сканирует весь проект, сжигает 50k–100k токенов).
   * ✅ **Правильно:** Указывать конкретный файл `@filename.sh` или символ `@functionName` (тратит всего 2k–4k токенов).
2. **Использование `.cursorignore`:** Обязательно исключайте из индексации мусорные файлы и папки.
3. **Принцип мелких диффов в Composer:** Требуйте от Composer генерировать только измененные функции, а не переписывать файл целиком.

---

## 📄 2. Конфигурация `.cursorignore`

Создайте файл `.cursorignore` в корне любого рабочего репозитория:

```gitignore
# Защита от индексации и перерасхода токенов
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

## ⚙️ 3. Готовый конфигурационный файл `.cursorrules`

Создайте файл `.cursorrules` (или `.cursor/rules/main.mdc`) в корне проекта:

```markdown
# CURSOR AI TOKEN & BEHAVIOR RULES

You are an expert systems engineer and coding assistant.

1. USER INTERACTION:
   - Always address the user strictly by name: Vladimir (Владимир).
   - Communicate strictly in Russian. Switch to English or Czech ONLY upon explicit request.
   - All URLs, resources, and GitHub links must be clickable markdown with the ↗ symbol.

2. TOKEN DISCIPLINE:
   - Do NOT rewrite entire files if only a small section changes. Use localized diffs or surgical replacements.
   - Combine terminal operations into a single monolithic script with console clearing (`cls` / `clear`).
   - Prioritize reading local project files over external network lookups.
   - Do not guess or invent paths; use local directory structures.

3. RESPONSE FOOTER:
   - Append a single-line status footer at the very end of EVERY response:
     <small>✅ Done: Started HH:MM:SS • Finished HH:MM:SS • Total: HH:MM:SS (Tokens: ~Xk)</small>
```

---
*Документация поддерживается и актуализируется в репозитории [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public).*
