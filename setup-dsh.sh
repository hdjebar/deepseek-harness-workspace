#!/usr/bin/env bash
set -euo pipefail

# 1. Parse command line arguments for target configuration directory
# Default: Local Workspace Mode ($PWD/.dsh)
# Options:
#   --global, -g       : Install configuration globally into ~/.dsh
#   --dir, -d <path>   : Install configuration into a custom directory
USER_HOME="${HOME:-$(cd ~ 2>/dev/null && pwd || echo "$PWD")}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DSH_TARGET="${DSH_HOME:-$PWD/.dsh}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --global|-g)
            DSH_TARGET="${USER_HOME}/.dsh"
            shift
            ;;
        --dir|-d)
            if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
                DSH_TARGET="$2"
                shift 2
            else
                echo "❌ Error: --dir requires a directory path argument."
                exit 1
            fi
            ;;
        --help|-h)
            echo "Usage: ./setup-dsh.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  (default)          Install configuration locally into ./.dsh (isolated per workspace)"
            echo "  --global, -g       Install configuration globally into ${USER_HOME}/.dsh (shared across projects)"
            echo "  --dir, -d <path>   Install configuration into a custom directory"
            echo "  --help, -h         Show this help message"
            exit 0
            ;;
        *)
            echo "❌ Error: Unknown option '$1'. Use --help for usage."
            exit 1
            ;;
    esac
done

if [ -t 1 ]; then
    clear 2>/dev/null || true
fi
echo "=========================================================================="
echo "    DEEPSEEK HARNESS (DSH) MASTER PRODUCTION ENV BOOTSTRAP                "
echo "    [OpenRouter + Free Search + VSCode UX + TUI Matrix + Models Pro]      "
echo "=========================================================================="
echo ""

mkdir -p "${DSH_TARGET}"
DSH_DIR="$(cd "${DSH_TARGET}" 2>/dev/null && pwd || echo "${DSH_TARGET}")"
export DSH_HOME="${DSH_DIR}"

if [ "${DSH_DIR}" = "${USER_HOME}/.dsh" ]; then
    echo "📁 DSH Configuration Target: ${USER_HOME}/.dsh (Global Mode)"
else
    echo "📁 DSH Configuration Target: ${DSH_DIR} (Workspace Mode)"
fi
echo ""

# 2. Enforce structural execution dependency check (Fail-Fast Gate)
if ! command -v bun > /dev/null 2>&1; then
    echo "❌ Execution Aborted: 'bun' binary runtime is missing from your system."
    echo "   Please install it first: curl -fsSL https://bun.sh | bash"
    exit 1
fi
echo "✅ Detected Bun runtime: $(bun --version)"

if ! command -v bunx > /dev/null 2>&1; then
    echo "❌ Execution Aborted: 'bunx' binary is missing from your system PATH."
    exit 1
fi

if ! command -v pnpm > /dev/null 2>&1; then
    echo "ℹ️  'pnpm' not found in PATH — ensuring pnpm is available via Bun..."
    bun add -g pnpm > /dev/null 2>&1 || true
fi
if command -v pnpm > /dev/null 2>&1; then
    echo "✅ Detected pnpm runtime: $(pnpm --version)"
fi
echo ""

# 3. Capture the OpenRouter key silently without outputting it to logs
read -rsp "Enter your OpenRouter Master API Key (sk-or-...): " OR_KEY; echo ""
OR_KEY="$(printf '%s' "${OR_KEY}" | tr -d '[:space:]')"

# 3a. Pre-flight Gate: Validate the captured key pattern
if [[ -z "${OR_KEY}" || ! "${OR_KEY}" =~ ^sk-or- ]]; then
    echo "❌ Input Validation Error: Invalid OpenRouter API Key structure."
    echo "   Your token must begin with the standard 'sk-or-' prefix and cannot be empty."
    exit 1
fi

# 3b. Remote Gate: validate the key against OpenRouter before anything is written
echo "🔑 Validating key against the OpenRouter API..."
# shellcheck disable=SC2016
KEY_STATUS="$(
  OR_KEY="${OR_KEY}" bun -e '
    try {
      const r = await fetch("https://openrouter.ai/api/v1/auth/key", {
        headers: { Authorization: `Bearer ${process.env.OR_KEY}` },
        signal: AbortSignal.timeout(10000)
      });
      process.stdout.write(String(r.status));
    } catch {
      process.stdout.write("000");
    }
  ' 2>/dev/null
)"
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

echo "🙈 Ensuring local runtime and credential artifacts are ignored by Git..."
ensure_gitignore_entry() {
    local pattern="$1"
    touch .gitignore
    if ! grep -qxF "$pattern" .gitignore 2>/dev/null; then
        printf '%s\n' "$pattern" >> .gitignore
    fi
}

ensure_gitignore_entry ".env"
ensure_gitignore_entry ".env.*"
ensure_gitignore_entry "!.env.example"
ensure_gitignore_entry "*.credentials.yaml"
ensure_gitignore_entry ".credentials.yaml"
ensure_gitignore_entry "node_modules/"
ensure_gitignore_entry "package-lock.json"
ensure_gitignore_entry "pnpm-lock.yaml"
ensure_gitignore_entry ".dsh-target"
ensure_gitignore_entry ".dsh/"
ensure_gitignore_entry "*.log"

# 5. Initialize project manifest context safely (preserving any pre-existing files)
echo "⚡ Installing DeepSeek Harness framework engine & TUI via Bun..."
if [ ! -f "package.json" ]; then
    cat << 'EOF' > package.json
{
  "name": "deepseek-harness-workspace",
  "private": true,
  "peerDependencies": {
    "typescript": "^5"
  },
  "dependencies": {
    "@deepseek-ai/dsh": "^0.1.1-rc.2",
    "dsh-tui": "^0.2.19"
  }
}
EOF
    bun install
else
    if ! grep -q "@deepseek-ai/dsh" package.json 2>/dev/null || ! grep -q "dsh-tui" package.json 2>/dev/null; then
        bun add @deepseek-ai/dsh dsh-tui
    else
        bun install
    fi
fi

echo "🧩 Provisioning workspace command wrappers..."
copy_if_missing() {
    local src="$1"
    local dest="$2"
    if [ -f "$src" ] && [ ! -f "$dest" ]; then
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
    fi
}

copy_if_missing "${SCRIPT_DIR}/bin/resolve-dsh.js" "bin/resolve-dsh.js"
copy_if_missing "${SCRIPT_DIR}/bin/dsh-web.js" "bin/dsh-web.js"
copy_if_missing "${SCRIPT_DIR}/bin/dsh-cli.js" "bin/dsh-cli.js"
copy_if_missing "${SCRIPT_DIR}/bin/dsh-headless.js" "bin/dsh-headless.js"
copy_if_missing "${SCRIPT_DIR}/bin/dsh-upgrade.js" "bin/dsh-upgrade.js"
copy_if_missing "${SCRIPT_DIR}/doctor.js" "doctor.js"
copy_if_missing "${SCRIPT_DIR}/reset.sh" "reset.sh"
if [ -f "reset.sh" ]; then
    chmod +x "reset.sh"
fi

# 6. Establish strict folder boundary permissions
echo "🛡️ Establishing strict OS-level folder boundary permissions..."
mkdir -p "${DSH_DIR}"
chmod 700 "${DSH_DIR}"

# 7. Generate the Unified Zero-Plaintext Master Patch Orchestration Template (Top-level YAML Array)
if [ -f "${DSH_DIR}/cordis.patch.yml" ]; then
    cp "${DSH_DIR}/cordis.patch.yml" "${DSH_DIR}/cordis.patch.yml.bak"
    echo "ℹ️  Existing configuration backed up to ${DSH_DIR}/cordis.patch.yml.bak"
fi
echo "✍️ Writing verified configuration patch layer to ${DSH_DIR}/cordis.patch.yml..."
cat << 'EOF' > "${DSH_DIR}/cordis.patch.yml"
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

# 8. Explicitly resolve and link verified public ecosystem modules into the runtime profiles
echo "🔐 Deploying and linking external multi-profile plugin segments..."
mkdir -p "${DSH_DIR}/profiles/web"
cat << 'EOF' > "${DSH_DIR}/profiles/web/pnpm-workspace.yaml"
packages:
  - .

nodeLinker: hoisted
autoInstallPeers: false
allowBuilds:
  node-pty: true
  "@deepseek-ai/dsh-subprocess-local": true
  koffi: true
  protobufjs: true
  "@google/genai": true
EOF

cat << 'EOF' > "${DSH_DIR}/profiles/web/package.json"
{
  "name": "dsh-profile-web",
  "private": true,
  "dependencies": {}
}
EOF

DSH_HOME="${DSH_DIR}" bunx @deepseek-ai/dsh plugin --profile web add \
    dshmarket@^1.36.0 \
    dsh-mcp-panel@^0.6.1 \
    dsh-better-sidebar@^0.17.1 \
    dsh-find-plugin@^0.3.7 \
    @liustack/modsearch@^5.10.0 \
    dsh-provider-model-configurator@github:LiangYin233/dsh-provider-model-configurator#70f88112c7d92fadeb93e46f5dcb8b1f3ae6eba3

mkdir -p "${DSH_DIR}/profiles/headless"
cat << 'EOF' > "${DSH_DIR}/profiles/headless/pnpm-workspace.yaml"
packages:
  - .

nodeLinker: hoisted
autoInstallPeers: false
allowBuilds:
  "@deepseek-ai/dsh-subprocess-local": true
EOF

cat << 'EOF' > "${DSH_DIR}/profiles/headless/package.json"
{
  "name": "dsh-profile-headless",
  "private": true,
  "dependencies": {}
}
EOF

DSH_HOME="${DSH_DIR}" bunx @deepseek-ai/dsh plugin --profile headless add \
    @liustack/modsearch@^5.10.0 \
    dsh-find-plugin@^0.3.7

# 9. Store OpenRouter API credentials in the managed credential store and configure settings.yaml
echo "🗝️ Injecting token into the managed store ${DSH_DIR}/.credentials.yaml and configuring ${DSH_DIR}/settings.yaml..."
cat << EOF > "${DSH_DIR}/.credentials.yaml"
version: 1
refs:
  OPENROUTER_API_KEY: "${OR_KEY}"
EOF
chmod 600 "${DSH_DIR}/.credentials.yaml"

cat << EOF > "${DSH_DIR}/settings.yaml"
llm-pi-ai:
  providers:
    openrouter:
      apiKeyEnv: OPENROUTER_API_KEY
agent-default-model:
  provider: openrouter
  model: deepseek/deepseek-chat
EOF
chmod 600 "${DSH_DIR}/settings.yaml"

# Single-copy consolidation: the managed store outranks the .env
# user-env fallback layer, so purge the legacy plaintext duplicate.
rm -f "${DSH_DIR}/.env"

# 10. Provision the standalone OpenRouter model catalog synchronization tool
if [ ! -f "sync-models.js" ]; then
    echo "📋 Writing standalone model catalog sync tool to sync-models.js..."
    cat << 'EOF' > sync-models.js
#!/usr/bin/env bun
import fs from "node:fs";
import path from "node:path";
import { resolveDshDir } from "./bin/resolve-dsh.js";

async function syncOpenRouterModels() {
  const modelsApiUrl = process.env.OPENROUTER_MODELS_URL || "https://openrouter.ai/api/v1/models";
  console.log(`🌐 Fetching live model catalog from OpenRouter API (${modelsApiUrl})...`);
  
  const res = await fetch(modelsApiUrl, {
    signal: AbortSignal.timeout(15000)
  });
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

  const dshDir = resolveDshDir();
  const patchPath = path.join(dshDir, "cordis.patch.yml");
  if (!fs.existsSync(patchPath)) {
    throw new Error(`cordis.patch.yml not found at ${patchPath}`);
  }

  const patchContent = fs.readFileSync(patchPath, "utf8");

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

  const anchorRe = /^[ \t]*openrouter:[\s\S]*?(?=\n# Route default model|\n- id: agent-default-model)/m;
  if (!anchorRe.test(patchContent)) {
    throw new Error("Failed to locate the openrouter block anchor in cordis.patch.yml (missing '# Route default model' comment or agent-default-model entry).");
  }

  const updatedContent = patchContent.replace(anchorRe, openrouterBlock + "\n");

  fs.writeFileSync(patchPath, updatedContent, "utf8");
  console.log(`🎉 Successfully synced ${models.length} live OpenRouter models into ${patchPath}!`);
}

syncOpenRouterModels().catch(err => {
  console.error("❌ Model sync failed:", err.message);
  process.exit(1);
});
EOF
    chmod +x sync-models.js
fi

# 11. Programmatically bind scripts and commit target routing marker
echo "📌 Writing runtime script bindings and committing target routing..."
bun pm trust --all || true
if [ -n "${USER_HOME:-}" ] && [ "${DSH_DIR}" = "${USER_HOME}/.dsh" ]; then
    echo "global" > .dsh-target
elif [[ "${DSH_DIR}" == "$PWD"/* ]]; then
    printf './%s\n' "${DSH_DIR#"$PWD"/}" > .dsh-target
else
    printf '%s\n' "${DSH_DIR}" > .dsh-target
fi

# shellcheck disable=SC2016
bun -e '
  const fs = require("fs");
  const p = JSON.parse(fs.readFileSync("package.json", "utf8"));
  p.scripts = {
    ...p.scripts,
    web: "bun run bin/dsh-web.js",
    cli: "bun run bin/dsh-cli.js",
    headless: "bun run bin/dsh-headless.js",
    "sync-models": "bun run sync-models.js",
    ...(fs.existsSync("doctor.js") ? { doctor: "bun doctor.js" } : {}),
    ...(fs.existsSync("reset.sh") ? { reset: "bash reset.sh" } : {}),
    ...(fs.existsSync("bin/dsh-upgrade.js") ? { upgrade: "bun run bin/dsh-upgrade.js" } : {})
  };
  fs.writeFileSync("package.json", JSON.stringify(p, null, 2));
'

# 12. Automatically execute live model sync on bootstrap (runs last so a sync
# failure — e.g. offline — cannot skip the script bindings above)
echo "🔄 Automatically syncing live OpenRouter models into runtime..."
DSH_HOME="${DSH_DIR}" bun run sync-models.js

echo -e "\n🏆 CONSOLIDATED ENVIRONMENT COMPILED SUCCESSFULLY!"
echo "--------------------------------------------------------"
echo "➡️ Target Configuration Folder:                 ${DSH_DIR}"
echo "➡️ To boot the VS-Code Web Workbench UI:       bun run web"
echo "➡️ To boot the Keyboard-First Terminal TUI:     bun run cli"
echo "➡️ To resync live OpenRouter models (LOV):      bun run sync-models"
echo "➡️ To invoke the Headless background pipeline:  bun run headless \"Your task\""
echo "➡️ To run the read-only health check:          bun run doctor"
echo "➡️ To completely wipe & reset the workspace:   bun run reset"
echo "➡️ To upgrade the framework, plugins & models:  bun run upgrade"
echo "--------------------------------------------------------"
