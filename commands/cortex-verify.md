---
description: Verify that your recent changes actually satisfy the original task intent. Reads .cortex/active-intent.json and checks the current diff against it.
argument-hint: Optional - override with a specific intent description instead of reading from file
---

# Cortex Verify

You are performing an intent-anchored verification. This is NOT just "did tests pass" — it's "did we actually build what was asked?"

---

## Step 1: Load Intent

**If $ARGUMENTS is provided**: Use that as the intent description directly. Parse it into implied requirements.

**Otherwise**: Read `.cortex/active-intent.json`.

If neither exists, tell the user: "No active intent found. Run `/cortex-focus <task>` before starting work, or pass the intent directly: `/cortex-verify Add OAuth login with Google`"

The intent contains:
- `task`: the original task description
- `implied_requirements`: list of specific things that need to happen
- `context_files`: files that were identified as relevant

**Staleness check**: After loading the intent, compare the `captured_at` timestamp against the most recent git commit. Run `git log -1 --format=%ct` to get the latest commit timestamp. If the intent's `captured_at` predates the latest commit, display this warning:

> ⚠️ Warning: This intent was captured before your most recent commit. It may not reflect the current task. Consider running `/cortex-focus` again, or proceed with the existing intent.

Then continue with verification regardless.

---

## Step 2: Gather the Diff

Run: `git diff HEAD` to see all uncommitted changes.

If the result is empty, try: `git diff HEAD~1` (last commit) or ask the user how many commits represent this work.

Parse the diff into:
- **New files created**: list them
- **Files modified**: list them with line count changed
- **Files deleted**: list them

---

## Step 3: Launch Intent Verifier

Launch the **intent-verifier** agent with:
- The original task description
- The list of implied requirements
- The full diff text
- The list of context_files (files that were expected to change)
- The project conventions from `.cortex/profile.json` (if it exists)

The intent-verifier will return a structured evaluation.

---

## Step 4: Output Verdict

Present the results in this format:

```
## Cortex Verify: "<task>"

### Requirements Check
- [PASS] <requirement 1> — <evidence in diff>
- [PASS] <requirement 2> — <evidence in diff>
- [WARN] <requirement 3> — <partial evidence, what's missing>
- [FAIL] <requirement 4> — <no evidence found>

### Side Effects
- [EXPECTED] <file> was changed — <why this makes sense>
- [FLAG] <file> was changed but wasn't in the original context — <is this intentional?>

### Convention Compliance
- [PASS] New files follow naming conventions
- [WARN] <specific issue if any>

### Overall: PASS / PASS WITH WARNINGS / FAIL

<If FAIL or WARN: specific next steps>
```

**Verdict rules:**
- **PASS**: All implied requirements have clear evidence in the diff
- **PASS WITH WARNINGS**: All critical requirements met, but minor gaps or convention issues
- **FAIL**: One or more requirements have no evidence

---

## Step 5: On Failure

If the verdict is FAIL, be specific:
- Which requirement is missing?
- What would satisfy it? (What code needs to exist?)
- Is this a gap in implementation or a gap in how the requirement was interpreted?

Ask the user: "Should we address the missing requirements now, or was this intentional?"

If the user says intentional, offer to update `.cortex/active-intent.json` to mark those requirements as explicitly out of scope.
