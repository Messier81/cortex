---
description: Parallel best-of-N. Generate 3 diverse solution candidates simultaneously — each with a different strategy (simplicity, performance, readability) — evaluate all, and pick the winner via tournament selection. Cross-checks candidates for behavioral disagreements.
argument-hint: "Task description" [--n N] [--metric "shell command"]
---

# Cortex Sweep

You are running a parallel best-of-N experiment. Instead of trying one approach and hoping it's good, you generate N diverse candidates simultaneously and pick the best through tournament selection.

**Task:** $ARGUMENTS

If no task provided, ask: "What would you like to sweep? Describe the change you want implemented."

---

## Step 1: Pre-flight

1. Run `git status --porcelain`. If uncommitted changes, stop: "Commit or stash first."

2. Load `.cortex/profile.json` for conventions and default metric command.

3. Parse arguments:
   - `--n N` — number of candidates (default: 3, max: 5)
   - `--metric "<command>"` — evaluation metric (default: test command from profile)

4. Run metric to capture **baseline**.

5. Record savepoint: `SAVEPOINT=$(git rev-parse HEAD)`
   Do not stash — the working directory is already clean from Step 1.

---

## Step 2: Strategy Assignment

Assign one strategy to each candidate slot:
- Candidate A: `simplicity` — minimize lines, remove over add, prefer well-known patterns
- Candidate B: `performance` — prioritize metric improvement above all else
- Candidate C: `readability` — maximize clarity, explicit types, clear naming
- Candidate D (if n=4): `default` — balanced approach
- Candidate E (if n=5): `architectural` — consider structural changes, not just surface edits

Tell the user:
```
Launching N candidates in parallel:
  A: simplicity strategy
  B: performance strategy
  C: readability strategy
  ...
```

---

## Step 3: Sequential Generation

Launch N **experimenter** agents ONE AT A TIME (sequentially, not in parallel — all agents share the same working directory and simultaneous writes would corrupt results):

For each candidate slot (A, B, C, ...):
1. Restore to savepoint: `git reset --hard $SAVEPOINT`
2. Launch the **experimenter** agent with:
   - The task description
   - The metric command + baseline
   - Any existing experiment log from `.cortex/experiments/log.json` (avoid known bad approaches)
   - This candidate's assigned strategy hint
   - `think_harder: false`
   - Project conventions
3. After the agent finishes, save its changes as a patch file:
   `git diff > .cortex/experiments/candidate-<letter>.patch`
   (e.g. `candidate-a.patch`, `candidate-b.patch`)
   If the patch is empty, the agent made no changes — mark that candidate as failed.
4. Do NOT commit. The patch file is the persistent record of this candidate's work.

After all agents have run, restore to savepoint: `git reset --hard $SAVEPOINT`

---

## Step 4: Evaluation Tournament

For each candidate (A, B, C, ...) using the patch files saved in Step 3:

1. **Restore and apply**: `git reset --hard $SAVEPOINT && git apply .cortex/experiments/candidate-<letter>.patch`
   If `git apply` fails, mark that candidate as failed (patch didn't apply cleanly).
2. **Run metric**: Capture exit code + stdout
3. **Run lint** (if lint command in profile): capture pass/fail
4. **Count lines changed**: `git diff --stat | tail -1`
5. **Record result**:
   ```
   Candidate <letter>: metric=<value>, lint=<pass/fail>, lines_changed=<N>
   ```
6. **Restore**: Reset back to savepoint for next candidate

---

## Step 5: Cross-Check (if 2+ candidates passed)

If more than one candidate passed the metric:

Look at the implementations. Do they disagree on anything observable?
- Do they handle edge cases differently?
- Do they have different error handling strategies?
- Are there inputs where their outputs would differ?

If behavioral disagreements are found:
```
⚠ Cross-check found disagreement between candidates A and C:
  [file:line] Candidate A uses strict null check, C does not.
  One of these may have a bug. Review before selecting.
```

---

## Step 6: Tournament Selection

Score each candidate:
1. **Metric score** (primary): Best metric value wins. PASS > FAIL.
2. **Simplicity** (tiebreaker): Fewer lines changed wins.
3. **Convention compliance** (tiebreaker): Fewer lint warnings wins.

Present the ranked table:
```
## Sweep Results: "<task>"

| Candidate | Strategy      | Metric  | Lint | Lines Δ | Score |
|-----------|---------------|---------|------|---------|-------|
| B ✓       | performance   | 380kb   | PASS | +45     | 1st   |
| A         | simplicity    | 392kb   | PASS | +12     | 2nd   |
| C         | readability   | 401kb   | PASS | +28     | 3rd   |

Winner: Candidate B (performance strategy)
Metric: baseline 450kb → 380kb (-15.6%)
```

---

## Step 7: Apply Winner

Ask the user for confirmation before touching the working tree:

```
Apply winner (Candidate <X>, <strategy> strategy) and discard others? [Y/n]
```

If there are cross-check warnings from Step 5, surface them here before the user decides.

On confirmation:
1. Restore to savepoint: `git reset --hard $SAVEPOINT`
2. Apply the winner's patch: `git apply .cortex/experiments/candidate-<letter>.patch`
3. Commit: `git commit -am "sweep: <strategy> strategy — <description>"`
4. Delete the candidate patch files: `rm -f .cortex/experiments/candidate-*.patch`
5. Append the session to `.cortex/experiments/log.json` — read the existing file, push into the `sessions` array, write back. Never overwrite the whole file. Use `"type": "sweep"`:
   ```json
   {
     "id": "<ISO timestamp>",
     "type": "sweep",
     "task": "<task>",
     "metric_command": "<command>",
     "baseline": "<value>",
     "final_value": "<winner metric>",
     "started_at": "<ISO timestamp>",
     "completed_at": "<ISO timestamp>",
     "status": "completed",
     "attempts": [
       {
         "iteration": 1,
         "description": "<candidate description>",
         "metric_value": "<value>",
         "status": "keep | discard",
         "strategy": "<simplicity|performance|readability>",
         "reflection": "<null if kept, reason if discarded>",
         "files_changed": ["<paths>"],
         "timestamp": "<ISO timestamp>"
       }
     ],
     "patterns_learned": []
   }
   ```

On rejection (user says N):
- Restore to savepoint: `git reset --hard $SAVEPOINT`
- Delete patch files: `rm -f .cortex/experiments/candidate-*.patch`
- Tell the user: "No changes applied. Run `/cortex-sweep` again or try `/cortex-auto` for iterative improvement."

---

## Step 8: If All Candidates Failed

If no candidate passed or improved the metric:
```
All N candidates failed to improve the metric.

Best attempt:
  Candidate <X>: <metric value> (<description>)

Suggestions:
- Run /cortex-debug to diagnose why the metric isn't moving
- Run /cortex-auto to try iterative approaches with reflexion
- Revisit the metric command — is it measuring what you expect?
```

Log all attempts to the experiment log with status `discard` and reflections.

---

## Step 9: Summary

```
## Sweep Complete: "<task>"

Winner: Candidate <X> (<strategy> strategy)
Metric: <baseline> → <final> (<delta>)
Candidates evaluated: N

Run /cortex-review for quality review.
Run /cortex-ship to push and open a PR.
```
