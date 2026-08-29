#!/usr/bin/env bun
/**
 * doctor.js — DSH workspace health check.
 *
 * Read-only: it reports; it never repairs, rewrites, or deletes anything.
 * Run with: bun run doctor   (or: bun doctor.js)
 * Exit code: 0 when every critical check passes, 1 otherwise.
 *
 * Credential resolution mirrors the runtime (dsh-credentials-local), highest
 * priority first: inherited environment → ~/.dsh/.credentials.yaml (managed
 * store) → ~/.dsh/.env (user-env fallback). The key itself is never printed.
 */
import fs from "node:fs";
import path from "node:path";
import os from "node:os";

function resolveDshDir() {
  if (process.env.DSH_HOME) return path.resolve(process.env.DSH_HOME);
  const localDir = path.join(process.cwd(), ".dsh");
  if (fs.existsSync(localDir)) return localDir;
  return path.join(os.homedir(), ".dsh");
}

const HOME_DSH = resolveDshDir();
const IS_LOCAL = HOME_DSH.startsWith(process.cwd());
const DISPLAY_TARGET = IS_LOCAL ? `./.dsh (local workspace)` : HOME_DSH.replace(os.homedir(), "~");

const PLUGIN_DIR = path.join(HOME_DSH, "profiles", "web", "node_modules");
const HEADLESS_PLUGIN_DIR = path.join(HOME_DSH, "profiles", "headless", "node_modules");
const EXPECTED_PLUGINS = [
  "dshmarket",
  "dsh-mcp-panel",
  "dsh-better-sidebar",
  "dsh-find-plugin",
  "@liustack/modsearch",
];
const EXPECTED_HEADLESS_PLUGINS = [
  "dsh-find-plugin",
  "@liustack/modsearch",
];

let failures = 0;
const lines = [];

function pass(label, detail = "") { lines.push(`✅ ${label}${detail ? ` — ${detail}` : ""}`); }
function warn(label, detail = "") { lines.push(`⚠️  ${label}${detail ? ` — ${detail}` : ""}`); }
function fail(label, detail = "") { failures += 1; lines.push(`❌ ${label}${detail ? ` — ${detail}` : ""}`); }
function info(label, detail = "") { lines.push(`ℹ️  ${label}${detail ? ` — ${detail}` : ""}`); }

function readIfExists(p) {
  try { return fs.readFileSync(p, "utf8"); } catch { return null; }
}

/** Mirror dsh-credentials-local's layering; never log the value itself. */
function resolveKey() {
  const envKey = process.env.OPENROUTER_API_KEY;
  if (envKey) return { key: envKey, source: "inherited environment" };

  const credDoc = readIfExists(path.join(HOME_DSH, ".credentials.yaml"));
  if (credDoc) {
    const m = credDoc.match(/^\s+OPENROUTER_API_KEY:\s*["']?([^\s"'\r\n]+)["']?\s*$/m);
    if (m) return { key: m[1], source: `${DISPLAY_TARGET}/.credentials.yaml (managed store)` };
  }

  const userEnv = readIfExists(path.join(HOME_DSH, ".env"));
  if (userEnv) {
    const m = userEnv.match(/^OPENROUTER_API_KEY\s*=\s*["']?([^\s"'\r\n]+)["']?\s*$/m);
    if (m) return { key: m[1], source: `${DISPLAY_TARGET}/.env (user-env fallback)` };
  }
  return null;
}

async function checkCredentials() {
  const found = resolveKey();
  if (!found) {
    fail("OpenRouter credentials",
      `none found (environment → ${DISPLAY_TARGET}/.credentials.yaml → ${DISPLAY_TARGET}/.env) — run ./setup-dsh.sh`);
    return;
  }
  try {
    const res = await fetch("https://openrouter.ai/api/v1/auth/key", {
      headers: { Authorization: `Bearer ${found.key}` },
    });
    if (res.status === 200) {
      let detail = `source: ${found.source}`;
      try {
        const body = await res.json();
        const label = body?.data?.label ?? "";
        const limit = body?.data?.limit == null ? "no spending limit" : `$${body.data.limit}`;
        if (label || limit) detail += `; ${[label, limit].filter(Boolean).join(", ")}`;
      } catch { /* JSON payload optional */ }
      pass("OpenRouter key valid", detail);
    } else if (res.status === 401) {
      fail("OpenRouter key rejected", `HTTP 401 Unauthorized (source: ${found.source})`);
    } else {
      warn("OpenRouter key check", `HTTP ${res.status} from https://openrouter.ai/api/v1/auth/key`);
    }
  } catch (err) {
    warn("OpenRouter unreachable", `${err.message} (skipping live validation)`);
  }
}

function checkPatch() {
  const patchPath = path.join(HOME_DSH, "cordis.patch.yml");
  const content = readIfExists(patchPath);
  if (content === null) {
    fail("Runtime patch layer", `${patchPath} not found — run ./setup-dsh.sh`);
    return;
  }
  if (!content.includes("openrouter:")) {
    fail("Runtime patch layer", "openrouter provider block missing — run ./setup-dsh.sh");
    return;
  }
  const modelCount = (content.match(/^\s+- id:\s*["'][^"']+["']/gm) || []).length;
  if (modelCount > 0) pass("Model catalog synced", `${modelCount} models in ${DISPLAY_TARGET}/cordis.patch.yml`);
  else warn("Model catalog synced", "0 models — run: bun run sync-models");

  if (/# Route default model|^- id: agent-default-model/m.test(content)) {
    pass("Sync anchor present");
  } else {
    warn("Sync anchor present",
      "'# Route default model' comment / agent-default-model entry missing — re-run ./setup-dsh.sh, then bun run sync-models");
  }
}

function checkSettings() {
  const settingsPath = path.join(HOME_DSH, "settings.yaml");
  const content = readIfExists(settingsPath);
  if (content === null) { warn("Settings layer", `${settingsPath} not found — run ./setup-dsh.sh`); return; }
  if (content.includes("openrouter")) pass("Settings layer", `${DISPLAY_TARGET}/settings.yaml routes openrouter`);
  else warn("Settings layer", `${DISPLAY_TARGET}/settings.yaml does not mention openrouter — run ./setup-dsh.sh`);
}

function checkWorkspace() {
  const manifest = readIfExists(path.join(process.cwd(), "package.json"));
  if (manifest === null) { fail("Workspace manifest", "package.json not found in the current directory"); return; }

  let scripts = {};
  let version = "unknown";
  try {
    const pkg = JSON.parse(manifest);
    scripts = pkg.scripts ?? {};
  } catch { fail("Workspace manifest", "package.json is not valid JSON"); return; }

  const dshPkg = readIfExists(path.join(process.cwd(), "node_modules", "@deepseek-ai", "dsh", "package.json"));
  if (dshPkg) {
    try { version = JSON.parse(dshPkg).version ?? version; pass("Framework installed", `@deepseek-ai/dsh ${version}`); }
    catch { warn("Framework installed", "could not read installed version"); }
  } else {
    fail("Framework installed", "node_modules/@deepseek-ai/dsh missing — run: bun install");
  }

  const required = ["web", "cli", "headless", "sync-models", "doctor"];
  const missing = required.filter((s) => !scripts[s]);
  if (missing.length === 0) pass("Script bindings", "web, cli, headless, sync-models, doctor");
  else warn("Script bindings", `missing in package.json: ${missing.join(", ")} — re-run ./setup-dsh.sh`);
}

function checkPlugins() {
  try {
    fs.readdirSync(PLUGIN_DIR);
    const missing = EXPECTED_PLUGINS.filter((p) => !fs.existsSync(path.join(PLUGIN_DIR, p)));
    const present = EXPECTED_PLUGINS.length - missing.length;
    if (missing.length === 0) pass("Web profile plugins", `${present}/${EXPECTED_PLUGINS.length} installed`);
    else warn("Web profile plugins", `missing: ${missing.join(", ")} — re-run ./setup-dsh.sh`);
  } catch {
    info("Web profile plugins", "no web profile provisioned yet — run ./setup-dsh.sh");
  }

  try {
    fs.readdirSync(HEADLESS_PLUGIN_DIR);
    const missing = EXPECTED_HEADLESS_PLUGINS.filter((p) => !fs.existsSync(path.join(HEADLESS_PLUGIN_DIR, p)));
    const present = EXPECTED_HEADLESS_PLUGINS.length - missing.length;
    if (missing.length === 0) pass("Headless profile plugins", `${present}/${EXPECTED_HEADLESS_PLUGINS.length} installed`);
    else warn("Headless profile plugins", `missing: ${missing.join(", ")} — re-run ./setup-dsh.sh`);
  } catch {
    info("Headless profile plugins", "no headless profile provisioned yet — run ./setup-dsh.sh");
  }
}

async function checkPort() {
  try {
    const res = await fetch("http://127.0.0.1:3080", { signal: AbortSignal.timeout(1500) });
    info("Port 3080", `a web server is responding (HTTP ${res.status})`);
  } catch (err) {
    const cause = String(err?.cause?.code ?? err?.code ?? err?.message ?? "");
    const lower = cause.toLowerCase();
    if (lower.includes("econnrefused") || lower.includes("connectionrefused") || lower.includes("connection refused") || lower.includes("failed to connect")) {
      info("Port 3080", "free — nothing listening");
    } else {
      warn("Port 3080", `probe failed: ${cause}`);
    }
  }
}

console.log("🩺 DSH workspace doctor — read-only diagnostics\n");

pass("Bun runtime", `bun ${Bun.version}`);
checkWorkspace();
await checkCredentials();
checkPatch();
checkSettings();
checkPlugins();
await checkPort();

console.log(lines.join("\n"));
console.log("");
if (failures === 0) {
  console.log("✅ All critical checks passed.");
  process.exit(0);
} else {
  console.log(`❌ ${failures} critical check${failures === 1 ? "" : "s"} failed — see the ❌ items above.`);
  process.exit(1);
}
