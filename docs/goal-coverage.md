# Goal Coverage

This document estimates how much of the README goal is currently covered by the repository.

This is not code coverage. It is a qualitative product and operations coverage estimate based on the stated goal:

```text
Create a personal, local, inspectable AI environment that is easy to bootstrap, secure by default, and portable across web, TUI, and headless workflows.
```

## Current Estimate

Estimated goal coverage: **83%**

## Coverage Breakdown

| Goal Area | Estimated Coverage | Evidence / Facts / Findings | Notes |
| :--- | ---: | :--- | :--- |
| One-command bootstrap | 88% | `setup-dsh.sh` installs dependencies, writes config, validates the key, provisions profiles, writes scripts, copies wrapper files into fresh workspaces, and runs model sync. A fresh-folder install initially exposed missing wrapper provisioning; that is now fixed. | Covers the main bootstrap path, but still depends on live network and external package availability. |
| Local isolated workspace | 92% | Default target is `$PWD/.dsh`; `.dsh-target`, `.dsh/`, `node_modules/`, credentials, and env files are ignored by Git. Manual test confirmed isolated folder install succeeds after fixes. | Strong default for independent workspaces. |
| OpenRouter gateway setup | 90% | Installer validates the OpenRouter key before writing config, writes `llm-pi-ai` OpenRouter provider config, routes `agent-default-model`, and syncs the live catalog. | Good coverage, but live API availability remains an operational dependency. |
| Free search provider setup | 80% | `cordis.patch.yml` disables DeepSeek search, sets `searchProvider: modsearch`, and installs `@liustack/modsearch` in web and headless profiles. | Configured by default, but deeper runtime search behavior is not tested in CI. |
| Credential protection | 88% | Installer writes `.dsh/.credentials.yaml`, applies `chmod 600`, applies `chmod 700` to the DSH directory, and `doctor.js` checks fatal credential permissions. Setup now also creates Git ignore rules before writing secrets in fresh workspaces. | Good POSIX protection; pasted or externally leaked keys still require rotation outside the repo. |
| Web, TUI, and headless interfaces | 80% | `package.json` exposes `web`, `cli`, and `headless`; wrappers exist under `bin/`. Process tests confirmed `bun run web` starts a listener on `127.0.0.1:3080`. | Basic paths exist; TUI backend detection only checks that a URL responds. |
| Plugin/profile provisioning | 75% | Installer creates `web` and `headless` profiles and installs expected plugins. `doctor.js` checks `6/6` web plugins and `2/2` headless plugins. Plugin install logs show peer warnings. | Functional, but expected peer warnings and custom profile behavior need stronger validation. |
| Model sync | 85% | `sync-models.js` fetches OpenRouter models, injects them into `cordis.patch.yml`, and CI checks fresh run, rerun idempotency, missing-anchor failure, and YAML validity. | Good behavior coverage, but CI uses the live OpenRouter API and can fail nondeterministically. |
| Reset and upgrade operations | 75% | `reset.sh` and `bun run upgrade` exist and are documented. Manual reset removed runtime files, but one test showed DSH processes remained alive after reset reported success. | Commands exist; reset should verify process/port cleanup after signaling. |
| Golden template and multi-workspace operations | 92% | `create-dsh-template.sh` creates a secret-free template with vanilla `.dsh` placeholders. Validated in CI test suite. | Workflow is scripted, documented, and validated in CI. |
| CI validation | 75% | GitHub Actions runs bash syntax, ShellCheck, frozen Bun install, embedded sync diff, sync smoke tests, doctor negative tests, permission checks, template generator validation, and YAML validation. | Covers operational workflows, sync idempotency, permission gates, and template creation. |

## Main Gaps

- CI model-sync tests depend on live OpenRouter responses, which can create nondeterministic failures.
- `reset.sh` can report process termination success even if a DSH process remains alive in some environments.
- No line, branch, function, or integration coverage report is generated.
- Shared-config write-conflict behavior is documented, but there is no locking or guardrail for simultaneous writers.
- Plugin peer-dependency warnings are accepted operationally, but not classified in CI as expected vs unexpected.

## Resolved Findings

- Fresh-folder installs initially failed because generated `sync-models.js` imported `./bin/resolve-dsh.js`, but `setup-dsh.sh` did not copy the `bin/` helpers into a new workspace. Setup now provisions the required wrapper files.
- `.dsh-target` was generated local routing state but was not ignored by Git. It is now ignored.
- Fresh installs initialized a Git repository before writing credentials, but did not guarantee ignore rules existed first. Setup now ensures runtime and credential ignore rules are present before writing secrets.
- Golden-template creation was previously a manual convention. It is now scripted with `create-dsh-template.sh` and exposed through `bun run create-template`.
- `create-dsh-template.sh` is now validated automatically in GitHub Actions CI.
- Template usage for isolated workspaces is now documented in the README and Standard Operations guide.

## Suggested Next Milestones

To raise goal coverage toward 90%:

1. Add deterministic CI fixtures for `sync-models.js` instead of relying only on the live OpenRouter API.
2. Add reset verification that checks the target port after signaling processes and warns or fails if it is still occupied.
3. Add shell test coverage for setup target resolution: default local, `--global`, `--dir`, and inherited `DSH_HOME`.
4. Add a lightweight coverage or smoke-test summary command that reports operational coverage explicitly.

## Interpretation

At 83%, the repository covers the practical user journey: bootstrap, configure, run, diagnose, reset, upgrade, create isolated workspaces, and generate a vanilla template. The remaining work is mostly about rigor: deterministic tests, stronger process cleanup, CI-backed template validation, and clearer handling of shared mutable config.

---

[Back to README](../README.md)
