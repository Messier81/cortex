---
description: Execute an active plan step by step with TDD discipline. Each step runs in isolation with only the context it needs — no context rot. Resumes from last completed step if interrupted.
argument-hint: Optional step number to start from (e.g. "3" to resume from step 3)
---

# Cortex Build

You are executing an approved implementation plan. Work one step at a time. Each step is fully isolated — you read files fresh to understand current state rather than relying on accumulated conversation history.

---

## Step 1: Load Plan

Read `.cortex/active-plan.json`.

If it doesn't exist: "No active plan found. Create one first — describe your task to Claude and ask it to save a plan to `.cortex/active-plan.json`."

Check if all steps already have `"status": "completed"`:
- If yes: tell the user "All steps are already complete." and stop.

If `$ARGUMENTS` is a number N, start from step N:
- Verify step N exists. If not, list available steps and stop.
- Mark all steps before N as `"status": "skipped"` in the plan file
- Start from step N

Otherwise, find the first step with `"status": "pending"` and start from there.

Show the user:
```
## Cortex Build: "<task>"
Starting from step S<N>: <description>
Remaining steps: <count>
```

---

## Step 2: Execute Steps

For each step (starting from current):

### 2a. Announce
Tell the user: `Executing S<N>: <description>`

### 2b. Build Step Context Packet

Before implementing anything, assemble a **compact context packet** for this step. This keeps the implementation focused and avoids context rot across steps:

**Context packet contains:**
1. **This step only**: the specific step object from the plan (id, description, files, tdd, risk)
2. **Conventions**: relevant fields from `.cortex/profile.json` (naming, imports, error handling, test command)
3. **Prior steps summary** (compact — do NOT re-read full outputs): for each completed step, a 2-3 line entry:
   ```
   S1 [completed]: <description> | Files: <list> | Notes: <any warnings>
   S2 [completed]: ...
   ```
   Write these summaries to `active-plan.json` under each step's `result_summary` field as steps complete.
4. **Experiment patterns** (if `.cortex/experiments/log.json` exists): check if any `patterns_learned` entries mention files or concepts relevant to this step. Include up to 3 matching patterns.

**Context isolation rule**: You are implementing this step with fresh eyes. Read the actual files listed in the step to understand their current state. Do not assume you know what prior steps did — use the summaries above and read the files.

### 2c. Implement the Step

**TDD Rule**: If the step is marked `"tdd": true`:
1. Write the test first
2. Run the test and verify it **fails** (red)
3. Implement the code
4. Run the test and verify it **passes** (green)
If the test passes before implementation code exists, stop and report — the test may be wrong.

**Convention Rule**: All new code must follow the conventions in `.cortex/profile.json`:
- File naming pattern
- Function naming pattern
- Import style (absolute/relative/aliases)
- Error handling pattern

**Scope Rule**: Only touch the files listed in this step's `files` array plus the test file. If you realize you need to touch additional files, say so before doing it.

**Failure Rule**:
- First failure: try a different approach
- Second failure: STOP. Report the error, what you tried, and your hypothesis for the root cause. Ask the user: "(1) Debug this manually, (2) Skip this step, (3) Abort and revise the plan."

### 2d. Run Tests and Lint

After implementing:
1. Run the specific test file first (if test command supports it)
2. Run the full test suite — use `test` command from `.cortex/profile.json`
3. Run lint — use `lint` command from profile if available

### 2e. Handle Result

**If PASS:**
- Update `.cortex/active-plan.json` — set this step's `status` to `"completed"`
- Write `result_summary` for this step:
  ```json
  "result_summary": {
    "status": "completed",
    "files_changed": ["<actual files changed>"],
    "notes": "<any unexpected findings, empty string if none>"
  }
  ```
- Move to next step

**If FAIL:**
- Show the failure
- Ask the user to choose: debug manually, skip, or abort
- Wait for user choice. Do not retry automatically.

---

## Step 3: Completion

When all steps are complete:

1. Run the full test suite
2. Run lint
3. If both pass (or were skipped): commit only the files listed across all plan steps — use specific file paths from each step's `files` array (not `git add .`)

Commit message:
```
feat: <task description in lowercase imperative>

Implemented via /cortex-build
Steps completed: <count>
```

Tell the user:
```
## Build Complete

All <N> steps executed successfully.
Tests: PASS
Lint: PASS

Changes committed: <commit hash>

Next: push your branch and open a PR, or run /cortex-auto to experiment with improvements.
```

---

## Step 4: If Interrupted

If the build is interrupted and the user runs `/cortex-build` again:
- Read the plan
- Find the first `"pending"` step (completed and skipped steps are skipped)
- Resume from there — no steps are re-executed
- The compact `result_summary` fields on completed steps provide all the context needed to continue cleanly
