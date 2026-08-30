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
