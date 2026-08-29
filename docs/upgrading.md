# 🔄 Upgrading the DSH Ecosystem

DSH is a bootstrap/config layer around a large family of `@deepseek-ai/dsh-*` packages (see [What is DSH?](../README.md#-what-is-dsh)). "Upgrading" isn't one operation — it's four different ones, with different mechanics and different risk. This page covers each, verified against the actual package registry and `setup-dsh.sh`'s real behavior rather than assumed.

## Quick start: the routine upgrade

```bash
bun update            # picks up newer @deepseek-ai/dsh / dsh-tui within the existing ^ range
bun run sync-models    # refresh the model catalog — separate concern, always safe/idempotent
bun run doctor         # verify nothing broke
git add bun.lock package.json && git commit -m "chore: upgrade @deepseek-ai/dsh and dsh-tui"
```

That's the whole routine case. **Don't re-run `setup-dsh.sh`** for either a framework or a plugin upgrade — `bun update` covers the framework, and `dsh plugin --profile <name> update` (§2 below) covers plugins; neither touches `cordis.patch.yml` or your credentials. Re-running `setup-dsh.sh` is a separate, riskier operation (see the warning at the bottom of this page) that's only actually needed to regenerate config from scratch or bootstrap a brand-new profile — not for routine upgrades of either kind.

> [!IMPORTANT]
> **`bun update` does not include plugins**, even though both are technically "npm packages." They're two disjoint dependency trees:
> | | Framework (`@deepseek-ai/dsh`, `dsh-tui`) | Plugins (`dshmarket`, `dsh-mcp-panel`, ...) |
> | :--- | :--- | :--- |
> | Lives in | this repo's own `./node_modules` | `<DSH_HOME>/profiles/<name>/node_modules` — **inside the `.dsh` config folder**, not the repo |
> | Package manager | `bun` (this repo's `package.json`/`bun.lock`) | `pnpm` (each profile has its own `pnpm-workspace.yaml`, written by `setup-dsh.sh`) |
> | Upgrade command | `bun update` | `dsh plugin --profile <name> update` |
>
> `bun update` genuinely cannot see plugins — they're not in this repo's `package.json` at all, and `pnpm`, not `bun`, manages that tree. Run both commands if you want both upgraded.

Two situations need more than the quick start:
* **Crossing a minor version boundary** (e.g. a future `0.2.0`): `bun update` won't cross it — use `bun add @deepseek-ai/dsh@<version> dsh-tui@<version>` instead, then run the rest of the sequence above.
* **Want newer plugins** (`dshmarket`, `dsh-mcp-panel`, etc.): `dsh plugin --profile <name> update` — see §2 below for the exact command.

---

## 1. The framework (`@deepseek-ai/dsh`, `dsh-tui`)

`package.json` pins these with caret ranges: `"@deepseek-ai/dsh": "^0.1.1-rc.2"`, `"dsh-tui": "^0.2.19"`.

* **Within the existing range** (a newer `0.1.x`/`0.2.x` patch/prerelease): `bun update` picks it up and regenerates `bun.lock`. At the time of writing, both packages' npm `latest` tag already matches what's pinned, so there's nothing newer to pick up right now — but the command is `bun update`, not a special DSH command.
* **Crossing a minor/major boundary** (e.g. a future `0.2.0`): `^0.1.1-rc.2` won't cross that automatically — semver caret ranges on a `0.x` version only float within the same minor. You'd need `bun add @deepseek-ai/dsh@<new-version>` explicitly.
* **CI will reject an unsynced upgrade.** `.github/workflows/ci.yml` runs `bun install --frozen-lockfile` (see [docs/ci.md](ci.md)) — after any local `bun update`, the regenerated `bun.lock` must be committed alongside `package.json`, or the very next CI run fails on a lockfile mismatch, not on anything related to what you changed.

### A trap in the ~100 transitive sub-packages — don't `bun add` one directly
`@deepseek-ai/dsh` pulls in roughly a hundred `@deepseek-ai/dsh-*` sub-packages as its own dependencies (visible in `bun.lock`). Checking several of them against the npm registry turned up a consistent split: most have a `latest` dist-tag that's **behind** their `next` tag — e.g. `@deepseek-ai/dsh-tool-workflow`: `latest` is `0.0.1-rc.1`, `next` is `0.1.1-rc.2` (the version actually resolved in this repo's `bun.lock`). The same gap shows up for `dsh-base`, `dsh-headless`, `dsh-web`, `dsh-credentials-local`, and others checked. A plain `bun update` in this repo is unaffected — it resolves sub-packages through `@deepseek-ai/dsh`'s own declared dependency ranges, not each sub-package's npm tag. But if you ever manually run `bun add @deepseek-ai/dsh-<something>@latest` to "update" one piece directly, you'd likely **downgrade** it instead. Don't do that — let the top-level `@deepseek-ai/dsh` upgrade pull its own sub-dependencies.

---

## 2. Plugins (`dshmarket`, `dsh-mcp-panel`, `dsh-better-sidebar`, `dsh-find-plugin`, `@liustack/modsearch`)

Two ways, both real — verified against `@deepseek-ai/dsh`'s own README (`dsh plugin --profile <name> <pnpm args>`, described there as "manage a profile's plugins **by forwarding to pnpm** in the profile directory"):

* **GUI**: the dshmarket store in the Web IDE ("Browse, install, update, and toggle community plugins... with a single click," per the [Plugins guide](plugins.md)).
* **CLI**: `dsh plugin --profile <name> update` runs `pnpm update` inside that profile's `node_modules`, upgrading every installed plugin within its recorded version range — the same mechanism `setup-dsh.sh` uses to *install* them (`bunx @deepseek-ai/dsh plugin --profile web add ...`), just with `update` instead of `add`. Since the raw `dsh` CLI doesn't know this repo's `.dsh-target`/local-`.dsh` conventions (only `bin/dsh-web.js`/`dsh-cli.js`/`dsh-headless.js` resolve those), set `DSH_HOME` explicitly, matching `setup-dsh.sh`'s own pattern:
  ```bash
  # Local mode (the default)
  DSH_HOME="$PWD/.dsh" bunx @deepseek-ai/dsh plugin --profile web update
  DSH_HOME="$PWD/.dsh" bunx @deepseek-ai/dsh plugin --profile headless update

  # Global mode
  DSH_HOME="$HOME/.dsh" bunx @deepseek-ai/dsh plugin --profile web update
  ```
  This won't move `dsh-provider-model-configurator` past its pinned commit (see §3) — a git-commit dependency has no version range for `pnpm update` to bump.

---

## 3. The one plugin that needs a maintainer, not a user: `dsh-provider-model-configurator`

`setup-dsh.sh` installs it by **git commit hash**, not a registry version:
```
github:LiangYin233/dsh-provider-model-configurator#70f88112c7d92fadeb93e46f5dcb8b1f3ae6eba3
```
The script's own comment says it plainly: *"pinned to upstream commit 70f8811 — bump deliberately."* `bun update` never touches this — a commit-pinned git dependency isn't resolved by semver ranges at all, and neither `dshmarket` nor a plain re-run of `setup-dsh.sh` will move it forward. Upgrading it is a manual, deliberate maintainer action: find a newer commit on that fork, edit the hash in `setup-dsh.sh`, re-run setup.

---

## 4. The model catalog

Already documented — `bun run sync-models` (see the [Troubleshooting Matrix](troubleshooting.md) and the [Diagnostic Health Check](../README.md#-diagnostic-health-check)). Idempotent, safe to re-run anytime, and the one upgrade operation in this list that genuinely is low-risk.

---

## ⚠️ The real gotcha: re-running `setup-dsh.sh` is not safe for your customizations

The docs elsewhere call `setup-dsh.sh` "fully idempotent" (see [Troubleshooting](troubleshooting.md), the README's "Why DSH?" table) — true in the sense that running it twice lands you in the same clean state, **not** true in the sense that it preserves anything you've added since the first run. Verified directly in the script:

* `cordis.patch.yml` gets exactly **one** `.bak` copy taken before being unconditionally overwritten with the stock template (`setup-dsh.sh` lines 154–158) — no merge, no diff, no prompt. Any custom entries you've added by hand — a local on-prem provider under `llm-pi-ai` (per the [Going Local guide](customization.md)), a persona's MCP servers, a hand-tuned `agent-default-model` — are silently replaced on the next run.
* `.credentials.yaml` and `settings.yaml` are rewritten too, with **no backup at all**, and the script always re-prompts interactively for a fresh OpenRouter key — there's no "skip, I already have one configured" path (this is the exact gap [CR-004](../ChangeRequest/CR-004-credential-rotation.md) proposes closing).

**Practical rule**: don't re-run `setup-dsh.sh` on an already-customized workspace expecting it to just pick up a framework upgrade cleanly. If you do, immediately diff `cordis.patch.yml.bak` against the fresh `cordis.patch.yml` and manually restore what you added — the backup is there, but nothing restores it for you.

---

[← Back to README](../README.md)
