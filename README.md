# Cortex

**Adaptive project intelligence for Claude Code.**

Most AI coding tools tell Claude *how* to work. Cortex tells Claude *what to know about your project* — your conventions, your architecture, your context.

Three commands. Zero configuration. Works with any codebase.

---

## The Problem

Every time you open Claude Code, it starts cold. It doesn't know:
- That you use kebab-case for files and camelCase for functions
- That tests live colocated with source, not in a `tests/` folder
- That the auth module is in `src/features/auth/` not `src/auth/`
- That `pnpm lint --fix` is the command to run before pushing

So you either write a long CLAUDE.md (manual, gets stale) or repeat yourself every session.

And when Claude finishes a task, how do you know it actually built what you asked? "Tests pass" isn't the same as "intent satisfied."

---

## The Solution

```bash
# One-time: analyze your project
/cortex-init

# Before any task: find the right files
/cortex-focus Add OAuth2 login with Google

# After implementation: verify the intent was satisfied
/cortex-verify
```

That's it.

---

## What Each Command Does

### `/cortex-init`
Runs 3 parallel agents that scan your codebase:
- **Convention scanner**: naming patterns, file organization, error handling, import style
- **Dependency mapper**: stack, frameworks, core abstractions, test structure
- **History analyzer**: git commit style, hotspot files, exact CI commands

Produces `.cortex/profile.json` (machine-readable) and `.cortex/CONVENTIONS.md` (human-readable). Commit both so your whole team benefits.

### `/cortex-focus <task>`
Given a task description, finds the most relevant files using a 3-tier algorithm:
1. Keyword + structural search (guided by your project profile)
2. Import graph expansion (traces who imports what)
3. Claude-based re-ranking (reads files to verify relevance)

Outputs: primary files, secondary files, test files, conventions to follow, and implied requirements. Saves the task as the active intent for `/cortex-verify`.

### `/cortex-verify`
Compares your diff against the original intent. Checks:
- **Completeness**: did every implied requirement get implemented?
- **Correctness**: do the changes logically satisfy the task?
- **Side effects**: are there changes outside the expected scope?
- **Convention compliance**: does new code follow project patterns?

Returns a structured PASS/WARN/FAIL verdict.

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
curl -fsSL https://raw.githubusercontent.com/cortex-cc/cortex/main/install.sh | bash

# Or clone and install locally
git clone https://github.com/cortex-cc/cortex
cd cortex && ./install.sh /path/to/your/project
```

This copies the commands, agents, and skills into your project's `.claude/` directory. No plugin required.

---

## How It Composes With Other Tools

Cortex is infrastructure, not a workflow. It layers underneath whatever you're already using:

- **With GSD**: Run `/cortex-focus` before starting a GSD phase to give the agents better context
- **With Superpowers**: Cortex's `project-intelligence` skill injects conventions into Superpowers' planning and TDD skills
- **With spec-kit**: Use `/cortex-init` instead of manually writing a constitution
- **Standalone**: Use the three commands as your complete workflow

---

## What Gets Committed

```
.cortex/
├── profile.json       ← commit this (team-shared conventions)
├── CONVENTIONS.md     ← commit this (human-readable)
├── .gitignore         ← auto-created (ignores active-intent.json)
└── active-intent.json ← NOT committed (per-session)
```

---

## Roadmap

**Phase 1 (current)**: Auto-derived conventions, semantic context selection, intent verification

**Phase 2**: Persistent project memory (SQLite), `/cortex-remember`, `/cortex-recall`, risk classification with `/cortex-risk`

**Phase 3**: Local embeddings for semantic memory search, cross-project learning, team-shared memories

---

## Why Cortex

Every existing tool requires you to configure it before it's useful. Cortex is useful from the first run because it reads your project rather than asking you to describe it.

It doesn't replace your workflow — it makes your workflow smarter.
