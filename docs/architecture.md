# 🏛️ System Architecture

```mermaid
flowchart TD
    subgraph Repo ["📁 Repo Root — bun-managed"]
        PKG["package.json / bun.lock\n@deepseek-ai/dsh, dsh-tui"]
    end

    subgraph Storage ["🔒 Isolated Config Store (.dsh)"]
        CRED[".dsh/.credentials.yaml\n(POSIX 0600 Managed Store)"]
        PATCH[".dsh/cordis.patch.yml\n(Provider & Plugin Orchestration)"]
        SETT[".dsh/settings.yaml\n(Default Model & Provider Routes)"]
        PROFILES[".dsh/profiles/*/ — pnpm-managed\ndshmarket, dsh-mcp-panel, dsh-find-plugin, ..."]
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

    UPGRADE["🔄 bun run upgrade"]
    UPGRADE -->|bun update| PKG
    UPGRADE -->|dsh plugin update| PROFILES

    Repo --> Runtime
    Storage --> Runtime
    Runtime --> Interfaces
    SYNC -->|Live Catalog Sync| OR
    CORE -->|Streaming & Tool Calls| OR
    MODSEARCH -->|Scraping & Queries| WEB_NET
```

`.dsh/` resolves to `./.dsh` inside the current workspace by default (local mode — DSH's default) or `~/.dsh` if installed with `./setup-dsh.sh --global`.

**Two disjoint package trees, one command to upgrade both** (see [docs/upgrading.md](upgrading.md)): the repo root is `bun`-managed (`package.json`/`bun.lock`, holding just `@deepseek-ai/dsh` and `dsh-tui`), while every installed plugin lives inside `.dsh/profiles/<name>/`, managed by `pnpm` via its own `pnpm-workspace.yaml`. `bun update` only ever touches the first; `dsh plugin --profile <name> update` only ever touches the second. `bun run upgrade` runs both in sequence, plus the model-catalog sync and a health check.

---

[← Back to README](../README.md)
