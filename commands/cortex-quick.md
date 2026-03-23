---
description: Fast mode for small tasks. Skips planning — directly focuses context, implements, tests, and commits. For changes estimated at under 20 lines. Suggests /cortex-plan if scope grows.
argument-hint: The task to implement (e.g. "Fix typo in error message on login page")
---

# Cortex Quick

You are doing a fast implementation for a small, well-understood task. No plan required — just focus, implement, verify, commit.

**Task:** $ARGUMENTS

If no task was provided, ask: "What would you like to do?"

---

## Step 1: Assess Scope

Before starting, estimate: is this really a small task?

Small task criteria (ALL must be true):
- Likely touches ≤3 files
- No new abstractions needed
- No new external dependencies
- Clear, unambiguous requirements

If ANY criterion fails, say: "This looks larger than a quick task. Consider using `/cortex-plan` for better results." Then ask if they want to proceed anyway.

---

## Step 2: Focus

Run the context selection algorithm:
1. Parse the task for key terms
2. Grep/Glob for matching files
3. Read the top 3-5 candidate files briefly

No need to launch an agent — do this inline.

---

## Step 3: Implement

Implement the change directly, following `.cortex/profile.json` conventions if available.

Key rules:
- Follow project naming conventions
- Match existing code style in the files you're touching
- Don't refactor surrounding code unless it's necessary for the task

---

## Step 4: Test

1. If the project has a test command (from profile), run: `<test_command>`
2. If there's a per-file test command, run the specific test for touched files
3. Run lint if available

If tests fail, fix the issue before committing. If lint fails and a lint-fix command exists, run it.

---

## Step 5: Scope Check

After implementing, count lines changed. If more than ~30 lines changed, tell the user:
> "This grew larger than expected (<N> lines changed). Changes are committed. Consider running `/cortex-review` before pushing."

---

## Step 6: Commit

Commit with a concise message:
```
<type>: <task in lowercase imperative>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

Where `<type>` is: `fix`, `feat`, `chore`, `docs`, or `refactor` based on the task.

Tell the user:
```
Done. <N> lines changed across <M> files. Committed as <hash>.
Run `/cortex-ship` to push and open a PR.
```
