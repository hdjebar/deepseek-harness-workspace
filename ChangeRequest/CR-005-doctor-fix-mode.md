# CR-005: `bun run doctor --fix` for mechanical repairs

**Status:** 🟡 Proposed — open for challenge
**Priority:** Low
**Area:** `doctor.js`

## Summary

`doctor.js` is deliberately read-only today (its own header comment says so explicitly: "it reports; it never repairs, rewrites, or deletes anything"). Several of the things it detects have an unambiguous, mechanical fix — wrong file permissions, missing `package.json` script bindings — that currently require the user to either run the fix command it prints (e.g. `chmod 600 <path>`) or re-run `./setup-dsh.sh` entirely. This CR proposes an *opt-in* `--fix` flag for the subset of findings that are safe to auto-repair, while keeping the default behavior read-only.

## Detail

### Problem
Two concrete examples from the current checks:
- `checkPermissions()` (line 66) prints `... run: chmod 600 ${credPath}` when the credential file has the wrong mode — the fix is a single, unambiguous shell command the user then has to run manually.
- `checkWorkspace()` (line 203) prints `missing in package.json: ... — re-run ./setup-dsh.sh` when script bindings are missing — but re-running the *entire* setup script to fix a missing `package.json` key is disproportionate (and re-triggers plugin installs, model sync, etc., same overkill problem as CR-004).

### Proposed change
Add a `--fix` flag that, after running the normal read-only checks, offers (with a single y/N confirmation, listing exactly what it's about to change — same posture as `reset.sh`'s confirmation prompt) to apply only the subset of fixes that are:
- **Deterministic** — there's exactly one correct fix, not a judgment call.
- **Local** — no network calls, no reinstalling anything, no talking to OpenRouter.

Concretely, in scope for `--fix`:
- `chmod 600`/`chmod 700` corrections for the credential file/directory (mirrors what the tool already tells the user to type).
- Adding missing `package.json` script bindings (`web`, `cli`, `headless`, `sync-models`, `doctor`, `reset`) without touching anything else in the file.

Explicitly **not** in scope for `--fix` (stays "re-run `./setup-dsh.sh`" or "run `bun run sync-models`"):
- Missing `cordis.patch.yml` / missing OpenRouter provider block — reconstructing this from scratch isn't a single obvious fix without re-running setup.
- Missing/invalid credentials — that's CR-004's job, and involves user input `doctor.js` shouldn't be prompting for.
- Missing plugins — requires network installs, out of character for a diagnostic tool.

### Scope
This CR only concerns `doctor.js`'s own findings. If CR-004 (key rotation) ships, `--fix` should *not* attempt to touch credentials — that stays a deliberate, separate action.

### Open questions
- Does adding any write capability to `doctor.js` undermine the "it's the one tool you can always trust to be read-only" property that makes it safe to run freely (e.g. in CI, as the negative tests in `.github/workflows/ci.yml` already do)? This is the strongest argument *against* this CR as proposed — an opt-in flag preserves the default, but "doctor never writes" is a simple, valuable invariant to give up even partially. Worth deciding explicitly rather than assuming `--fix` is obviously fine.
- Alternative that avoids the invariant question entirely: keep `doctor.js` fully read-only, and instead have it print copy-pasteable exact commands (it already does this for the `chmod` case) rather than an auto-fix flag. This CR should be weighed against just doing that more consistently, which is much lower risk.

### Effort estimate
Small for the two fixes described, but the open question above is worth resolving before writing code — this may end up rejected in favor of the "print better commands" alternative.
