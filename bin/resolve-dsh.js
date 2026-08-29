import fs from "node:fs";
import path from "node:path";
import os from "node:os";

export function resolveDshDir(cwd = process.cwd()) {
  // 1. Explicit environment variable
  if (process.env.DSH_HOME) {
    let raw = process.env.DSH_HOME.trim();
    if (raw.startsWith("~")) raw = path.join(os.homedir(), raw.slice(1));
    return path.resolve(raw);
  }

  // 2. .dsh-target file in workspace
  const targetFile = path.join(cwd, ".dsh-target");
  if (fs.existsSync(targetFile)) {
    try {
      let content = fs.readFileSync(targetFile, "utf8").trim();
      if (content) {
        if (content.startsWith("~")) content = path.join(os.homedir(), content.slice(1));
        return path.resolve(cwd, content);
      }
    } catch { /* ignore read failure */ }
  }

  // 3. Local workspace .dsh directory
  const localDir = path.join(cwd, ".dsh");
  const localConfig = fs.existsSync(path.join(localDir, "cordis.patch.yml")) || fs.existsSync(path.join(localDir, ".credentials.yaml"));
  if (localConfig) return localDir;

  // 4. Global ~/.dsh directory
  const globalDir = path.join(os.homedir(), ".dsh");
  const globalConfig = fs.existsSync(path.join(globalDir, "cordis.patch.yml")) || fs.existsSync(path.join(globalDir, ".credentials.yaml"));
  if (globalConfig) return globalDir;

  if (fs.existsSync(localDir)) return localDir;
  return globalDir;
}
