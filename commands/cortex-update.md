---
description: Incrementally update your project profile by re-scanning only files changed since last init. Much faster than a full /cortex-init.
argument-hint: Optional - branch to diff against (default: uses your profile's default branch)
---

# Cortex Update

You are performing an incremental profile update. Instead of scanning the entire codebase, you only re-analyze files that have changed. This is fast and keeps the profile accurate as the project evolves.

---

## Step 1: Load Current Profile

Read `.cortex/profile.json`. If it doesn't exist, tell the user: "No profile found. Run `/cortex-init` to create one." and stop.

Note the `generated_at` (or `last_updated_at` if present) timestamp and the `git.default_branch` field.

---

## Step 2: Find Changed Files

The default branch to diff against: use `$ARGUMENTS` if provided, otherwise use the `git.default_branch` from the profile, otherwise fall back to `main`.

Run:
- `git diff <branch> --name-only` — files changed vs the default branch
- `git diff --name-only --diff-filter=A` — newly added but unstaged files

Combine and deduplicate. If no files found, tell the user: "No changes detected vs `<branch>`. Profile is up to date." and stop.

---

## Step 3: Categorize Changes

Sort the changed files into:
- **Source files**: `.ts`, `.tsx`, `.js`, `.jsx`, `.py`, `.go`, `.rs`, `.rb`, `.java`, `.kt`, `.swift`, `.cpp`, `.c` files
- **Config/CI files**: `package.json`, `*.yml`, `*.yaml`, `Makefile`, `Dockerfile`, `tsconfig.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `.buildkite/*`, `.github/workflows/*`
- **Test files**: files matching the profile's `test_suffix` pattern
- **Other**: everything else

---

## Step 4: Run Scoped Agents (only what's needed)

Launch only the agents needed based on what changed, IN PARALLEL where applicable:

**If source files changed**: Launch **convention-scanner** agent with instructions to ONLY examine these specific files (pass the explicit list of changed source files). Ask it to identify any convention shifts and report what changed vs the norm.

**If source files changed**: Launch **dependency-mapper** agent with instructions to check if any new core abstractions, new entry points, or new dependencies appear in the changed files.

**If config/CI files changed**: Launch **history-analyzer** agent with instructions to only re-read the changed config files and update the CI commands and git conventions sections.

If nothing changed in a category, skip its agent entirely.

---

## Step 5: Patch the Profile

For each agent that ran, merge its output back into the existing `profile.json` — replace only the sub-fields the agent returned new data for. Do NOT overwrite fields the agent didn't touch.

Update:
- `generated_at`: set to the current timestamp (run: `date -u +%Y-%m-%dT%H:%M:%SZ`)
- `last_updated_at`: set to the same current timestamp
- Add `changed_files_scanned`: list of files that were analyzed in this update

Write the updated `profile.json` back to `.cortex/profile.json`.

---

## Step 6: Update CONVENTIONS.md

If any conventions fields changed, regenerate `.cortex/CONVENTIONS.md` using the same format as `/cortex-init`.

---

## Step 7: Report Changes

Show the user what changed:

```
## Cortex Update Complete

Scanned <N> changed files vs <branch>.

### Profile changes
- conventions.naming.files: kebab-case → snake_case (3 new files use snake_case)
- ci.commands.test: npm test → pnpm test
- (no change): architecture, git conventions

### Unchanged
Everything else in the profile remains the same.
```

If nothing in the profile changed after the scan, say: "Scanned <N> files — no convention changes detected. Profile is current."
