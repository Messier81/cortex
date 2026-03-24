---
description: Save a decision, pattern, gotcha, or architecture note to persistent cross-session memory. Recalled later with /cortex-recall.
argument-hint: What to remember (e.g. "We chose Zustand over Redux because of bundle size")
---

# Cortex Remember

You are saving a memory for future sessions.

**Content to save:** $ARGUMENTS

---

## Step 1: Classify the Memory

Analyze the content and determine the category:
- **decision**: contains "chose", "decided", "went with", "picked", "selected", "because", "instead of"
- **pattern**: contains "always", "pattern", "convention", "approach", "way we", "how we"
- **gotcha**: contains "don't", "careful", "gotcha", "bug", "workaround", "issue", "watch out", "avoid", "never"
- **architecture**: contains "module", "service", "layer", "structure", "architecture", "abstraction", "system"

Default to **decision** if ambiguous.

---

## Step 2: Extract Tags

Pull out 2-5 significant technical terms or nouns from the content. These are what users will search for later. Examples: `zustand`, `redux`, `state`, `bundle-size`, `auth`, `oauth`, `database`.

---

## Step 3: Generate ID and Save

Generate an ID using the current timestamp: run `date -u +%Y%m%d-%H%M%S` and use that as the ID.

Create `.cortex/memories/` if it doesn't exist.

Ensure `.cortex/.gitignore` exists and contains the full exclusion set. Create the file unconditionally if needed (do not require `/cortex-init` to have run first):
- If `.cortex/.gitignore` doesn't exist: create it with all five lines:
  ```
  active-intent.json
  active-plan.json
  db/
  memories/
  experiments/
  ```
- If it exists but is missing any of these lines: append the missing ones

Write `.cortex/memories/<id>.json`:

```json
{
  "id": "<id>",
  "category": "<decision|pattern|gotcha|architecture>",
  "content": "<the full original text from $ARGUMENTS>",
  "tags": ["<tag1>", "<tag2>"],
  "timestamp": "<ISO-8601 from: date -u +%Y-%m-%dT%H:%M:%SZ>",
  "project": "<basename of current working directory>"
}
```

---

## Step 4: Confirm

Tell the user:
```
Saved [<category>] memory — "<first 60 chars of content>..."
Tags: <tag1>, <tag2>, <tag3>
ID: <id>

Recall it later with: /cortex-recall <tag>
```
