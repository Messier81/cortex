---
description: View and query the experiment history. Shows all past sessions (auto, sweep, evolve, experiment) with metrics and outcomes. Use --patterns to see codebase-specific patterns learned from all reflections.
argument-hint: "[keyword or session ID] [--patterns]"
---

# Cortex Log

You are querying the Cortex experiment history — a record of everything tried across all experiment sessions, including reflections on failures and patterns learned.

---

## Step 1: Load Log

Read `.cortex/experiments/log.json`.

If the file doesn't exist or is empty:
```
No experiment history found.

Run /cortex-experiment, /cortex-auto, /cortex-sweep, or /cortex-evolve to start experimenting.
```

If the file exists but is not valid JSON (malformed/truncated):
```
⚠ Experiment log is corrupted or incomplete (.cortex/experiments/log.json).
You can delete it to start fresh, or inspect it manually to recover data.
```
Stop — do not attempt to parse invalid JSON.

If valid JSON but `sessions` array is empty or missing: treat the same as "no sessions" above.

---

## Step 2: Parse Arguments

**If `$ARGUMENTS` contains `--patterns`:**
Go to Step 5 (Pattern Summary mode).

**If `$ARGUMENTS` is empty:**
Go to Step 3 (Session Summary mode).

**If `$ARGUMENTS` is a keyword or session ID (without --patterns):**
Go to Step 4 (Filtered Detail mode).

---

## Step 3: Session Summary Mode

Show a summary table of all sessions, most recent first:

```
## Experiment Log

| Date        | Type       | Task                              | Baseline | Final  | Δ      | Kept | Status     |
|-------------|------------|-----------------------------------|----------|--------|--------|------|------------|
| 2026-03-24  | auto       | Fix TypeScript strict errors      | 47 err   | 0 err  | -100%  | 8    | completed  |
| 2026-03-23  | evolve     | Reduce bundle size                | 450kb    | 280kb  | -37.8% | 5    | completed  |
| 2026-03-22  | experiment | Replace lodash with native        | PASS     | PASS   | —      | 1    | keep       |
| 2026-03-21  | sweep      | Add input validation              | FAIL     | PASS   | ✓      | 1    | completed  |

Total: N sessions  |  M experiments run  |  K improvements kept

Run /cortex-log <keyword> to filter  |  /cortex-log --patterns to see learned patterns
```

---

## Step 4: Filtered Detail Mode

Filter sessions where the task description OR any attempt description contains `$ARGUMENTS`.

For each matching session, show full detail:

```
## Session: <date> — <task>
Type: <type>  |  Status: <status>
Metric: <command>
Baseline: <value>  →  Final: <value>  (<delta>)

### Attempts

| # | Description                        | Metric  | Status  |
|---|------------------------------------|---------|---------|
| 1 | Tree-shake lodash imports          | 430kb   | ✓ KEEP  |
| 2 | Replace moment.js with date-fns    | 440kb   | ✗ DISCARD |
| 3 | Lazy-load routes                   | 380kb   | ✓ KEEP  |

### Reflections (discards)
- Attempt 2: "Replacing moment with date-fns would have saved 20kb, but date-fns locale files were
  also being imported. The net change was actually larger. Learned: check ALL imports of a package,
  not just direct usage."

### Patterns Learned
- <pattern 1>
- <pattern 2>
```

---

## Step 5: Pattern Summary Mode (`--patterns`)

Extract and synthesize ALL patterns from ALL sessions in the log.

Read every `patterns_learned` array and every `reflection` field across all sessions.

**pctx enhancement (if available)**: also call `pctx_search` with tags `["cortex-experiment"]` to retrieve any experiment experience records stored in pctx. Merge these with the local `log.json` patterns — pctx may have patterns from sessions run in other worktrees or before the local log existed.

Organize the synthesized patterns into categories:

```
## Codebase Patterns — Learned from N Experiments
<Source: log.json (N sessions) + pctx (M records)>

### What Tends to Work
- <pattern> (seen in N sessions)
- <pattern>
- <pattern>

### What Tends to Fail
- <pattern> (failed in N attempts across M sessions)
- <pattern>

### Architectural Constraints Discovered
- <constraint> (e.g., "Changing the auth store requires updating 5+ consumers")
- <constraint>

### High-Impact Areas
- <finding> (e.g., "Unused imports are high-impact — tree-shaking is not configured")

### Low-Impact Areas
- <finding> (e.g., "CSS optimization has minimal effect — styles are not on the critical path")

---
Patterns extracted from experiment reflections across all sessions.
Run /cortex-reflect for a full cross-session intelligence synthesis.
```

This is the "Voyager skill library" equivalent — accumulated knowledge from all experiments, surfaced as actionable patterns specific to this codebase.
