# Deployment & CI Phase (New Projects)

For new projects, establish CI and deployment infrastructure BEFORE feature work. "Deploy early, deploy often" - every vertical slice should be deployable from day one.

## Detection - Skip If Already Configured

Check for existing infrastructure before asking deployment questions:

**CI Detection:**
```bash
# GitHub Actions
ls .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null
```
If workflows exist → skip CI questions, note existing setup in spec.

**Deployment Detection:**
```bash
# Fly.io
ls fly.toml 2>/dev/null

# Cloudflare
ls wrangler.toml wrangler.json wrangler.jsonc 2>/dev/null
```
If deployment config exists → skip deployment questions, note existing setup in spec.

## When to Trigger

Only ask deployment/CI questions when:
- No existing CI config detected AND/OR no deployment config detected
- Project appears to be new (few commits, no releases)
- User mentions "new project", "starting fresh", "greenfield"

## Stack → Platform Recommendations

| Stack | Recommended Platform | Reason |
|-------|---------------------|--------|
| Elixir/Phoenix | Fly.io | Native BEAM support, easy clustering |
| .NET | Fly.io | Container-based, good .NET support |
| Node.js (full-stack) | Fly.io | Containers with persistent storage |
| Node.js (edge/static) | Cloudflare Pages/Workers | Edge-first, excellent DX |
| Static + API | Cloudflare Pages + Workers | Fast global CDN |
| Any with PostgreSQL | Fly.io | Fly Postgres or easy DB attachment |

## Deployment Questions

Ask using AskUserQuestion (only if not detected):

1. **Platform preference**:
   - Fly.io (containers, databases, full-stack)
   - Cloudflare (edge, static, serverless)
   - Other (specify)

2. **Deploy trigger**:
   - Continuous (deploy on every main merge)
   - Manual (deploy on demand/tag)

## Output: Infrastructure Spec

Add an **Infrastructure** section to the spec file:

```markdown
## Infrastructure

### CI (GitHub Actions)
- Trigger: Push to main, PRs
- Steps: Lint → Test → Build
- Required checks before merge: Yes

### Deployment
- Platform: [Fly.io / Cloudflare]
- Trigger: [On main merge / Manual]
- Environment: [Production only / Staging + Production]
```

## Persist to CLAUDE.md

Key infrastructure decisions must survive session boundaries. Append to CLAUDE.md:

```markdown
## Infrastructure

### Deployment
- Platform: [Fly.io / Cloudflare]
- Deploy command: [fly deploy / wrangler deploy]
- Secrets: [fly secrets set / wrangler secret put]

### CI
- All PRs must pass CI before merge
- Run `[mix test / npm test / dotnet test]` locally before pushing

### Environment Variables
See `.env.example` for required variables.
```

## First Beads Issues (Infrastructure)

When creating issues, infrastructure comes FIRST:

```bash
# 1. CI (always first)
bd create "Set up GitHub Actions CI" --validate --description "$(cat <<'EOF'
## Summary
Configure GitHub Actions for continuous integration.

## Acceptance Criteria
- [ ] Workflow runs on push to main and PRs
- [ ] Runs lint, test, build steps
- [ ] Required status check before merge enabled

## Implementation Hints
- Create .github/workflows/ci.yml
- Use appropriate action for stack (actions/setup-node, erlef/setup-beam, actions/setup-dotnet)
EOF
)"

# 2. Deployment (second)
bd create "Set up deployment to [Platform]" --validate --description "$(cat <<'EOF'
## Summary
Configure automated deployment to [Fly.io/Cloudflare].

## Acceptance Criteria
- [ ] Deploy succeeds on main branch merge
- [ ] Secrets configured in GitHub
- [ ] Health check passes post-deploy

## Implementation Hints
- Fly.io: fly launch, add deploy job to CI
- Cloudflare: wrangler.toml, pages/workers config
EOF
)"

# 3. Production environment (third)
bd create "Configure production environment" --validate --description "$(cat <<'EOF'
## Summary
Set up production secrets, environment variables, and external service connections.

## Acceptance Criteria
- [ ] All required secrets documented in README or .env.example
- [ ] Secrets configured in deployment platform
- [ ] Database connection configured (if applicable)
- [ ] External API keys configured (if applicable)
- [ ] App boots successfully in production with all services connected

## Implementation Hints
- Create .env.example with all required variables (no values)
- Document secret setup in README
- Fly.io: fly secrets set KEY=value
- Cloudflare: wrangler secret put KEY
EOF
)"
```
