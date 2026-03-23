---
description: Search your persistent Cortex memories by keyword. Surfaces past decisions, patterns, gotchas, and architecture notes.
argument-hint: Search query (e.g. "auth", "state management", "database")
---

# Cortex Recall

**Search query:** $ARGUMENTS

---

## Step 1: Check for Memories

Look for `.json` files in `.cortex/memories/`. If the directory doesn't exist or has no `.json` files:
Tell the user: "No memories saved yet. Use `/cortex-remember <what>` to save your first one."
Stop.

---

## Step 2: Search

Read all `.json` files in `.cortex/memories/`.

Parse `$ARGUMENTS` into individual keywords (split on spaces).

For each memory file, compute a relevance score:
- **+3** for each keyword that matches a tag (case-insensitive)
- **+2** if any keyword appears in the content (case-insensitive)
- **+1** if any keyword matches the category name

A memory with score 0 is excluded from results.

Sort by score descending. Take top 10.

---

## Step 3: Output

```
## Cortex Recall: "<query>"

Found <N> memories

1. [decision] We chose Zustand over Redux because of bundle size — vanilla...
   Tags: zustand, redux, state, bundle-size | Saved: 2024-03-15

2. [gotcha] Don't use barrel files — the build tooling doesn't tree-shake...
   Tags: imports, build, performance | Saved: 2024-03-10
```

Show the full content (not truncated) for each result.

---

## Step 4: No Results

If no memories score above 0:
- Say "No memories found for '<query>'"
- List all unique tags across all memory files: "Available tags: auth, zustand, database, ..."
- Suggest trying one of those tags
