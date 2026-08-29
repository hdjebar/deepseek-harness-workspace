# 🧹 Stopping, Killing & Resetting

## 🛑 Stopping & Killing Processes

If a background DSH process, web server, or port (`3080`) is locked or lingering:

```bash
# Terminate lingering web server on port 3080
lsof -ti :3080 | xargs kill -9 2>/dev/null || true

# Kill any active DSH background processes
pkill -9 -f "bun.*dsh" 2>/dev/null || pkill -9 -f "dsh-tui" 2>/dev/null || true
```

---

## 🧹 Clean Slate & Reset

To completely reset the workspace, purge stored credentials, and clean local caches:

```bash
# Interactive local reset (prompts for confirmation)
bun run reset
# or
./reset.sh

# Reset global ~/.dsh configuration
./reset.sh --global

# Non-interactive force reset (for CI or automation)
./reset.sh --force
```

The reset script safely:
1. Terminates any lingering DSH web servers on the configured port (`3080` or `$DSH_PORT`).
2. Purges the target configuration store (local `./.dsh` by default, or `~/.dsh` with `--global`).
3. Cleans local untracked `node_modules`, `.dsh/`, and runtime logs in local mode (without affecting other workspaces).

*To reinstall and configure fresh after reset, simply run `./setup-dsh.sh`.*

---

[← Back to README](../README.md)
