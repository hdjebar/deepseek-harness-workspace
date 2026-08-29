---
name: git-standards
description: Conventional commits, branching models, PR guidelines, and git history management.
---

# Git Standards & Workflow Skill

Use this skill when staging, committing, branching, or structuring version control operations.

## 1. Conventional Commits Format

Format: `<type>(<optional scope>): <description>`

### Types
- `feat`: A new feature or capability for the user
- `fix`: A bug fix or patch
- `docs`: Documentation changes only (README, architecture notes)
- `style`: Changes that do not affect code logic (formatting, whitespace)
- `refactor`: Code restructuring without bug fixes or feature additions
- `perf`: Code changes improving performance or memory footprint
- `test`: Adding missing tests or correcting existing tests
- `chore`: Maintenance tasks, dependency updates, CI workflow changes

### Good Commit Message Examples
- `feat(auth): support OpenRouter token validation in pre-flight`
- `fix(doctor): resolve port probe connection refused on macOS`
- `docs(readme): add architecture diagrams and troubleshooting table`
- `chore(ci): enforce frozen lockfile verification in GitHub Actions`

## 2. Commit Best Practices
1. **Atomic Commits:** Each commit should represent one logical unit of work.
2. **Imperative Mood:** Write commit titles like `feat: add reset script`, not `added reset script`.
3. **No Secret Commits:** Never commit `.env`, `*.credentials.yaml`, or API tokens.
