#!/usr/bin/env bash
set -euo pipefail

clear
echo "=========================================================================="
echo "    DEEPSEEK HARNESS (DSH) MASTER PRODUCTION ENV BOOTSTRAP                "
echo "    [OpenRouter + Free Search + VSCode UX + TUI Matrix + Tmux Context]    "
echo "=========================================================================="
echo ""

# 1. Enforce structural execution dependency check (Fail-Fast Gate)
if ! command -v bun &> /dev/null; then
    echo "❌ Execution Aborted: 'bun' binary runtime is missing from your system."
    echo "   Please install it first: curl -fsSL https://bun.sh | bash"
    exit 1
fi
echo "✅ Detected Bun runtime: $(bun --version)"
echo ""

# 2. Capture the OpenRouter key silently without outputting it to logs
read -rsp "Enter your OpenRouter Master API Key (sk-or-...): " OR_KEY; echo ""

# 3. Pre-flight Gate: Validate the captured key pattern
if [[ -z "${OR_KEY}" || ! "${OR_KEY}" =~ ^sk-or- ]]; then
    echo "❌ Input Validation Error: Invalid OpenRouter API Key structure."
    echo "   Your token must begin with the standard 'sk-or-' prefix and cannot be empty."
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

echo "⚡ Pulling DeepSeek Harness framework engine & TUI via Bun..."
bun add @deepseek-ai/dsh dsh-tui

# 6. Build global user home configuration directory tree and tighten access rights
echo "🛡️ Establishing strict OS-level folder boundary permissions..."
mkdir -p "$HOME/.dsh"
chmod 700 "$HOME/.dsh"

# 7. Generate the Unified Zero-Plaintext Master Patch Orchestration Template (Top-level YAML Array)
echo "✍️ Writing verified configuration patch layer to ~/.dsh/cordis.patch.yml..."
cat << 'EOF' > "$HOME/.dsh/cordis.patch.yml"
# Disable default official DeepSeek provider in favor of OpenRouter Gateway
- id: llm-deepseek
  disabled: true

# Disable default paid DeepSeek search in favor of free ModSearch
- id: web-search-deepseek
  disabled: true

- id: web
  config:
    searchProvider: modsearch

# Configure LLM Provider Gateway via llm-pi-ai (OpenRouter)
# Models are managed dynamically via Model Pro (dsh-provider-model-configurator)
- id: llm-pi-ai
  config:
    providers:
      openrouter:
        apiKeyEnv: OPENROUTER_API_KEY
        displayName: "OpenRouter"
        api: openai-completions
        baseURL: "https://openrouter.ai/api/v1"

# Route default model to OpenRouter DeepSeek V3
- id: agent-default-model
  config:
    provider: openrouter
    model: deepseek/deepseek-chat

# Configure MCP Management Console Cockpit
- id: mcp-panel
  config:
    auto_discover_local: true
    enable_trial_console: true
    backup_generations: true

# Configure VS Code Integrated Browser Layout Panel Grid
- id: better-sidebar
  config:
    layout: vscode-classic
    persistent_terminal: true
    enable_git_diff: true
EOF

# 8. Explicitly resolve and link verified public ecosystem modules into the runtime profile
echo "🔐 Deploying and linking external multi-profile plugin segments..."
bunx @deepseek-ai/dsh plugin --profile web add dshmarket dsh-mcp-panel dsh-better-sidebar dsh-find-plugin @liustack/modsearch github:LiangYin233/dsh-provider-model-configurator

# 9. Store OpenRouter API credentials and configure ~/.dsh/settings.yaml
echo "🗝️ Injecting tokens securely into ~/.dsh/.credentials.yaml and configuring ~/.dsh/settings.yaml..."
cat << EOF > "$HOME/.dsh/.credentials.yaml"
version: 1
refs:
  OPENROUTER_API_KEY: "${OR_KEY}"
EOF
chmod 600 "$HOME/.dsh/.credentials.yaml"

cat << EOF > "$HOME/.dsh/settings.yaml"
llm-pi-ai:
  providers:
    openrouter:
      apiKeyEnv: OPENROUTER_API_KEY
agent-default-model:
  provider: openrouter
  model: deepseek/deepseek-chat
EOF
chmod 600 "$HOME/.dsh/settings.yaml"

cat << EOF > "$HOME/.dsh/.env"
OPENROUTER_API_KEY="${OR_KEY}"
EOF
chmod 600 "$HOME/.dsh/.env"

# 10. Programmatically bind scripts using 100% Bun Execution
echo "📌 Writing runtime script bindings to your local package.json..."
bun pm trust --all || true
bun -e '
  const fs = require("fs");
  const p = JSON.parse(fs.readFileSync("package.json", "utf8"));
  p.scripts = { ...p.scripts, web: "dsh web", cli: "dsh-tui", headless: "dsh --profile headless", "sync-models": "bun run sync-models.js" };
  fs.writeFileSync("package.json", JSON.stringify(p, null, 2));
'

echo -e "\n🏆 CONSOLIDATED ENVIRONMENT COMPILED SUCCESSFULLY!"
echo "--------------------------------------------------------"
echo "➡️ To boot the VS-Code Web Workbench UI:       bun run web"
echo "➡️ To boot the Keyboard-First Terminal TUI:     bun run cli"
echo "➡️ To sync live OpenRouter models (LOV):        bun run sync-models"
echo "➡️ To invoke the Headless background pipeline:  bun run headless \"Your task\""
echo "--------------------------------------------------------"
