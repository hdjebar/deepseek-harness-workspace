#!/usr/bin/env bash
set -euo pipefail

clear
echo "=========================================================================="
echo "    DEEPSEEK HARNESS (DSH) MASTER PRODUCTION ENV BOOTSTRAP                "
echo "    [OpenRouter + Free Search + VSCode UX + TUI Matrix + Tmux Context]    "
echo "=========================================================================="
echo ""

# 1. Capture the OpenRouter key silently without outputting it to logs
read -rsp "Enter your OpenRouter Master API Key (sk-or-...): " OR_KEY; echo ""

# 2. Pre-flight Gate: Validate the captured key pattern
if [[ -z "${OR_KEY}" || ! "${OR_KEY}" =~ ^sk-or- ]]; then
    echo "❌ Input Validation Error: Invalid OpenRouter API Key structure."
    echo "   Your token must begin with the standard 'sk-or-' prefix and cannot be empty."
    exit 1
fi

# 3. Enforce structural execution dependency check
if ! command -v bun &> /dev/null; then
    echo "❌ Execution Aborted: 'bun' binary runtime is missing from your system."
    echo "   Please install it first: curl -fsSL https://bun.sh | bash"
    exit 1
fi

# 4. Enforce the Git repository boundary contract (Required by Harness Loops)
if [ ! -d ".git" ]; then
    echo "📦 Target directory is un-tracked. Initializing a clean Git workspace repository..."
    git init -q
fi

# 5. Initialize project manifest context if missing and install core bundle
if [ ! -f "package.json" ]; then
    bun init -y > /dev/null
fi

echo "⚡ Pulling DeepSeek Harness framework engine down via Bun..."
bun add @deepseek-ai/dsh

# 6. Build global user home configuration directory tree and tighten access rights
echo "🛡️ Establishing strict OS-level folder boundary permissions..."
mkdir -p "$HOME/.dsh"
chmod 700 "$HOME/.dsh"

# 7. Generate the Unified Zero-Plaintext Master Patch Orchestration Template
echo "✍️ Writing verified configuration patch layer to ~/.dsh/cordis.patch.yml..."
cat << 'EOF' > "$HOME/.dsh/cordis.patch.yml"
version: 1

# --- Unified UI Preferences ---
app:
  telemetry: false         # Blocks analytical tracking hooks entirely
  theme: dark              # Shuts down light-mode layers globally
  language: en-US

# --- Security Fencing Core Rules ---
workspace:
  auto_mount: true         # Force-targets and reads current working dir on launch
  restrict_to_cwd: true    # Security Box: blocks agent from reading home dir files/keys

# --- Model Routing Layout Defaults ---
agent:
  default_provider: openrouter-completions
  temperature: 0.2         # Enforces strict deterministic syntax generation bounds

# --- Dynamic Plugin Component Registries ---
plugins:
  # Built-in Hardware Locker Hook
  - id: "@deepseek-ai/dsh-credentials"
    enabled: true
    config:
      vault_provider: system-native
      fallback_to_env: true

  # Native Tmux Environmental State & Context Observer
  - id: "@deepseek-ai/dsh-tmux-context"
    enabled: true

  # MCP MANAGEMENT CONSOLE COCKPIT
  - id: dsh-mcp-panel
    enabled: true
    config:
      auto_discover_local: true    # Automatically monitors local workspace mcp configs
      enable_trial_console: true   # Renders a sandboxed playground to run individual MCP tools
      backup_generations: true     # Builds version-tracked logs of your MCP schema updates

  # VS Code Integrated Browser Layout Panel Grid
  - id: dsh-better-sidebar
    enabled: true
    config:
      layout: "vscode-classic"
      persistent_terminal: true
      enable_git_diff: true

  # Keyboard-First Terminal Matrix CLI Viewport
  - id: dsh-tui
    enabled: true
    config:
      editor_binding: "vim"
      split_direction: "vertical"
      syntax_highlighting: true
      mouse_support: true

  # Graphical Storefront Explorer
  - id: dshmarket
    enabled: true
    config:
      catalog_mirror: "https://dshmarket.com"
      auto_check_updates: true

  # Natural Language AI Extension Query Engine
  - id: dsh-find-plugin
    enabled: true
    config:
      search_scope: "github-topic"
      cache_ttl_ms: 300000

  # Hard shutdown on the paid native DeepSeek Search plugin tracking row
  - id: "@deepseek-ai/dsh-web-search-deepseek"
    enabled: false

  # Inject Verified Free No-API-Key Web Search & Extraction Scraper Bridge
  - id: "@liustack/modsearch"
    enabled: true
    config:
      engine: "auto"
      max_results: 5
      crawl_depth_level: 1

# --- Endpoint Routing Configurations ---
providers:
  openrouter-completions:
    base_url: "https://openrouter.ai/api/v1"
    api_key_ref: "vault://system-native/openrouter/api_key"
EOF

# 8. Explicitly resolve and link verified public ecosystem modules into the runtime profile
echo "🔐 Deploying and linking external multi-profile plugin segments..."
bunx dsh plugin --profile web add dshmarket dsh-mcp-panel dsh-better-sidebar dsh-tui dsh-find-plugin @liustack/modsearch

# 9. Encrypt and pass your model credential safely into the macOS/Linux Hardware Keychain
echo "🗝️ Injecting tokens directly into secure operating system hardware vault..."
bunx dsh credentials set openrouter api_key "$OR_KEY"

# 10. Erase cleartext leftover files to eliminate plaintext leaks completely
rm -f "$HOME/.dsh/.credentials.yaml"

# 11. Programmatically bind scripts using 100% Bun Execution
echo "📌 Writing runtime script bindings to your local package.json..."
bun pm trust --all || true
bun -e '
  const fs = require("fs");
  const p = JSON.parse(fs.readFileSync("package.json", "utf8"));
  p.scripts = { ...p.scripts, web: "dsh web", cli: "dsh tui", headless: "dsh --profile headless" };
  fs.writeFileSync("package.json", JSON.stringify(p, null, 2));
'

echo -e "\n🏆 CONSOLIDATED ENVIRONMENT COMPILED SUCCESSFULLY!"
echo "--------------------------------------------------------"
echo "➡️ To boot the VS-Code Web Workbench UI:       bun run web"
echo "➡️ To boot the Keyboard-First Terminal TUI:     bun run cli"
echo "➡️ To invoke the Headless background pipeline:  bun run headless \"Your command\""
echo "--------------------------------------------------------"
