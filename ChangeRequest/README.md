# Change Requests

This folder tracks **proposed** improvements to DSH — things worth doing, not yet decided or scheduled. Each CR is a self-contained pitch: a short **Summary** for a quick read, and a **Detail** section with the problem, proposed change, scope, and open questions for whoever reviews it to push back on.

**Nothing here is implemented.** A CR describes a change to make, not a change that's been made. Status moves as a CR gets reviewed:

| Status | Meaning |
| :--- | :--- |
| 🟡 Proposed | Written up, not yet reviewed or challenged |
| 🔵 Under discussion | Being reviewed; open questions being resolved |
| 🟢 Accepted | Agreed on; ready to implement |
| ⚪ Rejected | Considered and declined (reason recorded in the CR) |
| ✅ Implemented | Done — link to the commit/PR |

## Index

| ID | Title | Priority | Area | Status |
| :--- | :--- | :--- | :--- | :--- |
| [CR-001](CR-001-reset-test-suite.md) | Test suite for `reset.sh`'s marker/safety logic | High | `reset.sh`, CI | 🟡 Proposed |
| [CR-002](CR-002-doctor-windows-acl-check.md) | Real Windows ACL check in `doctor.js` (replace the no-op) | Medium | `doctor.js` | 🟡 Proposed |
| [CR-003](CR-003-reset-dry-run.md) | `--dry-run` mode for `reset.sh` | Medium | `reset.sh` | 🟡 Proposed |
| [CR-004](CR-004-credential-rotation.md) | Credential rotation without a full reset | Medium | `setup-dsh.sh` | 🟡 Proposed |
| [CR-005](CR-005-doctor-fix-mode.md) | `bun run doctor --fix` for mechanical repairs | Low | `doctor.js` | 🟡 Proposed |
| [CR-006](CR-006-doctor-usage-visibility.md) | Spend/usage visibility in `doctor.js` | Low | `doctor.js`, `sync-models.js` | 🟡 Proposed |
| [CR-007](CR-007-cost-aware-model-router.md) | Cost-aware default-model routing | Low (bigger swing) | `cordis.patch.yml`, `sync-models.js` | 🟡 Proposed |
| [CR-008](CR-008-encrypted-credentials.md) | Encrypted-at-rest credential option (age/sops) | Low (bigger swing) | `setup-dsh.sh`, security model | 🟡 Proposed |
| [CR-009](CR-009-warn-on-inherited-dsh-home.md) | Warn when `$DSH_HOME` overrides the local/marker target | High | `reset.sh`, `setup-dsh.sh` | 🟡 Proposed |
| [CR-010](CR-010-preserve-customizations-on-setup-rerun.md) | Preserve custom `cordis.patch.yml` entries across `setup-dsh.sh` re-runs | Medium | `setup-dsh.sh` | 🟡 Proposed |

Ordered roughly by leverage, not by number — CR-001 and CR-009 are the two I'd push back on hardest if someone wanted to skip them: both are about `reset.sh` silently deleting the wrong thing (a marker-classification bug and an inherited-env-var override, respectively), and both are classes of bug that have already bitten this repo, not hypothetical ones.

---

[← Back to README](../README.md)
