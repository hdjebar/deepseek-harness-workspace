# CR-006: Spend/usage visibility in `doctor.js`

**Status:** 🟡 Proposed — open for challenge
**Priority:** Low
**Area:** `doctor.js`, `sync-models.js`

## Summary

`doctor.js` already calls OpenRouter's `/api/v1/auth/key` endpoint to validate the stored key (`checkCredentials()`, lines 116–145) and already surfaces `label` and `limit` from that response. OpenRouter's key-info response also includes usage data it currently discards. Given DSH's positioning as a personal, cost-conscious AI environment (a recurring theme in this README's "Why DSH?" pitch), surfacing current spend in the existing health check is a small addition with a clear fit.

## Detail

### Problem
`checkCredentials()` already fetches `https://openrouter.ai/api/v1/auth/key` and reads `body.data.label` and `body.data.limit` (lines 132–134) into the `detail` string, but drops the rest of the payload. OpenRouter's key-info endpoint also returns usage figures (spend to date) in that same response — this data is already being fetched on every `bun run doctor` call; it's just not being displayed.

### Proposed change
Extend the existing `detail` string construction in `checkCredentials()` to also include usage, e.g.:
```
✅ OpenRouter key valid — source: ~/.dsh/.credentials.yaml (managed store); limit: $50; usage: $12.40 (24.8%)
```
When no spending limit is set (the common case, per the existing doctor sample output — `"limit: no spending limit"`), show usage without a percentage: `usage: $12.40 spent`.

### Scope
- In scope: reading and displaying fields already present in the response `doctor.js` already fetches. No new API calls, no new network dependency.
- Out of scope: historical spend trends, per-model cost breakdown, or budget alerts — those would need either a different OpenRouter endpoint or local usage tracking, both bigger asks than this CR.

### Open questions
- Should a `warn()` (rather than the current `pass()`) trigger once usage crosses some percentage of the configured limit (e.g. 90%)? That's a small step from "display" to "alert" and might belong in a separate, explicitly-scoped follow-up CR rather than bundled in here.
- Need to verify OpenRouter's exact response field name for usage (`usage`, `usage_daily`, etc.) against their current API docs before implementing — this CR is written from the assumption the data is present based on the fields already being read from the same response, not from having inspected the full response schema.

### Effort estimate
Trivial-to-small — extending an existing string built from an already-fetched response, contingent on confirming the exact field name.
