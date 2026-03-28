---
description: Analyze this project and auto-derive conventions, architecture, and coding patterns. Creates .cortex/profile.json and .cortex/CONVENTIONS.md. Use --update to rescan only changed files.
argument-hint: "[--update] [focus area, e.g. 'focus on auth and API patterns']"
---

# Cortex Init

You are performing a project intelligence scan. Your goal is to deeply understand this codebase and produce a structured profile that Cortex will use in every future session — so the AI never starts cold again.

**Arguments:** $ARGUMENTS

---

## Mode Detection

Check if `$ARGUMENTS` contains `--update`:

- **`--update` flag present**: Run in incremental update mode (see Update Mode section below)
- **No `--update` flag**: Run in full init mode (continue to Phase 1)

**Focus area** (for full init only): any text in `$ARGUMENTS` besides `--update`

---

## Full Init Mode

### Phase 1: Parallel Discovery

Launch these 3 agents IN PARALLEL right now:

**Agent 1 — convention-scanner**: "Scan this codebase for coding conventions. Focus on: naming patterns (files, functions, classes, constants), file organization style (feature-based vs layer-based), error handling patterns, import/export style, comment style, and test file conventions. Sample the 3 most recently modified source files per top-level directory (skip node_modules, .git, vendor, dist, build). Extract patterns with evidence — note specific files as examples. Return findings as structured JSON."

**Agent 2 — dependency-mapper**: "Map this project's dependencies and architecture. Read all package manifest files (package.json, pyproject.toml, Cargo.toml, go.mod, requirements.txt, Gemfile, etc.). Trace the main entry points and identify the 5-10 core abstractions (key classes, modules, or patterns). Map which directories/files other code imports most frequently — these are the core dependencies. Detect change coupling from git history. Find test file locations and naming conventions relative to source files. Return findings as structured JSON."

**Agent 3 — history-analyzer**: "Analyze this project's git history and CI configuration. Run: git log --oneline -100 to see recent commits. Extract: (1) commit message style (conventional commits, freeform, ticket-prefix?), (2) branch naming patterns from merge commits, (3) the 10 most-changed files in recent history (hotspots). Read .github/workflows/*.yml, Makefile, .buildkite/, or any CI config you find. Extract exact lint, test, build, and type-check commands. Return findings as structured JSON."

---

### Phase 2: Synthesize Profile

Once all 3 agents complete, synthesize their findings into a unified profile. Create the `.cortex/` directory if it doesn't exist.

Write `.cortex/profile.json` with this structure:

```json
{
  "project": {
    "name": "<from package.json or directory name>",
    "type": "<monorepo|library|cli|fullstack|backend|frontend|mobile>",
    "languages": ["<primary language>"],
    "frameworks": ["<frameworks detected>"],
    "package_managers": ["<npm|pnpm|yarn|pip|cargo|go|etc>"]
  },
  "conventions": {
    "naming": {
      "files": "<kebab-case|camelCase|snake_case|PascalCase>",
      "functions": "<camelCase|snake_case>",
      "classes": "<PascalCase|etc>",
      "constants": "<SCREAMING_SNAKE|etc>",
      "evidence": ["<file path showing this pattern>"]
    },
    "structure": {
      "pattern": "<feature-based|layer-based|hybrid>",
      "description": "<brief description of how code is organized>",
      "test_location": "<colocated|mirror|__tests__|tests/>",
      "test_suffix": "<.test.ts|.spec.ts|_test.go|etc>"
    },
    "error_handling": {
      "pattern": "<exceptions|result-types|error-codes|mixed>",
      "example_file": "<file:line>"
    },
    "imports": {
      "style": "<absolute|relative|path-aliases>",
      "aliases": ["<@/|~/|etc>"]
    }
  },
  "architecture": {
    "entry_points": ["<main files>"],
    "core_abstractions": [
      {
        "name": "<abstraction name>",
        "location": "<directory or file>",
        "description": "<what it does>"
      }
    ],
    "hotspots": ["<frequently changed files>"],
    "test_framework": "<vitest|jest|pytest|go test|rspec|etc>",
    "coupling_hotspots": [
      {
        "file": "<path>",
        "importers": "<count>",
        "exports": "<count>",
        "coupling_score": "<importers * exports>"
      }
    ],
    "change_coupled_pairs": [
      {
        "files": ["<path-a>", "<path-b>"],
        "co_change_count": "<N>"
      }
    ]
  },
  "ci": {
    "platform": "<github-actions|buildkite|circleci|none>",
    "commands": {
      "lint": "<exact command>",
      "lint_fix": "<exact command or null>",
      "test": "<exact command>",
      "test_file": "<command with {file} placeholder or null>",
      "type_check": "<exact command or null>",
      "build": "<exact command or null>"
      }
  },
  "git": {
    "default_branch": "<main|master|etc>",
    "commit_style": "<conventional|freeform|ticket-prefix>",
    "commit_examples": ["<2-3 real examples from log>"],
    "branch_pattern": "<detected pattern or null>"
  },
  "cortex_version": "2.0.0",
  "generated_at": "<run: date -u +%Y-%m-%dT%H:%M:%SZ and use the output>"
}
```

Fill every field with real data from the agents' findings. Use `null` for fields where no evidence was found. Always include evidence files for conventions.

---

### Phase 3: Write Human-Readable Summary

Write `.cortex/CONVENTIONS.md` — a concise, scannable reference for both humans and AI:

```markdown
# Project Conventions

Auto-generated by Cortex on <run: date -u +%Y-%m-%dT%H:%M:%SZ>. Re-run `/cortex-init` to update.

## Stack
- **Language**: <language>
- **Framework**: <framework>
- **Package manager**: <manager>
- **Test framework**: <framework>

## Naming
- Files: `<pattern>` (e.g. `user-profile.ts`, `UserProfile.tsx`)
- Functions: `<pattern>` (e.g. `getUserById`, `get_user_by_id`)
- Classes: `<pattern>`
- Constants: `<pattern>`

## Structure
<brief description — "Feature-based: code organized by domain (auth/, billing/, users/)">

## Tests
- Location: <colocated|mirror>
- Pattern: `<example.test.ts>` alongside `<example.ts>`
- Run single file: `<command>`

## Error Handling
<brief description of the pattern used>

## Imports
<brief description — "Absolute with @/ alias for src/">

## Git
- Commit style: `<feat: description>` or `<freeform>`
- Branch pattern: `<feature/description>`

## Key Commands
\`\`\`
lint:       <command>
test:       <command>
build:      <command>
type-check: <command>
\`\`\`

## Core Abstractions
<list the 3-5 most important patterns/abstractions in this codebase>

## High-Coupling Files
<list top 3 files from coupling_hotspots — touch these carefully>
```

---

### Phase 4: Confirm

Tell the user:
- What was detected (stack, conventions, key patterns)
- Any gaps or ambiguities (fields that are null or uncertain)
- Top coupling hotspots (files that are high-risk to change)
- That they can edit `.cortex/profile.json` directly to correct anything
- That these files should be committed so teammates benefit:
  - `.cortex/profile.json` — machine-readable project profile
  - `.cortex/CONVENTIONS.md` — human-readable conventions reference
  - `.cortex/.gitignore` — ensures session and experiment files stay local

Write `.cortex/.gitignore` (create or update):
```
active-intent.json
active-plan.json
experiments/
```

---

## Update Mode (`--update`)

Used when the codebase has evolved since the last `/cortex-init`.

### Update Step 1: Find Changed Files

Run: `git diff $(cat .cortex/profile.json | python3 -c "import json,sys; print(json.load(sys.stdin).get('generated_at','HEAD'))[:10]" 2>/dev/null || echo "HEAD~20") --name-only 2>/dev/null || git diff HEAD~20 --name-only`

Or more simply: find files modified since the profile was generated by checking `profile.json`'s `generated_at` timestamp vs file mtimes. If that fails, use `git diff HEAD~20 --name-only` as a fallback.

Show the user: "Found N changed files since last init."

### Update Step 2: Re-run Targeted Agents

If changed files include source code (`.ts`, `.js`, `.py`, `.go`, `.rs`, `.rb`, `.java`, `.kt`):
- Re-run the **convention-scanner** agent focused on only those files
- Re-run the **dependency-mapper** agent to refresh coupling data (git coupling analysis covers recent history automatically)

If changed files include CI configs (`.yml`, `Makefile`, `.buildkite`):
- Re-run the **history-analyzer** agent

### Update Step 3: Patch Profile

Merge the new agent findings into the existing `.cortex/profile.json`:
- Update only the fields that changed
- Set `last_updated_at` to current timestamp
- Add `changed_files_scanned` array listing what was re-scanned
- Keep `generated_at` as the original full-init timestamp

Update `CONVENTIONS.md` if conventions changed.

### Update Step 4: Confirm

Tell the user what changed and what was updated in the profile.
