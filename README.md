# Cortex

> Autonomous experiment loops and project intelligence for Claude Code.

Cortex gives Claude two things: **permanent memory of your project** (conventions, architecture, CI commands — scanned once, used forever), and an **autonomous experiment engine** that improves your code against any metric while you sleep.

```bash
curl -fsSL https://raw.githubusercontent.com/Messier81/cortex/main/install.sh | bash
```

---

## The idea

You give Cortex a goal and a way to measure it:

```
/cortex-auto "Fix all TypeScript strict errors" --metric "npx tsc --noEmit 2>&1 | grep -c error"
```

It runs a loop — make a change, measure, keep or discard, write a reflection on why it failed, try again — until the goal is met or you hit the limit. Each failure teaches the next attempt something specific about *this* codebase.

```
Baseline: 47 errors

✓  Attempt 1  Add null checks in useAuth          47 → 31 errors
✗  Attempt 2  Add `as unknown as T` casts         31 → 33 errors  ← regression
              Reflection: type assertions hide errors downstream. avoid them.
✓  Attempt 3  Explicit return types in services   31 → 18 errors
✓  Attempt 4  Optional chaining in UserProfile    18 → 9 errors
...
✓  Goal met after 11 attempts. 47 → 0 errors.
```

Not just pass/fail — it builds causal understanding of why things fail in your specific codebase.

---

## Install

```bash
# Into your project
cd your-project
curl -fsSL https://raw.githubusercontent.com/Messier81/cortex/main/install.sh | bash

# Or clone first
git clone https://github.com/Messier81/cortex
cd cortex && ./install.sh /path/to/your-project
```

Then scan your project once:

```bash
/cortex-init
```

Commit `.cortex/profile.json` and `.cortex/CONVENTIONS.md` — your whole team benefits.

> Pair with [pctx](https://github.com/Messier81/pctx) for decision tracking and cross-session intelligence. Cortex works without it, but pctx unlocks `/cortex-reflect` and `/cortex-digest`.

---

## Commands

### Experimentation

**`/cortex-auto <task> --metric "<command>"`**
Autonomous improvement loop. Reflexion memory, curriculum decomposition (easy→hard sub-goals), best-shot context (top 3 past wins shown to each attempt). Runs until goal met or `--max` hit.

**`/cortex-sweep <task>`**
Generate N candidates simultaneously — each with a different strategy (simplicity, performance, readability) — evaluate all, apply the winner. Cross-checks candidates for behavioral disagreements.

```
| Candidate | Strategy    | Tests | Lines Δ | Rank |
|-----------|-------------|-------|---------|------|
| A ✓       | simplicity  | PASS  | +42     | 1st  |
| C         | readability | PASS  | +67     | 2nd  |
| B         | performance | FAIL  | +89     | 3rd  |
```

**`/cortex-evolve <goal> --metric "<command>"`**
Evolutionary optimization across generations. Best survivors inspire the next generation. Simplicity pressure penalizes bloat.

```
Gen 1:  430,120 bytes  (KEEP -6.1%)   tree-shake lodash
Gen 2:  412,400 bytes  (KEEP -9.8%)   lazy-load routes
Gen 5:  365,200 bytes  (KEEP -20.2%)  replace moment → date-fns
Gen 8:  198,200 bytes  (KEEP ✓ TARGET MET -56.7%)
```

**`/cortex-experiment <hypothesis>`**
Single cycle: one change, one measurement, keep or discard with a reflection.

**`/cortex-log [--patterns]`**
View experiment history. `--patterns` synthesizes what this codebase has learned across all sessions.

```
What Tends to Work
  - Removing unused imports (tree-shaking not configured — big wins)
  - Explicit return types in service layer

What Tends to Fail
  - Type assertions — hide errors, cause downstream failures
  - Changing the auth store shape — blast radius too high (5+ consumers)
```

### Project Intelligence

**`/cortex-init [--update]`**
Scan codebase with 3 parallel agents. Derives naming conventions, test locations, CI commands, core abstractions, and coupling hotspots (files that frequently change together in git). `--update` rescans only changed files.

**`/cortex-build`**
Execute a structured plan step by step. Each step gets a fresh isolated context — no accumulated garbage from previous steps degrading quality.

### Cross-Session Intelligence

**`/cortex-reflect`**
Full synthesis: experiment patterns, pctx decision history, progressions (how understanding evolved), stale knowledge. The compound intelligence flywheel.

**`/cortex-digest`**
Quick daily reference card. Recent decisions + recent experiment learnings. Designed to be called at the start of a session.

---

## How it works

**Reflexion memory** — on every discard, the experimenter writes a structured reflection: what it tried, why it failed, what constraint it learned. This feeds into subsequent attempts. By attempt 5, the agent understands why things fail in this codebase, not just what failed.

**Best-shot context** — the top 3 successful past changes are shown to each new attempt as examples. The agent learns what kinds of changes work here.

**Curriculum decomposition** — complex goals are broken into sub-goals ordered easy→hard. Early wins scaffold harder problems.

**Git checkpoints** — creates a dedicated branch, commits before each attempt, `git reset --hard` on discard. The branch shows exactly what worked.

**Context isolation in builds** — each plan step gets a compact context packet (conventions + prior step summaries) rather than the full accumulated session. Step 8 runs with the same quality as step 1.

---

## What's inside

```
9 commands · 4 agents · 2 hooks
Pure markdown + shell. Zero dependencies.
```

| | |
|---|---|
| **Agents** | `convention-scanner`, `dependency-mapper`, `history-analyzer`, `experimenter` |
| **Hooks** | `pre-task-inject` — injects project context + recent experiment learnings on every prompt |
| | `post-tool-lint` — auto lint-fix after every file write |

---

## What gets committed

```
.cortex/
├── profile.json        ← commit (shared project intelligence)
├── CONVENTIONS.md      ← commit (human-readable reference)
└── experiments/        ← gitignored (local history)
    └── log.json
```

---

## License

MIT
