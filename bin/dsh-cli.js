#!/usr/bin/env bun
import { spawn } from "node:child_process";

const PORT = process.env.DSH_PORT || process.env.PORT || "3080";
const targetUrl = process.env.DSH_URL || `http://127.0.0.1:${PORT}`;

async function isServerRunning() {
  try {
    const res = await fetch(targetUrl, { signal: AbortSignal.timeout(1500) });
    return true;
  } catch {
    return false;
  }
}

async function main() {
  const running = await isServerRunning();
  if (!running) {
    console.error(`\n⚠️  DSH Web/Backend host is not active on ${targetUrl}.`);
    console.error("➡️  dsh-tui is a terminal client that connects to a running DSH session.");
    console.error("\n💡 To use the TUI:");
    console.error(`   1. In terminal 1, start the backend: ${PORT === "3080" ? "bun run web" : `DSH_PORT=${PORT} bun run web`}`);
    console.error(`   2. In terminal 2, attach the matrix: ${PORT === "3080" ? "bun run cli" : `DSH_PORT=${PORT} bun run cli`}`);
    console.error("\n💡 Or for standalone automated tasks without a browser/server, run:");
    console.error("   bun run headless \"Your prompt or instruction\"\n");
    process.exit(1);
  }

  const child = spawn("dsh-tui", process.argv.slice(2), {
    stdio: "inherit",
    env: { ...process.env, DSH_URL: targetUrl, DSH_PORT: PORT, PORT: PORT },
  });

  child.on("exit", (code) => {
    process.exit(code ?? 0);
  });
}

main();
