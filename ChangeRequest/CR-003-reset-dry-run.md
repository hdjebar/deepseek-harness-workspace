# CR-003: `--dry-run` mode for `reset.sh`

**Status:** 🟡 Proposed — open for challenge
**Priority:** Medium
**Area:** `reset.sh`

## Summary

`reset.sh` is destructive by design and has already had two safety regressions in this repo's history (see CR-001). Right now the only way to see what it *would* do is to read the confirmation prompt's summary (which is a high-level description, not an exact file list) or read the script. This CR proposes a `--dry-run` flag that prints exactly what would be deleted — target directory contents, processes that would be killed, marker file handling — without deleting anything, confirming, or touching a running process.

## Detail

### Problem
The current confirmation prompt (lines ~121–139 of `reset.sh`) tells the user *which mode* it's operating in (`local` vs a specific `${REAL_TARGET}` path) and lists the *categories* of action ("Wipe target configuration store", "Purge local workspace artifacts"), but not the actual resolved paths and files about to be `rm -rf`'d, nor which specific PIDs would be killed. Given the target-resolution logic is exactly what has had bugs before, a user who wants to double-check *before* typing `y` currently has no way to do that short of reading the script's variable state themselves.

### Proposed change
Add `--dry-run`/`-n` as a new flag alongside `--force`/`--global`/`--dir`. When set:
- Run all the same resolution and safety-check logic (marker parsing, `IS_GLOBAL_MARKER`, safety-abort, sentinel verification) — a dry run should still refuse to proceed against a dangerous or non-DSH target, since that's diagnostic information worth surfacing too.
- Instead of the confirmation prompt and the destructive steps (process kill, `rm -rf`), print:
  - The exact resolved `${REAL_TARGET}` path and whether it's local or global mode.
  - The list of PIDs on the target port that *would* be killed (from the same `lsof` lookup, without calling `kill_pid_safely`).
  - The exact paths that would be `rm -rf`'d (`${REAL_TARGET}`, and in local mode: `node_modules`, `.dsh`, `*.log`, `$TARGET_MARKER`).
- Exit 0 without prompting, without killing anything, without deleting anything.

### Scope
- In scope: `reset.sh` only — a read-only preview mode over its existing resolution logic.
- Out of scope: a `--dry-run` for `setup-dsh.sh` (setup is largely additive/idempotent already, lower risk; could be a separate CR if wanted).

### Open questions
- Should `--dry-run` combined with `--force` be an error (the two are semantically contradictory — force skips confirmation, dry-run never reaches confirmation) or should `--force` just be ignored under `--dry-run`? Leaning toward ignored-with-a-notice, to avoid punishing `--dry-run --force` used defensively in a script.
- Worth having `bun run reset -- --dry-run` be documented as the recommended first step in `docs/reset.md`, given the history here? I'd say yes once this exists.

### Effort estimate
Small — mostly restructuring existing print statements and gating the destructive calls behind a flag check; no new resolution logic needed.
