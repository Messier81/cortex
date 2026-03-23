---
description: Run a single experiment — try one specific hypothesis, measure the result against a metric, then keep or discard with proper git management. Writes a reflection on discard. The atomic unit of the Cortex experimentation system.
argument-hint: "Hypothesis to test" [--metric "measurement command"]
---

# Cortex Experiment

You are running a single experiment cycle: one hypothesis, one measurement, one decision. This is the atomic unit — `/cortex-auto` runs many of these in a loop.

**Hypothesis:** $ARGUMENTS

If no hypothesis provided, ask: "What do you want to try? Describe the specific change you want to test."

---

## Step 1: Pre-flight

1. Run `git status --porcelain`. If there are uncommitted changes, stop:
   > "Working directory has uncommitted changes. Commit or stash them first, then re-run."

2. Load `.cortex/profile.json` if it exists (for project conventions and default test command).

3. Parse `--metric` from `$ARGUMENTS` if provided. If not:
   - Use the `test` command from `.cortex/profile.json` if available
   - Otherwise ask: "What command measures success? (e.g., `npm test`, `npx tsc --noEmit`, `wc -l src/*.ts`)"

---

## Step 2: Capture Baseline

Run the metric command. Capture:
- Exit code (0 = pass, nonzero = fail)
- stdout (if it's a number, treat as numeric metric)

Show the user:
```
Baseline: <value or PASS/FAIL>
```

If the baseline metric crashes (error, not just failure), warn: "Metric command failed on baseline. Fix this before running experiments."

---

## Step 3: Create Savepoint

Run: `git stash push -m "cortex-experiment: savepoint before <short hypothesis>"`

Or if a commit is preferred: `git commit --allow-empty -m "experiment: savepoint"`

Record the savepoint ref.

---

## Step 4: Load Experiment History

Check if `.cortex/experiments/log.json` exists. If it does, load it and extract:
- Previous attempts related to this hypothesis (keyword match)
- Any reflections that might be relevant

Pass this context to the experimenter agent.

---

## Step 5: Launch Experimenter

Launch the **experimenter** agent with:
- The hypothesis as the task
- The metric command and baseline value
- Relevant experiment history and reflections
- `strategy_hint: "default"`
- `think_harder: false`
- Project conventions from profile

---

## Step 6: Measure

Run the metric command again. Capture exit code + stdout.

Parse the result:
- **Pass/fail metric**: did it change from FAIL to PASS? Or PASS to FAIL (regression)?
- **Numeric metric**: is the number better? (lower is better for error counts, bundle sizes; higher is better for scores, coverage)

Show comparison:
```
Baseline:  <value>
After:     <value>
Delta:     <+/- or changed to PASS/FAIL>
```

---

## Step 7: Decide

Auto-recommend based on the metric:
- If improved or passed: **Recommend KEEP** ✓
- If same or worse: **Recommend DISCARD** ✗
- If the metric crashed: **Recommend DISCARD** ✗ (and note it as a crash)

Ask the user to confirm:
```
Recommendation: KEEP / DISCARD
Keep this change? [Y/n]
```

**If KEEP:**
- Unstash/keep the changes
- Commit: `git commit -am "experiment: keep — <hypothesis short form>"`
- Append to `.cortex/experiments/log.json` with status `keep` and no reflection needed

**If DISCARD:**
- Restore savepoint: `git stash pop` (or `git reset --hard` to savepoint commit)
- Write a reflection: Ask the experimenter agent (or infer from the result) to explain why this failed
- Append to `.cortex/experiments/log.json` with status `discard` and the reflection

---

## Step 8: Update Experiment Log

Ensure `.cortex/experiments/` directory exists. Write/append to `.cortex/experiments/log.json`:

```json
{
  "sessions": [
    {
      "id": "<ISO timestamp>",
      "type": "experiment",
      "task": "<hypothesis>",
      "metric_command": "<command>",
      "baseline": "<value>",
      "final_value": "<value>",
      "started_at": "<run: date -u +%Y-%m-%dT%H:%M:%SZ>",
      "completed_at": "<run: date -u +%Y-%m-%dT%H:%M:%SZ>",
      "status": "keep | discard | crash",
      "attempts": [
        {
          "iteration": 1,
          "description": "<experimenter's description>",
          "metric_value": "<value>",
          "status": "keep | discard | crash",
          "reflection": "<why it failed, or null if kept>",
          "files_changed": ["<paths>"],
          "timestamp": "<run: date -u +%Y-%m-%dT%H:%M:%SZ>"
        }
      ],
      "patterns_learned": []
    }
  ]
}
```

---

## Step 9: Summary

```
## Experiment Complete

Hypothesis: <hypothesis>
Result: KEPT ✓ / DISCARDED ✗

Baseline:  <value>
Final:     <value>

<If discarded>:
Reflection: <why it failed>

Run /cortex-log to see full experiment history.
Run /cortex-auto to run experiments autonomously.
```
