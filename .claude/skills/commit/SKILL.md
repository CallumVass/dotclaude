---
name: commit
description: Create a git commit following conventional commit standards.
user_invocable: true
arguments:
  - name: message
    description: Optional commit message hint
    required: false
---

# Commit

Creates a standardized git commit.

## Format

```
<type>(<scope>): <description>
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`

**Scope:** Optional - `auth`, `api`, `ui`, `db`, etc.

## Process

1. **Check changes**: `git status` and `git diff --staged`
2. **Stage files**: `git add <files>` (only related changes, never secrets)
3. **Determine type**: feat (new), fix (bug), docs, refactor, etc.
4. **Commit**:
   ```bash
   git commit -m "type(scope): description"
   ```

## Rules

- Subject: max 50 chars, imperative mood ("Add" not "Added"), no period
- One logical change per commit
- If you need "and" in your message, split the commit
- Never `--no-verify` unless asked
- Never amend pushed commits

## Examples

```bash
git commit -m "feat(auth): add OAuth2 login support"
git commit -m "fix(api): handle null response from payment gateway"
git commit -m "docs: update installation steps"
```
