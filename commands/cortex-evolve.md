---
description: Population-based evolutionary optimization for numeric metrics. Each generation produces N candidates (launched in parallel), the best survive and inspire the next generation. Simplicity pressure ensures elegant convergence. Like AlphaEvolve but for any codebase.
argument-hint: "Optimization goal" --metric "command that outputs a number" [--target value] [--generations N] [--population N]
---

# Cortex Evolve

You are running an evolutionary optimization. Each generation produces a population of candidate improvements. The best survive and inspire the next generation. Over multiple generations, the code evolves toward the goal.

**Goal:** $ARGUMENTS

If no goal provided, ask: "What would you like to optimize? (e.g., 'Reduce bundle size', 'Improve test coverage', 'Reduce TypeScript errors')"

---

## Step 1: Pre-flight

1. Run `git status --porcelain`. If uncommitted changes, stop.

2. Load `.cortex/profile.json`.

3. Parse arguments:
   - `--metric "<command>"` — **required**: must output a number to stdout (e.g., `npx tsc --noEmit 2>&1 | grep -c error`, `du -b dist/bundle.js | cut -f1`)
   - `--target <value>` — stop when metric reaches this value (optional)
   - `--generations N` — max generations (default: 10)
   - `--population N` — candidates per generation (default: 3)

4. Run metric to capture **baseline**. Verify it outputs a parseable number. If not: "The metric command must output a number to stdout. Example: `echo 42` or `wc -l src/*.ts | tail -1 | awk '{print $1}'`"

5. Create branch: `git checkout -b cortex-evolve/<goal-slug>`
   - Sanitize goal to slug: lowercase, spaces→hyphens, strip non-alphanumeric, max 30 chars
   - If branch already exists: offer "(1) Resume from last kept commit or (2) Delete and start fresh"

6. If target is provided and baseline already meets it: "Baseline already meets the target. Nothing to optimize."

7. Show setup:
```
## Cortex Evolve: "<goal>"
Metric: <command>
Baseline: <value>
Target: <value or "minimize">
Generations: <max>
Population: <per generation>
Branch: <branch name>
```

---

## Step 2: Initialize Program Database

Create `.cortex/experiments/active-session.json` with:
- Session type: `evolve`
- Task, metric, baseline, target
- `program_database: []` — will hold all candidate implementations tried, with their scores
- `generation: 0`
- `current_best: baseline`
- `last_kept_commit: <HEAD>`

The program database is the core of the evolutionary approach: every candidate tried is stored with its score and description. When generating new candidates, the top-K from this database are shown as "inspirations."

---

## Step 3: Generation Loop

**LOOP** for each generation (1 to max):

### 3a. Announce Generation
```
## Generation N / <max>
Current best: <value>  (baseline: <baseline>, improvement so far: <delta>)
```

### 3b. Select Inspirations
From the program database, select the **top 3 by metric** (best scores so far).
These will be shown to all candidate agents as examples of successful approaches.

### 3c. Generate Population (Sequential)
Launch `population` number of **experimenter** agents ONE AT A TIME (sequentially — agents share the working directory, so parallel writes would corrupt results). For each candidate:

1. Restore to `last_kept_commit`: `git reset --hard $LAST_KEPT_COMMIT`
2. Launch the **experimenter** agent with:
   - The optimization goal
   - The metric command + current best value
   - The program database (all attempts so far with scores) — so it avoids tried approaches
   - The top 3 inspirations explicitly highlighted: "These changes improved the metric — use them as inspiration for your approach"
   - A different strategy hint per candidate:
     - Agent 1: `simplicity` — favor removing code
     - Agent 2: `performance` — maximize metric movement
     - Agent 3: `default` — balanced approach
     - (Additional agents rotate through these strategies)
   - `think_harder: true` if generation >= 3 and no improvement in last 2 generations
   - Project conventions
3. After the agent finishes, capture its changes as a diff
4. Restore to `last_kept_commit` before the next agent runs

After all agents have run, proceed to evaluation.

### 3d. Evaluate Population
For each candidate:
1. Apply changes to codebase (restore to last_kept_commit first, then apply)
2. Run metric command — capture the number
3. Apply **simplicity pressure**: if metric delta is ≤ 2% improvement but adds >30 lines, automatically count as tied (score = current best)
4. Record in program database: description, metric value, lines_added, lines_removed, status pending
5. Reset to last_kept_commit

### 3e. Select Survivor
The single best candidate this generation = lowest metric value. If tied by metric, choose the one with fewer lines added (simplicity pressure).

If the best candidate improved on `current_best`:
- **KEEP it**: Apply the survivor's changes, commit: `"evolve: gen N — <description> (<old> → <new>)"`
- Update `current_best` and `last_kept_commit`
- Mark candidate as `keep` in program database
- Mark all others in this generation as `discard`
- Clear `no_improvement_streak`

If no candidate improved on `current_best`:
- **No advancement** this generation
- Mark all as `discard` in program database
- Increment `no_improvement_streak`

### 3f. Progress Visualization

After each generation, show progress as a text chart:
```
Progress (lower is better):
Gen 0 (baseline): 450,000  ████████████████████████████████████████
Gen 1:            430,000  ██████████████████████████████████████  (KEEP, -4.4%)
Gen 2:            430,000  ██████████████████████████████████████  (no improvement)
Gen 3:            412,000  ████████████████████████████████████    (KEEP, -8.4%)
Target:           200,000  ██████████████████
```

### 3g. Check Stopping Conditions
- If `current_best <= target`: break (goal achieved)
- If `generation >= max`: break
- If `no_improvement_streak >= 3`:
  ```
  No improvement in 3 consecutive generations. Entering think-harder mode.
  Agents will now try unconventional and structural approaches.
  ```
  Set `think_harder: true` for remaining generations
- If `no_improvement_streak >= 5`: pause and ask user to continue or stop

---

## Step 4: Extract Patterns

Read all entries in the program database. Extract patterns:
- Which approach categories (optimization/refactor/removal/architectural) tended to improve the metric?
- What did discarded attempts have in common?
- Any constraints discovered?

---

## Step 5: Completion

```
## Cortex Evolve: Complete

Goal: "<goal>"
Metric command: <command>

Baseline:  <value>
Final:     <current_best>
Improvement: <absolute delta> (<percentage>%)
Target: <met ✓ / not reached ✗>

Generations run: N  |  Candidates evaluated: M  |  Kept: K

Progress:
<text chart showing all generations>

Patterns learned:
- <pattern 1>
- <pattern 2>

Branch: <branch-name>

Next: /cortex-review, /cortex-ship
```

Save patterns to `log.json` session entry.
