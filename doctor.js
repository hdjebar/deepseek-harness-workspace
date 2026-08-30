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
import { resolveDshDir } from "./bin/resolve-dsh.js";

const HOME_DSH = resolveDshDir();
const rel = path.relative(process.cwd(), HOME_DSH);
const IS_LOCAL = !rel.startsWith("..") && !path.isAbsolute(rel);
const DISPLAY_TARGET = IS_LOCAL ? `./.dsh (local workspace)` : HOME_DSH.replace(os.homedir(), "~");

const PLUGIN_DIR = path.join(HOME_DSH, "profiles", "web", "node_modules");
const HEADLESS_PLUGIN_DIR = path.join(HOME_DSH, "profiles", "headless", "node_modules");
const EXPECTED_PLUGINS = [
  "dshmarket",
  "dsh-mcp-panel",
  "dsh-better-sidebar",
  "dsh-find-plugin",
  "@liustack/modsearch",
  "dsh-provider-model-configurator",
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

function checkPermissions() {
  if (!fs.existsSync(HOME_DSH)) return;
  try {
    const dirStat = fs.statSync(HOME_DSH);
    const dirMode = dirStat.mode & 0o777;
    if (process.platform !== "win32" && (dirMode & 0o077) !== 0) {
      warn("Folder permissions", `${DISPLAY_TARGET} is mode 0${dirMode.toString(8)} (recommend 0700)`);
    } else {
      pass("Folder permissions", `${DISPLAY_TARGET} mode 0${dirMode.toString(8)}`);
    }

    const credPath = path.join(HOME_DSH, ".credentials.yaml");
    if (fs.existsSync(credPath)) {
      const credStat = fs.statSync(credPath);
      const credMode = credStat.mode & 0o777;
      if (process.platform !== "win32" && (credMode & 0o077) !== 0) {
        fail("Credential permissions", `${DISPLAY_TARGET}/.credentials.yaml is mode 0${credMode.toString(8)} (fatal: must be 0600) — run: chmod 600 ${credPath}`);
      } else {
        pass("Credential permissions", `${DISPLAY_TARGET}/.credentials.yaml mode 0${credMode.toString(8)}`);
      }
    }
  } catch (err) {
    warn("Permission check", err.message);
  }
}

/** Mirror dsh-credentials-local's layering; never log the value itself. */
async function resolveKey() {
  const envKey = process.env.OPENROUTER_API_KEY;
  if (envKey) return { key: envKey, source: "inherited environment" };

  const credPath = path.join(HOME_DSH, ".credentials.yaml");
  const credDoc = readIfExists(credPath);
  if (credDoc) {
    try {
      let key;
      try {
        const { parseCredentialsDocument } = await import("@deepseek-ai/dsh-credentials-local");
        const parsed = parseCredentialsDocument(credDoc, credPath);
        key = parsed.refs.get("OPENROUTER_API_KEY");
      } catch (err) {
        if (err.code !== "MODULE_NOT_FOUND" && !String(err.message).includes("Cannot find module") && !String(err.message).includes("Cannot find package")) throw err;
        const verMatch = credDoc.match(/^\s*version:\s*(\d+)/m);
        if (!verMatch || parseInt(verMatch[1], 10) !== 1) {
          throw new Error(`credentials-local: ${credPath} must declare version: 1`);
        }
        const m = credDoc.match(/^\s*OPENROUTER_API_KEY\s*:\s*["']?([^\s"'\r\n]+)["']?/m);
        if (m) key = m[1];
      }
      if (key) return { key, source: `${DISPLAY_TARGET}/.credentials.yaml (managed store)` };
      fail("OpenRouter credential missing", `${DISPLAY_TARGET}/.credentials.yaml has no OPENROUTER_API_KEY in refs`);
      return null;
    } catch (err) {
      fail("Credential schema", err.message);
      return null;
    }
  }

  const userEnv = readIfExists(path.join(HOME_DSH, ".env"));
  if (userEnv) {
    const m = userEnv.match(/^OPENROUTER_API_KEY\s*=\s*["']?([^\s"'\r\n]+)["']?\s*$/m);
    if (m) return { key: m[1], source: `${DISPLAY_TARGET}/.env (user-env fallback)` };
  }
  return null;
}

async function checkCredentials() {
  const found = await resolveKey();
  if (!found) {
    fail("OpenRouter credentials",
      `none found (environment → ${DISPLAY_TARGET}/.credentials.yaml → ${DISPLAY_TARGET}/.env) — run ./setup-dsh.sh`);
    return;
  }
  if (!found.key.startsWith("sk-or-")) {
    fail("OpenRouter key format", `expected prefix 'sk-or-', found '${found.key.slice(0, 8)}...' (source: ${found.source})`);
    return;
  }
  try {
    const res = await fetch("https://openrouter.ai/api/v1/auth/key", {
      headers: { Authorization: `Bearer ${found.key}` },
      signal: AbortSignal.timeout(5000),
    });
    if (res.status === 200) {
      const data = await res.json().catch(() => ({}));
      const label = data.data?.label || maskKey(found.key);
      const limit = data.data?.limit ? `limit $${data.data.limit}` : "no spending limit";
      pass("OpenRouter key valid", `source: ${found.source}; ${label}, ${limit}`);
    } else if (res.status === 401) {
      fail("OpenRouter key rejected", `HTTP 401 Unauthorized (source: ${found.source})`);
    } else {
      warn("OpenRouter key probe", `HTTP ${res.status} from openrouter.ai/api/v1/auth/key`);
    }
  } catch (err) {
    warn("OpenRouter reachability", `probe failed: ${err.message} — key validation skipped`);
  }
}

function checkPatch() {
  const patchPath = path.join(HOME_DSH, "cordis.patch.yml");
  const content = readIfExists(patchPath);
  if (!content) {
    fail("Runtime patch layer", `${patchPath} not found — run ./setup-dsh.sh`);
    return;
  }
  const count = (content.match(/^[ \t]*- id:\s*["']?[^"'\r\n]+["']?/gm) || []).length;
  if (count > 0) {
    pass("Model catalog synced", `${count} models in ${DISPLAY_TARGET}/cordis.patch.yml`);
  } else {
    fail("Model catalog empty", `${DISPLAY_TARGET}/cordis.patch.yml has no model entries — run bun run sync-models`);
  }

  // Verify the sync anchor is present so `sync-models.js` can update models later
  if (content.includes("# Route default model") || content.includes("- id: agent-default-model")) {
    pass("Sync anchor present");
  } else {
    fail("Sync anchor missing", `${DISPLAY_TARGET}/cordis.patch.yml is missing the '# Route default model' anchor comment required by sync-models`);
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
    const deps = { ...pkg.dependencies, ...pkg.devDependencies };
    if (!deps["@deepseek-ai/dsh"]) warn("Framework dependency", "@deepseek-ai/dsh missing in package.json dependencies");
    if (!deps["dsh-tui"]) warn("TUI dependency", "dsh-tui missing in package.json dependencies");
  } catch { fail("Workspace manifest", "package.json is not valid JSON"); return; }

  const dshPkg = readIfExists(path.join(process.cwd(), "node_modules", "@deepseek-ai", "dsh", "package.json"));
  if (dshPkg) {
    try { version = JSON.parse(dshPkg).version ?? version; pass("Framework installed", `@deepseek-ai/dsh ${version}`); }
    catch { warn("Framework installed", "could not read installed version"); }
  } else {
    fail("Framework installed", "node_modules/@deepseek-ai/dsh missing — run: bun install");
  }

  const required = ["web", "cli", "headless", "sync-models", "doctor", "reset", "upgrade"];
  const missing = required.filter((s) => !scripts[s]);
  if (missing.length === 0) pass("Script bindings", required.join(", "));
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
  const port = process.env.DSH_PORT || process.env.PORT || "3080";
  try {
    const res = await fetch(`http://127.0.0.1:${port}`, { signal: AbortSignal.timeout(1500) });
    const text = await res.text().catch(() => "");
    const isDsh = text.includes("dsh") || text.includes("DeepSeek") || text.includes("Cordis") || (res.headers.get("x-powered-by") || "").toLowerCase().includes("dsh");
    if (isDsh || res.status === 200) {
      info(`Port ${port}`, `a web server is responding (HTTP ${res.status}${isDsh ? " — DSH verified" : ""})`);
    } else {
      info(`Port ${port}`, `occupied by non-DSH server (HTTP ${res.status}) — verify manually`);
    }
  } catch (err) {
    const cause = String(err?.cause?.code ?? err?.code ?? err?.message ?? "");
    const lower = cause.toLowerCase();
    if (lower.includes("econnrefused") || lower.includes("connectionrefused") || lower.includes("connection refused") || lower.includes("failed to connect")) {
      info(`Port ${port}`, "free — nothing listening");
    } else {
      warn(`Port ${port}`, `probe failed: ${cause}`);
    }
  }
}

console.log("🩺 DSH workspace doctor — read-only diagnostics\n");

pass("Bun runtime", `bun ${Bun.version}`);
checkWorkspace();
checkPermissions();
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
