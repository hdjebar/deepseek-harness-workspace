# CR-004: Credential rotation without a full reset

**Status:** 🟡 Proposed — open for challenge
**Priority:** Medium
**Area:** `setup-dsh.sh`

## Summary

There is currently no way to update the stored OpenRouter API key (e.g. after rotating it at openrouter.ai, or switching accounts) without wiping and re-running the entire setup via `reset.sh` + `./setup-dsh.sh`, which also discards the synced model catalog, plugin installs, and any manual `cordis.patch.yml` edits. This CR proposes a narrower `--update-key` path that only touches the credential.

## Detail

### Problem
`setup-dsh.sh`'s API-key capture (lines 82–115: masked `read -rsp`, prefix validation, live validation against `https://openrouter.ai/api/v1/auth/key`) only runs as part of the full bootstrap flow, which then goes on to reinstall plugins, regenerate `cordis.patch.yml` from scratch (overwriting any manual edits, though it does back up the previous file to `cordis.patch.yml.bak`), and re-sync the model catalog. A user who just needs to swap a revoked or rotated key has no lighter-weight path — `docs/troubleshooting.md`'s own guidance for `HTTP 401 Unauthorized` is "re-run `./setup-dsh.sh` with a valid key," i.e., the full flow.

### Proposed change
Add a `--update-key` (or `--rotate-key`) flag to `setup-dsh.sh` that:
1. Resolves the existing target directory the same way the rest of the script does (respecting `--global`/`--dir`/`.dsh-target`, same precedence as today).
2. Runs only the masked-input + prefix-validation + live-validation steps (reusing the existing logic at lines 82–115 verbatim).
3. On success, rewrites only the `OPENROUTER_API_KEY` ref inside `.credentials.yaml` (preserving file permissions, `chmod 600` already enforced) and exits — skipping plugin installation, `cordis.patch.yml` regeneration, and model sync entirely.
4. On failure (invalid/rejected key), leaves the existing credential file untouched, matching the existing script's "fail before writing anything" behavior for the main flow.

### Scope
- In scope: the credential file only.
- Out of scope: rotating *other* stored secrets — today there's only the one (`OPENROUTER_API_KEY`); if `docs/customization.md`'s "Going Local" pattern is followed and a second provider's key is added (e.g. `OLLAMA_API_KEY`), this CR's flag would need a `--key-name` parameter to target the right ref, or a follow-up CR would generalize it. Scoping this CR to the single-key case for now.

### Open questions
- Should `--update-key` require the target to already look like a valid DSH install (same sentinel check `reset.sh` uses), so it can't be run against an empty directory and silently do nothing useful? Seems right — reuse that check rather than inventing a new one.
- Is `doctor.js` the better home for this instead of `setup-dsh.sh` — e.g. `bun run doctor --update-key`? `doctor.js` is documented as strictly read-only today ("it reports; it never repairs, rewrites, or deletes anything" — see its own header comment), so adding a write path there would break that contract. Putting it in `setup-dsh.sh` (which already writes credentials) keeps the read-only/write-capable split clean.

### Effort estimate
Small — largely re-uses existing validated-input code; the new part is a narrower write path and target-resolution reuse.
