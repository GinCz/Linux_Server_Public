# 🤖 OpenAI Codex & ChatGPT: Zero-Waste Token Economy Specification

> **Dedicated optimization profile for OpenAI Codex (Scenario B - Enterprise & Work Environment).**  
> Tailored for corporate environments where Codex is connected via MCP to Microsoft Confluence, Jira, and a local Knowledge Base (NotebookLM/custom files).  
> *Note: For home infrastructure (AWS, Cloudflare, SSH), see ANTIGRAVITY.md.*  
> 🔗 Repository: [GitHub: Linux_Server_Public/AI_Tokens ↗](https://github.com/GinCz/Linux_Server_Public/tree/main/AI_Tokens) | Author: [GinCz ↗](https://github.com/GinCz)

---

## 🔍 Mandatory Name Canary & Zero Greeting Rule

> [!IMPORTANT]
> - **Direct Name Addressing:** Address the user by name (**"Vladimir, ..."**) at the start of every response.
> - **No Repetitive Greetings:** NEVER say *"Hello"*, *"Hi"*, or conversational pleasantries on every turn.
> - **Telemetry Canary:** Это критический индикатор. Если модель забывает обратиться по имени, это означает, что контекст переполнен (context fatigue), началось "размытие" инструкций и возможны галлюцинации — необходимо немедленно зафиксировать работу и открыть новый чат (`Ctrl+N`).

---

## 🚨 Dynamic Session Guard & Token Overload

Monitor actual context utilization rather than a strict 15-step rule. Output a warning banner when approaching the model's effective context limit for complex reasoning, or when a session reaches ~15-20 heavy turns:

> <span style="color:#ff3333; font-weight:bold; font-size:1.1em;">⚠️ WARNING: High token usage detected! To prevent context dilution and excessive API costs, please commit your changes to WORKLOG.md and start a fresh chat (Ctrl+N)!</span>

---

## 📑 Table of Contents

1. [Zero-Waste Architecture for OpenAI Codex (Windows 10/11)](#1-zero-waste-architecture-for-openai-codex-windows-1011)
2. [Precision `config.toml` Tuning (Reasoning & Memory Controls)](#2-precision-configtoml-tuning-reasoning--memory-controls)
3. [Local Knowledge Cache `%USERPROFILE%\knowledge` (90-Day Retention)](#3-local-knowledge-cache-userprofileknowledge-90-day-retention)
4. [Additive Instruction Optimization in `AGENTS.md`](#4-additive-instruction-optimization-in-agentsmd)
5. [Audit and Control of Plugins and Heavy MCP Servers](#5-audit-and-control-of-plugins-and-heavy-mcp-servers)
6. [Experiments with `.codexignore`](#6-experiments-with-codexignore)
7. [ChatGPT Web, Canvas, Custom GPTs & Custom Instructions](#7-chatgpt-web-canvas-custom-gpts--custom-instructions)
8. [Knowledge Base Indexing Script (`sync-kb.ps1`)](#8-knowledge-base-indexing-script-sync-kbps1)

---

## 1. Zero-Waste Architecture for OpenAI Codex (Windows 10/11)

The **Zero-Waste Token Economy** eliminates avoidable token waste without sacrificing code quality, security, or existing personalization.

### Standardized Windows Environment Paths:
* `$env:CODEX_HOME` or `%USERPROFILE%\.codex`
* `%USERPROFILE%\knowledge\` — Local cache cards and ticket summaries
* `%USERPROFILE%\zero-waste-setup\` — Portable backups, logs, and installation scripts

---

## 2. Precision `config.toml` Tuning (Reasoning & Memory Controls)

In `%USERPROFILE%\.codex\config.toml`, configure settings that curb hidden Chain-of-Thought token generation:

```toml
# ==============================================================================
# ZERO-WASTE CODEX OPTIMIZATION CONFIG (Windows 10/11)
# ==============================================================================

# Reasoning depth controls (prevents runaway 10k CoT hidden tokens)
model_reasoning_effort = "medium"
model_reasoning_summary = "concise"

# Response verbosity (low eliminates conversational fluff and redundant explanations)
model_verbosity = "low"

# Memory management
memories_enabled = true
memory_use_when_external_context_active = false
memory_retention_days = 30

# Telemetry
telemetry_enabled = false
```

---

## 3. Local Knowledge Cache (Cache-First Architecture)

Instead of repeatedly scraping external enterprise systems (Confluence, Jira, Microsoft 365, SharePoint), maintain a comprehensive local cache. On the corporate network, Codex is connected via MCP to Confluence and Jira, but these should only be used to **populate** the cache, not to query it constantly.

### Information Source Hierarchy:
1. **Local Search:** Local knowledge cache (`D:\AI\knowledge\cache\`).
2. **Task Knowledge Pack:** Task-specific local documentation assembled from the cache.
3. **Workspace Search:** Targeted workspace search with `rg` (ripgrep) or SQLite FTS5.
4. **External Systems (MCP):** Strictly used to fetch full tickets/pages when missing locally or when freshness verification is required.

### Knowledge Card Format (`D:\AI\knowledge\cache\*\*.md`):
```markdown
---
id: CONFLUENCE-PAGE-12345
source: confluence
source_url: https://confluence.company.com/pages/12345
source_updated: 2026-08-01T10:00:00Z
cached_at: 2026-08-10T12:00:00Z
freshness_check_after: 2026-11-08T12:00:00Z
etag: "a1b2c3d4"
content_hash: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
tags: [nginx, fastpanel, php-fpm]
---
Brief factual summary (maximum 300 words).
Key directives and architectural parameters without raw HTML bloat.
```

### Cache Retention Rules:
* **Freshness TTL, NOT Deletion:** We do not delete tickets after 90 days. Set `freshness_check_after`. Old tickets are valuable historical context.
* **Update Mechanism:** The sync script checks the remote `etag` or `source_updated` before overwriting.
* **No Secret Storage:** Never cache passwords, API keys, personal user data, or raw email threads.

---

## 4. Additive Instruction Optimization in `AGENTS.md`

In `AGENTS.md` and custom instructions, enforce these universal operational guidelines:

1. **Name Addressing:** Start by addressing the user by name without repetitive greetings.
2. **Distinguish Facts vs Assumptions:** Clearly separate verified facts from interpretation. Do not manufacture certainty.
3. **Direct Disagreement:** When disagreeing with a user's technical proposal, state so directly BEFORE taking action, supported by verifiable facts.
4. **The `/compact` Command:** Use `/compact` whenever context accumulates to summarize decisions and discard stale logs.
5. **Surgical Modifications:** Generate focused diffs instead of printing full 1,000-line files.
6. **One Task Per Chat:** Commit milestones and restart the conversation to maintain the token budget.

---

## 5. Audit and Control of Plugins and Heavy MCP Servers

Every connected MCP server or plugin injects its full JSON tool schema into **every single request**:

| Extension Category | Input Token Overhead | Zero-Waste Action |
| :--- | :--- | :--- |
| **Heavy Enterprise MCP (Jira/Confluence/DB)** | **4,000 – 12,000 tokens/step** | Enable only when actively interacting with that specific service. |
| **Core System MCP (FS, Git, Terminal)** | **500 – 1,500 tokens/step** | Keep enabled permanently. |
| **Browser Scrapers (Playwright/Puppeteer)** | **3,000 – 8,000 tokens/step** | Replace with local `curl` or targeted knowledge cards. |

---

## 6. Experiments with `.codexignore`

Exclude non-essential assets from Codex workspace discovery by creating `.codexignore`:

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

For the web interface of ChatGPT (GPT-4o, Canvas), configure **Settings ➔ Custom Instructions**:

### Section 1: "What would you like ChatGPT to know about you?"
```text
- Name: Vladimir (Владимир). Address strictly by name in Russian.
- Role: Systems Architect, DevOps Engineer (Linux Ubuntu 24.04 Master Node DE-222, RU-109, VPN nodes).
- Work Directory: D:\AI\ and C:\UTIL\. Never use Desktop.
- Repositories: GitHub GinCz (Secret_Privat, Linux_Server_Public).
```

### Section 2: "How would you like ChatGPT to respond?"
```text
1. Address user directly as Vladimir without saying "Hello/Здравствуйте" on every turn.
2. Provide concise, production-ready technical responses without introductory fluff.
3. Output multi-command tasks as a single monolithic script starting with clear / cls.
4. Format all external URLs and GitHub links as clickable markdown with the ↗ symbol.
5. Use Canvas for surgical diffs rather than reprinting entire files.
6. If session length exceeds 15 turns, output the red warning banner.
7. Conclude every response with:
   <small>✅ Done: Started HH:MM:SS • Finished HH:MM:SS • Total: HH:MM:SS (Tokens: ~Xk)</small>
```

---

## 8. Knowledge Base Indexing Script (`sync-kb.ps1`)

Save this script as `%USERPROFILE%\knowledge\sync-kb.ps1` for local cache maintenance:

```powershell
# PowerShell 5.1 / 7+ Zero-Waste KB Sync Script
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
    # Check 90-day expiration
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
*Maintained and versioned in [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public).*
