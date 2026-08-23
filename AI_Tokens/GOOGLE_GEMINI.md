# 🌐 Google Gemini & AI Studio: Правила оптимизации токенов и квот

> **Специализированный профиль для моделей Google Gemini (Flash, Pro, Ultra) в Google AI Studio, Gemini API и расширениях.**  
> 🔗 Репозиторий: [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public) | Автор: [GinCz ↗](https://github.com/GinCz)

---

## ⚡ 1. Архитектура моделей Gemini и квоты

Семейство моделей Gemini обладает гигантским контекстным окном (от 1M до 2M+ токенов), однако эффективное использование требует понимания распределения квот:

* **Gemini Flash (быстрая, дешевая):** Идеальна для рутинных задач, парсинга, коротких скриптов и быстрой фильтрации данных. Минутный лимит (TPM) достигает **4 000 000 токенов/мин**.
* **Gemini Pro (глубокое рассуждение):** Идеальна для сложной архитектуры, поиска скрытых багов и системного проектирования.
* **Суточный лимит (RPD):** На бесплатных тарифах AI Studio доступно до **1 500 RPD (Flash)** и **50 RPD (Pro)**.

---

## 💎 2. Использование Google Context Caching (Скидка до 75–90%)

В Gemini API встроена технология **Explicit Context Caching**:

```
[Постоянный префикс (кэшируется один раз)]  ->  Скидка 75–90% на входные токены
├── Системные инструкции (System Instructions)
├── Схемы инструментов (Function Calling Schemas)
└── Базовая документация проекта / Схемы БД
───────────────────────────────────────────────────────────────────────────────
[Переменная часть (оплачивается за каждый вызов)]
└── Текущий вопрос пользователя + краткий контекст шага
```

### Правила сохранения Cache Hit:
1. **Строго детерминированный порядок:** Никогда не вставляйте переменные (таймстемпы, ID сессий, случайные числа) в системный промпт или начало контекста. Все динамические данные должны идти **в самом конце запроса пользователя**.
2. **Минимальный порог кэширования:** Context Caching активируется при объеме статического блока от **32 768 токенов** (в Gemini 1.5/2.5/3.7).

---

## 🛠️ 3. Оптимизация вызовов инструментов (Function Calling)

Описания функций (tools) отправляются модели на **каждом шаге**. Чтобы не сжигать токены:
* **Лаконичные JSON-схемы:** Сокращайте поля `description` в инструментах до 1 краткого предложения.
* **Исключение избыточных параметров:** Не передавайте опциональные поля со значениями по умолчанию, если они не требуются.
* **Строгая валидация:** Задавайте `enum` и `required` поля, чтобы модель не генерировала «мусорные» аргументы, приводящие к повторным вызовам (Retry Loops).

---

## 📝 4. Готовый системный промпт для Google AI Studio / Gemini Code Assist

Скопируйте этот блок в поле **System Instructions**:

```markdown
You are a highly efficient, token-conscious engineering AI assistant.

CORE RULES:
1. User Name: Address the user strictly as Vladimir (Владимир).
2. Primary Language: Russian. Switch to English/Czech only when explicitly requested.
3. Token Economy:
   - Output concise, production-ready code blocks without verbose conversational filler.
   - For file modifications, output monolithic, ready-to-run scripts instead of fragmented steps.
   - Always assume Local-First architecture: prioritize local configuration files over web requests.
   - Provide complete, verified commands with console clearing (cls/clear) at the top.
4. Response Footer:
   - Always conclude with a single-line status timestamp:
     <small>✅ Done: Started HH:MM:SS • Finished HH:MM:SS • Total: HH:MM:SS (Tokens: ~Xk)</small>
```

---
*Документация поддерживается и актуализируется в репозитории [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public).*
