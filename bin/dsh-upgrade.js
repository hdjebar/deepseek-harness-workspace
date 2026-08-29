#!/usr/bin/env bun
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { resolveDshDir } from "./resolve-dsh.js";

const dshHome = resolveDshDir();
const dshEnv = { ...process.env, DSH_HOME: dshHome };

function run(label, cmd, args, env = process.env) {
  console.log(`\n${label}`);
  const result = spawnSync(cmd, args, { stdio: "inherit", env });
  if (result.error) {
    console.error(`\n❌ Failed to run ${cmd} ${args.join(" ")}: ${result.error.message}`);
    process.exit(1);
  }
  if (result.status !== 0) {
    console.error(`\n❌ ${cmd} ${args.join(" ")} exited with code ${result.status}`);
    process.exit(result.status ?? 1);
  }
}

console.log("🔄 DSH ecosystem upgrade");
console.log("========================================");

run("📦 [1/4] Upgrading framework (@deepseek-ai/dsh, dsh-tui) via bun update...", "bun", ["update"]);

const profilesDir = path.join(dshHome, "profiles");
const profiles = fs.existsSync(profilesDir)
  ? fs.readdirSync(profilesDir, { withFileTypes: true })
      .filter((entry) => entry.isDirectory())
      .map((entry) => entry.name)
      .filter((name) => fs.existsSync(path.join(profilesDir, name, "package.json")))
      .sort()
  : [];

if (profiles.length === 0) {
  console.log(`\n🔌 [2/4] No provisioned profiles found under ${profilesDir} — skipping plugin upgrade.`);
} else {
  for (const profile of profiles) {
    run(`🔌 [2/4] Upgrading plugins for the "${profile}" profile...`, "dsh", ["plugin", "--profile", profile, "update"], dshEnv);
  }
}

run("🌐 [3/4] Syncing live OpenRouter model catalog...", "bun", ["run", "sync-models"], dshEnv);

run("🩺 [4/4] Running health check...", "bun", ["run", "doctor"], dshEnv);

console.log("\n✅ Upgrade complete.");
console.log('➡️  Commit the regenerated lockfile: git add bun.lock package.json && git commit -m "chore: upgrade DSH ecosystem"');
