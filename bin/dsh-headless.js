#!/usr/bin/env bun
import { spawn } from "node:child_process";
import { resolveDshDir } from "./resolve-dsh.js";

const dshHome = resolveDshDir();
const args = ["--profile", "headless", ...process.argv.slice(2)];

const child = spawn("dsh", args, {
  stdio: "inherit",
  env: {
    ...process.env,
    DSH_HOME: dshHome
  }
});

child.on("exit", (code, signal) => {
  if (code !== null) process.exit(code);
  if (signal === "SIGTERM") process.exit(143);
  if (signal === "SIGINT") process.exit(130);
  process.exit(1);
});
