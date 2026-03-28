---
description: Quick-reference decision digest. Shows the most recent decisions and experiment learnings as a compact card. Lightweight — designed to be called frequently. Uses pctx if available.
argument-hint: "[--decisions N] [--experiments N]"
---

# Cortex Digest

You are generating a quick-reference card — the most recent and relevant intelligence from this project in a compact, scannable format. Fast to generate, designed to be called at the start of a work session.

**Arguments:** $ARGUMENTS (parse `--decisions N` and `--experiments N` for overrides; defaults: 5 decisions, 3 experiments)

---

## Step 1: Load Recent Intelligence

### From log.json (always)
Read `.cortex/experiments/log.json` if it exists. Extract the most recent N `patterns_learned` entries (one per session, most recent first). Skip sessions with empty `patterns_learned`.

If no log.json: note "No experiment history yet."

### From pctx (if available)
Check if pctx tools are available by attempting `pctx_list`. If available:
- Call `pctx_list` filtered to `record_type: "decision"` and `status: "accepted"`, sorted by most recent, take top N
- Call `pctx_search` with tags `["cortex-experiment"]`, take top 3 most recent experience records

If pctx is not available, continue with log.json only.

---

## Step 2: Output the Digest Card

Format as a compact reference card:

```
## Cortex Digest — <project name>
<date>

### Recent Decisions (from pctx)
1. [DEC-007] <title> — <one-line body summary> (<date>)
2. [DEC-006] <title> — ...
3. ...
(Run /cortex-reflect for full decision history and progressions)

### Recent Experiment Learnings
1. <pattern from most recent session> (from <session type>, <date>)
2. <pattern>
3. <pattern>
(Run /cortex-log --patterns for full pattern synthesis)

### Quick Context
- Stack: <from profile.json if available>
- Test: `<test command>`
- Lint: `<lint command>`
```

**If pctx not connected**, skip the decisions section and show only experiment learnings + quick context. Add a note: "Connect pctx to see decision history here."

**If no data at all** (no profile, no log, no pctx): tell the user:
"Nothing to show yet. Run /cortex-init to scan your project, then use /cortex-auto to start experimenting."

---

## Step 3: Done

No follow-up questions. The digest is meant to be glanced at quickly. If the user wants more depth: `/cortex-reflect` for full synthesis, `/cortex-log --patterns` for experiment patterns.
