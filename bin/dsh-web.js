#!/usr/bin/env bun
import { spawn } from "node:child_process";
import { resolveDshDir } from "./resolve-dsh.js";

const dshHome = resolveDshDir();
const userArgs = process.argv.slice(2);
const port = process.env.DSH_PORT || process.env.PORT;
if (!process.env.DSH_PORT && process.env.PORT) {
  console.warn(`⚠️  Using generic PORT env var ('${process.env.PORT}') — prefer DSH_PORT for DSH-specific port configuration`);
}

const args = ["web", ...userArgs];

// Check if user already provided port or if this is a dump / help command (which reject app args)
const hasPortArg = userArgs.some((arg) => arg === "--port" || arg === "-p" || arg.startsWith("--port="));
const isDumpOrHelp = userArgs.some((arg) =>
  arg === "--dump-config" ||
  arg === "--dump-default-config" ||
  arg === "--help" ||
  arg === "-h" ||
  arg === "--version" ||
  arg === "-v"
);

if (port && !hasPortArg && !isDumpOrHelp) {
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
