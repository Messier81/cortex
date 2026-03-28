---
description: Full cross-session intelligence synthesis. Surfaces what this project has learned — decisions made, experiment patterns, architectural constraints, and how understanding has evolved. Uses pctx if available, falls back to log.json only.
argument-hint: "[--since <date>] [keyword filter]"
---

# Cortex Reflect

You are synthesizing everything this project has learned across all sessions. This is the compound intelligence flywheel — every experiment, every decision, every correction surfaced in one coherent narrative.

**Arguments:** $ARGUMENTS

---

## Step 1: Load Sources

### From log.json (always)
Read `.cortex/experiments/log.json` if it exists. Extract:
- All `patterns_learned` arrays across all sessions
- All `reflection` fields from all attempts
- Session metadata: type, task, metric, baseline→final, date, status

If log.json doesn't exist, note: "No experiment history yet."

### From pctx (if available)
Check if pctx tools are available by attempting `pctx_list`. If available:
- Call `pctx_reflect` to get the full narrative of recorded decisions, experiences, beliefs, and threads
- Call `pctx_search` with tags `["cortex-experiment"]` for experiment experience records
- Call `pctx_list` to see all record types and their counts

If pctx is not available, continue with log.json data only. Note at the top of the output: "(pctx not connected — showing experiment data only. Connect pctx for full decision history.)"

---

## Step 2: Synthesize Intelligence

### 2a. What This Project Has Learned (Experiments)

From all experiment sessions, synthesize:

```
## What This Codebase Has Learned
From <N> experiment sessions across <date range>

### What Tends to Work
- <pattern> — seen in N sessions
...

### What Tends to Fail
- <pattern> — failed N times
...

### Architectural Constraints Discovered
- <constraint> — discovered via <experiment type>
...

### High-Impact Areas
- <area> — consistently delivers metric improvements
...
```

### 2b. Decision History (if pctx available)

From pctx `decision` records, show:

```
## Decision History

### Active Decisions (<N> total)
- [DEC-001] <title> — <one-line summary> (<date>)
- [DEC-002] ...

### Decision Progressions (Understanding That Evolved)
If any decisions have `supersedes` links, trace the chain:
- DEC-001 → DEC-004 → DEC-007: "Auth approach evolved from session-based → JWT → PASETO"
  This shows how understanding shifted, not just the final decision.

### Stale Decisions (>30 days, may need review)
- [DEC-003] <title> — last updated <date>
```

### 2c. Experiment × Decision Connections (if pctx available)

Call `pctx_connections` to find records that are related but not yet explicitly linked.

If any experiment experience records relate to existing decisions (same topic/files), flag them:
```
## Connections Found
- Experiment "Reduce bundle size" patterns relate to DEC-002 ("Use dynamic imports") — consider linking
```

---

## Step 3: Output

Present the full synthesis. Format for scanning:

```
# Cortex Reflect: <project name>
Generated: <date>

## Intelligence Sources
- Experiments: <N> sessions, <M> total attempts
- pctx records: <K> decisions, <L> experiences, <P> other (or "pctx not connected")

---

<synthesized sections from Step 2>

---

## Recommended Actions
- <action based on stale decisions or unlinked experiments>
- <action if patterns suggest an architecture problem>
- Run /cortex-digest for a quick daily reference card.
- Run /cortex-log --patterns for experiment-only pattern view.
```

If there is very little data (< 3 experiment sessions and < 5 pctx records), tell the user:
"Not enough history to synthesize yet. Run some experiments with /cortex-auto or save decisions to pctx to build up intelligence."
