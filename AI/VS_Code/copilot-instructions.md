# VS Code AI Instructions (GitHub Copilot & Coding Assistants)

## Standards & Formatting
- **Language:** Default response language is Russian. Code, symbols, variable names, and Git commits are always in English.
- **Encoding:** Always UTF-8 without BOM.
- **Token Economy:**
  - Concise, direct responses without boilerplate greetings or conversational fillers.
  - One task per chat (`Ctrl+N`) to keep context fresh and token-efficient.
  - Never dump entire large source files into chat; provide targeted edits and file paths.
  - Combine multi-step shell commands into a single monolithic script starting with `clear` (Linux) or `cls` (Windows).
- **Paths:** Workspace sandbox is organized under `C:\AI\VSCode\` with shared knowledge base in `C:\AI\BASE\`.