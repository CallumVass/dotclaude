# Autonomous-Ready Issues (Ralph Workflow)

When creating issues destined for autonomous execution via `/ralph-task`, ensure they meet these criteria.

## Size Guidelines

Issues must be completable in a single Claude session (roughly 30-60 minutes of work):

| Good Size | Too Large |
|-----------|-----------|
| Add single API endpoint with tests | Add entire CRUD API |
| Create one component with tests | Build complete page with multiple components |
| Fix specific bug with regression test | Refactor entire module |
| Add single feature flag | Implement feature flagging system |

**Rule of thumb**: If you can't describe the implementation in 3-5 bullet points, break it down further.

## Issue Description Format

When creating issues with `bd create`, use this structure:

```markdown
## Summary
[One sentence describing what needs to be built]

## Acceptance Criteria
- [ ] [Specific, testable criterion]
- [ ] [Specific, testable criterion]
- [ ] [Boundary test added]

## Implementation Hints
- Entry point: [file path or pattern to start from]
- Pattern to follow: [reference to similar existing feature]
- Key files: [2-3 files likely to need changes]

## Test Requirements
| Boundary | Test Type |
|----------|-----------|
| [Component/Endpoint/View] | [Component test/Request test/LiveViewTest] |

## Dependencies
- Blocked by: [bd-xxx] (if any)
- Blocks: [bd-yyy] (if any)

## Agent Instructions (optional)
[Skills to invoke, e.g., "Use /frontend-design skill when creating UI components"]
```

## Example: Good Autonomous Issue

```bash
bd create "Add user avatar upload to profile settings" --validate --description "$(cat <<'EOF'
## Summary
Add avatar image upload functionality to the profile settings page.

## Acceptance Criteria
- [ ] Upload button appears on /settings/profile
- [ ] Accepts PNG, JPG, GIF under 2MB
- [ ] Shows preview before save
- [ ] Saves to user record on submit
- [ ] Shows error for invalid files

## Implementation Hints
- Entry point: src/pages/settings/profile.vue
- Pattern to follow: src/pages/settings/notifications.vue (similar form)
- Key files: src/api/users.ts, src/components/ImageUpload.vue (create)
EOF
)"
```

**Note:** The `--validate` flag ensures beads rejects issues missing required sections (e.g., `## Acceptance Criteria` for tasks).

## Example: Too Vague (Not Autonomous-Ready)

```markdown
## Summary
Improve user profile functionality.

## Notes
Make the profile better. Users have complained.
```

This issue needs breaking down into specific, testable tasks.

## Dependency Hierarchy

For complex features, create an epic with ordered tasks:

```bash
# Create epic
bd create "User Profile Improvements" --epic

# Create tasks linked to epic
bd create "Add avatar upload endpoint" --parent bd-epic-id
bd create "Add avatar upload component" --parent bd-epic-id
bd create "Add avatar display to header" --parent bd-epic-id
```

Tasks should be ordered so dependencies are completed first. The autonomous workflow will pick them up in order via `bd ready`.
