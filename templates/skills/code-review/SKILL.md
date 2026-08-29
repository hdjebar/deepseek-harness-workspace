---
name: code-review
description: Comprehensive guidelines, checklists, and automated patterns for thorough code reviews and diff analysis.
---

# Code Review Skill

Use this skill when conducting code reviews, reviewing pull requests, or analyzing diffs.

## Review Checklist

### 1. Correctness & Logic
- [ ] Does the implementation fulfill all requirements of the issue/task?
- [ ] Are edge cases handled (empty arrays, null/undefined, network timeouts, zero-division)?
- [ ] Are race conditions or concurrency issues present?

### 2. Security & Credentials
- [ ] No hardcoded secrets, API tokens, passwords, or private keys.
- [ ] Inputs are sanitized and parameterized (prevent SQLi, Command Injection, XSS).
- [ ] Least-privilege permissions applied on files, directories, and endpoints.

### 3. Performance & Resource Efficiency
- [ ] No memory leaks (unclosed streams, unbounded event listeners, infinite loops).
- [ ] Avoid redundant network calls, N+1 queries, or heavy synchronous computations on the main thread.
- [ ] Efficient data structures and proper algorithmic complexity.

### 4. Maintainability & Style
- [ ] Variable and function names are intention-revealing and unambiguous.
- [ ] Functions are short, cohesive, and have a single responsibility.
- [ ] Existing comments and docstrings are preserved unless explicitly refactored.
