---
description: Generate a structured implementation plan for a task. Analyzes context, breaks down requirements, defines test strategy, and self-challenges before presenting for approval. Saves to .cortex/active-plan.json.
argument-hint: The task to plan (e.g. "Add OAuth2 login with Google")
---

# Cortex Plan

You are orchestrating a planning session. The goal is to produce an approved, structured plan before a single line of code is written.

**Task:** $ARGUMENTS

If no task was provided, ask: "What would you like to plan?"

---

## Step 1: Load Context

First, check if `.cortex/profile.json` exists. If not, suggest running `/cortex-init` first, but continue with best-effort planning.

Run the context selection algorithm inline (same as `/cortex-focus`):
1. Parse the task for key nouns and verbs
2. Glob for files matching those terms in likely directories
3. Grep for matching content in source files
4. Present the top 5-10 candidate files to ground the planning

Read each candidate file briefly (first 50 lines) to understand current structure.

---

## Step 2: Launch Planner Agent

Launch the **planner** agent with:
- The task description
- The list of context files
- The content of `.cortex/profile.json` (if it exists)
- Any implied requirements you've identified

The planner will return a structured JSON plan.

---

## Step 3: Present the Plan

Format the plan for human review:

```
## Plan: "<task>"

### Requirements
| ID | Requirement | Acceptance Criteria | Priority |
|----|------------|---------------------|----------|
| R1 | ...        | ...                 | MUST     |

### Implementation Steps
**S1** — <description>
- Files: `<file>`, `<file>`
- TDD: Yes/No
- Risk: <brief risk note>

**S2** — ...

### Test Strategy
<summary>

### Uncertainties
- <anything the planner flagged as uncertain>
```

---

## Step 4: Approval Gate

**HARD GATE**: Do not proceed to implementation. Present the plan and explicitly ask:

> "Does this plan look right? Any changes before we start? Once approved, run `/cortex-build` to execute."

---

## Step 5: Save Plan

Save the plan JSON to `.cortex/active-plan.json`:

```json
{
  "task": "<task>",
  "created_at": "<run: date -u +%Y-%m-%dT%H:%M:%SZ>",
  "status": "approved",
  "current_step": 0,
  "requirements": [...],
  "steps": [
    {
      "id": "S1",
      "description": "...",
      "files": [...],
      "tdd": false,
      "depends_on": [],
      "risk": "...",
      "status": "pending"
    }
  ],
  "test_strategy": "...",
  "uncertainties": [...]
}
```

Also save `.cortex/active-intent.json` (for `/cortex-verify` compatibility):
```json
{
  "task": "<task>",
  "implied_requirements": ["<each MUST requirement>"],
  "context_files": ["<list of context files>"],
  "captured_at": "<same timestamp>"
}
```
