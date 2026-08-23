# 🤖 OpenAI Codex & ChatGPT: Zero-Waste Token Economy & Мастер-Оптимизация

> **Специализированный профиль для OpenAI Codex (CLI / Desktop / Windows) и ChatGPT (GPT-4o, o1, o3, Canvas, Projects).**  
> Включает полную техническую спецификацию **Zero-Waste Token Economy for Codex on Windows** (локальная база знаний, точный `config.toml`, кэширование Confluence/Jira на 90 дней, аудит MCP и скрипты резервирования).  
> 🔗 Репозиторий: [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public) | Автор: [GinCz ↗](https://github.com/GinCz)

---

## 📑 Содержание

1. [Архитектура Zero-Waste для OpenAI Codex (Windows 10/11)](#1-архитектура-zero-waste-для-openai-codex-windows-1011)
2. [Оптимизация `config.toml` (Регулировка рассуждений и памяти)](#2-оптимизация-configtoml-регулировка-рассуждений-и-памяти)
3. [Локальная база знаний `%USERPROFILE%\knowledge` (90-day Cache)](#3-локальная-база-знаний-userprofileknowledge-90-day-cache)
4. [Аддитивная оптимизация `AGENTS.md` (Universal Operating Rules)](#4-аддитивная-оптимизация-agentsmd-universal-operating-rules)
5. [Аудит и контроль тяжелых плагинов и MCP-серверов](#5-аудит-и-контроль-тяжелых-плагинов-и-mcp-серверов)
6. [Эксперименты с `.codexignore`](#6-эксперименты-с-codexignore)
7. [ChatGPT Web, Canvas, Custom GPTs & Custom Instructions](#7-chatgpt-web-canvas-custom-gpts--custom-instructions)
8. [Скрипты инсталляции и бэкапа (Install & Rollback Scripts)](#8-скрипты-инсталляции-и-бэкапа-install--rollback-scripts)

---

## 1. Архитектура Zero-Waste для OpenAI Codex (Windows 10/11)

Концепция **Zero-Waste Token Economy** устраняет непроизводительные расходы токенов без потери качества кода, безопасности и актуальности данных.

### Ключевые пути окружения Windows:
* `$env:CODEX_HOME` или `%USERPROFILE%\.codex`
* `%USERPROFILE%\knowledge\` — локальный кэш карточек знаний и тикетов
* `%USERPROFILE%\zero-waste-setup\` — скрипты развертывания, бэкапы и логи

---

## 2. Оптимизация `config.toml` (Регулировка рассуждений и памяти)

В файле конфигурации `%USERPROFILE%\.codex\config.toml` настраиваются параметры, снижающие избыточные цепочки рассуждений (Chain-of-Thought) и оптимизирующие память:

```toml
# ==============================================================================
# ZERO-WASTE CODEX OPTIMIZATION CONFIG
# ==============================================================================

# Уровень рассуждений модели (предотвращает генерацию скрытых 10k CoT токенов)
model_reasoning_effort = "medium"
model_reasoning_summary = "concise"

# Уровень многословия ответов (Low отсекает пустые вступительные и заключительные фразы)
model_verbosity = "low"

# Управление памятью Codex
memories_enabled = true
memory_use_when_external_context_active = false
memory_retention_days = 30

# Безопасность и телеметрия
telemetry_enabled = false
```

> ⚠️ **Важно:** Не изменяйте системные параметры модели вслепую. Всегда сохраняйте резервную копию `config.toml` перед правками.

---

## 3. Локальная база знаний `%USERPROFILE%\knowledge` (90-day Cache)

Вместо повторного парсинга внешних систем (Confluence, Jira, Microsoft 365, SharePoint) создается локальный кэш карточек.

### Приоритет источников данных:
1. Локальная документация задачи.
2. Локальные карточки знаний (`%USERPROFILE%\knowledge\`).
3. Точечный поиск по рабочей области через `rg` (ripgrep).
4. Внешние системы (только если данных нет локально или требуется проверка свежести).

### Формат карточки кэша (`%USERPROFILE%\knowledge\.cache\*.md`):
```markdown
---
id: CONFLUENCE-PAGE-12345
source: confluence
source_url: https://confluence.company.com/pages/12345
source_updated: 2026-08-01T10:00:00Z
cached_at: 2026-08-10T12:00:00Z
expires_at: 2026-11-08T12:00:00Z
etag: "a1b2c3d4"
content_hash: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
tags: [fastpanel, nginx, php-fpm]
---
Краткая фактологическая выжимка страницы (максимум 300 слов).
Основные конфигурационные директивы и параметры без сырого HTML-дампа.
```

### Правила ротации кэша:
* **Срок жизни (TTL):** Ровно **90 дней** с момента `cached_at`.
* **Автоочистка:** Устаревшие карточки удаляются при очередном запуске `sync-kb.ps1`.
* **Запрет на дампы:** Запрещено кэшировать секреты, токены, личные данные, полные дампы почты и вложения.

---

## 4. Аддитивная оптимизация `AGENTS.md` (Universal Operating Rules)

В правилах агента (`AGENTS.md` / `custom instructions`) действуют жесткие правила:

1. **Разграничение фактов и гипотез:** Четко отделять доказанные факты от предположений. Не выдумывать уверенность.
2. **Прямое несогласие:** Если агент видит ошибку в запросе пользователя, он обязан открыто заявить об этом ДО начала действий, подкрепив позицию фактами.
3. **Команда `/compact`:** При накоплении длинного контекста вызывать `/compact` для архивации решений и очистки истории.
4. **Сургические правки:** Использовать точечные патчи и поиск через `rg` вместо чтения сотен строк кода.
5. **Один чат — одна задача:** Завершать сессию после каждого функционального блока.

---

## 5. Аудит и контроль тяжелых плагинов и MCP-серверов

Каждый подключенный MCP-сервер или плагин внедряет свою JSON-схему во входящий контекст (Input Tokens) **на каждом запросе**:

| Тип расширения | Расход на схему (Input per step) | Рекомендация Zero-Waste |
| :--- | :--- | :--- |
| **Тяжелый MCP (Jira/Confluence/DB)** | **4 000 – 12 000 токенов** | Включать только при активной работе с этой системой. Выключать в повседневном кодинге. |
| **Системный MCP (FS, Git, Terminal)** | **500 – 1 500 токенов** | Держать активным постоянно. |
| **Браузерный парсер (Puppeteer/Playwright)** | **3 000 – 8 000 токенов** | Заменять прямыми локальными вызовами curl / fetch карточек. |

---

## 6. Эксперименты с `.codexignore`

Для предотвращения индексации мусорных файлов создается `.codexignore` в корне проектов:

```gitignore
node_modules/
vendor/
.git/
*.log
*.zip
*.tar.gz
*.sql
*.csv
.cache/
dist/
build/
```

---

## 7. ChatGPT Web, Canvas, Custom GPTs & Custom Instructions

В веб-интерфейсе ChatGPT применяются следующие настройки профиля:

### Custom Instructions (Настройки ➔ Пользовательские инструкции):
* **Блок 1 (О пользователе):**
  ```text
  - Имя: Владимир (обращаться строго по имени Владимир).
  - Профиль: Системный архитектор, DevOps/Linux/Windows инженер.
  - Язык: Русский (английский/чешский только по явной просьбе).
  - Рабочие серверы: Master Node DE-222 (NetCup, Ubuntu 24.04), RU-109, сеть VPN узлов.
  - Локальный диск: D:\AI\ и C:\UTIL\. Рабочий стол (Desktop) НЕ использовать.
  - Проекты: GitHub GinCz (Secret_Privat, Linux_Server_Public).
  ```
* **Блок 2 (О стиле ответов):**
  ```text
  - Отвечать лаконично, структурированно, без воды.
  - Команды собирать в единый монолитный блок с clear/cls в начале.
  - Ссылки делать кликабельными с символом ↗ (например: [GitHub: GinCz ↗](https://github.com/GinCz)).
  - Применять режим Canvas для диффов и точечных правок.
  - Завершать ответ статус-таймстемпом:
    <small>✅ Done: Started HH:MM:SS • Finished HH:MM:SS • Total: HH:MM:SS (Tokens: ~Xk)</small>
  ```

---

## 8. Скрипты инсталляции и бэкапа (Install & Rollback Scripts)

### Скрипт индексации локального кэша: `%USERPROFILE%\knowledge\sync-kb.ps1`
```powershell
# PowerShell 5.1 / 7+ KB Sync Script
$kbPath = Join-Path $env:USERPROFILE "knowledge"
$cachePath = Join-Path $kbPath ".cache"
$indexPath = Join-Path $kbPath ".index\kb_index.json"

if (-not (Test-Path $cachePath)) { New-Item -ItemType Directory -Path $cachePath -Force | Out-Null }
if (-not (Test-Path (Split-Path $indexPath))) { New-Item -ItemType Directory -Path (Split-Path $indexPath) -Force | Out-Null }

$now = Get-Date
$cards = Get-ChildItem -Path $cachePath -Filter "*.md" -Recurse

$index = @()
foreach ($file in $cards) {
    $content = Get-Content -Path $file.FullName -Raw
    # Проверка на истечение 90 дней
    if ($content -match 'expires_at:\s*([^\r\n]+)') {
        $expires = [DateTime]::Parse($matches[1])
        if ($now -gt $expires) {
            Write-Host "Removing expired cache card: $($file.Name)" -ForegroundColor Yellow
            Remove-Item -Path $file.FullName -Force
            continue
        }
    }
    
    $hash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
    $index += [PSCustomObject]@{
        Path = $file.Name
        Hash = $hash
        LastModified = $file.LastWriteTimeUtc.ToString("o")
    }
}

$index | ConvertTo-Json -Depth 3 | Set-Content -Path $indexPath -Encoding UTF8
Write-Host "KB Sync complete. Indexed $($index.Count) cards." -ForegroundColor Green
```

---
*Документация поддерживается и актуализируется в репозитории [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public).*
