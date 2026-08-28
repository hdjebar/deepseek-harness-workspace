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
         ┌───────────────────────────────────────────────────┐
         │             CONSOLIDATED BACKEND CORES            │
         ├───────────────────────────────────────────────────┤
         │ 🛡️ Runtime File Sandbox (workspace-write mode)    │
         │ 🌐 Universal Gateway (OpenRouter v1 Endpoint)     │
         │ 🔄 Live Model Catalog Sync (sync-models.js)       │
         │ 🔍 Free Search Network (@liustack/modsearch)      │
         │ 🔌 Extensible MCP Terminal Hub (dsh-mcp-panel)    │
         │ 📁 VSCode-Style Sidebar (dsh-better-sidebar)      │
         │ ⚙️ Advanced Model Configurator (Model Pro)        │
         │ 🛒 Community Plugin Store (dshmarket & search)    │
         └───────────────────────────────────────────────────┘
```

## Core Infrastructure Features

* **Strict POSIX Permission Isolation:** API credentials are protected with strict `0600` user-only permissions (`~/.dsh/.credentials.yaml` and `~/.dsh/.env`) inside the `0700` user home configuration root.
* **Unified OpenRouter Gateway:** Routes completions directly to OpenRouter (`https://openrouter.ai/api/v1`) with full support for streaming, function calling, and multimodal inputs.
* **Live Dynamic Model Sync (`sync-models.js`):** Automatically queries OpenRouter's live API (`https://openrouter.ai/api/v1/models`) to fetch and register all real-time models into your runtime patch.
* **Free No-Key Web Search & Extraction:** Replaces paid search defaults with `@liustack/modsearch`. Provides zero-configuration web search, Firecrawl scraping, and multi-engine fallback.
* **Dual Interface Environments:**
  * **VS Code Web Layout (`dsh-better-sidebar`):** Full browser IDE experience with multi-tab editor, tree explorer, live terminal, and git diff viewer.
  * **Terminal Keyboard Matrix (`dsh-tui`):** Fast, keyboard-driven Vim-style terminal client.
* **Unified MCP Control Room (`dsh-mcp-panel`):** Auto-discovers local Model Context Protocol servers and provides a trial execution console with version-backed backups.
* **Models Pro / Advanced Model Configurator (`dsh-provider-model-configurator`):** Dedicated UI in Settings (`Model Pro`) to create, edit, copy presets, and tune context windows, max tokens, modalities, and reasoning effort.
* **Plugin Storefront & Discovery (`dshmarket` & `dsh-find-plugin`):** Integrated GUI store and natural-language GitHub topic discovery for community plugins.

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
  *Opens the browser UI at `http://127.0.0.1:3080` with `dsh-better-sidebar` enabled.*

* **Launch the Keyboard-First Terminal Interface (TUI Matrix):**
  ```bash
  bun run cli
  ```
  *Launches the Vim-bound terminal matrix via `dsh-tui`.*

* **Sync Live OpenRouter Models (LOV):**
  ```bash
  bun run sync-models
  ```
  *Queries OpenRouter's live API (`https://openrouter.ai/api/v1/models`) to dynamically sync all active models.*

* **Run a Background Headless Agent Pipeline Task:**
  ```bash
  bun run headless "Analyze codebase and optimize build scripts"
  ```

## Stopping & Killing Running Processes

If a background DSH process, web server, or port (`3080`) is locked or lingering, terminate them safely:

```bash
# 1. Kill any active DSH web server holding port 3080
lsof -ti :3080 | xargs kill -9 2>/dev/null || true

# 2. Kill running DSH processes
pkill -9 -f "bun.*dsh" 2>/dev/null || pkill -9 -f "dsh-tui" 2>/dev/null || true
```

## Reset & Clean Slate

To wipe the global DSH environment, credentials, and local workspace artifacts to start completely fresh:

```bash
# 1. Kill any active DSH background processes
lsof -ti :3080 | xargs kill -9 2>/dev/null || true
pkill -9 -f "bun.*dsh" 2>/dev/null || pkill -9 -f "dsh-tui" 2>/dev/null || true

# 2. Remove global DSH home directory (profiles, credentials, patch layers)
rm -rf "$HOME/.dsh"

# 3. Clean local workspace artifacts, dependencies, and lockfiles
rm -rf node_modules package.json bun.lock bun.lockb .dsh
```

After running the reset, execute `./setup-dsh.sh` to reinstall and rebuild from scratch.

## Security & Sandboxing

Agent filesystem access is enforced by DSH's **runtime file sandbox**, not by the cordis patch layer: every file mutation is fenced by a per-session sandbox mode — `read-only`, `workspace-write` (mutations allowed only under the session's workspace root), or `danger-full-access` — and wider modes are gated behind the interactive approval policy. This bootstrap makes no patch-level changes to that policy; the previously documented `workspace.restrict_to_cwd` patch entry had no effect on the current runtime and has been removed.

Credentials are protected at the OS level: `0600` user-only permissions on `~/.dsh/.credentials.yaml`, `~/.dsh/settings.yaml`, and `~/.dsh/.env`, inside the `0700` `~/.dsh` root.
