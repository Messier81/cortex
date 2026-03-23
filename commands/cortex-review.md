---
description: Two-stage adversarial code review. Stage 1 checks spec compliance (did we build what was asked?). Stage 2 checks code quality (convention adherence, security, error handling, test coverage).
argument-hint: Optional - override intent with a description (e.g. "Add OAuth login")
---

# Cortex Review

You are running a two-stage adversarial review. This is more thorough than `/cortex-verify` — it checks both intent satisfaction AND code quality.

---

## Step 1: Load Intent + Plan

**If $ARGUMENTS is provided**: Use that as the intent description.

**Otherwise**: Try to load `.cortex/active-intent.json`. If that doesn't exist, try `.cortex/active-plan.json`. If neither exists:
> "No active intent found. Run `/cortex-focus <task>` or `/cortex-plan <task>` before reviewing, or pass the intent directly: `/cortex-review Add OAuth login`"

---

## Step 2: Gather Diff

Run `git diff HEAD` to get all uncommitted changes.

If empty, try `git diff HEAD~1` (last commit). Ask the user if more commits should be included.

---

## Step 3: Stage 1 — Spec Compliance

Launch the **intent-verifier** agent with:
- The task description
- The implied requirements
- The full diff
- The context files

Wait for results. Display Stage 1 findings immediately:

```
### Stage 1: Spec Compliance
- [PASS/WARN/FAIL] <requirement> — <evidence>
...
Stage 1 result: PASS | PASS WITH WARNINGS | FAIL
```

If Stage 1 is FAIL: Ask the user if they want to continue to Stage 2 or address spec gaps first.

---

## Step 4: Stage 2 — Code Quality

Launch the **code-reviewer** agent with:
- The full diff text
- The project conventions from `.cortex/profile.json`
- The list of changed file paths (to read for full context)

Wait for results. Display Stage 2 findings:

```
### Stage 2: Code Quality

#### CRITICAL
- [file:line] <issue> — <fix>

#### WARNING
- [file:line] <issue> — <fix>

#### INFO
- [file:line] <observation>

Stage 2 result: PASS | PASS_WITH_WARNINGS | FAIL
```

---

## Step 5: Combined Verdict

```
## Review Complete: "<task>"

Stage 1 (Spec):    PASS | PASS WITH WARNINGS | FAIL
Stage 2 (Quality): PASS | PASS WITH WARNINGS | FAIL

Overall: PASS | PASS WITH WARNINGS | FAIL

<If issues found>:
Critical issues to fix before merging:
1. <issue>

Run `/cortex-ship` when ready to push.
```

**Verdict rules:**
- **PASS**: Both stages pass cleanly
- **PASS WITH WARNINGS**: No critical issues, but warnings present
- **FAIL**: Any CRITICAL quality issue OR any Stage 1 FAIL
