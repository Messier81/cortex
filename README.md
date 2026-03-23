# Cortex

**Project intelligence, complete workflow, and autonomous experimentation for Claude Code.**

Cortex tells Claude what to know about your project, gives it a complete plan-build-review-ship workflow, and lets it run autonomous experiment loops overnight — improving your code while you sleep.

**19 commands. 11 agents. Zero configuration. No other tools required.**

---

## The Problem

Every time you open Claude Code, it starts cold. It doesn't know your naming conventions, where your tests live, what commands CI runs, or how your architecture is organized. So you repeat yourself every session or write a CLAUDE.md that immediately goes stale.

And if you want a real workflow — not just one-shot code generation — you need to install three separate tools that overlap and conflict.

And there's no way to run Claude autonomously overnight, improving a metric across dozens of iterations, the way a researcher would run experiments.

Cortex fixes all three.

---

## Install

### As a Claude Code plugin (recommended)

```bash
/plugin install cortex-cc/cortex
```

Then in any project:

```bash
/cortex-init
```

### Into a specific project

```bash
# From the web (run from your project root)
curl -fsSL https://raw.githubusercontent.com/Messier81/cortex/main/install.sh | bash

# Or clone and install locally
git clone https://github.com/Messier81/cortex
cd cortex && ./install.sh /path/to/your/project
```

---

## Three Things Cortex Does

### 1. Project intelligence

Scans your codebase once and auto-derives everything Claude needs to know: naming conventions, test locations, CI commands, core abstractions, git style. Stores it in `.cortex/profile.json` and `.cortex/CONVENTIONS.md`. Commit both — your whole team benefits.

Every future session starts with this context already loaded. No more repeating yourself.

### 2. Complete workflow

A full plan → build → review → ship loop without needing any other tool. Plans are structured and require approval before a line of code is written. Builds execute step by step with TDD discipline and stop on failure instead of spinning. Review is two-stage: spec compliance first, then code quality. Ship creates the PR automatically.

### 3. Autonomous experimentation

Inspired by Karpathy's autoresearch. Give Cortex a task and a metric command, and it loops autonomously: make a change, measure the result, keep or discard, reflect on failures, try again. Run it overnight. Wake up to a branch full of improvements.

Three modes: a single autonomous loop (`/cortex-auto`), parallel candidates evaluated in a tournament (`/cortex-sweep`), and population-based evolutionary optimization across generations (`/cortex-evolve`).

---

## Quick Start

```bash
# One-time: scan the project
/cortex-init

# For a new feature
/cortex-plan Add OAuth2 login with Google
/cortex-build
/cortex-ship

# To fix something measurable autonomously
/cortex-auto Fix all TypeScript strict mode errors --metric "npx tsc --noEmit 2>&1 | grep -c error"
```

---

## Walkthrough: Building a Feature

### 1. Initialize

```
/cortex-init
```

```
Analyzed: TypeScript · React · Vite · Zustand
Conventions: kebab-case files, camelCase functions, @/ absolute imports
Tests: colocated .test.ts, run with: pnpm test
CI: pnpm lint, pnpm build
Commit style: conventional commits

Profile saved to .cortex/profile.json
Conventions saved to .cortex/CONVENTIONS.md
```

Commit both files. Done — every future session starts with this context.

### 2. Plan

```
/cortex-plan Add a dark mode toggle that persists the user's preference
```

```
Plan: "Add dark mode toggle"

Requirements
R1  Toggle on/off                                     MUST
R2  Persists across reloads (localStorage)            MUST
R3  Respects system preference on first load          SHOULD
R4  Accessible (aria-label, keyboard navigable)       MUST

Steps
S1  theme slice in Zustand store        TDD: Yes
S2  Persist to localStorage             TDD: Yes
S3  Read system preference on init      TDD: Yes
S4  DarkModeToggle component            TDD: Yes
S5  Wire into Header                    TDD: No

Approve this plan? Run /cortex-build to execute.
```

### 3. Build

```
/cortex-build
```

```
Executing S1: Add theme slice to Zustand store
  → Writing test first... FAIL (expected)
  → Implementing... PASS ✓

Executing S2: Persist to localStorage
  → Writing test first... FAIL (expected)
  → Implementing... PASS ✓

...all 5 steps complete.
Tests: PASS  Lint: PASS
Committed: feat: add dark mode toggle with persistence (a3f91c2)
```

### 4. Review

```
/cortex-review
```

```
Stage 1 — Spec Compliance
  [PASS] Toggle works — DarkModeToggle component confirmed
  [PASS] Persists — localStorage read/write in store
  [PASS] System preference respected on init
  [PASS] Accessible — aria-label and keyboard handler present

Stage 2 — Code Quality
  [PASS] kebab-case file naming
  [PASS] localStorage wrapped in try/catch
  [WARN] No test for keyboard navigation

Overall: PASS WITH WARNINGS
```

### 5. Ship

```
/cortex-ship
```

```
Pushing branch feature/dark-mode-toggle...
PR created: https://github.com/your-org/your-repo/pull/47
```

---

## Walkthrough: Autonomous Experimentation

This is the autoresearch mode. You give Cortex a goal and a way to measure it. It loops on its own, making changes, measuring, keeping what works, and learning from what doesn't.

### How it works

1. **One change per attempt** — the `experimenter` agent makes exactly one conceptual change, so the metric delta is always attributable
2. **Reflexion memory** — on every discard, it writes a structured reflection: what it tried, why it failed, what constraint it learned. This feeds into the next attempt's prompt. By attempt 5, the agent isn't just avoiding past approaches — it knows *why* they failed
3. **Best-shot context** — the top 3 successful past changes are always shown as examples (inspired by FunSearch). The agent learns what kinds of changes work in *this* codebase
4. **Curriculum decomposition** — complex goals are broken into sub-goals ordered easy→hard. Early wins scaffold harder problems
5. **Git-based checkpoints** — creates a dedicated branch, commits before each attempt, `git reset --hard` on discard. The branch shows exactly what worked

### `/cortex-auto` — Autonomous loop

```
/cortex-auto Fix all TypeScript strict mode errors --metric "npx tsc --noEmit 2>&1 | grep -c error" --max 15
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

✓ Attempt 4: KEEP — Fix optional chaining in UserProfile component
  18 → 9 errors

[...continuing autonomously...]

Goal met after 11 attempts. 47 → 0 errors.
8 kept · 3 discarded

Patterns learned this session:
- Type assertions consistently make things worse here
- Service layer is the highest-yield target for type annotations
- Component props are already well-typed — focus on hooks and utilities
```

Compare this to autoresearch: autoresearch keeps a TSV of results with no explanations. Cortex accumulates *causal understanding* — it learns why things fail, not just what failed.

### `/cortex-sweep` — Parallel best-of-N

Instead of trying one approach and hoping, generate N candidates simultaneously with different strategies and pick the winner.

```
/cortex-sweep "Add rate limiting to the API" --n 3
```

```
Launching 3 candidates in parallel:
  A: simplicity strategy  — minimize lines, remove over add
  B: performance strategy — maximize metric improvement
  C: readability strategy — clarity, explicit types, clean naming

Evaluating...

| Candidate | Strategy    | Tests | Lint | Lines Δ | Rank |
|-----------|-------------|-------|------|---------|------|
| A ✓       | simplicity  | PASS  | PASS | +42     | 1st  |
| C         | readability | PASS  | PASS | +67     | 2nd  |
| B         | performance | FAIL  | PASS | +89     | 3rd  |

Winner: Candidate A — fewest lines, tests pass
```

If more than one candidate passes, Cortex cross-checks them for behavioral disagreements — different implementations of the same thing will sometimes handle edge cases differently, and that's a bug.

### `/cortex-evolve` — Evolutionary optimization

For numeric metrics. Each generation spawns N parallel candidates using the best solutions from prior generations as inspiration. Simplicity pressure ensures the code stays clean.

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
Target: ████████████████████
```

### `/cortex-experiment` — Single cycle

When you have one specific hypothesis to test:

```
/cortex-experiment "Replace lodash.get with optional chaining" --metric "npm test"
```

```
Baseline: PASS
After:    PASS (8 lines removed)

Recommendation: KEEP ✓
Keep this change? [Y/n]
```

### `/cortex-log` — Experiment history

```
/cortex-log --patterns
```

```
Patterns learned from 6 experiment sessions:

What Tends to Work
- Removing unused imports (tree-shaking not configured — big wins here)
- Adding explicit return types to service functions
- Replacing moment.js with date-fns for any date operation

What Tends to Fail
- Type assertions (as X) — hide errors, cause downstream failures
- Modifying the auth store shape — blast radius is too high (5+ consumers)

High-Impact Areas
- src/services/ — under-typed, lots of implicit any
- src/utils/ — unused exports not removed, adds to bundle

Low-Impact Areas
- CSS optimization — styles not on critical path, minimal effect
```

---

## All Commands

### Intelligence

| Command | What it does |
|---------|-------------|
| `/cortex-init` | Scan codebase, auto-derive conventions, architecture, and CI commands. Creates `.cortex/profile.json` and `CONVENTIONS.md`. |
| `/cortex-update` | Rescan only changed files and patch the profile. Faster than re-init. |
| `/cortex-ask <question>` | "Where should I add a new store?" "What's the test command?" Answers from the profile. |

### Workflow

| Command | What it does |
|---------|-------------|
| `/cortex-plan <task>` | Structured plan with requirements, TDD steps, file paths. Requires approval before building. |
| `/cortex-build` | Execute plan step by step, TDD-first, stops on failure. Resumes if interrupted. |
| `/cortex-review` | Two-stage review: spec compliance then code quality (security, conventions, error handling). |
| `/cortex-debug <description>` | Reproduce → hypothesize → investigate → fix with regression test. Never guess-and-check. |
| `/cortex-ship` | Full review → commit → push → PR with auto-generated description. |
| `/cortex-quick <task>` | Fast path for small changes. No planning — focus, implement, test, commit. |

### Experimentation

| Command | What it does |
|---------|-------------|
| `/cortex-auto <task>` | Autonomous loop. Makes changes, measures, keeps improvements, writes reflections on failures, repeats. Runs until goal met or `--max` hit. |
| `/cortex-sweep <task>` | Generate N parallel candidates with different strategies, evaluate all, apply the winner. |
| `/cortex-evolve <goal>` | Evolutionary optimization across generations. Uses past successes as inspiration. Progress chart per generation. |
| `/cortex-experiment <hypothesis>` | Single cycle: try one change, measure, keep or discard. |
| `/cortex-log [query]` | View experiment history. `--patterns` shows what's been learned across all sessions. |

### Context & Memory

| Command | What it does |
|---------|-------------|
| `/cortex-focus <task>` | Find relevant files using keyword search + import graph + Claude re-ranking. |
| `/cortex-verify` | Verify diff against original intent. PASS/WARN/FAIL with evidence. |
| `/cortex-risk` | Blast radius assessment for pending changes. Risk per file with mitigations. |
| `/cortex-remember <what>` | Save a decision, pattern, or gotcha for future sessions. |
| `/cortex-recall <query>` | Search saved memories by keyword. |

---

## What Gets Committed

```
.cortex/
├── profile.json        ← commit this
├── CONVENTIONS.md      ← commit this
├── .gitignore          ← auto-created
├── active-intent.json  ← NOT committed (per-session)
├── active-plan.json    ← NOT committed (per-session)
├── memories/           ← NOT committed (personal, local)
│   └── <timestamp>.json
└── experiments/        ← NOT committed (local history)
    ├── active-session.json
    └── log.json
```

---

## What's Inside

| Component | Count | Details |
|-----------|-------|---------|
| Commands | 19 | User-invokable slash commands |
| Agents | 11 | convention-scanner, dependency-mapper, history-analyzer, context-ranker, intent-verifier, risk-assessor, planner, executor, code-reviewer, debugger, experimenter |
| Auto-skill | 1 | `project-intelligence` — injects conventions automatically when Claude starts a task |
| Hooks | 2 | `pre-task-inject` (context on prompt) + `post-tool-lint` (auto lint-fix on file write) |

Pure markdown + shell scripts. Zero dependencies. No Node.js, no npm, no build step.

---

## Roadmap

**Phase 1** ✓ — Auto-derived conventions, semantic context selection, intent verification

**Phase 2** ✓ — Persistent memory, incremental profile updates, natural language queries, risk classification, pre-task context injection

**Phase 3** ✓ — Complete standalone workflow: plan, build, review, debug, ship, quick

**Phase 4** ✓ — Autonomous experimentation: `/cortex-auto` (reflexion + curriculum), `/cortex-sweep` (parallel tournament), `/cortex-evolve` (population evolution), `/cortex-experiment`, `/cortex-log`

**Phase 5** — Semantic search over experiment history, cross-project learning, team-shared memories

---

## Why Cortex

autoresearch runs an AI in a loop improving ML training code overnight. Cortex does the same thing for any codebase, with any metric, and adds three things autoresearch doesn't have: it learns *why* changes fail (not just what failed), it runs parallel candidates with different strategies, and it accumulates codebase-specific patterns across sessions that make every future experiment smarter.

It also covers everything else: project intelligence, structured workflow, debugging, shipping. One tool.
