#!/usr/bin/env bun
import fs from "node:fs";
import path from "node:path";
import os from "node:os";

async function syncOpenRouterModels() {
  console.log("🌐 Fetching live model catalog from OpenRouter API (https://openrouter.ai/api/v1/models)...");
  
  try {
    const res = await fetch("https://openrouter.ai/api/v1/models");
    if (!res.ok) {
      throw new Error(`OpenRouter API error: HTTP ${res.status} ${res.statusText}`);
    }
    
    const data = await res.json();
    const rawModels = data.data || [];
    console.log(`✅ Successfully fetched ${rawModels.length} models from OpenRouter!`);

    // Cleanly map model entries
    const models = rawModels.map(m => ({
      id: m.id,
      name: m.name || m.id,
      context_length: m.context_length,
      max_output: m.top_provider?.max_completion_tokens || undefined,
      modalities: m.architecture?.input_modalities || ["text"]
    }));

    const patchPath = path.join(os.homedir(), ".dsh", "cordis.patch.yml");
    if (!fs.existsSync(patchPath)) {
      console.error(`❌ ~/.dsh/cordis.patch.yml not found at ${patchPath}`);
      return;
    }

    // Read existing patch file
    let patchContent = fs.readFileSync(patchPath, "utf8");

    // Format models YAML block
    const modelsYaml = models.map(m => `          - id: ${m.id}\n            name: "${m.name.replace(/"/g, '\\"')}"`).join("\n");

    const openrouterBlock = `      openrouter:
        apiKeyEnv: OPENROUTER_API_KEY
        displayName: "OpenRouter"
        api: openai-completions
        baseURL: "https://openrouter.ai/api/v1"
        models:
${modelsYaml}`;

    // Replace openrouter provider section
    const updatedContent = patchContent.replace(
      /openrouter:[\s\S]*?(?=\n# Route default model|\n- id: agent-default-model)/,
      openrouterBlock + "\n"
    );

    fs.writeFileSync(patchPath, updatedContent, "utf8");
    console.log(`🎉 Successfully synced ${models.length} live OpenRouter models into ~/.dsh/cordis.patch.yml!`);
    console.log("➡️ Restart your web server ('bun run web') and refresh your browser to view all models.");
  } catch (err) {
    console.error("❌ Failed to sync models from OpenRouter:", err.message);
  }
}

syncOpenRouterModels();
