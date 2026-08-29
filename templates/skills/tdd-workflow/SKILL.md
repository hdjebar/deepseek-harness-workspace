---
name: tdd-workflow
description: Test-Driven Development (TDD) workflow, unit testing conventions, and mock strategies.
---

# Test-Driven Development (TDD) Skill

Use this skill when implementing features or fixing bugs using test-driven methodology.

## The Red-Green-Refactor Loop

1. **🔴 Red Phase (Write a Failing Test):**
   - Write an automated unit or integration test defining the desired behavior.
   - Run the test and confirm it fails for the expected reason.

2. **🟢 Green Phase (Make it Pass):**
   - Implement the minimal amount of code necessary to make the test pass.
   - Do not write extra features or over-engineer in this phase.

3. **🔵 Refactor Phase (Clean and Optimize):**
   - Clean up code duplication, improve naming, and optimize performance.
   - Ensure all tests continue to pass (`exit code: 0`).

## Writing Maintainable Tests with Bun Test
```typescript
import { describe, expect, it } from "bun:test";

describe("ModelSync", () => {
  it("should sanitize model IDs with quotes", () => {
    const raw = { id: 'org/"special-model"' };
    const safe = raw.id.replace(/"/g, '\\"');
    expect(safe).toBe('org/\\"special-model\\"');
  });
});
```
