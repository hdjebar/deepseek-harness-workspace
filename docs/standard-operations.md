# Standard Operations

This guide defines the normal operating patterns for DSH workspaces.

## Core Rule

`cd` controls the runnable workspace. `--dir` controls only the DSH configuration directory.

The runnable workspace is where these files live:

```text
package.json
bun.lock
bin/
sync-models.js
doctor.js
reset.sh
node_modules/
```

The DSH configuration directory is where runtime state lives:

```text
.dsh/
  cordis.patch.yml
  settings.yaml
  .credentials.yaml
  profiles/
```

## Self-Contained Workspace

Use this for independent projects. Each workspace gets its own local `.dsh` config.

```bash
mkdir dsh-work-a
cd dsh-work-a
../setup-dsh.sh
bun run doctor
bun run web
```

Create another independent workspace the same way:

```bash
cd ..
mkdir dsh-work-b
cd dsh-work-b
../setup-dsh.sh
```

Run simultaneous workspaces with different ports:

```bash
cd dsh-work-a
DSH_PORT=3080 bun run web
```

```bash
cd dsh-work-b
DSH_PORT=3081 bun run web
```

Use this pattern by default.

## Shared Config

Use `--dir` when multiple runnable workspaces should share one DSH config store.

```bash
mkdir dsh-work-a
cd dsh-work-a
../setup-dsh.sh --dir ../shared-dsh-config
```

```bash
cd ..
mkdir dsh-work-b
cd dsh-work-b
../setup-dsh.sh --dir ../shared-dsh-config
```

Both workspaces now read and write:

```text
shared-dsh-config/
```

Shared state includes credentials, `settings.yaml`, `cordis.patch.yml`, profiles, plugins, and synced OpenRouter models.

Avoid running independent active sessions against the same shared config unless shared writes are intentional.

## Golden Template

Use a golden template when you want repeatable independent workspaces with the same starting files.

Create a vanilla secret-free template:

```bash
./create-dsh-template.sh dsh-template
# or
bun run create-template -- dsh-template
```

The script creates the runnable files and empty placeholder config files. It does not write credentials, install dependencies, or create `.dsh-target`.

Template contents:

```text
dsh-template/
  package.json
  bun.lock
  setup-dsh.sh
  bin/
  sync-models.js
  doctor.js
  reset.sh
  .gitignore
  .dsh/
    cordis.patch.yml
    settings.yaml
    profiles/
```

The `.dsh/cordis.patch.yml` and `.dsh/settings.yaml` files are intentionally empty in the vanilla template. They are placeholders that make the intended structure visible and can be committed in a template repository. `setup-dsh.sh` rewrites them during real workspace bootstrap and ensures the bootstrapped workspace ignores runtime `.dsh/` state.

Do not include:

```text
.dsh/.credentials.yaml
.env
node_modules/
.dsh-target
```

Create a project from the template:

```bash
cp -R dsh-template project-a
cd project-a
./setup-dsh.sh
bun run doctor
bun run web
```

This produces an isolated DSH workspace:

```text
project-a/
  package.json
  bun.lock
  setup-dsh.sh
  bin/
  sync-models.js
  doctor.js
  reset.sh
  node_modules/
  .dsh/
    cordis.patch.yml
    settings.yaml
    .credentials.yaml
    profiles/
  .dsh-target
```

Each project gets fresh credentials, its own local routing, its own plugins, and its own synced model catalog. The project does not share writable DSH state with `dsh-template`.

Create another isolated workspace from the same template:

```bash
cd ..
cp -R dsh-template project-b
cd project-b
./setup-dsh.sh
DSH_PORT=3081 bun run web
```

`project-a` and `project-b` are now independent. Changes to model settings, credentials, profiles, or plugins in one workspace do not affect the other.

When running multiple isolated workspaces at the same time, use different ports:

```bash
cd project-a
DSH_PORT=3080 bun run web
```

```bash
cd ../project-b
DSH_PORT=3081 bun run web
```

## Reset

Reset the current local workspace:

```bash
bun run reset
```

Reset without an interactive prompt:

```bash
./reset.sh --force
```

Reset a custom config directory:

```bash
./reset.sh --dir ../shared-dsh-config --force
```

Reset global config only:

```bash
./reset.sh --global --force
```

Always check the printed target path before confirming a reset.

## Upgrade

Run upgrades from the runnable workspace directory, not from the DSH config directory.

Routine upgrade for the current runnable workspace:

```bash
cd dsh-work-a
bun run upgrade
```

This updates framework dependencies, discovered profile plugins, the OpenRouter model catalog, and then runs `doctor`.

Do not rerun `setup-dsh.sh` as a routine upgrade path if you have hand-edited DSH config, because setup rewrites core config files.

### Self-Contained Workspace Upgrade

Each self-contained workspace has its own runnable files and its own local `.dsh` config, so upgrade each workspace independently.

```bash
cd dsh-work-a
bun run upgrade
```

```bash
cd ../dsh-work-b
bun run upgrade
```

Commit changed `package.json` and `bun.lock` in each workspace repository when appropriate.

### Shared Config Upgrade

For workspaces sharing a config directory through `--dir`, run upgrade from one runnable workspace that points at the shared config.

```bash
cd dsh-work-a
bun run upgrade
```

This updates the runnable workspace dependencies in `dsh-work-a/` and also updates shared DSH profiles and model catalog in the shared config directory.

Afterward, other runnable workspaces that use the same shared config may still need their own dependency update if their local `package.json`, `bun.lock`, or wrapper files are separate:

```bash
cd ../dsh-work-b
bun update
bun run doctor
```

Use `bun run upgrade` in the second workspace only if you also want it to drive shared plugin/model updates again.

### Golden Template Upgrade

Upgrade the template before creating new project workspaces from it.

```bash
cd dsh-template
bun run upgrade
bun run doctor
```

Then create new workspaces from the updated template:

```bash
cd ..
cp -R dsh-template project-a
cd project-a
./setup-dsh.sh
```

Existing projects copied from an older template do not update automatically. Upgrade them directly or refresh them from the template using your normal project migration process.

### Upgrade vs Setup

Use:

```bash
bun run upgrade
```

for routine framework, plugin, and model-catalog updates.

Use:

```bash
./setup-dsh.sh
```

only for initial bootstrap, credential reinitialization, or deliberate regeneration of core config.

## Git Hygiene

Runtime and secret files must remain ignored:

```text
.dsh/
.dsh-target
node_modules/
.env
.env.*
*.credentials.yaml
.credentials.yaml
```

If you create a new workspace from scratch, `setup-dsh.sh` ensures these ignore rules exist before writing credentials.

---

[Back to README](../README.md)
