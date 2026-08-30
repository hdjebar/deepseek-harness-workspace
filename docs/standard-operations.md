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

Template contents:

```text
dsh-template/
  package.json
  bun.lock
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
```

Each project gets fresh credentials and its own local routing.

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

Routine upgrade:

```bash
bun run upgrade
```

This updates framework dependencies, profile plugins, the OpenRouter model catalog, and then runs `doctor`.

Do not rerun `setup-dsh.sh` as a routine upgrade path if you have hand-edited DSH config, because setup rewrites core config files.

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
