# CR-010: Preserve custom `cordis.patch.yml` entries across `setup-dsh.sh` re-runs

**Status:** 🟡 Proposed — open for challenge
**Priority:** Medium
**Area:** `setup-dsh.sh`

## Summary

`setup-dsh.sh` unconditionally overwrites `cordis.patch.yml` with its stock template on every run (taking one `.bak` copy first, but never merging), and rewrites `.credentials.yaml`/`settings.yaml` with no backup at all. This makes any hand-added customization — a local on-prem provider, a persona's MCP servers, a custom `agent-default-model` — silently disappear the next time `setup-dsh.sh` is re-run, e.g. to pick up a framework upgrade. Discovered while documenting [docs/upgrading.md](../docs/upgrading.md); this CR proposes the fix.

## Detail

### Problem
`setup-dsh.sh` lines 154–158:
```bash
if [ -f "${DSH_DIR}/cordis.patch.yml" ]; then
    cp "${DSH_DIR}/cordis.patch.yml" "${DSH_DIR}/cordis.patch.yml.bak"
fi
echo "✍️ Writing verified configuration patch layer to ${DSH_DIR}/cordis.patch.yml..."
cat << 'EOF' > "${DSH_DIR}/cordis.patch.yml"
...
```
The `.bak` is written but never read back or diffed against — it's purely a manual-recovery artifact the user has to know to look for. `.credentials.yaml` and `settings.yaml` (lines 238–255) don't even get that; they're rewritten from scratch every time, and the script always re-prompts for a fresh OpenRouter key interactively (no "already configured, skip" path — see [CR-004](CR-004-credential-rotation.md), which this CR complements rather than duplicates: CR-004 is about *rotating* a key on purpose, this one is about *not destroying everything else* when you didn't mean to).

This directly contradicts the "fully idempotent" framing used elsewhere in this repo's own docs (`docs/troubleshooting.md`, the README's "Why DSH?" table) — idempotent in the sense of "converges to the same state," not in the sense a user would reasonably assume ("safe to re-run without losing my changes").

### Proposed change
On a re-run where `cordis.patch.yml` already exists and differs from the stock template in ways beyond what the script itself would generate (i.e., contains entries the script didn't just write — additional `id:` blocks, extra `providers` under `llm-pi-ai`, etc.):
1. Detect the divergence (diff the existing file's entries against the freshly-generated template's entries by `id:`).
2. Preserve any `id:` blocks present in the existing file but not in the fresh template, appending them to the newly-generated file rather than discarding them.
3. For `id:` blocks that exist in both (e.g. `llm-pi-ai`, `agent-default-model`), keep the existing file's `config:` if it differs from the template's default rather than clobbering a hand-tuned value — this is the trickier part, since it means merging rather than just union-by-id.
4. Print an explicit summary of what was preserved vs. regenerated, so the user isn't left guessing.

A simpler, lower-effort first step: skip regeneration entirely if `cordis.patch.yml` already exists and passes the same sentinel check `reset.sh` uses (i.e., it looks like a real, already-customized DSH install) — print a message pointing at `.bak` recovery instead of silently overwriting. This trades "setup-dsh.sh always produces a known-good file" for "setup-dsh.sh doesn't destroy customizations by default," which may be the better default for a script whose primary re-run motivation (per `docs/upgrading.md`) is picking up a framework version bump, not resetting config.

### Scope
- In scope: `cordis.patch.yml` specifically, since it's the file customizations actually accumulate in (per the Customization Guide and Persona guide).
- Out of scope: `.credentials.yaml`/`settings.yaml` — those are simple enough (one key, one model route) that CR-004's rotation flow is a better fit than a merge strategy here.

### Open questions
- Full merge (preserve hand-tuned `config:` values) vs. the simpler "don't touch it if it already looks customized, point at `.bak`" approach — the simpler version is much lower risk to implement correctly and matches this repo's general caution around touching `cordis.patch.yml`/`reset.sh`-adjacent logic (see CR-001). I'd start there.
- How does this interact with `sync-models.js`, which *does* need to rewrite the `openrouter:` provider block on every sync (that's its whole job)? Whatever preservation logic lands here needs to not conflict with that — `sync-models.js`'s own anchor-based replacement (`# Route default model` comment) is a narrower, already-working example of "modify one block, leave the rest," worth reusing the same approach rather than inventing a second one.

### Effort estimate
Medium — the "don't overwrite if already customized" version is small; the "merge intelligently" version is larger and needs care given this file's history of regressions when touched carelessly.
