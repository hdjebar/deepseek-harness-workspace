# 🧪 Automated CI & Quality Gates

This repository is strictly validated by GitHub Actions ([`.github/workflows/ci.yml`](../.github/workflows/ci.yml)):

- 🛡️ **ShellCheck & Syntax Validation:** Rigorous style and syntax enforcement on all bash automation.
- 📦 **Frozen Lockfile Concurrency:** Verification of byte-exact dependencies using `bun install --frozen-lockfile`.
- 🔄 **Idempotent Model Syncing:** Validates that live catalog updates preserve patch integrity without duplication.
- 🩺 **Negative Diagnostic Tests:** Ensures error conditions and missing credentials fail loudly and predictably.
- 📜 **YAML Schema Validation:** Python `pyyaml` validation verifying provider and model block structures.

---

[← Back to README](../README.md)
