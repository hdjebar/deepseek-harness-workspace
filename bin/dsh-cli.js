#!/usr/bin/env bun
import { spawn } from "node:child_process";

async function isServerRunning() {
  try {
    const res = await fetch("http://127.0.0.1:3080", { signal: AbortSignal.timeout(1500) });
    return true;
  } catch {
    return false;
  }
}

async function main() {
  const running = await isServerRunning();
  if (!running) {
    console.error("\n⚠️  DSH Web/Backend host is not active on http://127.0.0.1:3080.");
    console.error("➡️  dsh-tui is a terminal client that connects to a running DSH session.");
    console.error("\n💡 To use the TUI:");
    console.error("   1. In terminal 1, start the backend: bun run web");
    console.error("   2. In terminal 2, attach the matrix: bun run cli");
    console.error("\n💡 Or for standalone automated tasks without a browser/server, run:");
    console.error("   bun run headless \"Your prompt or instruction\"\n");
    process.exit(1);
  }

  const child = spawn("dsh-tui", process.argv.slice(2), {
    stdio: "inherit",
    env: process.env,
  });

  child.on("exit", (code) => {
    process.exit(code ?? 0);
  });
}

main();
