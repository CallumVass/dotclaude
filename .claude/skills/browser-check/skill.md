---
name: browser-check
description: Use Playwright MCP to verify UI in browser. Takes a URL/path and instruction to check.
user_invocable: true
arguments:
  - name: url
    description: Full URL or path to check (e.g., http://localhost:3000 or /dashboard)
    required: false
  - name: instruction
    description: What to verify (e.g., "Check login form submits correctly")
    required: false
---

# Browser Check

Verify UI in the browser using Playwright MCP tools.

## Usage

When asked to verify or check something in the browser, use this flow.

### Arguments

- `$URL` - The URL or path to check (defaults to `http://localhost:3000`)
- `$INSTRUCTION` - What to do and verify

## Process

### 1. Determine Dev Server

Check for common dev server ports based on stack:

| Stack | Default Port | Check Command |
|-------|-------------|---------------|
| Vite/Vue/React | 3000, 5173 | `netstat -ano \| findstr :3000` |
| Next.js | 3000 | `netstat -ano \| findstr :3000` |
| Phoenix | 4000 | `netstat -ano \| findstr :4000` |
| .NET | 5000, 5001 | `netstat -ano \| findstr :5000` |

If server not running, suggest starting it:
- **npm/pnpm/yarn**: `pnpm dev` or `npm run dev`
- **Phoenix**: `mix phx.server`
- **.NET**: `dotnet run` or `dotnet watch`

### 2. Navigate to the Page

Use `mcp__plugin_playwright_playwright__browser_navigate`:

```
mcp__plugin_playwright_playwright__browser_navigate({
  url: "$URL"
})
```

If `$URL` is a path (starts with `/`), prepend the detected localhost URL.

### 3. Take a Snapshot

Use `mcp__plugin_playwright_playwright__browser_snapshot` to get page structure:

```
mcp__plugin_playwright_playwright__browser_snapshot({})
```

### 4. Perform Requested Actions

If `$INSTRUCTION` includes interactions:

**Click elements:**
```
mcp__plugin_playwright_playwright__browser_click({
  element: "description of element",
  ref: "element ref from snapshot"
})
```

**Type text:**
```
mcp__plugin_playwright_playwright__browser_type({
  element: "description of element",
  ref: "element ref from snapshot",
  text: "text to type"
})
```

**Fill forms:**
```
mcp__plugin_playwright_playwright__browser_fill_form({
  fields: [
    { name: "email", type: "textbox", ref: "ref", value: "test@example.com" }
  ]
})
```

### 5. Take Screenshot if Needed

```
mcp__plugin_playwright_playwright__browser_take_screenshot({})
```

### 6. Report Findings

Report back:
- Whether the check passed or failed
- What was observed
- Any issues or unexpected behavior
- Console errors if relevant

## Common Verifications

### Form Submission
1. Navigate to form page
2. Fill required fields
3. Click submit
4. Verify success state or error handling

### Navigation
1. Navigate to starting page
2. Click navigation elements
3. Verify correct page loads
4. Check URL changes

### Responsive/Mobile
1. Resize browser: `browser_resize({ width: 375, height: 667 })`
2. Verify mobile layout
3. Check touch targets (44px minimum)
4. Verify mobile navigation

### Error States
1. Trigger error condition
2. Verify error message displays
3. Check error is actionable

## Notes

- Use snapshots for structure, screenshots for visual verification
- Check console messages for JavaScript errors
- Always verify both happy path and error states when applicable
- For mobile-first projects, test at mobile viewport first
