<div align="center">

# ⚡ DeepSeek Harness (DSH)
### *Your Personal AI Environment — One Command, 390+ Models, Fully Yours*

[![Bun Runtime](https://img.shields.io/badge/Bun-1.2%2B-000000?style=for-the-badge&logo=bun&logoColor=white)](https://bun.sh)
[![DeepSeek Harness](https://img.shields.io/badge/@deepseek--ai/dsh-0.1.1--rc.2-0066FF?style=for-the-badge&logo=codeforces&logoColor=white)](https://github.com/deepseek-ai)
[![OpenRouter](https://img.shields.io/badge/OpenRouter-390%2B%20Live%20Models-6366F1?style=for-the-badge&logo=openai&logoColor=white)](https://openrouter.ai)
[![Free Search](https://img.shields.io/badge/Web%20Search-%40liustack%2Fmodsearch%20(Free)-06B6D4?style=for-the-badge&logo=searxng&logoColor=white)](https://www.npmjs.com/package/@liustack/modsearch)
[![Security](https://img.shields.io/badge/Security-POSIX%200600%20Isolated-10B981?style=for-the-badge&logo=auth0&logoColor=white)](docs/security.md)
[![CI Status](https://github.com/hdjebar/deepseek-harness-workspace/actions/workflows/ci.yml/badge.svg)](https://github.com/hdjebar/deepseek-harness-workspace/actions/workflows/ci.yml)
[![GitHub Stars](https://img.shields.io/github/stars/hdjebar/deepseek-harness-workspace?style=for-the-badge&color=FFD700&logo=github)](https://github.com/hdjebar/deepseek-harness-workspace/stargazers)
[![License](https://img.shields.io/badge/License-MIT-F59E0B?style=for-the-badge)](LICENSE)

<p align="center">
  <b>Stop juggling provider API keys, paid search subscriptions, and plaintext <code>.env</code> files scattered across projects.</b><br>
  DSH is a local-first, <a href="https://bun.sh">Bun</a>-powered workbench that gives you your own AI environment in one command —<br>
  a live gateway to <b>390+ models</b>, free multi-engine web search, a plugin marketplace, and a growing library of skills that stay <i>yours</i>.
</p>

---

[🤔 Why](#-why-dsh) • [💡 What](#-what-is-dsh) • [🎯 Who It's For](#-who-its-for) • [⏱️ When](#-when-to-reach-for-dsh) • [🏛️ How](#-how-it-works) • [🚀 Quick Start](#-quick-start-in-60-seconds) • [✨ Features](#-core-capabilities) • [🎨 Customize](docs/customization.md) • [🛡️ Security](docs/security.md)

---

</div>

## 🤔 Why DSH?

| Without DSH | With DSH |
| :--- | :--- |
| A separate API key and billing plan per model provider | One [OpenRouter](https://openrouter.ai) gateway → **390+ models**, one key |
| Paying for search APIs (Tavily, Bing, Google Search) | `@liustack/modsearch` — multi-engine web search, **zero cost, zero keys** |
| Plaintext `.env` secrets scattered across repos | A POSIX `0600` credential vault with legacy `.env` auto-purged |
| Re-installing and reconfiguring tooling per project | `./setup-dsh.sh` — isolated, idempotent, **under 60 seconds** |
| Locked into one interface | The same environment in a **web IDE, terminal TUI, or headless agent** |
| Static, one-time setup | A workspace that **grows with you** — plugins, skills, and models synced live |

If you want an AI workbench that's actually *yours* — local, inspectable, and shaped by your own skills and prompts rather than a vendor's chat window — DSH is built for that.

---

## 💡 What is DSH?

DeepSeek Harness (DSH) is a **Bun-powered bootstrap and configuration layer** around the [`@deepseek-ai/dsh`](https://github.com/deepseek-ai) agent framework — it is not itself a model, and it's not a hosted product. Running `./setup-dsh.sh` once wires up a single isolated workspace with:

* an OpenRouter gateway across 390+ models,
* a free, multi-engine web search provider,
* a plugin marketplace and MCP tooling console,
* three interfaces — web IDE, terminal TUI, headless runner — that all read the same configuration.

Everything it configures is plain YAML/JSON on your own disk (`cordis.patch.yml`, `settings.yaml`, `.credentials.yaml`), not a proprietary format or a cloud account. That's what makes it *yours*: you can read, edit, or version every piece of it.

---

## 🎯 Who It's For

* **Solo developers & indie hackers** who want one workbench across many models instead of separate accounts, keys, and billing per provider.
* **Builders who want to own their setup** — inspectable config, a local credential vault, and a `./skills/` folder that becomes a personal knowledge base over time (see the [Customization Guide](docs/customization.md)).
* **Anyone automating with headless pipelines** — CI/CD tasks, background codebase audits, or scripted multi-step jobs via `bun run headless`.
* **People who may eventually want local/on-prem inference** — the `llm-pi-ai` provider layer makes swapping in Ollama, LM Studio, or vLLM a config change, not a rewrite (see the "Going Local" section of the [Customization Guide](docs/customization.md)).

**Probably not the right fit if you need:**
* Shared, multi-user, cloud-hosted state — DSH is a single-user, local-first workspace by design.
* A zero-setup GUI chat app — DSH is a workbench you configure once via script, not a hosted product.
* Native Windows without WSL2 — see [Windows Support](docs/windows.md) for the WSL2 path and what a native port would take.

---

## ⏱️ When to Reach for DSH

**Reach for it when you want to:**
* Prototype or compare across many models without opening a separate account for each.
* Keep one private, growing library of your own skills/prompts that travels with you across projects.
* Kick off an agent headlessly and walk away: `bun run headless "..."`.
* Swap models or providers by editing YAML, not application code.

**It's the wrong tool when you need:**
* Guaranteed offline/local-only inference *out of the box* — OpenRouter is the default; going fully local is possible (see [docs/customization.md](docs/customization.md)) but is an extra step, not the initial state.
* A production, multi-tenant backend — this is a personal dev workbench, not a hosted service.

---

## 🏛️ How It Works

At a glance: an isolated, permission-locked credential store feeds a local Bun runtime engine, which serves three interchangeable interfaces and talks to OpenRouter and free web search upstream.

📖 **Full diagram:** [docs/architecture.md](docs/architecture.md)

### 🛒 Everything is a Plugin (`dshmarket` & `dsh-find-plugin`)

In the **DeepSeek Harness** architecture, **everything is a plugin** — skills, MCP adapters, UI widgets, LLM providers, and agent loops. This workspace ships with a visual marketplace (`dshmarket`), natural-language plugin discovery (`dsh-find-plugin`), CLI plugin management, and a per-profile capability matrix.

📖 **Full guide:** [docs/plugins.md](docs/plugins.md)

### 🔍 Zero-Cost Web Search (`@liustack/modsearch`)

This workspace replaces paid search APIs (Tavily, Bing, Google Search API) with **[`@liustack/modsearch`](https://www.npmjs.com/package/@liustack/modsearch)** — a zero-key, multi-engine search and scraping provider pre-wired into the runtime profile.

📖 **Full guide:** [docs/search.md](docs/search.md)

---

## ✨ Core Capabilities

| Feature | Description |
| :--- | :--- |
| 🌐 **Universal Gateway** | Stream completions directly from [OpenRouter](https://openrouter.ai) with streaming, tool calling, and multimodal reasoning across **390+ models**. |
| 🛒 **Plugin & Skill Marketplace** | Pre-installed `dshmarket` (GUI Store) and `dsh-find-plugin` (Natural Language Discovery) to add community plugins, tools, and skills on the fly. |
| 🔄 **Live Dynamic Model Sync** | `bun run sync-models` queries OpenRouter's live API to automatically register new frontier models into your runtime patch. |
| 🔍 **Zero-Cost Web Search** | Pre-integrated `@liustack/modsearch` replaces paid search APIs with zero-config multi-engine web search & Firecrawl scraping. |
| 🖥️ **Dual Interface Matrix** | Switch seamlessly between a **VS Code-style browser IDE** (`dsh-better-sidebar`) and a **Vim-inspired terminal matrix** (`dsh-tui`). |
| 🛡️ **Zero-Plaintext Security** | POSIX-isolated managed credential store (`0600` permissions in a `0700` root) with pre-flight API key verification and automatic `.env` purging. |
| 🔌 **Integrated MCP Hub** | Built-in Model Context Protocol panel (`dsh-mcp-panel`) with auto-discovery, trial execution console, and versioned backups. |
| ⚙️ **Models Pro Configurator** | Dedicated Settings UI (`dsh-provider-model-configurator`) to tune context windows, max tokens, sampling parameters, and reasoning budgets. |
| 🩺 **Non-Destructive Doctor** | Instant health diagnostics (`doctor.js`) validating runtime integrity, port bindings, permissions, and network connectivity. |

---

## 🚀 Quick Start in 60 Seconds

> [!NOTE]
> **Platform support:** DSH targets **macOS and Linux** natively — `setup-dsh.sh` and `reset.sh` are bash scripts, and the credential vault relies on POSIX `chmod` permissions. On Windows, run it inside **WSL2** (fully supported, ~10 minutes, zero code changes). See [docs/windows.md](docs/windows.md) for the WSL2 quick path and a detailed guide for anyone porting a native PowerShell version.

### 1. Prerequisites

* **Bun Runtime** — everything runs on it:
  ```bash
  curl -fsSL https://bun.sh/install | bash
  ```
* **Git** — needed to clone this repo, and `setup-dsh.sh` also runs `git init` internally if the target directory isn't already a repository.
* **An OpenRouter API key** — grab one at [openrouter.ai/keys](https://openrouter.ai/keys). `setup-dsh.sh` prompts for it and validates it against the live API before writing any configuration.

> [!TIP]
> `pnpm` is **not** a prerequisite — `setup-dsh.sh` installs it automatically via Bun if it isn't already on your `PATH`.

### 2. Environment Bootstrap (Isolated Local Setup by Default)
Clone the repository and run the setup pipeline:

```bash
git clone https://github.com/hdjebar/deepseek-harness-workspace.git
cd deepseek-harness-workspace
chmod +x setup-dsh.sh

# 📦 Default: Install locally into ./.dsh (100% isolated per workspace)
./setup-dsh.sh

# 🌍 Optional: Install globally into ~/.dsh (shared across projects)
./setup-dsh.sh --global

# 📁 Optional: Install into a custom directory
./setup-dsh.sh --dir /path/to/dsh-config
```

> [!TIP]
> **Local by Default:** Configurations, credentials, and plugins are stored in `./.dsh` (already ignored by `.gitignore`). You can have multiple distinct DSH workspaces on the same machine without any cross-project conflicts!

---

## 💻 Runtime Interfaces & Commands

```bash
# 🌐 1. Launch the VS Code-style Browser Web IDE (http://127.0.0.1:3080)
bun run web

# ⌨️ 2. Attach the Keyboard-First Terminal Matrix (Connects to active DSH backend)
# Tip: Run 'bun run web' in terminal 1, then run 'bun run cli' in terminal 2
bun run cli

# 🤖 3. Execute a Standalone Headless Agent Pipeline (Zero-browser, direct runner)
bun run headless "Audit this repository and suggest architecture optimizations"

# 🔄 4. Synchronize Live Models from OpenRouter
bun run sync-models

# 🩺 5. Run the Workspace Health Diagnostic (Detects local vs global target & permissions)
bun run doctor

# 🧹 6. Clean Slate Workspace Reset
bun run reset            # Resets local ./.dsh workspace configuration and artifacts
./reset.sh --global      # Resets global ~/.dsh configuration only
```

> [!TIP]
> **Running Multiple Workspaces Simultaneously (Port Customization):**  
> By default, DSH runs on port `3080`. To run a second workspace in parallel without collision, set `DSH_PORT`:  
> ```bash
> DSH_PORT=3081 bun run web      # Starts second workspace on http://127.0.0.1:3081
> DSH_PORT=3081 bun run cli      # Attaches TUI matrix to port 3081
> DSH_PORT=3081 bun run doctor   # Diagnoses port 3081
> ```

---

## 🎨 Extensibility & Customization

This workspace is designed to be fully customizable via conversational prompts, DSH plugins, and MCP servers:

* 🛒 **Community Plugins:** Install visual tools, sidebars, and models with 1-click via **`dshmarket`** in the Web UI.
* 🔍 **Natural-Language Discovery:** Ask your agent in chat (*"Find a plugin for Docker / PostgreSQL"*) via **`dsh-find-plugin`**.
* 🧠 **Custom Skills:** Add domain rules anytime by placing Markdown files in `./skills/<skill-name>/SKILL.md`.
* 📖 **Learn More:** Check out the [**Customization Guide**](docs/customization.md) for practical prompt recipes.

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

## 📚 Documentation

Deep-dive guides live in [`docs/`](docs/):

| Guide | Covers |
| :--- | :--- |
| [🎨 Customization](docs/customization.md) | Prompt-driven plugins, MCP servers, skills, model tuning, sandbox modes, headless pipelines |
| [🎭 Personas](docs/personas.md) | Composing skills + plugins/MCP + model choice + automation into a role-specific setup, including what the native `workflow` tool actually is |
| [🛒 Plugins & Marketplace](docs/plugins.md) | `dshmarket`, `dsh-find-plugin`, CLI plugin management, profile capability matrix |
| [🔍 Free Web Search](docs/search.md) | `@liustack/modsearch` zero-cost search integration |
| [🏛️ Architecture](docs/architecture.md) | System diagram — storage, interfaces, runtime, upstream infrastructure |
| [🛡️ Security & Sandboxing](docs/security.md) | Credential isolation, filesystem sandbox policies |
| [🧹 Stopping & Resetting](docs/reset.md) | Killing lingering processes, `reset.sh` clean-slate workflow |
| [❓ Troubleshooting](docs/troubleshooting.md) | Common errors and fixes |
| [🧪 CI & Quality Gates](docs/ci.md) | What GitHub Actions validates on every push |
| [🪟 Windows Support](docs/windows.md) | Why macOS/Linux only today, the WSL2 quick path, and a detailed native-porting guide |

Proposed-but-not-yet-built improvements live in [`ChangeRequest/`](ChangeRequest/) — each one a Summary + Detail writeup meant to be challenged before it's implemented, not a roadmap commitment.

---

<div align="center">

### ⭐ If DSH saves you setup time, star the repo — it helps others find it.

[![GitHub Stars](https://img.shields.io/github/stars/hdjebar/deepseek-harness-workspace?style=social)](https://github.com/hdjebar/deepseek-harness-workspace/stargazers)

Made with ⚡ by [Hdjebar](https://github.com/hdjebar) • Powered by [DeepSeek Harness](https://github.com/deepseek-ai) & [Bun](https://bun.sh)

</div>
