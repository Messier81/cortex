---
description: Execute the active plan step by step with TDD discipline. Resumes from last completed step if interrupted. Stops and diagnoses on repeated failures rather than brute-forcing.
argument-hint: Optional step number to start from (e.g. "3" to resume from step 3)
---

# Cortex Build

You are executing an approved implementation plan. Work one step at a time. Do not skip ahead.

---

## Step 1: Load Plan

Read `.cortex/active-plan.json`.

If it doesn't exist: "No active plan found. Run `/cortex-plan <task>` to create one first."

If `$ARGUMENTS` is a number, start from that step number. Otherwise, find the first step with `"status": "pending"`.

Show the user what's about to happen:
```
## Cortex Build: "<task>"
Starting from step S<N>: <description>
Remaining steps: <count>
```

---

## Step 2: Execute Steps

For each step (starting from current):

### 2a. Announce
Tell the user: "Executing S<N>: <description>"

### 2b. Launch Executor Agent
Launch the **executor** agent with:
- The full plan
- The specific step to execute (step ID)
- The project conventions from `.cortex/profile.json`

### 2c. Handle Result

**If PASS:**
- Update `.cortex/active-plan.json` — set this step's `status` to `"completed"`
- Move to next step

**If FAIL:**
- Show the failure report
- Ask: "This step failed. Options: (1) Debug with `/cortex-debug`, (2) Skip this step, (3) Abort and revise the plan with `/cortex-plan`"
- Wait for user choice. Do not retry automatically.

---

## Step 3: Completion

When all steps are complete:

1. Run the full test suite (use the `test` command from `.cortex/profile.json`)
2. Run lint (use the `lint` command from profile)
3. If both pass: commit all changes

Commit message format (conventional commits):
```
feat: <task description in lowercase imperative>

Implemented via /cortex-build
Steps completed: <count>
```

4. Tell the user:
```
## Build Complete

All <N> steps executed successfully.
Tests: PASS
Lint: PASS

Changes committed: <commit hash>

Next: Run `/cortex-review` for a full quality review, or `/cortex-ship` to push and create a PR.
```

---

## Step 4: If Interrupted

If the build is interrupted and the user runs `/cortex-build` again, it reads the plan, finds the first `"pending"` step, and resumes from there. No steps are re-executed.
