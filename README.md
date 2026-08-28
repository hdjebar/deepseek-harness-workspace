# DeepSeek Harness (DSH) Production Developer Workspace

An advanced, production-configured multi-interface AI engineering workspace built over the local-first **DeepSeek Harness (`@deepseek-ai/dsh`)** framework using **Bun**.

## Architecture Visual Layout

```
                  ┌──────────────────────────────┐
                  │   ~/.dsh/cordis.patch.yml    │  ◄── Global Profiles
                  └──────────────┬───────────────┘      & Security Rules
                                 │
                 ┌───────────────┴───────────────┐
                 ▼                               ▼
     ┌───────────────────────┐       ┌───────────────────────┐
     │      bun run web      │       │      bun run cli      │
     │   (VS Code Browser)   │       │   (Terminal Matrix)   │
     └───────────┬───────────┘       └───────────┬───────────┘
                 │                               │
                 └───────────────┬───────────────┘
                                 ▼
         ┌───────────────────────────────────────────────┐
         │             CONSOLIDATED BACKEND CORES        │
         ├───────────────────────────────────────────────┤
         │ 🔐 Hardware Vault (@deepseek-ai/dsh-credentials)│
         │ 🌐 Universal Gateway (OpenRouter v1 Endpoint) │
         │ 🔍 Free Search Network (@liustack/modsearch)  │
         │ 🔌 Extensible MCP Terminal Hub (dsh-mcp-panel)│
         │ 📁 VSCode-Style Sidebar (dsh-better-sidebar)  │
         │ 🛒 Community Plugin Store (dshmarket & search)│
         │ 🖥️  Tmux Context (@deepseek-ai/dsh-tmux-context)│
         └───────────────────────────────────────────────┘
```

## Core Infrastructure Features

* **Zero Plaintext Security Matrix:** API credentials are never written to disk unencrypted. Tokens are stored natively inside your operating system hardware vault (Keychain/DPAPI via `@deepseek-ai/dsh-credentials`), with cleartext artifacts purged on setup.
* **Unified Model Gateway:** Seamlessly routes completions to OpenRouter (`https://openrouter.ai/api/v1`) with deterministic temperature fencing (`0.2`).
* **Free No-Key Web Search & Extraction:** Replaces paid search defaults with `@liustack/modsearch`. Provides zero-configuration web search, Firecrawl scraping, and multi-engine fallback.
* **Dual Interface Environments:**
  * **VS Code Web Layout (`dsh-better-sidebar`):** Full browser IDE experience with multi-tab editor, tree explorer, live terminal, and git diff viewer.
  * **Terminal Keyboard Matrix (`dsh-tui`):** Fast, keyboard-driven Vim-style terminal client.
* **Unified MCP Control Room (`dsh-mcp-panel`):** Auto-discovers local Model Context Protocol servers and provides a trial execution console with version-backed backups.
* **Plugin Storefront & Discovery (`dshmarket` & `dsh-find-plugin`):** Integrated GUI store and natural-language GitHub topic discovery for community plugins.
* **Tmux Context Integration (`@deepseek-ai/dsh-tmux-context`):** Observes active terminal states and session context to enrich LLM prompts.

## Quick Start Guide

### 1. Prerequisites
Ensure you have the [Bun Runtime](https://bun.sh) installed on your host system:
```bash
curl -fsSL https://bun.sh/install | bash
```

### 2. Execution Setup
Run the consolidated bootstrap pipeline:
```bash
chmod +x setup-dsh.sh
./setup-dsh.sh
```
*Note: Provide your OpenRouter secret key (`sk-or-...`) when securely prompted by the script.*

### 3. Launching Your Preferred Workspace Interface

* **Launch the Web IDE Workbench (VS Code Style):**
  ```bash
  bun run web
  ```
  *Opens the browser UI with `dsh-better-sidebar` enabled.*

* **Launch the Keyboard-First Terminal Interface (TUI Matrix):**
  ```bash
  bun run cli
  ```
  *Launches the Vim-bound terminal matrix via `dsh-tui`.*

* **Run a Background Headless Agent Pipeline Task:**
  ```bash
  bun run headless "Analyze codebase and optimize build scripts"
  ```

## Security & Sandboxing

The `workspace.restrict_to_cwd: true` rule is enforced in `~/.dsh/cordis.patch.yml`. This restricts running AI agents to the repository directory boundary, preventing accidental traversal or inspection of sensitive files outside the workspace folder.
