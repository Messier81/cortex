# Cortex

**Complete project intelligence and workflow for Claude Code.**

Most AI coding tools tell Claude *how* to work. Cortex tells Claude *what to know about your project* — your conventions, your architecture, your context — and then gives it a complete workflow to plan, build, review, debug, and ship.

Fourteen commands. Zero configuration. Works with any codebase. No other tools required.

---

## The Problem

Every time you open Claude Code, it starts cold. It doesn't know:
- That you use kebab-case for files and camelCase for functions
- That tests live colocated with source, not in a `tests/` folder
- That the auth module is in `src/features/auth/` not `src/auth/`
- That `pnpm lint --fix` is the command to run before pushing

So you either write a long CLAUDE.md (manual, gets stale) or repeat yourself every session.

And when Claude finishes a task, how do you know it actually built what you asked? "Tests pass" isn't the same as "intent satisfied."

And if you want a full plan-build-review-ship workflow, you need to install GSD *and* Superpowers *on top of* a project intelligence layer. Three tools, manual setup, overlapping responsibilities.

---

## The Solution

```bash
# One-time: analyze your project
/cortex-init

# Plan → Build → Ship
/cortex-plan Add OAuth2 login with Google
/cortex-build
/cortex-ship
```

That's the whole workflow.

---

## Commands

### Intelligence (run once, benefits every session)

#### `/cortex-init`
Runs 3 parallel agents that scan your codebase:
- **Convention scanner**: naming patterns, file organization, error handling, import style
- **Dependency mapper**: stack, frameworks, core abstractions, test structure
- **History analyzer**: git commit style, hotspot files, exact CI commands

Produces `.cortex/profile.json` (machine-readable) and `.cortex/CONVENTIONS.md` (human-readable). Commit both so your whole team benefits.

#### `/cortex-update`
Rescans only changed files and patches the profile. Faster than re-running `/cortex-init`.

#### `/cortex-ask <question>`
Answers natural language questions about your project from the profile. "Where should I add a new store?" "What's the test command?"

---

### Workflow (use for every task)

#### `/cortex-plan <task>`
Generates a structured implementation plan before any code is written:
- Breaks down explicit + implied requirements with acceptance criteria
- Creates step-by-step implementation approach with file paths
- Defines TDD order (tests first for new functionality)
- Self-challenges the plan ("what's simpler? what could go wrong?")
- **Hard gate**: presents the plan for approval before anything is implemented

Saves to `.cortex/active-plan.json`.

#### `/cortex-build`
Executes the active plan step by step:
- Announces each step before doing it
- TDD-first: writes tests before implementation for flagged steps
- Runs tests after each step — stops and reports on failure (never brute-forces)
- Resumes from last completed step if interrupted
- Auto-commits on completion with a conventional commit message

#### `/cortex-review`
Two-stage adversarial review:
1. **Spec compliance**: did we build everything the intent required?
2. **Code quality**: convention adherence, security patterns, error handling, test coverage

Returns PASS / PASS WITH WARNINGS / FAIL per stage.

#### `/cortex-debug <description>`
Systematic hypothesis-driven debugging:
1. Reproduces the exact failure
2. Generates 3 ranked hypotheses
3. Investigates each one methodically (never guess-and-checks)
4. Implements a fix + regression test once root cause is confirmed

#### `/cortex-ship`
Finishes and ships the current work:
1. Runs full two-stage review
2. Commits any uncommitted changes
3. Pushes branch
4. Creates a PR with auto-generated description from the plan
5. Cleans up active intent and plan

#### `/cortex-quick <task>`
Fast path for small tasks (<20 lines). Skips planning — focuses context, implements, tests, and commits in one shot. Warns if scope grows larger than expected.

---

### Context & Memory

#### `/cortex-focus <task>`
Given a task, finds the most relevant files using a 3-tier algorithm:
1. Keyword + structural search (guided by your project profile)
2. Import graph expansion (traces who imports what)
3. Claude-based re-ranking (reads files to verify relevance)

Saves the task as the active intent for `/cortex-verify`.

#### `/cortex-verify`
Compares your diff against the original intent. Checks completeness, correctness, side effects, and convention compliance. Returns a structured PASS/WARN/FAIL verdict.

#### `/cortex-risk`
Classifies the blast radius of pending changes. Shows risk per file with mitigations.

#### `/cortex-remember <what>`
Saves decisions, patterns, and gotchas to `.cortex/memories/` for future sessions.

#### `/cortex-recall <query>`
Searches your saved memories by keyword.

---

## Install

### As a Claude Code Plugin (recommended)

```
/plugin install cortex-cc/cortex
```

Then in any project:
```
/cortex-init
```

### Install into a specific project

```bash
# From the web
curl -fsSL https://raw.githubusercontent.com/Messier81/cortex/main/install.sh | bash

# Or clone and install locally
git clone https://github.com/Messier81/cortex
cd cortex && ./install.sh /path/to/your/project
```

This copies the commands, agents, and skills into your project's `.claude/` directory. No plugin required.

---

## How It Composes With Other Tools

Cortex works standalone, but also layers underneath existing tools:

- **With GSD**: Run `/cortex-focus` before starting a GSD phase to give agents better context
- **With Superpowers**: Cortex's `project-intelligence` skill injects conventions into Superpowers' planning and TDD skills
- **With spec-kit**: Use `/cortex-init` instead of manually writing a constitution
- **Standalone**: Use `/cortex-plan` → `/cortex-build` → `/cortex-ship` as your complete workflow

---

## What Gets Committed

```
.cortex/
├── profile.json       ← commit this
├── CONVENTIONS.md     ← commit this
├── .gitignore         ← auto-created
├── active-intent.json ← NOT committed (per-session)
├── active-plan.json   ← NOT committed (per-session)
└── memories/          ← NOT committed (personal, local)
    └── <id>.json
```

---

## What's Inside

```
14 commands · 10 agents · 1 auto-skill · 2 hooks
Zero dependencies · Pure markdown + shell scripts
```

| Component | Count | Purpose |
|-----------|-------|---------|
| Commands | 14 | User-invokable slash commands |
| Agents | 10 | Specialized subagents (parallel where possible) |
| Auto-skill | 1 | `project-intelligence` — injects conventions automatically |
| Hooks | 2 | `pre-task-inject` (context on submit) + `post-tool-lint` (lint on write) |

---

## Roadmap

**Phase 1** ✓: Auto-derived conventions, semantic context selection, intent verification

**Phase 2** ✓: Persistent project memory, `/cortex-remember`, `/cortex-recall`, incremental updates, natural language queries, risk classification, pre-task context injection

**Phase 3** ✓ (current): Complete standalone workflow — `/cortex-plan`, `/cortex-build`, `/cortex-review`, `/cortex-debug`, `/cortex-ship`, `/cortex-quick`, post-tool lint hook

**Phase 4**: SQLite + embeddings for semantic memory search, cross-project learning, team-shared memories

---

## Why Cortex

Every existing tool requires you to configure it before it's useful, or requires multiple other tools to get a complete workflow. Cortex is useful from the first run because it reads your project — and it's complete because it covers the full plan-build-review-ship loop.

It doesn't replace your workflow. It *is* your workflow.
