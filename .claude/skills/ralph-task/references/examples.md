# Ralph Task Examples

## Success Output

```
## Completed: Add user avatar upload (bd-a1b2)

- Created: src/components/ImageUpload.vue, src/components/__tests__/ImageUpload.spec.ts
- Modified: src/pages/settings/profile.vue, src/api/users.ts
- Tests: Component test for ImageUpload, request test for avatar endpoint
- PR: https://github.com/owner/repo/pull/123 (merged)

<promise>COMPLETE</promise>
```

## Blocked Output

```
## Blocked: Add user avatar upload (bd-a1b2)

Code review identified issues that could not be resolved after 3 iterations:
- Security concern: File upload validation insufficient
- Need human decision on max file size policy

PR: https://github.com/owner/repo/pull/123 (open, needs review)

<promise>BLOCKED</promise>
```

## Unexpected State Output

```
## Unexpected State

Reached end of workflow without clear completion status.
- Started working on: bd-a1b2
- Got to step: 7 (Create PR)
- Unexpected situation: [describe what happened]

Human review recommended.

<promise>BLOCKED</promise>
```

## AC Verification Example (Good)

```
## AC Verification for bd-a1b2

1. [x] "Add Credo to dependencies"
   - Implemented: Added {:credo, "~> 1.7"} to mix.exs deps
   - Verified: mix deps.get succeeds, credo available

2. [x] "Configure CI to run Credo in strict mode"
   - Implemented: Added "mix credo --strict" step to .github/workflows/ci.yml
   - Verified: File contains the step

3. [x] "Credo passes locally"
   - Verified: Ran `mix credo --strict`, exits 0

## MC Verification (Mandatory Constraints)

1. [x] "Tests required for every feature"
   - Verified: Added test in test/credo_integration_test.exs

2. [x] "Tailwind only, semantic tokens"
   - N/A: No UI changes in this task

All AC and MC items complete. Proceeding to step 9.
```

## AC Verification Example (Failed)

```
## AC Verification FAILED

Item not complete: "Configure Credo in CI"
Reason: [explain why it cannot be done]
Action needed: [what human needs to do]

<promise>BLOCKED</promise>
```

## Resume Scenarios

```bash
# Scenario A: Crashed during code review
# - Branch exists, PR exists and open
# - Resume at step 8

# Scenario B: Crashed during implementation
# - Branch exists with some commits
# - git status shows uncommitted changes
# - Tests fail
# - Resume at step 4 (continue implementing)

# Scenario C: Crashed after implementation but before PR
# - Branch exists with commits
# - Tests pass
# - No PR yet
# - Resume at step 7 (create PR)
```
