# CR-001: Test suite for `reset.sh`'s marker/safety logic

**Status:** 🟡 Proposed — open for challenge
**Priority:** High
**Area:** `reset.sh`, `.github/workflows/ci.yml`

## Summary

`reset.sh` decides — from a `.dsh-target` marker file and `$USER_HOME` — whether a plain `./reset.sh` is safe to run, or whether it would delete the user's real global credential store. That logic has regressed at least twice in this repo's own commit history, most recently a shellcheck-motivated edit that silently broke recognition of tilde-form markers and introduced a false-positive substring match (fixed earlier in this branch's history). CI currently only runs `shellcheck` and a syntax check (`bash -n`) against `reset.sh` — it never exercises the marker-classification or safety-abort logic itself. This CR proposes a small test suite that does.

## Detail

### Problem
The relevant logic in `reset.sh` — `IS_GLOBAL_MARKER` classification (line ~55), the dangerous-target abort list (line ~96), and the sentinel verification (line ~102) — is exactly the kind of code where a "should be equivalent" refactor silently changes behavior, because the failure mode (over-broad or under-broad matching) only shows up as a data-loss bug, not a crash. Nothing in CI would have caught the regression fixed earlier in this repo's history; it was found by manual code review, not by a test failing.

### Proposed change
Add a test step to `.github/workflows/ci.yml` (or a separate `test-reset.sh` invoked from it) that sources or exercises `reset.sh`'s logic against fixture cases, asserting the expected `IS_GLOBAL_MARKER` / abort / no-abort outcome for each. At minimum:

| Fixture | `.dsh-target` content | `$USER_HOME` | Expected outcome |
| :--- | :--- | :--- | :--- |
| Global keyword | `global` | `/home/user` | Classified global — local routing only, real store preserved |
| Global tilde form | `~/.dsh` | `/home/user` | Classified global (this is the exact case that regressed) |
| Global absolute form | `/home/user/.dsh` | `/home/user` | Classified global |
| Unrelated path with matching suffix | `/mnt/backup/home/user/.dsh` | `/home/user` | **Not** classified global (this is the exact false-positive that regressed) |
| Local relative marker | `./.dsh` | `/home/user` | Local mode, not global |
| Target = `$USER_HOME` itself | n/a | `/home/user`, `TARGET_DSH=/home/user` | Safety-abort triggered |
| Target = `/` | n/a | any | Safety-abort triggered |
| Non-DSH directory (no sentinel files) | n/a | target dir has no `cordis.patch.yml`/`.credentials.yaml`/etc. | Safety-abort triggered |
| `HOME` unset | n/a | `HOME` unset | `USER_HOME` resolves via `cd ~`, not `$PWD` |

A shell test framework isn't required — a short bash script that sets up temp directories, sources the relevant variable-computation logic (or runs `reset.sh --force` against fixtures in a throwaway `$PWD` and inspects what would be deleted, without actually confirming), and asserts on stdout/exit behavior would do. `bats-core` is a reasonable off-the-shelf option if a heavier framework is preferred.

### Scope
- In scope: the marker-classification, safety-abort, and sentinel-verification logic specifically — the parts responsible for deciding *what* gets deleted.
- Out of scope: process-kill logic (`is_dsh_process`, `kill_pid_safely`) — lower risk (worst case is killing the wrong process, not deleting the wrong directory), and harder to fixture in CI without real running processes.

### Open questions
- Fixture via sourcing the script's variable-computation section directly (fast, but couples the test to internal line ranges) vs. running the real script end-to-end against a throwaway directory tree with `--force` and diffing what exists before/after (slower, more realistic, more CI setup)? Leaning toward the latter for fidelity, but it's slower and needs care to never point at a real path.
- Should this suite also cover `setup-dsh.sh`'s `.dsh-target`-writing logic (the producer side), or only `reset.sh`'s reading side? Testing both closes the loop but doubles the fixture surface.

### Effort estimate
Small — a few hours. The fixture table above is close to a complete test plan already.
