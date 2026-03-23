---
description: Classify the blast radius of your pending changes before making them. Shows risk per file and mitigation suggestions.
argument-hint: Optional - specific files to assess (default: current git diff)
---

# Cortex Risk

You are performing a pre-change risk assessment.

---

## Step 1: Get Files to Assess

**If $ARGUMENTS is provided**: treat the arguments as a space-separated list of file paths to assess.

**Otherwise**:
1. Run `git diff --name-only` (staged + unstaged uncommitted changes)
2. If empty, run `git diff HEAD~1 --name-only` (last commit)
3. If still empty, tell the user: "No changes detected. Pass specific files as arguments: `/cortex-risk src/auth/session.ts`"

Cap at 20 files. If more, assess the first 20 and note that the rest were skipped.

---

## Step 2: Load Profile

Read `.cortex/profile.json` if it exists. Pass it to the risk-assessor agent so it can use test conventions for accurate test file detection.

---

## Step 3: Launch Risk Assessor

Launch the **risk-assessor** agent with:
- The list of files to assess
- The project profile (or null if not present)

---

## Step 4: Output Results

Format the agent's JSON response as a readable report:

```
## Cortex Risk Assessment

**Overall Risk: <CRITICAL|HIGH|MEDIUM|LOW>**

| File | Criticality | Scope | Fan-out | Tests | Hotspot | Risk |
|------|-------------|-------|---------|-------|---------|------|
| src/auth/session.ts | HIGH | 45% | 12 | YES | YES | HIGH |
| src/utils/format.ts | LOW | 8% | 2 | YES | NO | LOW |

### Mitigations
- `src/auth/session.ts` (HIGH): Auth file with 12 dependents — review for security implications, run full test suite
- ...

### Summary
<N> files assessed: <X> CRITICAL, <Y> HIGH, <Z> MEDIUM, <W> LOW
<agent's one-sentence summary>
```

---

## Step 5: Advice

Based on the overall risk level:
- **CRITICAL/HIGH**: "Recommend running the full test suite before merging. Consider splitting into smaller PRs."
- **MEDIUM**: "Run relevant tests. Review flagged files carefully."
- **LOW**: "Low risk change. Standard review applies."
