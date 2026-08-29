#!/usr/bin/env bun
import { spawn } from "node:child_process";
import { resolveDshDir } from "./resolve-dsh.js";

const dshHome = resolveDshDir();
const userArgs = process.argv.slice(2);
const port = process.env.DSH_PORT || process.env.PORT;

const args = ["web", ...userArgs];

// Only append --port if user did not explicitly pass --port or -p in userArgs
const hasPortArg = userArgs.some((arg, i) => arg === "--port" || arg === "-p" || arg.startsWith("--port="));
if (port && !hasPortArg) {
  args.push("--port", String(port));
}

const child = spawn("dsh", args, {
  stdio: "inherit",
  env: {
    ...process.env,
    DSH_HOME: dshHome,
    ...(port ? { DSH_PORT: String(port), PORT: String(port) } : {})
  }
});

child.on("exit", (code, signal) => {
  if (code !== null) {
    process.exit(code);
  }
  if (signal === "SIGTERM") process.exit(143);
  if (signal === "SIGINT") process.exit(130);
  if (signal === "SIGHUP") process.exit(129);
  process.exit(1);
});
