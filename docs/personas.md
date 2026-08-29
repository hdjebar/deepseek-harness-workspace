# 🎭 Building a Persona (Role-Specific Setup)

"Customize DSH to a persona" — a specific role, team, or domain (a data analyst, a legal researcher, a frontend team) — isn't a single DSH feature. There's no `dsh persona` command. It's a **composition pattern** across several things that already exist independently. This guide names the pattern explicitly and works through one example end to end.

---

## The pattern

| A persona needs... | DSH mechanism | Where it lives |
| :--- | :--- | :--- |
| Its repeatable processes/procedures written down | **Skills** | `./.agents/skills/<name>/SKILL.md` (versioned with a project) or `<DSH_HOME>/skills/<name>/SKILL.md` (portable — see below) |
| The specific tools it touches day to day | **Plugins + MCP servers** | `dshmarket`/`dsh-find-plugin`; `cordis.patch.yml`'s `mcp-panel.config.servers` |
| The right cost/quality tradeoff for its work | **Model routing** | `agent-default-model` in `cordis.patch.yml` (see the [Customization Guide](customization.md), §4) |
| Repeatable, scripted automation | **Headless recipes** | `bun run headless "..."` |
| Large, multi-step orchestration *within* a session | **The native `workflow` tool** | Built into `@deepseek-ai/dsh` — see below |

A persona, concretely, is: **a skill set + a plugin/MCP list + a model choice + automation (headless recipes and/or the native workflow tool)** — pieces that already exist, assembled once and reused.

### DSH does have a native workflow tool — here's what it actually is

`@deepseek-ai/dsh` ships `dsh-tool-workflow` as a direct dependency (confirmed via `bun.lock` and the published package README, not this repo's own docs — DSH doesn't document it anywhere in this workspace). It's a **model-facing** tool: when the agent decides a task needs large multi-agent orchestration, it can write a JavaScript script (using `agent()`/`parallel()`/`pipeline()`-style primitives) that fans work out across subagents, and the tool runs it via a worker-thread engine. Concretely:

- Registered as a tool named `workflow` by default (`toolName` config).
- The tool's own system-prompt guidance restricts its use: *"ONLY when the user explicitly asks for a workflow or large multi-agent orchestration — for one or two delegations, prefer plain subagent calls."* So this isn't the default automation path for a persona's everyday tasks; it's for the occasional big fan-out job.
- It's synchronous — the parent turn blocks until the whole workflow settles; there's no background start/poll, no journaling/resume, and no saved/nested workflow definitions (per the package's own "Known Limitations" section).
- There's no config surface in this repo's `cordis.patch.yml` for authoring a *reusable, named* workflow — it's the model writing an ad-hoc script per invocation, not a template you define once in YAML.

**For a persona**, the practical implication: don't reach for "workflow" as your default automation mechanism — that's still headless recipes (a fixed, repeatable command, scripted or scheduled outside DSH). Reach for the native `workflow` tool only when a session genuinely needs large, one-off, multi-agent fan-out, and let the model invoke it itself when asked.

### One thing this still isn't (verified)

**Not (verifiably) a theming system.** The only evidence of installable visual themes is a generic label in the [plugins diagram](plugins.md) (`.dsh/profiles/web/node_modules` holding "Skills, Tools, Themes & MCPs") and `dsh-better-sidebar`'s `layout: vscode-classic` config. Unlike the workflow tool above, this one hasn't been checked against the actual published packages — treat it as unverified rather than confirmed absent, and check what `dshmarket` actually offers before relying on it.

### No one-step "apply a persona" command today

Assembling the pieces below is currently manual — write the skill file, add the plugins/MCP servers, edit `cordis.patch.yml`'s model block, save the headless recipes somewhere (a shell alias, a `Makefile` target, a README snippet). There's no `setup-dsh.sh --persona <name>` shortcut yet.

---

## ↔️ The inverted mechanism: one project, many contexts

Everything in [docs/reset.md](reset.md) and this guide's "Who It's For" framing describes **many projects sharing one context** — local (one project, one context), global (many projects, one shared context), `--dir` (same, at a custom path). The inverse also works, and it's the actual mechanism that makes a persona portable: **the same project, run against a different context per invocation**, with nothing written to disk to make it "stick."

### Why this works
`bin/dsh-web.js`, `bin/dsh-cli.js`, and `bin/dsh-headless.js` — the actual runtime commands, not just `setup-dsh.sh`/`reset.sh` — all resolve their target via `resolveDshDir()` (`bin/resolve-dsh.js`), which checks `process.env.DSH_HOME` first, above the project's own `.dsh-target` marker or local `./.dsh`. So a `DSH_HOME` set only for one command call temporarily borrows a different context, without touching this project's own configuration or marker file:

```bash
# Run this project against the data-analyst context
DSH_HOME=~/contexts/data-analyst bun run headless "..."

# Run the exact same project, same directory, against a different context
DSH_HOME=~/contexts/legal-reviewer bun run headless "..."
```

Because `<DSH_HOME>/skills/<name>/SKILL.md` is itself one of the ranked skill-discovery roots (see the [Customization Guide](customization.md), §3), a persona's skills travel along with its context automatically if you store them there — you don't need the skill file to already exist in whatever project you're running from.

### Running contexts in parallel
Combine with `DSH_PORT` (see the [Customization Guide](customization.md), §7) to run the same project against two different contexts at once, in two terminals, without a port collision:

```bash
# Terminal 1 — data-analyst context on the default port
DSH_HOME=~/contexts/data-analyst bun run web

# Terminal 2 — legal-reviewer context on a separate port
DSH_HOME=~/contexts/legal-reviewer DSH_PORT=3081 bun run web
```

### What this isn't
There's no `dsh --context <name>` switch — this is an emergent property of `DSH_HOME` being a plain per-invocation environment variable, not a named feature with its own flag. And each running process is still bound to exactly one context for its lifetime: "many contexts" here means many separate invocations, sequential or parallel — not several contexts held open simultaneously within one session.

---

## Worked example: a "Data Analyst" persona

This builds the persona as a **portable context** (`~/contexts/data-analyst/`) rather than editing any one project's local `.dsh` — that's what lets you run it against whichever project you're in via `DSH_HOME`, per the mechanism above. If you'd rather keep a persona tied to one project instead, use `./.agents/skills/` and that project's own `cordis.patch.yml` — same content, different location.

### 1. The skill (`~/contexts/data-analyst/skills/data-analyst/SKILL.md`)

```markdown
---
name: data-analyst
description: Use when querying, cleaning, or summarizing tabular/SQL data for this team.
---

# Data Analyst

## Guidelines & Rules
1. Always run read-only queries first; confirm before any UPDATE/DELETE.
2. Summarize result sets over 50 rows instead of dumping them raw.
3. Flag NULL-heavy columns (>20% NULL) before using them in aggregates.
4. Prefer the `sqlite-db` MCP tool over shell `sqlite3` calls — keeps output structured.

## Examples & Code Patterns
- "Show monthly active users for Q1" → aggregate query + a one-paragraph summary, not a raw table dump.
```

(Template reused from the [Customization Guide](customization.md), §3, "Creating & Teaching Domain Skills via Prompts". `<DSH_HOME>/skills/...` is discovery rank 400 — it's picked up automatically once `DSH_HOME=~/contexts/data-analyst` is set for a run, no per-project setup needed.)

### 2. Its tools (`~/contexts/data-analyst/cordis.patch.yml`, MCP block)

```yaml
- id: mcp-panel
  config:
    servers:
      sqlite-db:
        command: "npx"
        args: ["-y", "@modelcontextprotocol/server-sqlite", "--db-path", "./data.db"]
```

(Same MCP mechanism as the [Customization Guide](customization.md), §2, "Connecting Model Context Protocol (MCP) Servers" — just scoped to the tool this persona actually needs, not every MCP server available.)

### 3. Its model choice (same `cordis.patch.yml`)

```yaml
- id: agent-default-model
  config:
    provider: openrouter
    model: deepseek/deepseek-chat   # cheap, fast — fine for query drafting and summarization
```

Swap to a stronger model only for tasks that need it (e.g. reconciling ambiguous schema questions) — per-task override, not a change to the persona's default. See the [Customization Guide](customization.md), §4, "Model Selection & Temperature Tuning".

### 4. Its automation (a headless recipe, run from any project)

```bash
DSH_HOME=~/contexts/data-analyst bun run headless "Using the data-analyst skill, connect to ./data.db via the sqlite-db MCP tool, compute monthly active users for the last 2 quarters, and write a 1-paragraph summary to reports/mau.md"
```

Save recipes like this as shell aliases, a `Makefile`, or a small script — the `DSH_HOME=` prefix is what makes the recipe carry its own context wherever it's run, rather than depending on whatever `.dsh` happens to be local to the current project.

> [!NOTE]
> For a real persona context, run `./setup-dsh.sh --dir ~/contexts/data-analyst` once first — that's what gets you a validated OpenRouter key, installed plugins, and a generated `cordis.patch.yml` at that path. `setup-dsh.sh` doesn't create a `skills/` subfolder or know anything about MCP servers scoped to one persona, though — those two pieces (steps 1 and 2 above) you add yourself, on top of what it generates.

---

## Applying this to your own persona

1. Decide where it lives first: `./.agents/skills/` + this project's `cordis.patch.yml` for a persona tied to one project, or a dedicated `<DSH_HOME>/skills/` + `cordis.patch.yml` context folder (bootstrapped via `setup-dsh.sh --dir`) for one that should follow you across projects.
2. Write the skill — it's the only piece that's pure content, no config syntax to get wrong.
3. List the tools that persona *actually* uses regularly — resist adding every available plugin/MCP server "just in case"; a smaller, curated list is easier for the agent to reason about and for you to audit.
4. Pick a default model appropriate to the persona's typical task cost/complexity, not the most capable model by default.
5. Write down (don't just remember) the headless recipes for its recurring jobs — prefix with `DSH_HOME=<context>` if it's meant to be portable.

---

[← Back to README](../README.md)
