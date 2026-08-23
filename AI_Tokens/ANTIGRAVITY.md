# 🤖 Google Antigravity: Правила оптимизации токенов (Home & Corporate CANCOM)

> **Специализированный профиль для среды Google Antigravity.**  
> Включает единые правила для домашнего профиля (Home) и корпоративного контура CANCOM (Confluence, Jira, Microsoft 365 / Entra).  
> 🔗 Репозиторий: [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public) | Автор: [GinCz ↗](https://github.com/GinCz)

---

## 🎯 1. Глобальная архитектура экономии токенов

Antigravity — это автономный мульти-агентный инструмент. В каждом цикле вызова агента передаются: системные правила, схемы инструментов (tools), прочитанные файлы и история диалога. Для минимизации расхода токенов агент обязан соблюдать жесткие директивы:

1. **Local-First принцип:** Все правила, конфигурации и контекст читаются строго с локального диска `D:\AI\GitHub\Secret_Privat` и быстрых карточек `knowledge/` (без лишних сетевых и SSH запросов).
2. **«Один чат — одна задача» (Ctrl+N):** После выполнения задачи результат фиксируется в Git/логе, и открывается новый чат. Это снижает средний расход токенов на сессию на **90–95%**.
3. **Запрет на Polling-циклы (Anti-Hang):** Категорически запрещено вызывать `manage_task(status)` в цикле ожидания. Команды запускаются синхронно с достаточным `WaitMsBeforeAsync` (до 10000ms). Длительные задачи (> 2 мин) немедленно переводятся в системный демон/cron с оповещением в Telegram, а агент завершает шаг.

---

## 🏢 2. Корпоративный контур (CANCOM / Confluence / Microsoft Tickets)

> ⚠️ **Правило корпоративной фильтрации:** При взаимодействии с тяжелыми корпоративными базами данных (Confluence Wiki, Jira Service Management, Microsoft Graph API, Entra ID, Outlook / Teams Tickets) действуют специальные ограничения:

### [ПРАВИЛО: Корпоративный поиск в Confluence & SharePoint]
* **Запрет на выгрузку страниц целиком:** Страницы корпоративной документации часто содержат мегабайты разметки и таблиц.
* **Поиск только по метаданным:** Запрашивать сначала **Title**, **ID**, **URL** и краткий фрагмент (**Excerpt** до 200 символов) с ограничением `limit=3` или `limit=5`.
* **Точечная выгрузка заголовков:** Сначала выгружать только оглавление страницы (TOC), и лишь затем читать нужный подраздел.
* **Локальный кэш карточек (90-day TTL):** Сохранять выжимку в `%USERPROFILE%\knowledge\.cache\` с метаданными `cached_at` и `expires_at` (срок жизни 90 дней).

### [ПРАВИЛО: Обработка тикетов Microsoft / Jira / ServiceNow]
* **Запрет на чтение всей ветки комментариев:** Никогда не парсить 50+ комментариев переписки по тикету.
* **Фильтр полей (Field Mask):** Запрашивать строго 4 поля: `key`, `summary`, `status`, `last_comment`.
* **Запрет на парсинг вложений (Attachments):** Никогда не скачивать и не сканировать скриншоты, дампы памяти, PDF или Excel-вложения, если пользователь явно не указал конкретное имя файла.

---

## 👥 3. Экономика вызова субагентов (Subagents Budgeting)

При вызове субагентов через `invoke_subagent` действует градация моделей:
* **`flash_lite`:** Первичный сбор информации, проверка наличия файлов, поиск путей.
* **`flash` (по умолчанию):** Выполнение типовых Bash/PowerShell скриптов, быстрый рефакторинг, поиск по документации.
* **`pro`:** Только для сложного архитектурного проектирования, многокомпонентной отладки и разрешения неопределенностей.

---

## 🛠️ 4. Оптимизация встроенных инструментов Antigravity

| Инструмент | Запрещено (Сжигает токены) | Разрешено (Экономно) |
| :--- | :--- | :--- |
| `view_file` | Читать файлы > 200 строк целиком | Использовать `StartLine` и `EndLine` (точечные окна по 50–100 строк) |
| `grep_search` | Искать по всему корню без фильтра | Всегда передавать маску файлов в `Includes` (напр., `*.sh`, `*.md`) |
| `find_by_name` | Глубокий рекурсивный поиск без лимита | Задавать `MaxDepth: 2` или `3` и конкретный `SearchDirectory` |
| `run_command` | Запускать по 1 команде с 10 уточнениями | Формировать **единый монолитный блок** с `cls` / `clear` |
| `manage_task` | Циклический опрос `status` в цикле `while` | Дождаться завершения команды или перевести в фон с `IsDaemon: true` |

---

## ⚙️ 5. Готовый блок инструкций для вставки в `GEMINI.md` / системный промпт

Скопируйте этот блок в файл `C:\Users\USER\.gemini\config\rules\GEMINI.md` или передайте его ассистенту как директиву:

```markdown
# TOKEN OPTIMIZATION & AGENT CONTEXT DISCIPLINE

1. USER & LANGUAGE:
   - Always address the user strictly as Vladimir (Владимир).
   - Language: Russian by default (switch to English/Czech ONLY upon explicit request).

2. CONTEXT MINIMIZATION:
   - Practice "One Task Per Chat": Encourage closing long sessions (>15 steps) to prevent quadratic token growth.
   - Range-Based File Reading: Never read entire large files; use view_file with StartLine/EndLine slices.
   - Corporate Data Masking (CANCOM/Confluence/Microsoft): Always query with limit=5 and fetch metadata only (title, summary, status). Never ingest raw attachment blobs.
   - Local-First Knowledge: Read configurations and architecture maps from local repository D:\AI\GitHub\Secret_Privat.
   - Subagent Budgeting: Use flash/flash_lite for subagent research tasks.

3. EXECUTION DISCIPLINE:
   - Monolithic Scripting: Combine multiple shell steps into a single executable script starting with clear / cls.
   - Anti-Polling / Anti-Hang: Never poll background tasks in a loop. Long-running tasks (>2 min) must be decoupled into background daemons with Telegram notification.

4. FOOTER STATUS:
   - Append a single-line status footer at the very end of EVERY response:
     <small>✅ Done: Started HH:MM:SS • Finished HH:MM:SS • Total: HH:MM:SS (Tokens: ~Xk)</small>
```

---
*Документация поддерживается и актуализируется в репозитории [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public).*
