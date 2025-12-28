---
name: review-merge
description: Review code changes using the code-review plugin, then update PROGRESS.md after approval.
user_invocable: true
arguments:
  - name: branch
    description: Branch name to review (defaults to current branch)
    required: false
---

# Review & Merge

Combines code review with progress tracking. Uses Claude's built-in code review plugin, then updates PROGRESS.md on approval.

## Process

### 1. Identify Changes

Check current branch and uncommitted changes:

```bash
git status
git log --oneline main..HEAD  # or appropriate base branch
```

### 2. Invoke Code Review Plugin

Use the `code-review:code-review` skill to review the changes:

```
/code-review
```

The code review plugin will:
- Analyze all changed files
- Check for bugs, security issues, and code quality
- Verify adherence to project patterns
- Provide actionable feedback

### 3. Address Feedback

If review has critical issues:
- List the issues clearly
- Suggest fixes
- Wait for user to address before proceeding

If review passes or only has minor suggestions:
- Note the suggestions
- Proceed to progress update

### 4. Update PROGRESS.md

After approval, update `docs/PROGRESS.md`:

1. Find the relevant feature items that were completed
2. Check off completed items: `[ ]` -> `[x]`
3. Update the summary table counts
4. Update the "Last Updated" date
5. Add brief completion notes if helpful

**Example update:**
```markdown
Before:
- [ ] Implement user login form
- [ ] Add form validation

After:
- [x] Implement user login form
- [x] Add form validation
```

### 5. Commit Progress Update

```bash
git add docs/PROGRESS.md
git commit -m "docs: update progress for [feature-name]"
```

### 6. Merge Workflow

Suggest the appropriate merge strategy:

**For feature branches:**
```bash
git checkout main
git merge feat/[feature-name] --no-ff
git branch -d feat/[feature-name]
```

**For single-commit fixes:**
```bash
git checkout main
git merge feat/[feature-name] --ff-only
```

## Review Checklist

The code review will check (via the plugin):

- [ ] No obvious bugs or logic errors
- [ ] No security vulnerabilities
- [ ] Follows project patterns and conventions
- [ ] Appropriate error handling
- [ ] Tests included (if applicable)
- [ ] No unnecessary complexity

## Output Format

```
## Code Review: [branch-name]

### Review Results

[Summary from code-review plugin]

### Progress Updates

Completed items:
- [x] Item 1
- [x] Item 2

Updated docs/PROGRESS.md

### Merge Ready

Branch is ready to merge into main.

Commands:
  git checkout main
  git merge feat/[name] --no-ff
  git push origin main

Proceed with merge? (y/n)
```

## Notes

- Always run review before merging
- Keep PROGRESS.md in sync with actual completion
- Use meaningful commit messages for progress updates
- The code-review plugin handles the detailed review - this skill orchestrates the workflow
