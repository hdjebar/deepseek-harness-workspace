# CR-008: Encrypted-at-rest credential option (age/sops)

**Status:** 🟡 Proposed — open for challenge
**Priority:** Low (bigger swing)
**Area:** `setup-dsh.sh`, `doctor.js`, security model

## Summary

DSH's "Zero-Plaintext Security" claim rests entirely on POSIX file permissions (`chmod 600` on `.credentials.yaml` inside a `chmod 700` directory) — the key itself sits in plaintext on disk, protected only by the OS's user/group access control. That's a real and reasonable baseline, but it doesn't protect against another process running as the same OS user (a compromised dependency, a malicious plugin, another misbehaving tool) reading the file directly. This CR proposes an *optional* encrypted-at-rest mode using an existing tool (`age` or `sops`) rather than DSH inventing its own crypto.

## Detail

### Problem
`chmod 600` restricts *which users* can read a file; it does nothing to restrict *which processes running as that user* can read it. Given DSH explicitly runs a plugin marketplace (`dshmarket`, `dsh-find-plugin` — third-party, community-installed code, per `docs/plugins.md`) alongside the credential store, the threat model of "a plugin reads `.credentials.yaml`" is not hypothetical — it's a natural consequence of the "everything is a plugin" architecture this project is built around. Today, nothing more than filesystem permissions stands between an installed plugin and the raw OpenRouter key.

### Proposed change (sketch, not a spec)
Add an **optional** `--encrypt-credentials` flag to `setup-dsh.sh` (default off, to keep the current zero-dependency path as-is for anyone who doesn't want the extra tool dependency):
- If set, and [`age`](https://github.com/FiloSottile/age) is available, encrypt `.credentials.yaml` with an age identity generated (or supplied) at setup time, storing the encrypted blob instead of plaintext.
- The runtime (wherever DSH's credential resolution actually reads the file — this touches `@deepseek-ai/dsh`'s own credential loading, not just this repo's scripts) would need to decrypt on read, which is the part most likely to require upstream changes outside this repo's control, since `doctor.js`'s own credential-parsing fallback (lines 84–98) already shows there's a real parser (`@deepseek-ai/dsh-credentials-local`) this repo doesn't own.
- `doctor.js` would report encryption status as an additional (not required) check.

### Scope
This CR is explicitly the least-scoped of the list — it depends on whether DSH's actual runtime (`@deepseek-ai/dsh`, an external package this repo bootstraps but doesn't own) can be made to decrypt credentials at load time. If that's not feasible without upstream changes, this CR should be rejected or radically narrowed (e.g., "encrypt at rest, decrypt to a tmpfs-backed plaintext copy at `bun run web` startup" as a workaround) rather than attempted as originally sketched.

### Open questions
- **Blocking question:** does `@deepseek-ai/dsh`'s credential loader support anything other than the plaintext YAML `refs` format `doctor.js`'s fallback parser already documents? If not, this CR is blocked on an upstream feature request, not something implementable purely within this repo.
- Is the actual gap here "the credential file is plaintext" or "the plugin marketplace has no sandboxing at all" — i.e., would plugin-level filesystem sandboxing (already gestured at in `docs/security.md`'s `workspace-write`/`read-only`/`danger-full-access` modes) close this gap more directly than credential encryption would? Worth deciding which problem is actually being solved before committing to either.

### Effort estimate
Unknown until the blocking question above is answered — potentially small (if the upstream loader already supports pluggable decryption) or not implementable at all within this repo alone (if it doesn't). This is the CR I'd most want challenged before any work starts.
