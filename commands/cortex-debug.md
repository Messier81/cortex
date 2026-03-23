---
description: Systematic hypothesis-driven debugging. Reproduces the failure, generates ranked hypotheses, investigates methodically, and implements a fix with a regression test once root cause is confirmed.
argument-hint: Description of the failure (e.g. "test AuthService.login is failing with TypeError")
---

# Cortex Debug

You are orchestrating a systematic debugging session. No guessing. No random changes. Hypothesize, investigate, confirm, then fix.

**Failure description:** $ARGUMENTS

If no description was provided, ask: "What's failing? Describe the symptom or paste the error message."

---

## Step 1: Load Context

Read `.cortex/profile.json` for the project's test and run commands.

Parse the failure description for:
- A specific test name or file (to run directly)
- An error message (to grep for in source files)
- A feature/component name (to find relevant files)

---

## Step 2: Launch Debugger Agent

Launch the **debugger** agent with:
- The failure description
- The exact test command to run (from profile, if known)
- The project root
- Any files you've already identified as relevant

The debugger will:
1. Reproduce the failure
2. Generate 3 ranked hypotheses
3. Investigate each until root cause confirmed
4. Implement a fix + regression test

---

## Step 3: Present Results

When the debugger returns, present the full debug report:

```
## Debug Session: "<failure>"

### Root Cause
<confirmed hypothesis>

### Fix Applied
<what changed and why>

### Regression Test
<test name and file>

### Test Results
Full suite: PASS | N failures remaining
```

If the debugger could not find the root cause (all hypotheses denied), present what was ruled out and ask the user for additional context:
- Can you share the full stack trace?
- When did this start failing?
- What changed recently?

---

## Step 4: Follow-up

If the fix involved changes that seem risky, suggest running `/cortex-risk` to assess blast radius, then `/cortex-review` before shipping.
