# 🧠 Cortex

**Autonomous experiment loops and project intelligence for Claude Code.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-blueviolet)](https://claude.ai/code)
[![9 commands](https://img.shields.io/badge/commands-9-green)]()
[![Zero deps](https://img.shields.io/badge/dependencies-zero-orange)]()

Cortex gives Claude two superpowers: **permanent memory of your project** — conventions, architecture, CI commands scanned once and used forever — and an **autonomous experiment engine** that improves your code against any metric while you sleep.

```bash
curl -fsSL https://raw.githubusercontent.com/Messier81/cortex/main/install.sh | bash
```

---

## 💡 The idea

You give Cortex a goal and a way to measure it:

```
/cortex-auto "Fix all TypeScript strict errors" --metric "npx tsc --noEmit 2>&1 | grep -c error"
```

It runs a loop — make a change, measure, keep or discard, write a reflection on *why* it failed, try again — until the goal is met. Each failure teaches the next attempt something specific about **this** codebase.

```
Baseline: 47 errors

✓  Attempt 1  Add null checks in useAuth          47 → 31 errors
✗  Attempt 2  Add `as unknown as T` casts         31 → 33 errors  ← regression
              Reflection: type assertions hide errors downstream. avoid them.
✓  Attempt 3  Explicit return types in services   31 → 18 errors
✓  Attempt 4  Optional chaining in UserProfile    18 → 9 errors
...
🎯  Goal met after 11 attempts. 47 → 0 errors.
```

Not just pass/fail — it builds causal understanding of why things fail in your specific codebase.

---

## 🚀 Install

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

> 💬 Pair with [pctx](https://github.com/Messier81/pctx) for decision tracking and cross-session intelligence. Cortex works without it, but pctx unlocks `/cortex-reflect` and `/cortex-digest`.

---

## 🧪 Experimentation

### `/cortex-auto` — Reflexion loop

Autonomous improvement. Reflexion memory, curriculum decomposition (easy→hard sub-goals), best-shot context (top 3 past wins shown to each attempt).

```bash
/cortex-auto "Reduce bundle size" --metric "du -b dist/bundle.js | cut -f1" --max 20
```

### `/cortex-sweep` — Best-of-N tournament

Generate N candidates simultaneously with different strategies, evaluate all, apply the winner. Cross-checks for behavioral disagreements between candidates.

```
┌───────────┬─────────────┬───────┬─────────┬──────┐
│ Candidate │ Strategy    │ Tests │ Lines Δ │ Rank │
├───────────┼─────────────┼───────┼─────────┼──────┤
│ A ✓       │ simplicity  │ PASS  │ +42     │ 1st  │
│ C         │ readability │ PASS  │ +67     │ 2nd  │
│ B         │ performance │ FAIL  │ +89     │ 3rd  │
└───────────┴─────────────┴───────┴─────────┴──────┘
```

### `/cortex-evolve` — Evolutionary optimization

Best survivors inspire the next generation. Simplicity pressure penalizes bloat. Progress chart per generation.

```
Gen 1:  ████████████████████████  430,120 bytes  KEEP -6.1%   tree-shake lodash
Gen 2:  ███████████████████████   412,400 bytes  KEEP -9.8%   lazy-load routes
Gen 5:  █████████████████████     365,200 bytes  KEEP -20.2%  replace moment → date-fns
Gen 8:  █████████████████         198,200 bytes  ✓ TARGET MET -56.7%
```

### `/cortex-experiment` — Single cycle

One hypothesis → one measurement → keep or discard with a reflection.

### `/cortex-log --patterns` — What this codebase has learned

```
✅ What Tends to Work
   · Removing unused imports (tree-shaking not configured — big wins)
   · Explicit return types in service layer

❌ What Tends to Fail
   · Type assertions — hide errors, cause downstream failures
   · Changing the auth store shape — blast radius too high (5+ consumers)

⚡ High-Impact Areas
   · src/services/ — under-typed, lots of implicit any
```

---

## 🗺 Project Intelligence

### `/cortex-init [--update]`

Scans your codebase with 3 parallel agents:

- **convention-scanner** — naming patterns, file organization, error handling, import style
- **dependency-mapper** — entry points, core abstractions, coupling hotspots, change coupling from git history
- **history-analyzer** — commit style, hotspot files, exact CI commands

Produces `.cortex/profile.json` (machine-readable) and `.cortex/CONVENTIONS.md` (human-readable). `--update` rescans only changed files.

### `/cortex-build`

Execute a structured plan step by step. Each step gets a **fresh isolated context** — no accumulated garbage from previous steps. Step 8 runs with the same quality as step 1.

---

## 🔮 Cross-Session Intelligence

### `/cortex-reflect`

Full synthesis — experiment patterns, pctx decision history, progressions (how understanding evolved across sessions), stale knowledge flags.

### `/cortex-digest`

Quick daily reference card. Recent decisions + recent experiment learnings. Designed to be called at the start of a session.

---

## ⚙️ How it works

| Mechanism | What it does |
|-----------|-------------|
| **Reflexion memory** | On every discard, writes a structured reflection: what was tried, why it failed, what constraint was learned. Feeds forward into subsequent attempts. |
| **Best-shot context** | Top 3 successful past changes are shown to each new attempt as examples. The agent learns what kinds of changes work *here*. |
| **Curriculum decomposition** | Complex goals broken into sub-goals ordered easy→hard. Early wins scaffold harder problems. |
| **Git checkpoints** | Creates a dedicated branch, commits before each attempt, `git reset --hard` on discard. |
| **Context isolation** | Each build step gets a compact context packet — not the full accumulated session history. |
| **Coupling analysis** | Detects which files change together in git history, not just import graphs. High-risk files flagged in the profile. |

---

## 📦 What's inside

```
9 commands · 4 agents · 2 hooks · pure markdown + shell · zero dependencies
```

| Type | Details |
|------|---------|
| 🤖 **Agents** | `convention-scanner` · `dependency-mapper` · `history-analyzer` · `experimenter` |
| 🪝 **Hooks** | `pre-task-inject` — injects project context + recent learnings on every prompt |
| | `post-tool-lint` — auto lint-fix after every file write |

---

## 🗂 What gets committed

```
.cortex/
├── profile.json        ← ✅ commit this  (shared project intelligence)
├── CONVENTIONS.md      ← ✅ commit this  (human-readable reference)
└── experiments/        ← 🔒 gitignored  (local history)
    └── log.json
```

---

## 📄 License

MIT — [Messier81/cortex](https://github.com/Messier81/cortex)
