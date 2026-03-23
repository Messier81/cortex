---
description: Autonomous experiment loop. Loops indefinitely: decompose task into sub-goals, implement changes, measure against a metric, keep improvements, discard failures with reflections. Stops when goal is met, max iterations hit, or interrupted. Features reflexion memory, curriculum ordering, and best-shot context.
argument-hint: "Task description" [--metric "shell command"] [--max N]
---

# Cortex Auto

You are orchestrating an autonomous experiment loop. Once started, this runs without human input — you implement, measure, reflect, and iterate until the goal is met or you hit the limit.

**Task:** $ARGUMENTS

If no task provided, ask: "What goal should we work toward autonomously? (e.g., 'Fix all TypeScript strict mode errors', 'Reduce bundle size under 200kb')"

---

## Step 1: Pre-flight

1. Run `git status --porcelain`. If uncommitted changes exist, stop:
   > "Working directory has uncommitted changes. Commit or stash them first."

2. Load `.cortex/profile.json` for project conventions and default metric command.

3. Parse arguments:
   - `--metric "<command>"` — the measurement command (exit code + optional numeric stdout)
   - `--max N` — iteration cap (default: 20)
   - If no `--metric`: use `test` command from profile.json, or ask the user

4. Run the metric command to capture **baseline**. Record as iteration 0.

5. Create experiment branch: `git checkout -b cortex-auto/<task-slug>-<timestamp>`
   - Sanitize task to slug: lowercase, spaces→hyphens, max 30 chars
   - If branch already exists: offer "(1) Resume from last state or (2) Delete and start fresh"

6. Initialize `.cortex/experiments/active-session.json` with the session state.

---

## Step 2: Curriculum Decomposition

Before entering the loop, decompose the task into sub-goals ordered **easy→hard**.

Think about the task and identify 2-5 sub-goals where:
- Each sub-goal is independently measurable (the metric should improve after each)
- Earlier sub-goals are simpler or more isolated
- Later sub-goals build on earlier ones

Example for "Fix all TypeScript strict mode errors":
1. Fix null/undefined errors (most mechanical)
2. Fix implicit `any` types (add explicit annotations)
3. Fix strict function types (covariance/contravariance issues)
4. Fix remaining edge cases

Tell the user the decomposition:
```
Decomposed into N sub-goals:
  1. <easiest>
  2. <medium>
  ...
  N. <hardest>
Starting with sub-goal 1.
```

Save sub-goals to `active-session.json`.

---

## Step 3: Autonomous Loop

**DO NOT pause to ask the human during this loop.** Iterate until: (a) all sub-goals are met, (b) max iterations hit, or (c) the user interrupts.

For each iteration:

### 3a. Load State
Read `.cortex/experiments/active-session.json` for current state.
Load `.cortex/experiments/log.json` for the full history of this session.

### 3b. Prepare Context for Experimenter
- Current sub-goal description
- Metric command + current best value
- Full experiment log WITH reflections (not just descriptions)
- **Top 3 KEEPs** as "inspirations" (best-shot context — show what worked)
- `think_harder: true` if consecutive_discards >= 3
- Project conventions

### 3c. Launch Experimenter Agent
Launch the **experimenter** agent with the above context.

### 3d. Commit Snapshot
After the agent makes its change:
`git commit -am "experiment: attempt N — <experimenter's description>"`

### 3e. Run Metric
Run the metric command. Capture exit code + stdout.

If the metric command itself errors (not just returns nonzero):
- Capture stderr
- Check if it's fixable (SyntaxError, ImportError, ModuleNotFoundError, missing file)
- If fixable: launch **debugger** agent for one fix attempt, re-run metric
- If still crashing or not fixable: treat as CRASH, go to 3f

### 3f. Evaluate and Decide

**KEEP** if metric improved (lower number, or FAIL→PASS):
```
✓ Attempt N: KEEP — <description>
  Metric: <before> → <after>
```
- Update `current_best_value` in active-session.json
- Set `consecutive_discards = 0`
- Check if current sub-goal is now satisfied → if yes, advance to next sub-goal

**DISCARD** if metric same or worse:
```
✗ Attempt N: DISCARD — <description>
  Metric: <before> → <after> (no improvement)
```
- `git reset --hard` to last kept commit (or starting commit if nothing kept yet)
- Write a reflection: ask the experimenter agent what it learned from this failure
  Format: "Tried <X> because <Y>. Failed because <Z>. Learned: <constraint/insight>."
- Increment `consecutive_discards`

**CRASH** if metric command errored after fix attempt:
```
✗ Attempt N: CRASH — <description>
  Error: <stderr summary>
```
- `git reset --hard` to last kept commit
- Write reflection: "Crashed with: <error>. The change was fundamentally broken in this environment."
- Increment `consecutive_discards`

### 3g. Log the Attempt
Append to `.cortex/experiments/log.json` with description, metric value, status, reflection (if discard/crash), files changed, timestamp.

### 3h. Safety Checks
- If `consecutive_discards >= 5`: pause and tell the user:
  > "5 consecutive failures. No progress since attempt <N>. Should I continue with think-harder mode, or stop here?"
  Wait for user response before continuing.
- If `current_iteration >= max`: break the loop and go to Step 4

### 3i. Update Session State
Increment iteration counter. Set think_harder = (consecutive_discards >= 3).

---

## Step 4: Completion

When the loop ends (goal met, max hit, or interrupted):

### Show Summary Table
```
## Cortex Auto: "<task>"
Completed N iterations · M kept · P discarded · Q crashed

| # | Description | Metric | Status |
|---|-------------|--------|--------|
| 1 | <desc>      | 450k → 430k | ✓ KEEP |
| 2 | <desc>      | 430k → 435k | ✗ DISCARD |
...

Baseline:  <value>
Final:     <current best value>
Improvement: <delta / percentage>
```

### Extract Patterns
Read all reflections from this session. Extract 3-5 high-level patterns:
- Things that consistently work in this codebase
- Things that consistently fail (and why)
- Constraints discovered (blast radius concerns, architectural limits, etc.)

Save to `patterns_learned` in the session's log entry.

### Show Patterns
```
## Patterns Learned
- <pattern 1>
- <pattern 2>
...
Run /cortex-log --patterns to see patterns across all sessions.
```

### Final Status
```
Status: GOAL MET ✓ / MAX ITERATIONS / INTERRUPTED

Branch: <branch-name>
<N> improvements committed.

Next: /cortex-review to verify quality, /cortex-ship to push and open a PR.
```

### Cleanup
Delete `.cortex/experiments/active-session.json` (session is complete).
