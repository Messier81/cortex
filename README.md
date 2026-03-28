# Cortex

**Autonomous experimentation and project intelligence for Claude Code.**

Give Cortex a goal and a metric. It loops on its own — making changes, measuring results, keeping improvements, learning from failures — until the goal is met. It also scans your project once so Claude never starts cold again.

**9 commands. 4 agents. 2 hooks. Zero configuration.**

---

## The Problem

Claude Code starts cold every session. It doesn't know your naming conventions, test locations, CI commands, or architecture. So you repeat yourself or write a CLAUDE.md that goes stale.

And when you want to improve something measurable — reduce errors, shrink bundle size, improve coverage — you're stuck running the same manual loop: change, test, revert, repeat. There's no way to hand that off.

Cortex fixes both.

---

## Install

```bash
cd your-project
curl -fsSL https://raw.githubusercontent.com/Messier81/cortex/main/install.sh | bash
```

Or clone and point at a project:

```bash
git clone https://github.com/Messier81/cortex
cd cortex && ./install.sh /path/to/your-project
```

Then run once per project:

```bash
/cortex-init
```

> **Tip:** Install the [pctx MCP server](https://github.com/Messier81/pctx) for decision tracking and cross-session intelligence. Cortex works fully without it, but pctx unlocks `/cortex-reflect` and `/cortex-digest`.

---

## What Cortex Does

### Project Intelligence

Scans your codebase once and auto-derives everything Claude needs: naming conventions, test locations, CI commands, core abstractions, git style, and now — **which files are highest-risk to change** (coupling hotspots detected from import analysis and git history).

Stores everything in `.cortex/profile.json` and `.cortex/CONVENTIONS.md`. Commit both — your whole team benefits.

A hook fires on every prompt and injects a brief context summary automatically. Claude knows your project before you say anything.

### Autonomous Experimentation

Three modes for running experiments:

**`/cortex-auto`** — the main loop. Give it a task and a metric command. It runs autonomously: make a change, measure, keep or discard, reflect on why failures happened, try again. Runs until the goal is met or you hit `--max` iterations.

**`/cortex-sweep`** — best-of-N. Generates N candidates simultaneously with different strategies (simplicity, performance, readability), evaluates all, picks the winner via tournament selection. Cross-checks candidates for behavioral disagreements.

**`/cortex-evolve`** — evolutionary optimization. Each generation spawns N candidates inspired by the best solutions so far. Simplicity pressure keeps the code clean across generations.

**`/cortex-experiment`** — single cycle. One hypothesis, one measurement, keep or discard.

### Cross-Session Learning

Every experiment accumulates structured reflections — not just pass/fail, but *why* things fail. These feed forward into future attempts in the same session, and optionally into pctx as `experience` records discoverable across future sessions.

**`/cortex-reflect`** synthesizes everything: experiment patterns, pctx decision history, architectural constraints, how understanding evolved.

**`/cortex-digest`** gives you a quick daily reference card: recent decisions + recent experiment learnings.

---

## Quick Start

```bash
# One-time: scan the project
/cortex-init

# Autonomous improvement
/cortex-auto "Fix all TypeScript strict mode errors" --metric "npx tsc --noEmit 2>&1 | grep -c error"

# Or try N approaches, pick the winner
/cortex-sweep "Add input validation to the API layer"

# Review what the codebase has learned
/cortex-log --patterns
/cortex-reflect
```

---

## Walkthrough: Autonomous Experimentation

### `/cortex-auto` — Reflexion loop

```
/cortex-auto "Fix all TypeScript strict mode errors" --metric "npx tsc --noEmit 2>&1 | grep -c error" --max 15
```

```
Decomposed into 3 sub-goals:
  1. Fix null/undefined errors (most mechanical)
  2. Fix implicit `any` types
  3. Fix strict function type errors

Baseline: 47 errors

✓ Attempt 1: KEEP — Add null checks in useAuth hook
  47 → 31 errors

✗ Attempt 2: DISCARD — Add `as unknown as T` casts
  31 → 33 errors (regression)
  Reflection: Type assertions hide errors instead of fixing them. This codebase
  catches them downstream. Avoid assertions — use proper narrowing instead.

✓ Attempt 3: KEEP — Add explicit return types to service functions
  31 → 18 errors

[...continuing autonomously...]

Goal met after 11 attempts. 47 → 0 errors.
8 kept · 3 discarded

Patterns learned:
- Type assertions consistently make things worse here
- Service layer is the highest-yield target for type annotations
- Component props are already well-typed — focus on hooks and utilities
```

The reflexion system captures *why* attempts fail. By attempt 5, the agent isn't just avoiding past approaches — it understands the constraints of this specific codebase.

### `/cortex-sweep` — Parallel best-of-N

```
/cortex-sweep "Add rate limiting to the API" --n 3
```

```
Generating 3 candidates:
  A: simplicity  — minimize lines, remove over add
  B: performance — maximize metric improvement
  C: readability — clarity, explicit types, clean naming

| Candidate | Strategy    | Tests | Lint | Lines Δ | Rank |
|-----------|-------------|-------|------|---------|------|
| A ✓       | simplicity  | PASS  | PASS | +42     | 1st  |
| C         | readability | PASS  | PASS | +67     | 2nd  |
| B         | performance | FAIL  | PASS | +89     | 3rd  |

Winner: Candidate A
```

If multiple candidates pass, Cortex cross-checks them for behavioral disagreements before you decide.

### `/cortex-evolve` — Evolutionary optimization

```
/cortex-evolve "Reduce bundle size" --metric "du -b dist/bundle.js | cut -f1" --target 200000 --generations 8
```

```
Baseline: 458,240 bytes  |  Target: 200,000 bytes

Gen 1:  ████████████████████████  430,120  (KEEP, -6.1%)   [tree-shake lodash]
Gen 2:  ███████████████████████   412,400  (KEEP, -9.8%)   [lazy-load routes]
Gen 3:  ███████████████████████   412,400  (no improvement)
Gen 4:  ██████████████████████    390,800  (KEEP, -14.7%)  [code split vendor]
Gen 5:  █████████████████████     365,200  (KEEP, -20.2%)  [replace moment → date-fns]
Gen 6:  ████████████████████      340,100  (KEEP, -25.7%)  [replace axios → native fetch]
Gen 7:  ██████████████████        290,400  (KEEP, -36.6%)  [remove unused polyfills]
Gen 8:  █████████████████         198,200  (KEEP ✓ TARGET MET, -56.7%)
```

Simplicity pressure is built in: candidates that add >30 lines for ≤2% gain are ranked alongside the current best, not above it.

---

## All Commands

### Project Intelligence

| Command | What it does |
|---------|-------------|
| `/cortex-init` | Scan codebase, derive conventions, architecture, coupling hotspots. Creates `.cortex/profile.json` and `CONVENTIONS.md`. |
| `/cortex-init --update` | Rescan only changed files and patch the profile. Faster than a full re-init. |

### Experimentation

| Command | What it does |
|---------|-------------|
| `/cortex-auto <task>` | Autonomous loop. Reflexion memory, curriculum decomposition, best-shot context. Runs until goal met or `--max` hit. |
| `/cortex-sweep <task>` | Generate N candidates with different strategies, evaluate all, apply the winner. |
| `/cortex-evolve <goal>` | Evolutionary optimization across generations with simplicity pressure and progress visualization. |
| `/cortex-experiment <hypothesis>` | Single cycle: try one change, measure, keep or discard with reflection. |
| `/cortex-log [query]` | View experiment history. `--patterns` synthesizes what's been learned across all sessions. |

### Building (when you have a specific plan)

| Command | What it does |
|---------|-------------|
| `/cortex-build` | Execute a structured plan step by step. Each step runs in isolation with a fresh context packet — no context rot across steps. Resumes if interrupted. |

### Intelligence Synthesis

| Command | What it does |
|---------|-------------|
| `/cortex-reflect` | Full cross-session synthesis — experiment patterns, pctx decisions, progressions, stale knowledge. |
| `/cortex-digest` | Quick daily reference card: recent decisions + experiment learnings. |

---

## What Gets Committed

```
.cortex/
├── profile.json        ← commit this (shared project intelligence)
├── CONVENTIONS.md      ← commit this (human-readable reference)
├── .gitignore          ← auto-created
└── experiments/        ← NOT committed (local experiment history)
    ├── active-session.json
    └── log.json
```

---

## What's Inside

| Component | Count | Details |
|-----------|-------|---------|
| Commands | 9 | init, build, auto, sweep, evolve, experiment, log, reflect, digest |
| Agents | 4 | convention-scanner, dependency-mapper, history-analyzer, experimenter |
| Hooks | 2 | `pre-task-inject` (context + experiment learnings on every prompt) · `post-tool-lint` (auto lint-fix on file write) |

Pure markdown + shell scripts. Zero dependencies beyond Claude Code.

---

## How It Compares

**vs. autoresearch / AlphaCode-style loops**: Cortex adds reflexion memory (learning *why* failures happen), curriculum decomposition (easy→hard sub-goals), best-shot context (successful past attempts as inspiration), and cross-session pattern accumulation. autoresearch keeps a TSV of results — Cortex builds causal understanding.

**vs. GSD / complex workflow plugins**: Cortex deliberately avoids replicating what Claude Code already does well (planning, reviewing, debugging, shipping). Research shows complex plugins burn tokens and hurt performance. Cortex focuses on the one thing it uniquely provides: the experiment loop and project intelligence.

**vs. building your own CLAUDE.md**: A static CLAUDE.md goes stale, can't track decisions or experiments, and adds token overhead with diminishing returns (ETH Zurich 2026: LLM-generated context files reduce task success by 3%). Cortex's profile is auto-generated, stays current with `--update`, and injects only what's needed per prompt via the hook.

---

## License

MIT
