#!/usr/bin/env bun
import { spawn } from "node:child_process";
import { resolveDshDir } from "./resolve-dsh.js";

const dshHome = resolveDshDir();
const port = process.env.DSH_PORT || process.env.PORT || "3080";
const targetUrl = process.env.DSH_URL || `http://127.0.0.1:${port}`;

async function isServerRunning() {
  try {
    const res = await fetch(targetUrl, { signal: AbortSignal.timeout(1500) });
    return true;
  } catch {
    return false;
  }
}

async function main() {
  console.log(`🔍 Probing DSH backend at ${targetUrl}...`);
  const running = await isServerRunning();
  if (!running) {
    console.error(`\n⚠️  DSH Web/Backend host is not active on ${targetUrl}.`);
    console.error("➡️  dsh-tui is a terminal client that connects to a running DSH session.");
    console.error("\n💡 To use the TUI:");
    console.error(`   1. In terminal 1, start the backend: ${port === "3080" ? "bun run web" : `DSH_PORT=${port} bun run web`}`);
    console.error(`   2. In terminal 2, attach the matrix: ${port === "3080" ? "bun run cli" : `DSH_PORT=${port} bun run cli`}`);
    console.error("\n💡 Or for standalone automated tasks without a browser/server, run:");
    console.error("   bun run headless \"Your prompt or instruction\"\n");
    process.exit(1);
  }

  const child = spawn("dsh-tui", process.argv.slice(2), {
    stdio: "inherit",
    env: {
      ...process.env,
      DSH_HOME: dshHome,
      DSH_URL: targetUrl,
      DSH_PORT: port,
      PORT: port
    },
  });

  child.on("exit", (code, signal) => {
    if (code !== null) process.exit(code);
    if (signal === "SIGTERM") process.exit(143);
    if (signal === "SIGINT") process.exit(130);
    process.exit(1);
  });
}

main();
