#!/usr/bin/env bash
set -euo pipefail

clear
echo "=========================================================================="
echo "    DEEPSEEK HARNESS (DSH) MASTER PRODUCTION ENV BOOTSTRAP                "
echo "    [OpenRouter + Free Search + VSCode UX + TUI Matrix + Models Pro]      "
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
OR_KEY="$(printf '%s' "${OR_KEY}" | tr -d '[:space:]')"

# 3. Pre-flight Gate: Validate the captured key pattern
if [[ -z "${OR_KEY}" || ! "${OR_KEY}" =~ ^sk-or- ]]; then
    echo "❌ Input Validation Error: Invalid OpenRouter API Key structure."
    echo "   Your token must begin with the standard 'sk-or-' prefix and cannot be empty."
    exit 1
fi

# 3b. Remote Gate: validate the key against OpenRouter before anything is written
echo "🔑 Validating key against the OpenRouter API..."
KEY_STATUS="$(OR_KEY="${OR_KEY}" bun -e '
  try {
    const r = await fetch("https://openrouter.ai/api/v1/auth/key", {
      headers: { Authorization: `Bearer ${process.env.OR_KEY}` }
    });
    process.stdout.write(String(r.status));
  } catch {
    process.stdout.write("000");
  }
' 2>/dev/null)"
KEY_STATUS="$(printf '%s' "${KEY_STATUS}" | tr -dc '0-9')"

if [ "${KEY_STATUS}" != "200" ]; then
    echo "❌ OpenRouter rejected this key (HTTP ${KEY_STATUS})."
    echo "   Verify it at https://openrouter.ai/keys, then re-run ./setup-dsh.sh."
    exit 1
fi
echo "✅ OpenRouter accepted the key."

# 4. Enforce the Git repository boundary contract (Required by Harness Loops)
if [ ! -d ".git" ]; then
    echo "📦 Target directory is un-tracked. Initializing a clean Git workspace repository..."
    git init -q
fi

# 5. Initialize project manifest context if missing and install core bundle
# Reproducible installs: existing manifests resolve through the committed
# bun.lock; only truly fresh (non-clone) directories take new `bun add` ranges.
echo "⚡ Installing DeepSeek Harness framework engine & TUI via Bun..."
if [ ! -f "package.json" ]; then
    bun init -y > /dev/null
    rm -f CLAUDE.md index.ts tsconfig.json || true
    bun add @deepseek-ai/dsh dsh-tui
else
    bun install
fi

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
# dsh-provider-model-configurator is pinned to upstream commit 70f8811 — bump deliberately.
bunx @deepseek-ai/dsh plugin --profile web add dshmarket dsh-mcp-panel dsh-better-sidebar dsh-find-plugin @liustack/modsearch github:LiangYin233/dsh-provider-model-configurator#70f88112c7d92fadeb93e46f5dcb8b1f3ae6eba3

# 9. Store OpenRouter API credentials in the managed credential store and configure ~/.dsh/settings.yaml
echo "🗝️ Injecting token into the managed store ~/.dsh/.credentials.yaml and configuring ~/.dsh/settings.yaml..."
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

# Single-copy consolidation: the managed store outranks the ~/.dsh/.env
# user-env fallback layer, so purge the legacy plaintext duplicate.
rm -f "$HOME/.dsh/.env"

# 10. Provision the sync tool on fresh setups, and upgrade pre-hardening copies
# (older embedded versions failed silently when the patch anchor was missing)
if [ ! -f "sync-models.js" ] || ! grep -q "openrouter block anchor" sync-models.js 2>/dev/null; then
    echo "📡 Provisioning OpenRouter dynamic model synchronization tool..."
    cat << 'EOF' > sync-models.js
#!/usr/bin/env bun
import fs from "node:fs";
import path from "node:path";
import os from "node:os";

async function syncOpenRouterModels() {
  console.log("🌐 Fetching live model catalog from OpenRouter API (https://openrouter.ai/api/v1/models)...");
  
  const res = await fetch("https://openrouter.ai/api/v1/models");
  if (!res.ok) {
    throw new Error(`OpenRouter API responded with HTTP ${res.status} (${res.statusText})`);
  }
  
  const data = await res.json();
  const rawModels = data.data || [];
  if (rawModels.length === 0) {
    throw new Error("OpenRouter API returned an empty model list.");
  }
  
  console.log(`✅ Successfully fetched ${rawModels.length} models from OpenRouter!`);

  const models = rawModels.map(m => ({
    id: m.id,
    name: m.name || m.id
  }));

  const patchPath = path.join(os.homedir(), ".dsh", "cordis.patch.yml");
  if (!fs.existsSync(patchPath)) {
    throw new Error(`~/.dsh/cordis.patch.yml not found at ${patchPath}`);
  }

  const patchContent = fs.readFileSync(patchPath, "utf8");
  if (!patchContent.includes("openrouter:")) {
    throw new Error("Target 'openrouter:' provider section not found in cordis.patch.yml");
  }

  const modelsYaml = models.map(m => {
    const safeId = String(m.id).replace(/\\/g, "\\\\").replace(/"/g, '\\"');
    const safeName = String(m.name).replace(/\\/g, "\\\\").replace(/"/g, '\\"');
    return `          - id: "${safeId}"\n            name: "${safeName}"`;
  }).join("\n");

  const openrouterBlock = `      openrouter:
        apiKeyEnv: OPENROUTER_API_KEY
        displayName: "OpenRouter"
        api: openai-completions
        baseURL: "https://openrouter.ai/api/v1"
        models:
${modelsYaml}`;

  const anchorRe = /[ \t]*openrouter:[\s\S]*?(?=\n# Route default model|\n- id: agent-default-model)/;
  if (!anchorRe.test(patchContent)) {
    throw new Error("Failed to locate the openrouter block anchor in cordis.patch.yml (missing '# Route default model' comment or agent-default-model entry).");
  }

  const updatedContent = patchContent.replace(anchorRe, openrouterBlock + "\n");

  fs.writeFileSync(patchPath, updatedContent, "utf8");
  console.log(`🎉 Successfully synced ${models.length} live OpenRouter models into ~/.dsh/cordis.patch.yml!`);
}

syncOpenRouterModels().catch(err => {
  console.error("❌ Model sync failed:", err.message);
  process.exit(1);
});
EOF
    chmod +x sync-models.js
fi

# 11. Programmatically bind scripts using 100% Bun Execution
echo "📌 Writing runtime script bindings to your local package.json..."
bun pm trust --all || true
bun -e '
  const fs = require("fs");
  const p = JSON.parse(fs.readFileSync("package.json", "utf8"));
  p.scripts = { ...p.scripts, web: "dsh web", cli: "dsh-tui", headless: "dsh --profile headless", "sync-models": "bun run sync-models.js", ...(fs.existsSync("doctor.js") ? { doctor: "bun doctor.js" } : {}) };
  fs.writeFileSync("package.json", JSON.stringify(p, null, 2));
'

# 12. Automatically execute live model sync on bootstrap (runs last so a sync
# failure — e.g. offline — cannot skip the script bindings above)
echo "🔄 Automatically syncing live OpenRouter models into runtime..."
bun run sync-models.js

echo -e "\n🏆 CONSOLIDATED ENVIRONMENT COMPILED SUCCESSFULLY!"
echo "--------------------------------------------------------"
echo "➡️ To boot the VS-Code Web Workbench UI:       bun run web"
echo "➡️ To boot the Keyboard-First Terminal TUI:     bun run cli"
echo "➡️ To resync live OpenRouter models (LOV):      bun run sync-models"
echo "➡️ To invoke the Headless background pipeline:  bun run headless \"Your task\""
echo "➡️ To run the read-only health check:          bun run doctor"
echo "--------------------------------------------------------"
