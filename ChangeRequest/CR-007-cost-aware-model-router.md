# CR-007: Cost-aware default-model routing

**Status:** 🟡 Proposed — open for challenge
**Priority:** Low (bigger swing)
**Area:** `cordis.patch.yml` config shape, `sync-models.js`

## Summary

`sync-models.js` already pulls the full OpenRouter model catalog — including, per model, whatever pricing metadata OpenRouter's `/api/v1/models` endpoint returns — but currently only persists `id` and `name` into `cordis.patch.yml` (see the `models.map(m => ({ id: m.id, name: m.name || m.id }))` projection). This CR is a larger, more speculative proposal: use that discarded pricing data to let `agent-default-model` route by cost/quality tier instead of a single fixed model. Flagged explicitly as the most speculative item in this list — it changes DSH's model-selection story, not just a script.

## Detail

### Problem / opportunity
Today, `agent-default-model` in `cordis.patch.yml` is a single hardcoded `provider`/`model` pair (`openrouter` / `deepseek/deepseek-chat`), set once at setup time and only changed by manually editing YAML or picking from Model Pro's UI (per `docs/customization.md` section 4). There's no notion of "use a cheap fast model for trivial requests, escalate to a frontier model for hard ones" — every request goes to whatever single model is currently configured, regardless of task complexity or cost.

### Proposed change (sketch, not a spec)
1. Extend `sync-models.js`'s model projection to also persist pricing fields already present in the OpenRouter API response (prompt/completion cost per token) alongside `id`/`name`.
2. Introduce a small number of named tiers (e.g. `cheap`, `balanced`, `frontier`) in `cordis.patch.yml`, each mapping to a model chosen from the synced catalog by a simple, transparent rule (e.g. "cheapest model above some quality/context-length floor" for `cheap`; a pinned frontier model for `frontier`).
3. Some routing mechanism picks a tier per request — the simplest version is entirely manual (`agent-default-model` becomes a per-tier selector the user or a skill switches explicitly, e.g. via a prompt: *"use the cheap tier for this batch job"*), which requires no new inference logic at all. A more ambitious version would have the agent framework itself pick a tier heuristically per request, which is a materially bigger change touching request routing, not just config.

### Scope
This CR intentionally does **not** commit to the ambitious (automatic, heuristic) version. The manual-tier version — just richer config plus a documented convention for switching tiers by prompt — is a small, low-risk slice that delivers most of the value (cost visibility and easy manual switching) without building an actual router. Treat the automatic version as a separate, future CR contingent on this one proving useful.

### Open questions
- Is manual tier-switching (a documentation + config convention, no new code beyond the `sync-models.js` pricing capture) enough to be worth doing on its own, or does the value only materialize once selection is automatic? This is the central question — I'd want agreement on scoping to "manual tiers only" before starting, given the automatic version is a much bigger, more uncertain undertaking.
- OpenRouter's per-model pricing changes over time (that's exactly why `sync-models.js` exists) — a tier definition based on "cheapest above a floor" needs to be re-evaluated on every sync, not fixed once. Confirm `sync-models.js`'s existing idempotent re-run behavior extends cleanly to recomputing tier assignments, not just the flat model list.

### Effort estimate
Manual-tier slice: medium. Automatic routing: large, and arguably out of scope for what DSH is today (a config/bootstrap layer, not an inference-time decision engine) — worth challenging whether it belongs in this project at all versus being left to the underlying `@deepseek-ai/dsh` framework.
