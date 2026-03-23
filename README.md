# Cortex

**Complete project intelligence and workflow for Claude Code.**

Most AI coding tools tell Claude *how* to work. Cortex tells Claude *what to know about your project* — your conventions, your architecture, your context — and then gives it a complete workflow to plan, build, review, debug, and ship.

**14 commands. 10 agents. Zero configuration. No other tools required.**

---

## The Problem

Every time you open Claude Code, it starts cold. It doesn't know:
- That you use kebab-case for files and camelCase for functions
- That tests live colocated with source, not in a `tests/` folder
- That the auth module is in `src/features/auth/` not `src/auth/`
- That `pnpm lint --fix` is the command to run before pushing

So you either write a long CLAUDE.md (manual, gets stale) or repeat yourself every session.

And when Claude finishes a task, how do you know it actually built what you asked? "Tests pass" isn't the same as "intent satisfied."

And if you want a full plan-build-review-ship workflow, you currently need GSD *and* Superpowers *on top* of a project intelligence layer — three tools, manual setup, overlapping responsibilities.

Cortex is all three in one.

---

## Install

### Option 1: As a Claude Code plugin (recommended)

```bash
/plugin install cortex-cc/cortex
```

Then in any project:

```bash
/cortex-init
```

### Option 2: Install into a specific project

```bash
# From the web (run from your project root)
curl -fsSL https://raw.githubusercontent.com/Messier81/cortex/main/install.sh | bash

# Or clone and install locally
git clone https://github.com/Messier81/cortex
cd cortex && ./install.sh /path/to/your/project
```

This copies all commands, agents, hooks, and the skill into your project's `.claude/` directory. No plugin required.

---

## Quick Start

### Step 1: Analyze your project (once)

```
/cortex-init
```

Cortex launches 3 parallel agents that scan your codebase and produce:
- `.cortex/profile.json` — machine-readable project profile
- `.cortex/CONVENTIONS.md` — human-readable conventions summary

**Commit both files** so your whole team benefits automatically.

### Step 2: Use the workflow for every task

```
/cortex-plan Add OAuth2 login with Google
```
> Cortex reads your codebase, breaks down requirements, creates a step-by-step plan with TDD steps, and asks for your approval before writing a single line of code.

```
/cortex-build
```
> Executes the approved plan step by step. Writes tests first, then implementation. Runs tests after each step. Stops and reports if something fails — never brute-forces.

```
/cortex-ship
```
> Runs a full two-stage review (spec compliance + code quality), commits, pushes, and opens a PR with an auto-generated description.

---

## Walkthrough: Adding a Feature End to End

Here's what a complete Cortex session looks like on a real project.

### 1. First-time setup

```
you: /cortex-init
```

Cortex scans the codebase and outputs something like:

```
Analyzed: TypeScript · React · Vite · Zustand
Conventions: kebab-case files, camelCase functions, @/ absolute imports
Tests: colocated .test.ts files, run with: pnpm test
CI: pnpm lint, pnpm build
Commit style: conventional commits (feat:, fix:, chore:)

Profile saved to .cortex/profile.json
Conventions saved to .cortex/CONVENTIONS.md
```

You commit both files once, and every future session — yours and your teammates' — starts with this context already loaded.

### 2. Plan the feature

```
you: /cortex-plan Add a dark mode toggle that persists the user's preference
```

Cortex identifies the relevant files (theme store, layout component, user settings), then the `planner` agent produces:

```
Plan: "Add a dark mode toggle that persists the user's preference"

Requirements
R1  Dark mode can be toggled on/off                           MUST
R2  Preference is persisted across page reloads               MUST
R3  System preference is respected on first load              SHOULD
R4  Toggle is accessible (aria-label, keyboard navigable)     MUST

Implementation Steps
S1  Add `theme` slice to the Zustand store (src/stores/theme-store.ts)
    TDD: Yes  |  Risk: Low
S2  Persist theme to localStorage on change (src/stores/theme-store.ts)
    TDD: Yes  |  Risk: Low
S3  Read system preference on init (src/stores/theme-store.ts)
    TDD: Yes  |  Risk: Low
S4  Add DarkModeToggle component (src/components/dark-mode-toggle.tsx)
    TDD: Yes  |  Risk: Low
S5  Wire toggle into Header (src/components/header.tsx)
    TDD: No   |  Risk: Low — existing tests cover Header

Test Strategy: Write tests for store logic first. Component test for toggle.
Uncertainties: None

Does this plan look right? Run /cortex-build to execute.
```

You review it, maybe adjust a requirement, then approve.

### 3. Build it

```
you: /cortex-build
```

Cortex executes each step in order, announcing what it's doing:

```
Executing S1: Add `theme` slice to Zustand store

  → Writing test: src/stores/theme-store.test.ts
  → Running test... FAIL (expected — no implementation yet)
  → Implementing theme-store.ts
  → Running test... PASS

Step S1: PASS

Executing S2: Persist theme to localStorage
  ...

All 5 steps complete. Tests: PASS. Lint: PASS.
Committed: feat: add dark mode toggle with persistence (a3f91c2)

Next: /cortex-review or /cortex-ship
```

If a step fails twice, Cortex stops and suggests `/cortex-debug` rather than spinning in circles.

### 4. Review (optional but recommended)

```
you: /cortex-review
```

Two-stage adversarial review:

```
Stage 1: Spec Compliance
  [PASS] Dark mode toggles on/off — DarkModeToggle component confirmed
  [PASS] Preference persists — localStorage read/write in store
  [PASS] System preference respected — prefers-color-scheme check on init
  [PASS] Toggle is accessible — aria-label and keyboard handler present
  Stage 1: PASS

Stage 2: Code Quality
  [PASS] All new files follow kebab-case convention
  [PASS] Error handling: localStorage access wrapped in try/catch
  [WARN] dark-mode-toggle.test.tsx: no test for keyboard navigation
  [INFO] theme-store.ts:12: consider extracting STORAGE_KEY as a named constant
  Stage 2: PASS WITH WARNINGS

Overall: PASS WITH WARNINGS
Consider: add keyboard nav test before merging.
```

### 5. Ship it

```
you: /cortex-ship
```

```
Running review... PASS WITH WARNINGS
Pushing branch feature/dark-mode-toggle...
Creating PR...

PR: https://github.com/your-org/your-repo/pull/47
"feat: add dark mode toggle with persistence"

Active plan cleared. Ready for next task.
```

---

## All Commands

### Project Intelligence

| Command | What it does |
|---------|-------------|
| `/cortex-init` | Scan your codebase and auto-derive conventions, architecture, and stack. Creates `.cortex/profile.json` and `.cortex/CONVENTIONS.md`. |
| `/cortex-update` | Rescan only changed files and patch the profile. Faster than re-running init. |
| `/cortex-ask <question>` | Ask natural language questions about your project. "Where should I add a new store?" "What's the test command?" |

### Workflow

| Command | What it does |
|---------|-------------|
| `/cortex-plan <task>` | Generate a structured plan with requirements, TDD steps, and file paths. Hard gate — requires approval before building. |
| `/cortex-build` | Execute the active plan step by step. TDD-first. Stops on failure, never brute-forces. Resumes if interrupted. |
| `/cortex-review` | Two-stage review: spec compliance (did we build what was asked?) then code quality (security, conventions, error handling). |
| `/cortex-debug <description>` | Systematic debugging. Reproduces failure, generates ranked hypotheses, investigates methodically, fixes with regression test. |
| `/cortex-ship` | Full review → commit → push → PR with auto-generated description. Cleans up active plan and intent. |
| `/cortex-quick <task>` | Fast path for small tasks. Skips planning — focuses, implements, tests, commits. Warns if scope grows. |

### Experimentation

| Command | What it does |
|---------|-------------|
| `/cortex-auto <task>` | Autonomous experiment loop. Loops indefinitely: try a change, measure, keep or discard, reflect on failures, repeat. Features curriculum decomposition, reflexion memory, and best-shot context from past successes. |
| `/cortex-sweep <task>` | Parallel best-of-N. Generate 3 diverse candidates simultaneously (simplicity / performance / readability strategies), evaluate all, pick the best via tournament selection. |
| `/cortex-evolve <goal>` | Population-based evolutionary optimization. Each generation spawns N parallel candidates that use previous successes as inspiration. Progress tracked per generation with simplicity pressure. |
| `/cortex-experiment <hypothesis>` | Single experiment cycle. Try one hypothesis, measure, keep or discard. Writes a reflection on discard — fed into future attempts. |
| `/cortex-log [query]` | View experiment history. `--patterns` extracts codebase-specific patterns learned from all reflections across every session. |

### Context & Memory

| Command | What it does |
|---------|-------------|
| `/cortex-focus <task>` | Find the most relevant files for a task using keyword search + import graph expansion + Claude re-ranking. Saves active intent. |
| `/cortex-verify` | Compare your diff against the original intent. Returns PASS/WARN/FAIL with evidence. |
| `/cortex-risk` | Classify blast radius of pending changes. Risk per file with suggested mitigations. |
| `/cortex-remember <what>` | Save a decision, pattern, or gotcha to `.cortex/memories/` for future sessions. |
| `/cortex-recall <query>` | Search saved memories by keyword. |

---

## Autonomous Experimentation

Cortex includes an experiment loop inspired by Karpathy's autoresearch — but generalized to any codebase with any measurable metric.

### Single experiment

```
you: /cortex-experiment "Replace lodash.get with optional chaining" --metric "npm test"
```

```
Baseline: PASS
After:    PASS
Delta:    —

Recommendation: KEEP ✓ (tests still pass, 8 lines removed)
Keep this change? [Y/n]
```

### Autonomous loop

```
you: /cortex-auto Fix all TypeScript strict mode errors --metric "npx tsc --noEmit 2>&1 | grep -c error" --max 15
```

Cortex decomposes the goal into sub-goals (null errors → implicit any → strict function types), then loops autonomously:

```
Decomposed into 3 sub-goals:
  1. Fix null/undefined errors (most mechanical)
  2. Fix implicit `any` types
  3. Fix strict function type errors

Baseline: 47 errors

✓ Attempt 1: KEEP — Add null checks in useAuth hook (47 → 31 errors)
✗ Attempt 2: DISCARD — Add `as unknown as T` casts (31 → 33 errors, regression)
   Reflection: Casts hide errors rather than fix them. Avoid type assertions. Use proper narrowing.
✓ Attempt 3: KEEP — Add explicit return types to 5 service functions (31 → 18 errors)
✓ Attempt 4: KEEP — Fix optional chaining in UserProfile component (18 → 9 errors)
...

Goal met after 11 attempts! 47 → 0 errors.
8 improvements kept · 3 discarded

Patterns learned:
- Type assertions (as X) consistently make things worse in this codebase
- Service layer functions are the highest-yield target for type annotation
- Component props are already well-typed — focus on hooks and utilities
```

### Parallel sweep

```
you: /cortex-sweep "Add rate limiting to the API" --n 3
```

```
Launching 3 candidates in parallel:
  A: simplicity strategy
  B: performance strategy
  C: readability strategy

Evaluating...

## Sweep Results
| Candidate | Strategy    | Tests | Lint | Lines Δ | Rank |
|-----------|-------------|-------|------|---------|------|
| A ✓       | simplicity  | PASS  | PASS | +42     | 1st  |
| C         | readability | PASS  | PASS | +67     | 2nd  |
| B         | performance | FAIL  | PASS | +89     | 3rd  |

Winner: Candidate A (simplicity) — fewest lines, all tests pass
```

### Evolutionary optimization

```
you: /cortex-evolve "Reduce bundle size" --metric "du -b dist/bundle.js | cut -f1" --target 200000 --generations 8
```

```
## Cortex Evolve: "Reduce bundle size"
Baseline: 458,240 bytes  |  Target: 200,000 bytes

Gen 1:  ████████████████████████  430,120  (KEEP, -6.1%)  [tree-shake lodash]
Gen 2:  ███████████████████████   412,400  (KEEP, -9.8%)  [lazy-load routes]
Gen 3:  ███████████████████████   412,400  (no improvement)
Gen 4:  ██████████████████████    390,800  (KEEP, -14.7%) [code split vendor]
...
Gen 8:  █████████████████         198,200  (KEEP ✓ TARGET MET, -56.7%)
Target: ██████████████████████
```

---

## Debugging a Failure

If a build step fails, or you're chasing a bug:

```
you: /cortex-debug The AuthService.login test is failing with a TypeError on line 34
```

Cortex's `debugger` agent will:
1. Run the exact failing test and capture the full error
2. Generate 3 ranked hypotheses with evidence for/against each
3. Investigate the most likely one first — adding targeted diagnostics, not random changes
4. Once root cause is confirmed: implement the minimal fix and add a regression test
5. Run the full test suite to check for regressions

The key difference from asking Claude to "just fix it": Cortex never changes code to *try* something. Every change is based on a confirmed hypothesis.

---

## Memory: Saving What You Learn

Cortex has a persistent memory system for things that don't belong in code or git history:

```
you: /cortex-remember The payment webhook must be idempotent — we had a double-charge incident in Jan 2025

you: /cortex-remember We use feature flags via LaunchDarkly, not env vars — see src/lib/flags.ts

you: /cortex-recall payment
→ [2025-01-15] Payment webhook must be idempotent — double-charge incident (Jan 2025)
```

Memories are stored in `.cortex/memories/` as JSON files. They're not committed (they're personal and local) but they persist across sessions. The `pre-task-inject` hook warns you when your active intent predates your latest commit, so stale context doesn't cause drift.

---

## What Gets Committed

```
.cortex/
├── profile.json        ← commit this (shared project intelligence)
├── CONVENTIONS.md      ← commit this (human-readable summary)
├── .gitignore          ← auto-created
├── active-intent.json  ← NOT committed (per-session)
├── active-plan.json    ← NOT committed (per-session)
├── memories/           ← NOT committed (personal, local)
│   └── <timestamp>.json
└── experiments/        ← NOT committed (local experiment history)
    ├── active-session.json
    └── log.json
```

---

## How It Composes With Other Tools

Cortex works standalone, but layers cleanly underneath existing frameworks:

- **With GSD**: Run `/cortex-focus` before any GSD phase to give the wave agents better context
- **With Superpowers**: Cortex's `project-intelligence` skill injects conventions into Superpowers' planning and TDD skills
- **With spec-kit**: Use `/cortex-init` instead of manually writing a constitution
- **Standalone**: Use `/cortex-plan` → `/cortex-build` → `/cortex-ship` as your complete workflow

---

## What's Inside

| Component | Count | Details |
|-----------|-------|---------|
| Commands | 19 | User-invokable slash commands |
| Agents | 11 | convention-scanner, dependency-mapper, history-analyzer, context-ranker, intent-verifier, risk-assessor, planner, executor, code-reviewer, debugger, **experimenter** |
| Auto-skill | 1 | `project-intelligence` — reads profile and injects conventions when Claude starts a task |
| Hooks | 2 | `pre-task-inject` (context on prompt submit) + `post-tool-lint` (auto lint-fix on file write) |

Pure markdown + shell scripts. Zero dependencies. No Node.js, no npm, no build step.

---

## Roadmap

**Phase 1** ✓ — Auto-derived conventions, semantic context selection, intent verification

**Phase 2** ✓ — Persistent memory, `/cortex-remember`, `/cortex-recall`, incremental updates, natural language queries, risk classification, pre-task context injection via hooks

**Phase 3** ✓ — Complete standalone workflow: `/cortex-plan`, `/cortex-build`, `/cortex-review`, `/cortex-debug`, `/cortex-ship`, `/cortex-quick`, post-tool lint hook

**Phase 4** ✓ — Autonomous experimentation: `/cortex-auto` (reflexion + curriculum loop), `/cortex-sweep` (parallel best-of-N tournament), `/cortex-evolve` (population-based evolution), `/cortex-experiment` (single cycle), `/cortex-log` (history + pattern extraction). Inspired by autoresearch, AlphaEvolve, Reflexion, FunSearch, and Voyager.

**Phase 5** — SQLite + embeddings for semantic memory/experiment search, cross-project learning, team-shared memories

---

## Why Cortex

Every existing tool either requires manual configuration before it's useful, or covers only part of the workflow. Cortex auto-derives your project's conventions from the first run, and covers the full loop from planning to shipping.

It doesn't replace your workflow. It *is* your workflow.
