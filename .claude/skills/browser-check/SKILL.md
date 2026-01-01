---
name: browser-check
description: Verify UI in browser using Playwright. Use when user says "check the browser", "verify UI", "test in browser", "browser check", "does it look right", or wants visual verification of a page.
user_invocable: true
arguments:
  - name: url
    description: URL or path to check (defaults to localhost detection)
    required: false
  - name: instruction
    description: What to verify (e.g., "check login form works")
    required: false
---

# Browser Check

Visual UI verification using Playwright MCP.

---

## Constraints

```
REQUIRE server_running:
  Dev server must be running before navigation
  If not detected → suggest start command, wait for user

REQUIRE playwright_available:
  Playwright MCP tools must be accessible
  If unavailable → inform user, cannot proceed
```

---

## Inputs/Outputs

```
INPUTS:
  - url: explicit URL or path (optional)
  - instruction: what to verify (optional)

OUTPUTS:
  - status: "pass" | "fail" | "server_not_running"
  - observations[]: what was seen
  - issues[]: problems found (if any)
```

---

## Process

### Step 1: Determine Target

```
IF url provided:
  IF starts with "/":
    SET target = localhost + url (detect port first)
  ELSE:
    SET target = url
ELSE:
  SET target = detected localhost URL

DETECT localhost port by stack:
  | Stack            | Ports to check | Default |
  |------------------|----------------|---------|
  | Vite/Vue/React   | 5173, 3000     | 5173    |
  | Next.js          | 3000           | 3000    |
  | Phoenix          | 4000           | 4000    |
  | .NET             | 5000, 5001     | 5000    |

CHECK if server running:
  Windows: netstat -ano | findstr :[port]
  Unix: lsof -i :[port]

IF server not running:
  SUGGEST start command based on stack:
    - npm/pnpm/yarn: pnpm dev / npm run dev
    - Phoenix: mix phx.server
    - .NET: dotnet run / dotnet watch
  
  WAIT for user to start server
  RE-CHECK before proceeding
```

### Step 2: Navigate

```
RUN:
  mcp__plugin_playwright_playwright__browser_navigate({
    url: target
  })

IF navigation fails:
  REPORT: "Failed to navigate to [target]"
  EXIT with status = "fail"
```

### Step 3: Capture State

```
RUN:
  mcp__plugin_playwright_playwright__browser_snapshot({})

PARSE snapshot for:
  - Page structure
  - Interactive elements (buttons, forms, links)
  - Element refs for interaction
```

### Step 4: Execute Instruction

```
IF instruction provided:
  PARSE instruction for required actions
  
  FOR EACH action:
    
    IF click required:
      mcp__plugin_playwright_playwright__browser_click({
        element: "[description]",
        ref: "[ref from snapshot]"
      })
    
    IF type required:
      mcp__plugin_playwright_playwright__browser_type({
        element: "[description]",
        ref: "[ref from snapshot]",
        text: "[text to type]"
      })
    
    IF form fill required:
      mcp__plugin_playwright_playwright__browser_fill_form({
        fields: [
          { name: "[field]", type: "textbox", ref: "[ref]", value: "[value]" }
        ]
      })
    
    IF resize required (mobile check):
      mcp__plugin_playwright_playwright__browser_resize({
        width: 375,
        height: 667
      })
    
    TAKE snapshot after action to verify result

ELSE (no instruction):
  OBSERVE current state
  NOTE any obvious issues
```

### Step 5: Screenshot (if needed)

```
IF visual verification needed:
  RUN:
    mcp__plugin_playwright_playwright__browser_take_screenshot({})
```

### Step 6: Report

```
PRESENT:
  "## Browser Check: [PASS/FAIL]
  
  **URL:** [target]
  **Instruction:** [instruction or 'General check']
  
  **Observations:**
  - [what was seen]
  - [state after actions]
  
  **Issues found:**
  - [issue 1] (if any)
  - [issue 2] (if any)
  
  **Console errors:** [if any detected]"
```

---

## Common Patterns

### Form Submission Check

```
INSTRUCTION: "Check login form submits correctly"

STEPS:
  1. Navigate to form page
  2. Snapshot to get field refs
  3. Fill form fields with test data
  4. Click submit button
  5. Snapshot result
  6. Verify success state OR error handling
```

### Navigation Check

```
INSTRUCTION: "Verify navigation works"

STEPS:
  1. Navigate to starting page
  2. Snapshot to get nav element refs
  3. Click navigation element
  4. Verify URL changed
  5. Snapshot new page
  6. Verify expected content loaded
```

### Responsive/Mobile Check

```
INSTRUCTION: "Check mobile layout"

STEPS:
  1. Resize: width=375, height=667
  2. Navigate to page
  3. Snapshot mobile view
  4. Verify:
     - Mobile layout active
     - Touch targets ≥ 44px
     - Navigation accessible
     - No horizontal scroll
```

### Error State Check

```
INSTRUCTION: "Verify error handling"

STEPS:
  1. Navigate to form/feature
  2. Trigger error condition (invalid input, etc.)
  3. Snapshot error state
  4. Verify:
     - Error message displayed
     - Error is user-friendly
     - Recovery path available
```

---

## Quick Reference

```
TOOLS USED:
  - browser_navigate: go to URL
  - browser_snapshot: get page structure + refs
  - browser_click: click element by ref
  - browser_type: type text in element
  - browser_fill_form: fill multiple fields
  - browser_resize: change viewport
  - browser_take_screenshot: capture visual

WHEN TO SCREENSHOT:
  - Visual verification needed
  - Bug documentation
  - User requested

SERVER DETECTION:
  - Always check server running first
  - Suggest start command if not
  - Don't attempt navigation without server
```
