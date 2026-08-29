<div align="center">

# ⚡ DeepSeek Harness (DSH)
### *Production-Grade Developer Workspace & Multi-Interface AI Engine*

[![Bun Runtime](https://img.shields.io/badge/Bun-1.2%2B-000000?style=for-the-badge&logo=bun&logoColor=white)](https://bun.sh)
[![DeepSeek Harness](https://img.shields.io/badge/@deepseek--ai/dsh-0.1.1--rc.2-0066FF?style=for-the-badge&logo=codeforces&logoColor=white)](https://github.com/deepseek-ai)
[![OpenRouter](https://img.shields.io/badge/OpenRouter-390%2B%20Live%20Models-6366F1?style=for-the-badge&logo=openai&logoColor=white)](https://openrouter.ai)
[![Free Search](https://img.shields.io/badge/Web%20Search-%40liustack%2Fmodsearch%20(Free)-06B6D4?style=for-the-badge&logo=searxng&logoColor=white)](https://www.npmjs.com/package/@liustack/modsearch)
[![Security](https://img.shields.io/badge/Security-POSIX%200600%20Isolated-10B981?style=for-the-badge&logo=auth0&logoColor=white)](#-security--sandboxing)
[![CI Status](https://img.shields.io/badge/CI-Passing%20100%25-22C55E?style=for-the-badge&logo=githubactions&logoColor=white)](#-automated-ci--quality-gates)
[![License](https://img.shields.io/badge/License-MIT-F59E0B?style=for-the-badge)](LICENSE)

<p align="center">
  <b>A blazing-fast, local-first multi-interface AI engineering workbench built on the <a href="https://bun.sh">Bun runtime</a> and <a href="https://github.com/deepseek-ai">DeepSeek Harness</a> framework.</b><br>
  Equipped with dynamic OpenRouter model discovery, free search engines, MCP tooling consoles, and isolated credential stores.
</p>

---

[🚀 Quick Start](#-quick-start-in-60-seconds) • [✨ Key Features](#-core-capabilities) • [🔍 Free Search](#-zero-cost-web-search-modsearch) • [🏛️ Architecture](#%EF%B8%8F-system-architecture) • [💻 Interfaces](#-runtime-interfaces) • [🩺 Health Doctor](#-diagnostic-health-check) • [🛡️ Security](#-security--sandboxing)

---

</div>

## ✨ Core Capabilities

| Feature | Description |
| :--- | :--- |
| 🌐 **Universal Gateway** | Stream completions directly from [OpenRouter](https://openrouter.ai) with streaming, tool calling, and multimodal reasoning across **390+ models**. |
| 🔄 **Live Dynamic Model Sync** | `bun run sync-models` queries OpenRouter's live API to automatically register new frontier models into your runtime patch. |
| 🔍 **Zero-Cost Web Search** | Pre-integrated `@liustack/modsearch` replaces paid search APIs with zero-config multi-engine web search & Firecrawl scraping. |
| 🖥️ **Dual Interface Matrix** | Switch seamlessly between a **VS Code-style browser IDE** (`dsh-better-sidebar`) and a **Vim-inspired terminal matrix** (`dsh-tui`). |
| 🛡️ **Zero-Plaintext Security** | POSIX-isolated managed credential store (`0600` permissions in a `0700` root) with pre-flight API key verification and automatic `.env` purging. |
| 🔌 **Integrated MCP Hub** | Built-in Model Context Protocol panel (`dsh-mcp-panel`) with auto-discovery, trial execution console, and versioned backups. |
| ⚙️ **Models Pro Configurator** | Dedicated Settings UI (`dsh-provider-model-configurator`) to tune context windows, max tokens, sampling parameters, and reasoning budgets. |
| 🩺 **Non-Destructive Doctor** | Instant health diagnostics (`doctor.js`) validating runtime integrity, port bindings, permissions, and network connectivity. |

---

## 🔍 Zero-Cost Web Search (`@liustack/modsearch`)

Standard AI agent harnesses often rely on expensive search APIs (Tavily, Bing, Google Search API) with separate monthly quotas and rate limits. This workspace integrates **[`@liustack/modsearch`](https://www.npmjs.com/package/@liustack/modsearch)** directly into the runtime profile.

### 🌟 Why `@liustack/modsearch`?
* 🆓 **Zero API Keys & Zero Cost:** Queries the web without requiring any subscription or credit card.
* 🌐 **Multi-Engine Aggregator:** Automatically queries and falls back between DuckDuckGo, Bing, and open web indexers.
* 🕷️ **Clean Web Scraping:** Uses Firecrawl-compatible web extraction to deliver sanitized, readable Markdown directly into the agent's reasoning loop.
* ⚡ **Zero-Code Override:** Pre-configured in `~/.dsh/cordis.patch.yml` to automatically intercept and replace default paid search providers:

```yaml
# Disable default paid search in favor of free ModSearch
- id: web-search-deepseek
  disabled: true

- id: web
  config:
    searchProvider: modsearch
```

---

## 🏛️ System Architecture

```mermaid
flowchart TD
    subgraph Storage ["🔒 Isolated User Home (~/.dsh)"]
        CRED["~/.dsh/.credentials.yaml\n(POSIX 0600 Managed Store)"]
        PATCH["~/.dsh/cordis.patch.yml\n(Provider & Plugin Orchestration)"]
        SETT["~/.dsh/settings.yaml\n(Default Model & Provider Routes)"]
    end

    subgraph Interfaces ["💻 Dual Client Environments"]
        WEB["🌐 Web Workbench (Port 3080)\nVS Code Sidebar & Editor"]
        CLI["⌨️ Terminal Matrix\ndsh-tui (Vim-Style Navigation)"]
        HEADLESS["🤖 Headless Agent Runner\ndsh --profile headless"]
    end

    subgraph Runtime ["⚡ Local DSH Engine (Bun v1.2+)"]
        CORE["@deepseek-ai/dsh Kernel"]
        MODSEARCH["🔍 Free ModSearch Provider"]
        MCP["🔌 MCP Local Terminal Panel"]
        SYNC["🔄 Dynamic Model Synchronizer"]
    end

    subgraph Remote ["☁️ Upstream AI Infrastructure"]
        OR["🌐 OpenRouter Gateway v1\n(390+ Active Models)"]
        WEB_NET["🌍 Web Search & Extraction"]
    end

    Storage --> Runtime
    Runtime --> Interfaces
    SYNC -->|Live Catalog Sync| OR
    CORE -->|Streaming & Tool Calls| OR
    MODSEARCH -->|Scraping & Queries| WEB_NET
```

---

## 🚀 Quick Start in 60 Seconds

### 1. Prerequisites
Ensure the **Bun Runtime** is installed on your host machine:

```bash
curl -fsSL https://bun.sh/install | bash
```

### 2. One-Line Environment Bootstrap
Clone the repository and run the interactive setup pipeline:

```bash
git clone https://github.com/hdjebar/deepseek-harness-workspace.git
cd deepseek-harness-workspace
chmod +x setup-dsh.sh
./setup-dsh.sh
```

> [!TIP]
> Provide your OpenRouter API key (`sk-or-...`) when securely prompted. The installer validates your token remotely before writing any configuration.

---

## 💻 Runtime Interfaces & Commands

```bash
# 🌐 1. Launch the VS Code-style Browser Web IDE (http://127.0.0.1:3080)
bun run web

# ⌨️ 2. Launch the High-Performance Keyboard Terminal Matrix
bun run cli

# 🤖 3. Execute a Headless Agent Automation Pipeline
bun run headless "Audit this repository and suggest architecture optimizations"

# 🔄 4. Synchronize Live Models from OpenRouter
bun run sync-models

# 🩺 5. Run the Workspace Health Diagnostic
bun run doctor
```

---

## 🩺 Diagnostic Health Check

Run `bun run doctor` anytime for an instant, non-destructive health analysis of your environment:

```
🩺 DSH workspace doctor — read-only diagnostics

✅ Bun runtime — bun 1.3.14
✅ Framework installed — @deepseek-ai/dsh 0.1.1-rc.2
✅ Script bindings — web, cli, headless, sync-models, doctor
✅ OpenRouter key valid — source: ~/.dsh/.credentials.yaml (managed store); limit: no spending limit
✅ Runtime patch layer — /Users/user/.dsh/cordis.patch.yml
✅ Model catalog synced — 396 models in cordis.patch.yml
✅ Sync anchor present
✅ Settings layer — ~/.dsh/settings.yaml routes openrouter
✅ Web profile plugins — 5/5 installed
ℹ️  Port 3080 — free — nothing listening

✅ All critical checks passed.
```

---

## 🛡️ Security & Sandboxing

> [!IMPORTANT]
> **Strict POSIX Credential Isolation**  
> Credentials reside in `~/.dsh/.credentials.yaml` with strict `0600` permissions (readable/writable only by the owner) inside a `0700` directory. Legacy plaintext `.env` copies are automatically expunged on bootstrap.

> [!NOTE]
> **Runtime Filesystem Sandboxing**  
> Agent file mutations are fenced by DSH's native runtime sandbox policies (`read-only`, `workspace-write`, or `danger-full-access`). Dangerous filesystem mutations outside the workspace boundary require explicit user approval.

---

## 🛑 Stopping & Killing Processes

If a background DSH process, web server, or port (`3080`) is locked or lingering:

```bash
# Terminate lingering web server on port 3080
lsof -ti :3080 | xargs kill -9 2>/dev/null || true

# Kill any active DSH background processes
pkill -9 -f "bun.*dsh" 2>/dev/null || pkill -9 -f "dsh-tui" 2>/dev/null || true
```

---

## 🧹 Clean Slate & Reset

To completely reset the workspace, purge stored credentials, and clean local caches:

```bash
# Interactive reset (prompts for confirmation)
./reset.sh
# or via npm/bun script
bun run reset

# Non-interactive force reset (for CI or automation)
./reset.sh --force
```

The reset script safely:
1. Terminates any lingering DSH web servers on port 3080 and background processes.
2. Purges the global `~/.dsh` directory (credentials, profiles, patches).
3. Cleans local untracked `node_modules`, `.dsh/`, and runtime logs.

*To reinstall and configure fresh after reset, simply run `./setup-dsh.sh`.*

---

## ❓ Troubleshooting Matrix

| Issue / Symptom | Root Cause | Solution |
| :--- | :--- | :--- |
| **`HTTP 401 Unauthorized` on inference** | Invalid or revoked OpenRouter key | Check key status with `bun run doctor`, then re-run `./setup-dsh.sh` with a valid key from [openrouter.ai/keys](https://openrouter.ai/keys). |
| **`Port 3080` already in use** | Lingering background DSH web process | Run `lsof -ti :3080 \| xargs kill -9` and relaunch `bun run web`. |
| **Missing models in catalog** | Patch has not been synced recently | Execute `bun run sync-models` to pull real-time OpenRouter models. |
| **"Failed to locate openrouter block anchor"** | `cordis.patch.yml` lost its `# Route default model` anchor | Re-run `./setup-dsh.sh` to regenerate the patch layer. |
| **Plugin installation failure** | Network timeout during initial bootstrap | Re-run `./setup-dsh.sh` (setup is fully idempotent). |

---

## 🧪 Automated CI & Quality Gates

This repository is strictly validated by GitHub Actions ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)):

- 🛡️ **ShellCheck & Syntax Validation:** Rigorous style and syntax enforcement on all bash automation.
- 📦 **Frozen Lockfile Concurrency:** Verification of byte-exact dependencies using `bun install --frozen-lockfile`.
- 🔄 **Idempotent Model Syncing:** Validates that live catalog updates preserve patch integrity without duplication.
- 🩺 **Negative Diagnostic Tests:** Ensures error conditions and missing credentials fail loudly and predictably.
- 📜 **YAML Schema Validation:** Python `pyyaml` validation verifying provider and model block structures.

---

<div align="center">

Made with ⚡ by [Hdjebar](https://github.com/hdjebar) • Powered by [DeepSeek Harness](https://github.com/deepseek-ai) & [Bun](https://bun.sh)

</div>
