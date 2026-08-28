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
    const safeName = m.name.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
    return `          - id: "${m.id}"\n            name: "${safeName}"`;
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
