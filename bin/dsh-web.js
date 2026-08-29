#!/usr/bin/env bun
import { spawn } from "node:child_process";

const port = process.env.DSH_PORT || process.env.PORT || "3080";
const args = ["web", "--port", String(port), ...process.argv.slice(2)];

const child = spawn("dsh", args, {
  stdio: "inherit",
  env: { ...process.env, DSH_PORT: String(port), PORT: String(port) }
});

child.on("exit", (code) => {
  process.exit(code ?? 0);
});
