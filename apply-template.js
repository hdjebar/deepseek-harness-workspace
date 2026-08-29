#!/usr/bin/env bun
/**
 * apply-template.js — Persona, Skill & MCP Template Switcher for DSH
 *
 * Usage:
 *   bun run template                  (interactive or list available personas)
 *   bun apply-template.js <persona>   (e.g., bun apply-template.js fullstack-dev)
 */
import fs from "node:fs";
import path from "node:path";
import os from "node:os";

const TEMPLATES_DIR = path.join(process.cwd(), "templates");
const PERSONAS_DIR = path.join(TEMPLATES_DIR, "personas");
const SKILLS_DIR = path.join(TEMPLATES_DIR, "skills");
const MCP_DIR = path.join(TEMPLATES_DIR, "mcp");
const HOME_DSH = path.join(os.homedir(), ".dsh");

function parseYamlSimple(content) {
  const result = { suggestedSkills: [], mcpServers: [] };
  const lines = content.split("\n");
  let currentKey = null;

  for (let line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;

    if (trimmed.startsWith("- ") && currentKey) {
      const val = trimmed.replace(/^- ["']?/, "").replace(/["']?$/, "");
      if (Array.isArray(result[currentKey])) {
        result[currentKey].push(val);
      }
      continue;
    }

    const m = line.match(/^([a-zA-Z0-9_-]+):\s*(.*)$/);
    if (m) {
      const key = m[1];
      const val = m[2].trim().replace(/^["']/, "").replace(/["']$/, "");
      currentKey = key;
      if (val === "|" || val === ">" || val === "") {
        if (key === "suggestedSkills" || key === "mcpServers") {
          result[key] = [];
        } else {
          result[key] = "";
        }
      } else {
        result[key] = val;
      }
    }
  }
  return result;
}

function loadPersonas() {
  if (!fs.existsSync(PERSONAS_DIR)) return [];
  const files = fs.readdirSync(PERSONAS_DIR).filter(f => f.endsWith(".yaml") || f.endsWith(".yml"));
  return files.map(file => {
    const raw = fs.readFileSync(path.join(PERSONAS_DIR, file), "utf8");
    const parsed = parseYamlSimple(raw);
    parsed.file = file;
    parsed.id = parsed.id || file.replace(/\.ya?ml$/, "");
    return parsed;
  });
}

function applyPersona(personaId) {
  const personas = loadPersonas();
  const persona = personas.find(p => p.id === personaId || p.file === `${personaId}.yaml`);

  if (!persona) {
    console.error(`❌ Persona "${personaId}" not found in templates/personas/`);
    console.log(`Available personas: ${personas.map(p => p.id).join(", ")}`);
    process.exit(1);
  }

  console.log(`\n🎭 Applying Persona: \x1b[1;36m${persona.name || persona.id}\x1b[0m`);
  console.log(`ℹ️  ${persona.description || ""}`);

  // 1. Update ~/.dsh/settings.yaml with persona default model
  if (persona.model && fs.existsSync(HOME_DSH)) {
    const settingsPath = path.join(HOME_DSH, "settings.yaml");
    let settingsContent = fs.existsSync(settingsPath) ? fs.readFileSync(settingsPath, "utf8") : "";

    const modelBlock = `agent-default-model:\n  provider: openrouter\n  model: ${persona.model}`;
    if (settingsContent.includes("agent-default-model:")) {
      settingsContent = settingsContent.replace(/agent-default-model:[\s\S]*?(?=\n[a-zA-Z0-9_-]+:|$)/, modelBlock + "\n");
    } else {
      settingsContent += "\n" + modelBlock + "\n";
    }

    fs.writeFileSync(settingsPath, settingsContent.trim() + "\n", "utf8");
    console.log(`✅ Default model set to: \x1b[32m${persona.model}\x1b[0m in ~/.dsh/settings.yaml`);
  }

  // 2. Link suggested skills to workspace skills directory
  const destSkills = path.join(process.cwd(), "skills");
  if (persona.suggestedSkills && persona.suggestedSkills.length > 0) {
    fs.mkdirSync(destSkills, { recursive: true });
    let linked = 0;

    for (const skill of persona.suggestedSkills) {
      const srcSkill = path.join(SKILLS_DIR, skill);
      const targetSkill = path.join(destSkills, skill);
      if (fs.existsSync(srcSkill)) {
        fs.cpSync(srcSkill, targetSkill, { recursive: true });
        linked++;
      }
    }
    console.log(`🧠 Activated ${linked} skills in ./skills/ (${persona.suggestedSkills.join(", ")})`);
  }

  // 3. Output MCP Servers recommended for this persona
  if (persona.mcpServers && persona.mcpServers.length > 0) {
    console.log(`🔌 Recommended MCP Tools: ${persona.mcpServers.join(", ")}`);
    console.log(`   (Configs available in templates/mcp/)`);
  }

  console.log(`\n🎉 Persona \x1b[1;32m${persona.name}\x1b[0m successfully activated!`);
  console.log(`➡️  Launch Web IDE:   bun run web`);
  console.log(`➡️  Launch TUI:       bun run cli\n`);
}

function listPersonas() {
  const personas = loadPersonas();
  console.log("\n==========================================================================");
  console.log("       🎭 DEEPSEEK HARNESS (DSH) AVAILABLE PERSONA TEMPLATES               ");
  console.log("==========================================================================\n");

  personas.forEach((p, idx) => {
    console.log(`\x1b[1;33m[${idx + 1}] ${p.name}\x1b[0m (\x1b[36m${p.id}\x1b[0m)`);
    console.log(`    📝 ${p.description}`);
    console.log(`    🤖 Default Model: \x1b[32m${p.model || "deepseek/deepseek-chat"}\x1b[0m`);
    if (p.suggestedSkills?.length) console.log(`    🧠 Bundled Skills: ${p.suggestedSkills.join(", ")}`);
    if (p.mcpServers?.length) console.log(`    🔌 Bundled MCPs:   ${p.mcpServers.join(", ")}`);
    console.log("");
  });

  console.log("--------------------------------------------------------------------------");
  console.log("👉 To activate a persona, run:");
  console.log("   \x1b[1mbun run template <persona-id>\x1b[0m");
  console.log("   Example: \x1b[36mbun run template fullstack-dev\x1b[0m\n");
}

const targetArg = process.argv[2];
if (!targetArg || targetArg === "--help" || targetArg === "-h") {
  listPersonas();
} else {
  applyPersona(targetArg);
}
