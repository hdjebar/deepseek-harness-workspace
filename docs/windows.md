# 🪟 Windows Support & Porting Guide

DSH currently targets **macOS and Linux**. This page explains exactly why, gives you the fastest way to run DSH on Windows today (WSL2, no code changes), and — for anyone who wants to contribute native Windows support — a detailed breakdown of what porting `setup-dsh.sh` and `reset.sh` actually involves.

> **Status:** there is no native Windows (`cmd.exe` / PowerShell-only) install path yet. Nothing in this document ships today except the WSL2 route — the rest is a contributor's map, not a changelog.

---

## Why macOS/Linux only, today

Three things in the codebase are POSIX-specific:

| Where | What | Why it's POSIX-only |
| :--- | :--- | :--- |
| `setup-dsh.sh`, `reset.sh` | `#!/usr/bin/env bash` scripts | `cmd.exe` and PowerShell can't execute bash directly |
| `setup-dsh.sh` (credential vault) | `chmod 700` / `chmod 600` | NTFS has no POSIX permission bits — the whole "Zero-Plaintext Security" model is `chmod`-based |
| `reset.sh` (process cleanup) | `lsof`, `ps -p <pid> -o command=`, `pkill`, `kill -9`, `kill -15` | None of these exist on Windows outside WSL |

By contrast, `doctor.js`, `sync-models.js`, and everything in `bin/*.js` (`dsh-web.js`, `dsh-cli.js`, `dsh-headless.js`) are plain Bun/Node scripts and are **already cross-platform** — `doctor.js` even has explicit `process.platform !== "win32"` guards that skip the permission checks that don't apply there. The gap is specifically the two shell scripts and the permission model they implement.

---

## ✅ Fastest path: WSL2 (recommended, ~10 minutes, zero porting)

If you just want DSH running on a Windows machine, don't port anything — run it inside WSL2, where it's already fully supported:

```powershell
# In an elevated PowerShell prompt
wsl --install -d Ubuntu
```

Then, inside the WSL Ubuntu shell:

```bash
curl -fsSL https://bun.sh/install | bash
git clone https://github.com/hdjebar/deepseek-harness-workspace.git
cd deepseek-harness-workspace
chmod +x setup-dsh.sh
./setup-dsh.sh
bun run web
```

Notes:
* Keep the workspace on the **Linux filesystem** (`~/deepseek-harness-workspace`, not `/mnt/c/...`) — POSIX permissions (`chmod 600`) and I/O performance both degrade badly on the Windows-mounted `/mnt/c` path.
* WSL2 auto-forwards `localhost`, so `bun run web` on port `3080` is reachable from your Windows browser at `http://127.0.0.1:3080` with no extra networking setup.
* `bun run cli` (the TUI) works the same way, in a second WSL terminal.

This is the supported route until a native port lands.

---

## 🔧 Porting to native Windows (PowerShell), in detail

If you want DSH runnable with **no WSL and no Git Bash** — pure `pwsh`/`cmd.exe` — here's what has to change, piece by piece. This is contributor guidance, not a finished script.

### 1. Runtime entry points (`bin/*.js`) — mostly already portable, one real gotcha
`dsh-web.js`, `dsh-cli.js`, and `dsh-headless.js` all do:
```js
const child = spawn("dsh", args, { stdio: "inherit", env: { ... } });
```
On Windows, `bunx`/npm-installed binaries are exposed as `dsh.cmd` / `dsh.ps1` shims, not a bare `dsh` executable. `child_process.spawn("dsh", ...)` without `shell: true` will usually fail with `ENOENT` on Windows because it won't resolve `.cmd` shims. The fix is small:
```js
const child = spawn("dsh", args, {
  stdio: "inherit",
  shell: process.platform === "win32",
  env: { ... }
});
```
Apply the same change to the `spawn("dsh-tui", ...)` call in `dsh-cli.js`.

### 2. `setup-dsh.sh` → `setup-dsh.ps1`
Most of the script is just writing YAML/JSON text files (`cordis.patch.yml`, `pnpm-workspace.yaml`, `.credentials.yaml`, `settings.yaml`, `package.json`) — that content is OS-agnostic and can be reused verbatim in a PowerShell `here-string`. What actually needs re-implementing:

* **Arg parsing** — `--global`/`--dir`/`--help` become a `param()` block or a manual `for ($i = 0; $i -lt $args.Count; $i++)` loop.
* **Masked API key input** — replace `read -rsp` with:
  ```powershell
  $secure = Read-Host "Enter your OpenRouter Master API Key (sk-or-...)" -AsSecureString
  $orKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
      [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
  ```
  Note it still has to become plaintext in memory before being written to `.credentials.yaml` — DSH's runtime needs the raw key either way, same as on macOS/Linux.
* **`chmod 700` / `chmod 600` → ACL lockdown.** NTFS has no `0600`/`0700` bits; the equivalent is stripping inherited permissions and granting only the current user:
  ```powershell
  icacls $DshDir /inheritance:r /grant:r "$($env:USERNAME):(OI)(CI)F" | Out-Null
  icacls "$DshDir\.credentials.yaml" /inheritance:r /grant:r "$($env:USERNAME):F" | Out-Null
  ```
* **`command -v bun` → `Get-Command bun -ErrorAction SilentlyContinue`.**
* **`package.json` script wiring** — `"reset": "bash reset.sh"` needs an OS-aware dispatch, e.g. a tiny `bin/reset.js` that shells out to `reset.ps1` on `win32` and `reset.sh` (via `bash`) everywhere else, so `bun run reset` keeps working unmodified from the user's point of view.

### 3. `reset.sh` → `reset.ps1` (the destructive path — port this carefully)
This is the highest-risk file to port, since bugs here delete credential stores (see the fixes earlier in this repo's history). Map each piece 1:1 rather than rewriting the logic:

* **`$HOME` → `$env:USERPROFILE`**, with the same "resolve the real profile dir, don't just assume a fallback" caution as the `cd ~` fallback used on macOS/Linux.
* **`.dsh-target` marker parsing** — identical text-file logic; only the tilde/home-expansion needs `$env:USERPROFILE` instead of `$HOME`.
* **Dangerous-target abort list** — extend it for Windows roots: add `$env:SystemDrive\`, `C:\`, and `$env:USERPROFILE` itself (mirroring the existing `/`, `/tmp`, `/var`, `/usr`, `/etc`, `$USER_HOME` checks in `reset.sh`).
* **Sentinel verification** (`cordis.patch.yml` / `.credentials.yaml` / `settings.yaml` / `dsh.pid` / `profiles/` presence) — this check is pure file-existence logic and ports unchanged.
* **Port-based process kill** — replace `lsof -ti :$PORT | xargs kill`:
  ```powershell
  Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty OwningProcess -Unique |
    ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
  ```
  `Get-NetTCPConnection` needs the `NetTCPIP` module (present by default on Windows 8/Server 2012+); fall back to parsing `netstat -ano | findstr ":$Port"` on older systems.
* **Process identity check** (`reset.sh`'s `is_dsh_process`, which greps the command line for `dsh`/`dsh-tui`/etc. before killing anything) — the direct equivalent is:
  ```powershell
  $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $pid").CommandLine
  if ($cmdLine -match 'dsh|dsh-tui|dsh-web|dsh-cli|dsh-headless') { Stop-Process -Id $pid -Force }
  ```
  Keep this safety check — it's what stops the reset script from killing an unrelated process that happens to hold the port.
* **`rm -rf` → `Remove-Item -Recurse -Force -ErrorAction SilentlyContinue`**, applied to the same target list (`node_modules`, `.dsh`, `*.log`, the target marker, and the resolved `$RealTarget` directory).
* **Confirmation prompt** — `read -rp "...[y/N]: "` → `Read-Host`, same `^[Yy]$` match.

### 4. `doctor.js` — extend, don't just skip
`checkPermissions()` currently no-ops the permission check entirely on `win32`. A real Windows port should replace that no-op with an ACL-based equivalent (e.g. shelling out to `icacls` and checking the credential file grants no access beyond the current user), rather than silently skipping the credential-safety check DSH advertises as a core feature.

### 5. CI
`.github/workflows/ci.yml` currently runs `runs-on: ubuntu-latest` only, with `shellcheck` against the two `.sh` files. A native port needs a parallel `windows-latest` job that runs [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) against the new `.ps1` files and exercises the same negative-path tests `doctor.js`/`sync-models.js` already have (missing credentials, wrong ACL, missing patch anchor).

---

## Summary checklist

| Piece | macOS/Linux | Windows equivalent | Status |
| :--- | :--- | :--- | :--- |
| Setup script | `setup-dsh.sh` | `setup-dsh.ps1` | Not started |
| Reset script | `reset.sh` | `reset.ps1` | Not started |
| Folder/credential lockdown | `chmod 700` / `chmod 600` | `icacls` ACLs | Not started |
| Port-based process kill | `lsof` + `kill` | `Get-NetTCPConnection` + `Stop-Process` | Not started |
| Runtime entry points | `bin/*.js` via `spawn` | Same, + `shell: true` on `win32` | Small fix needed |
| Health check | `doctor.js` | Same file, extend `checkPermissions()` | Guards already in place |
| CI | `ubuntu-latest` + ShellCheck | Add `windows-latest` + PSScriptAnalyzer | Not started |

Contributions implementing any row above are welcome — open a PR against `setup-dsh.ps1` / `reset.ps1` and reference this guide. Given `reset.ps1` is a destructive script by design, treat its safety-abort and sentinel-verification logic (section 3 above) as the part that needs the most scrutiny in review, not the part to simplify away.

---

[← Back to README](../README.md)
