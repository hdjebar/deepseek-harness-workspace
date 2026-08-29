import fs from "node:fs";
import path from "node:path";
import { resolveDshHome, expandHomePath } from "@deepseek-ai/dsh-home-paths";

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
      const content = fs.readFileSync(targetFile, "utf8").trim();
      if (content.length > 0) {
        if (content === "~/.dsh" || content === "global") {
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
