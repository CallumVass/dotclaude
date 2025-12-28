---
name: review-merge
description: Review code changes, update PROGRESS.md, and merge.
user_invocable: true
arguments:
  - name: branch
    description: Branch name to review (defaults to current branch)
    required: false
---

# Review & Merge

Code review → progress update → merge workflow.

## Process

### 1. Check Changes

```bash
git status
git log --oneline main..HEAD
```

### 2. Run Code Review

Invoke the `code-review:code-review` plugin:

```
/code-review
```

If critical issues found, address them before continuing.

### 3. Update PROGRESS.md

After approval:
- Check off completed items: `[ ]` → `[x]`
- Update summary counts
- Update "Last Updated" date

### 4. Commit Progress

Use `/commit` skill:

```
/commit docs: update progress for [feature-name]
```

### 5. Merge

```bash
git checkout main
git merge feat/[feature-name] --no-ff
git branch -d feat/[feature-name]
```

## Notes

- Always review before merging
- Use `/commit` for standardized commit messages
- Keep PROGRESS.md in sync with actual completion
