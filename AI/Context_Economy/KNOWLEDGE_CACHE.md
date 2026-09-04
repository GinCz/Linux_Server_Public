# 🧠 Knowledge Cache Architecture

> **A unified local knowledge database for AI coding agents combining Jira, Confluence, and NotebookLM (Gemini) data.**
> 🔗 Repository: [GitHub: Linux_Server_Public/AI/Context_Economy ↗](https://github.com/GinCz/Linux_Server_Public/tree/main/AI_Tokens) | Author: [GinCz ↗](https://github.com/GinCz)

---

## 1. Unified Cache Vision

The goal is to maintain a single source of truth locally for all technical knowledge required by the AI agent. This eliminates redundant API calls to external enterprise systems (Jira, Confluence) and provides lightning-fast access to curated information (NotebookLM Gemini).

### Data Sources
* **Jira:** Tickets, comments, issue history.
* **Confluence:** Pages, architectural documents.
* **NotebookLM (Gemini):** Personal knowledge base, custom notes, historical insights.

---

## 2. Directory Structure

The local cache is organized on the filesystem into logical layers depending on your environment (Home/Infra vs Enterprise/Work):

```text
knowledge/
│
├── cache/                  # The Raw & AI-ready data
│   ├── jira/               # (Scenario B) Jira tickets via MCP
│   │   ├── ABC-1234.json
│   │   └── ABC-1234.md
│   │
│   ├── confluence/         # (Scenario B) Confluence pages via MCP
│   │   ├── 123456.json     
│   │   └── 123456.md       
│   │
│   ├── notebooklm/         # (Both) Personal notes, custom txt/images
│   │   ├── system_notes.md
│   │   └── db_schema.md
│   │
│   └── infra/              # (Scenario A) AWS, Oracle, Cloudflare, SSH configs
│       ├── master-de222.json
│       └── cloudflare-zones.md
│
├── index/                  # Search indices
│   ├── metadata.json       # Lightweight index for quick ID lookups
│   └── fts.db              # SQLite FTS5 database (for fast full-text search)
│
└── sessions/               # Task Knowledge Packs (Task-specific context)
    └── JIRA-14523/
        ├── task.md         # Current task context and hypotheses
        └── related/        # Symlinks or copies of relevant cached MD files
            ├── JIRA-12771.md
            └── 123456.md
```

---

## 3. The Three Layers

### A. Raw JSON
* Contains the **complete** API response (all fields, attachments metadata, full comment history).
* Purpose: To allow rebuilding the AI-ready `.md` files without re-downloading from the source if our parsing logic improves.

### B. Normalized Markdown (.md)
* A concise, AI-optimized version of the data.
* Stripped of HTML bloat, unnecessary metadata, and redundant system comments.
* Contains a standardized YAML frontmatter for programmatic parsing.

```markdown
---
id: ABC-1234
source: jira
source_updated: 2026-08-20T14:32:00Z
cached_at: 2026-08-25T20:00:00Z
freshness_check_after: 2026-09-25T20:00:00Z
etag: "a1b2c3d4"
status: resolved
---
# [ABC-1234] System Crash on Master Node
...
```

### C. Search Index (SQLite FTS5 / Ripgrep)
* An index built from the `.md` files.
* Allows the AI or the `kb-search.ps1` script to instantly find relevant tickets by keyword without parsing 10,000 files.

---

## 4. Freshness & Sync Strategy

1. **Etag / Last Modified:** We rely on `etag` or `source_updated` from the remote API.
2. **Freshness TTL:** We do NOT delete records after 90 days. We flag them for a "freshness check". If the AI needs an old ticket, the sync script will ping Jira for the `etag` or `updated` date. If it hasn't changed, the local cache remains valid.
3. **Differential Updates:** Only new comments or status changes are appended.

---

## 5. Integration with Codex / MCP

For OpenAI Codex and other MCP-enabled agents, the strategy shifts:
* The **Jira/Confluence MCP** is NO LONGER used for searching or answering general questions.
* The **Knowledge MCP** (Local Search) is used first.
* If a ticket is missing, the AI triggers a **cache population command** (e.g., `sync-jira-cache.ps1 -Action resync-ticket -TicketId ABC-1234`).
* Once populated, the AI reads the local `.md` file.

This ensures zero token waste on massive JSON payloads during the reasoning phase.
