#!/usr/bin/env bun
import fs from "node:fs";
import path from "node:path";
import os from "node:os";

async function syncOpenRouterModels() {
  console.log("🌐 Fetching live model catalog from OpenRouter API (https://openrouter.ai/api/v1/models)...");
  
  const res = await fetch("https://openrouter.ai/api/v1/models", {
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

  let dshDir;
  if (process.env.DSH_HOME) {
    let raw = process.env.DSH_HOME.trim();
    if (raw.startsWith("~")) raw = path.join(os.homedir(), raw.slice(1));
    dshDir = path.resolve(raw);
  } else {
    const targetFile = path.join(process.cwd(), ".dsh-target");
    if (fs.existsSync(targetFile)) {
      try {
        let content = fs.readFileSync(targetFile, "utf8").trim();
        if (content) {
          if (content.startsWith("~")) content = path.join(os.homedir(), content.slice(1));
          dshDir = path.resolve(process.cwd(), content);
        }
      } catch { /* ignore read failure */ }
    }
    if (!dshDir) {
      const localDir = path.join(process.cwd(), ".dsh");
      const localPatch = fs.existsSync(path.join(localDir, "cordis.patch.yml"));
      const globalDir = path.join(os.homedir(), ".dsh");
      const globalPatch = fs.existsSync(path.join(globalDir, "cordis.patch.yml"));

      if (localPatch) dshDir = localDir;
      else if (globalPatch) dshDir = globalDir;
      else if (fs.existsSync(localDir)) dshDir = localDir;
      else dshDir = globalDir;
    }
  }

  const patchPath = path.join(dshDir, "cordis.patch.yml");
  if (!fs.existsSync(patchPath)) {
    throw new Error(`cordis.patch.yml not found at ${patchPath}`);
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
  console.log(`🎉 Successfully synced ${models.length} live OpenRouter models into ${patchPath}!`);
}

syncOpenRouterModels().catch(err => {
  console.error("❌ Model sync failed:", err.message);
  process.exit(1);
});
