---
description: Ship your work. Runs a full two-stage review, commits any uncommitted changes, pushes the branch, and creates a PR with an auto-generated description. Cleans up active intent and plan.
argument-hint: Optional PR title override
---

# Cortex Ship

You are finishing and shipping the current work. This command reviews, commits, pushes, and opens a PR.

---

## Step 1: Pre-flight Checks

1. Run `git status` to see what's uncommitted
2. Run `git log --oneline -5` to see recent commits
3. Run `git branch --show-current` to confirm you're not on main/master

If on main/master: warn the user and ask if they want to create a branch first. Don't push to main without explicit confirmation.

---

## Step 2: Run Review

Run the full two-stage review inline (same as `/cortex-review`):
- Load active intent/plan
- Gather diff
- Stage 1: spec compliance
- Stage 2: code quality

**If the review returns FAIL**: Stop and present the critical issues. Ask: "There are critical issues to fix before shipping. Address them first, or use `/cortex-ship --force` to ship anyway (not recommended)."

If the user passed `--force` in arguments, note the override and continue.

---

## Step 3: Commit Uncommitted Changes

If `git status` shows uncommitted changes:
1. Show the user what will be committed
2. Stage all changed files (using specific file paths, not `git add .`)
3. Commit with a message derived from the active intent/plan:

```
feat: <task in lowercase imperative>

<2-3 line description of what was implemented>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

---

## Step 4: Push and Create PR

Pre-flight checks before pushing:
- Verify `gh` is installed: `which gh` — if not found, tell the user: "The `gh` CLI is required for PR creation. Install it from https://cli.github.com/ then re-run `/cortex-ship`."
- Verify a remote named `origin` exists: `git remote get-url origin` — if missing, tell the user to add one.
- Verify `gh` is authenticated: `gh auth status` — if not authenticated, tell the user: "Run `gh auth login` to authenticate, then re-run `/cortex-ship`."

1. Push the branch: `git push -u origin <branch-name>`
2. Generate a PR description from the active plan/intent:

```markdown
## Summary
- <bullet from each MUST requirement that was implemented>

## Changes
- <list of changed files with brief description>

## Test Plan
- [ ] All existing tests pass
- [ ] New tests cover <new functionality>
- [ ] Manual test: <key scenario from the task>

🤖 Built with [Cortex](https://github.com/Messier81/cortex)
```

3. Create the PR: `gh pr create --title "<task>" --body "<description>"`
4. Return the PR URL

---

## Step 5: Clean Up

After the PR is created:
- Clear `.cortex/active-intent.json` (delete or mark as shipped)
- Clear `.cortex/active-plan.json` (delete or mark as shipped)

Tell the user:
```
## Shipped

PR: <url>
Branch: <branch>
Commits: <count>

Active intent and plan cleared. Ready for the next task.
```
