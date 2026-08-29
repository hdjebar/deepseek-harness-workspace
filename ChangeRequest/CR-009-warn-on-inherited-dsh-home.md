# CR-009: Warn when `$DSH_HOME` overrides the local/marker target

**Status:** 🟡 Proposed — open for challenge
**Priority:** High
**Area:** `reset.sh`, `setup-dsh.sh`

## Summary

Both `reset.sh` and `setup-dsh.sh` resolve their target directory as `${DSH_HOME:-$PWD/.dsh}` — an inherited `DSH_HOME` environment variable silently overrides the "local by default" behavior, and in `reset.sh` it outranks even the `.dsh-target` marker file (documented precedence: `--dir → --global → DSH_HOME → .dsh-target marker → local`). A user with `DSH_HOME` left over in their shell from a previous `--global` test, a wrapper script, or an inherited CI variable can run a bare `./reset.sh` in an unrelated project expecting it to touch only that project's local `.dsh`, and instead silently wipe whatever `DSH_HOME` points to. This CR proposes making that divergence loud instead of quiet.

## Detail

### Problem
Neither script currently distinguishes, in its output, between "this is the local default because nothing else was configured" and "this is `$DSH_HOME`, inherited from your shell environment, and it happens to differ from what's in this directory." Both just print the resolved path (`📁 DSH Configuration Target: ...` in `setup-dsh.sh`; the `⚠️ WARNING:` block listing `${REAL_TARGET}` in `reset.sh`) with no indication of *why* that path was chosen. A user skimming the output — especially under `--force`/non-interactive use, or muscle-memory-typing `./reset.sh` in a new terminal tab that happens to have inherited `DSH_HOME` from an earlier `--global` experiment — has no signal that this run isn't behaving the way "local by default" is documented to behave.

This is the same failure shape as the two `IS_GLOBAL_MARKER` regressions already found and fixed in this repo's history (see CR-001): a case where the *resolved* outcome (which directory gets deleted) depends on state the user doesn't have front-of-mind, and the tooling doesn't call that out.

### Proposed change
In both scripts, when `DSH_HOME` is set in the environment **and** no explicit `--dir`/`--global` flag was passed **and** the resolved target differs from what the local default (`$PWD/.dsh`) would have been:
- Print an explicit line before the normal target-resolution output, e.g.:
  ```
  ℹ️  Using $DSH_HOME from your environment: /some/other/dir
     (No --global or --dir flag was passed; without $DSH_HOME set, this would default to ./.dsh here.)
  ```
- In `reset.sh` specifically, since this is the destructive path: consider requiring `--force` to be paired with an explicit acknowledgment when this divergence is detected non-interactively, OR at minimum make the existing confirmation prompt state the divergence explicitly rather than just the resolved path — so a human confirming interactively actually sees "this is coming from your environment, not this directory" before typing `y`.

### Scope
- In scope: detection and messaging only. This does not propose changing the precedence order itself (`DSH_HOME` outranking the marker is presumably intentional — it lets a user force a specific target without editing files — just currently invisible when it happens).
- Out of scope: removing `DSH_HOME` support, or changing what takes precedence over what.

### Open questions
- Should `setup-dsh.sh` get the same treatment as `reset.sh`, given it's additive/idempotent (lower risk than deletion), or is this worth prioritizing for `reset.sh` only given the destructive-operation asymmetry? Leaning toward both, since a *setup* run silently targeting the wrong directory is confusing even if not destructive — but `reset.sh` is the one that actually needs to block on it.
- Exact detection logic: "no explicit flag was passed" is easy to check (flag parsing already tracks this); "differs from what local default would have been" requires computing the counterfactual `$PWD/.dsh` path purely for comparison, which is cheap but is new code in a script whose destructive-path logic this repo has already had trouble keeping correct (see CR-001) — any change here should ship with the CR-001 test suite covering it, not before.

### Effort estimate
Small, contingent on CR-001 landing first (or alongside) so this addition is covered by tests rather than reviewed by eye alone, given the track record of this exact class of logic.
