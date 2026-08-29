# Contributing to DSH

This repo is a bootstrap/config layer around `@deepseek-ai/dsh` — most of what looks like "DSH's behavior" actually lives in that external package family, not in this repo's own code. That distinction is the source of most documentation bugs this project has had, and it's the first thing this guide is about.

---

## Before writing or changing docs: verify, don't assume

Nearly every doc fix landed in this repo so far was found by checking a claim against the actual installed/published package rather than trusting an existing doc, a plausible-sounding default, or "how similar tools usually work." Concrete examples from this repo's own history:

- Every doc claimed custom skills live in `./skills/<name>/SKILL.md`. The real discovery roots — verified by pulling the exact pinned `@deepseek-ai/dsh-skill-filesystem` package and reading its own README — are `<project>/.dsh/skills`, `<project>/.agents/skills`, and `<DSH_HOME>/skills`. `./skills/` was never a real root; nobody had checked.
- Docs claimed plugin upgrades were GUI-only. The core `@deepseek-ai/dsh` package's own README states `dsh plugin --profile <name> <pnpm args>` forwards straight to `pnpm`, so `update` works exactly like `add` does.
- The README's sample `doctor` output didn't match `doctor.js`'s actual `pass()`/`warn()` calls at all — it had a line no code path prints, and a plugin count that didn't match `EXPECTED_PLUGINS`'s real length.

**The method, concretely:**

1. Find the exact version this repo has pinned — check `bun.lock`, not `package.json`'s caret range (which only gives a floor).
2. `npm view <package>@<exact-version> dist-tags --json` — don't assume `latest` is what's actually in use. Checked across a dozen `@deepseek-ai/dsh-*` sub-packages, most have a `latest` tag that lags behind `next`, which is what's usually actually pinned. Blindly trusting `latest` will point you at stale or even older behavior.
3. `npm pack <package>@<exact-version>` and read the real `README.md`/source inside the tarball, rather than reasoning from a doc that might itself be stale.
4. For runtime behavior (not just static config), actually run it — in a scratch directory (`/tmp/...`, never this repo's own tree), not just reasoned about. `bin/dsh-upgrade.js` was validated this way: a throwaway `bun install` of the exact pinned `@deepseek-ai/dsh` version, then genuinely executing the script against fabricated fixture states (no profile, one profile, a failing step) rather than trusting the code read correctly.

If a claim about `@deepseek-ai/dsh` internals can't be verified this way in the time available, say so in the doc rather than asserting it — "unverified, treat as unconfirmed" is more useful to the next reader than a confident guess.

---

## CI gates — what actually has to pass

`.github/workflows/ci.yml` runs one job against every push/PR. Know these before you touch `setup-dsh.sh`, `reset.sh`, `sync-models.js`, or `doctor.js`:

- **`bash -n setup-dsh.sh reset.sh`** — syntax only. Trivial to pass, easy to forget to check locally before pushing.
- **`shellcheck --severity=style --exclude=SC2088 setup-dsh.sh reset.sh`** — SC2088 (quoted-tilde warnings) is deliberately excluded because both scripts do intentional literal string comparisons against `"~/.dsh"` (matching a marker file's raw content, not doing shell tilde expansion). Removing those comparisons to silence a shellcheck warning that's already excluded is exactly the mistake that caused a real regression in this repo's history — don't "fix" what isn't broken.
- **The embedded `sync-models.js` inside `setup-dsh.sh` must byte-for-byte match the standalone `sync-models.js` file.** CI extracts the heredoc block from `setup-dsh.sh` and diffs it against the real file. If you edit one, edit the other identically — there is no build step that generates one from the other.
- **`bun install --frozen-lockfile`** — `bun.lock` must already be in sync with `package.json` before you push. If you ran `bun update`/`bun add`, commit the regenerated lockfile in the same change (see [docs/upgrading.md](docs/upgrading.md)).
- **`sync-models.js` smoke tests**: a fresh run must produce a valid patch, a re-run must be byte-identical (idempotency), and removing the `# Route default model` comment / `- id: agent-default-model` anchor must make it fail loudly rather than silently. If you touch the anchor-matching logic, keep both those exact strings intact or update the test fixture that greps for them.
- **`doctor.js` negative tests**: it must exit non-zero with no credentials present, and the fatal-permission-check message must contain the literal substring `"fatal: must be 0600"`, with the passing case containing `"mode 0600"`. CI greps for those exact strings — don't reword them without checking `.github/workflows/ci.yml`.
- **Generated `cordis.patch.yml` must stay valid YAML** with at least 5 top-level entries and an `openrouter` provider block — checked with `pyyaml` in CI.

Run what you can locally before pushing: `bash -n`, `shellcheck` if installed, and manually exercising the script path you changed in a scratch directory (per the verification method above) beats finding out from a red CI run.

---

## Changing `reset.sh` or `setup-dsh.sh`'s target-resolution logic — extra caution

This is the highest-risk code in the repo. Its target/marker/precedence logic (`--dir` → `--global` → `$DSH_HOME` → `.dsh-target` marker → local `./.dsh`) has regressed more than once in this repo's history — most recently a shellcheck-motivated edit that silently broke recognition of a marker format and introduced a false-positive match, found only by manual review because nothing in CI exercises that logic directly (see [ChangeRequest/CR-001](ChangeRequest/CR-001-reset-test-suite.md)).

If you're changing this logic:
- Trace every branch by hand against the fixture table in CR-001 before pushing, not just the case you're fixing.
- Prefer writing a [Change Request](#proposing-larger-changes-the-changerequest-folder) first if the change is non-trivial, so the resolution logic gets a second pair of eyes before it's live — `reset.sh` deletes things.
- A "simplification" or "cleanup" of this logic is exactly the kind of change that has broken it before. Extra scrutiny, not less, for anything that looks obviously safe here.

---

## Documentation conventions

- **State the local/global (and `--dir`) path together, local first**, e.g. `./.dsh/cordis.patch.yml` by default, or `~/.dsh/cordis.patch.yml` with `--global`. Several docs stated only `~/.dsh` as if it were the default when it isn't — local is DSH's actual default.
- **Every `docs/*.md` page ends with `[← Back to README](../README.md)`** and gets a row in the README's Documentation table when added.
- **Avoid linking to a markdown heading anchor when the heading starts with an emoji.** GitHub's anchor-slug behavior around emoji-adjacent whitespace is inconsistent and easy to get wrong (a heading like `## 8. 🏠 Going Local: ...` produces a slug with an unintuitive double-hyphen). Link the file plainly, or name the section in prose (`the Customization Guide, §4`), instead of guessing a fragment.
- Prefer fixing a doc inaccuracy directly over leaving a TODO — this repo's history shows small, verified fixes landing continuously beats a backlog of known-wrong docs.

---

## Proposing larger changes: the `ChangeRequest/` folder

[`ChangeRequest/`](ChangeRequest/README.md) tracks proposed-but-not-implemented work — a lightweight RFC. Use it for anything that:
- changes behavior of `reset.sh` or `setup-dsh.sh` beyond an obvious bug fix,
- is speculative or needs a design decision before it's worth building (see CR-007, CR-008 for examples of appropriately-scoped-down speculative proposals), or
- you want feedback on before investing implementation time.

Each CR is a `Summary` (one paragraph) + `Detail` (problem, proposed change, scope, and explicit **open questions** meant to be challenged) + a priority + a status (`🟡 Proposed` → `🔵 Under discussion` → `🟢 Accepted`/`⚪ Rejected` → `✅ Implemented`). Small, obviously-correct fixes (a typo, a stale path, a doc that doesn't match the code) don't need a CR — just fix them.

---

## Commit messages

This repo's history favors commit messages that explain **why**, not just what changed — what was wrong, how it was verified, what the fix actually does differently. A one-line "fix docs" commit is much less useful to the next person than one that names the specific claim that was wrong and how you confirmed the correction. Look at recent history (`git log`) for the house style before writing yours.

---

[← Back to README](README.md)
