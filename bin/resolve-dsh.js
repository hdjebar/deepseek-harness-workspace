import fs from "node:fs";
import path from "node:path";
import os from "node:os";

let resolveDshHome, expandHomePath;
try {
  const mod = await import("@deepseek-ai/dsh-home-paths");
  resolveDshHome = mod.resolveDshHome;
  expandHomePath = mod.expandHomePath;
} catch {
  resolveDshHome = (configured, env = process.env) => {
    const fromEnv = env.DSH_HOME;
    const raw = configured ?? (fromEnv !== undefined && fromEnv.trim().length > 0 ? fromEnv : path.join(os.homedir(), ".dsh"));
    if (raw === "~") return os.homedir();
    if (raw.startsWith("~/") || raw.startsWith("~\\")) return path.join(os.homedir(), raw.slice(2));
    return path.resolve(raw);
  };
  expandHomePath = (p) => {
    if (p === "~") return os.homedir();
    if (p.startsWith("~/") || p.startsWith("~\\")) return path.join(os.homedir(), p.slice(2));
    return p;
  };
}

export function resolveDshDir(cwd = process.cwd()) {
  // 1. Explicit DSH_HOME in process.env (if set and non-empty)
  const envHome = process.env.DSH_HOME;
  if (typeof envHome === "string" && envHome.trim().length > 0) {
    return resolveDshHome();
  }

  // 2. .dsh-target file in workspace root
  const targetFile = path.join(cwd, ".dsh-target");
  if (fs.existsSync(targetFile)) {
    try {
      const lines = fs.readFileSync(targetFile, "utf8").split("\n");
      const content = lines[0] ? lines[0].trim() : "";
      if (content.length > 0) {
        if (content === "global" || content === "~/.dsh" || content === path.join(os.homedir(), ".dsh")) {
          return resolveDshHome();
        }
        return path.resolve(cwd, expandHomePath(content));
      }
    } catch { /* ignore read failure */ }
  }

  // 3. Local workspace .dsh directory (if present with configurations)
  const localDir = path.join(cwd, ".dsh");
  const localConfig = fs.existsSync(path.join(localDir, "cordis.patch.yml")) || fs.existsSync(path.join(localDir, ".credentials.yaml"));
  if (localConfig) return localDir;

  // 4. Default runtime home (~/.dsh)
  return resolveDshHome();
}
