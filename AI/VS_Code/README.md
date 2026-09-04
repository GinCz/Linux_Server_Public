# VS Code + Continue — Setup Guide

> = Rooted by VladiMIR + AI | v.2026.06.01 | github.com/GinCz =

Полное руководство по настройке VS Code + Continue на Windows 10/11 с бесплатными AI API.

---

## Что это даёт

- AI-помощник прямо в VS Code (как GitHub Copilot, но бесплатно)
- Подключение к серверам через SSH
- Agent Mode — AI сам выполняет команды на сервере (с подтверждением)
- Работа с GitHub репозиториями
- Автодополнение кода

---

## Шаг 1 — Установка VS Code

Скачать: https://code.visualstudio.com/

---

## Шаг 2 — Установка расширений

В VS Code нажми `Ctrl+Shift+X` и установи:

| Расширение | ID | Назначение |
|------------|-----|------------|
| **Continue** | `Continue.continue` | AI-помощник (главное расширение) |
| **Remote - SSH** | `ms-vscode-remote.remote-ssh` | Подключение к серверам |
| **Remote Explorer** | `ms-vscode.remote-explorer` | Управление SSH подключениями |

---

## Шаг 3 — Получи бесплатные API ключи

| Сервис | Ссылка | Лимит |
|--------|--------|-------|
| **Groq** | https://console.groq.com/keys | Бесплатно, быстрый |
| **Google Gemini** | https://aistudio.google.com/apikey | Бесплатно, 1M токенов контекст |
| **Mistral** | https://console.mistral.ai/api-keys | Бесплатно |
| **OpenRouter** | https://openrouter.ai/keys | Бесплатные модели (`:free`) |

---

## Шаг 4 — Настройка Continue config.yaml

Открой: `Ctrl+Shift+P` → `Continue: Open Config`

Или вручную:
```
%APPDATA%\Code\User\globalStorage\continue.continue\config.yaml
```

Вставь конфиг из файла `config.yaml` в этой папке, заменив `YOUR_KEY` на свои ключи.

### Модели с поддержкой Agent Mode ✅
- Groq Llama3.3 70b
- NVIDIA Nemotron 120b (OpenRouter)
- Mistral Large
- GPT-4o (OpenAI)

### Модели только Chat/Edit
- Gemini 2.5 Flash
- Claude 3.5 Sonnet (OpenRouter)

---

## Шаг 5 — Настройка SSH подключения к серверам

### Генерация SSH ключа (PowerShell)
```powershell
ssh-keygen
# Нажать Enter на все вопросы
```

### Копирование ключа на сервер
```powershell
type C:\Users\USER\.ssh\id_rsa.pub | ssh root@YOUR_SERVER_IP "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

### SSH Config файл
Открой: `notepad C:\Users\USER\.ssh\config`

Вставь (см. файл `ssh_config.example` в этой папке).

### Подключение в VS Code
`Ctrl+Shift+P` → `Remote-SSH: Connect to Host` → выбери сервер

---

## Шаг 6 — Использование Agent Mode

1. Подключись к серверу через Remote-SSH
2. Нажми **Open Folder** → выбери `/root` или нужную папку
3. В Continue переключись: **Chat → Agent**
4. Выбери модель с поддержкой Agent
5. Пиши задачу — Continue выполняет с подтверждением

### Пример команды для Agent:
```
Открой файл /root/Linux_Server_Public/blacklist/collect-blacklist.sh
и добавь в начало проверку что скрипт запущен от root
```

---

## Режимы Continue

| Режим | Назначение |
|-------|------------|
| **Chat** | Вопросы, объяснения кода |
| **Edit** | Редактирование выделенного кода |
| **Agent** | Автономное выполнение задач на сервере |

---

## Полезные горячие клавиши

| Клавиши | Действие |
|---------|----------|
| `Ctrl+Alt+I` | Открыть чат Continue |
| `Ctrl+Alt+Space` | Принудительное автодополнение |
| `Ctrl+Shift+P` → `Remote-SSH: Connect` | Подключиться к серверу |
