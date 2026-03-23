---
description: Ask natural language questions about your project's conventions, structure, and architecture. Answers from your auto-derived profile.
argument-hint: Your question (e.g. "Where should I add a new store?" or "What test framework do we use?")
---

# Cortex Ask

**Question:** $ARGUMENTS

You are answering a question about this specific project using its Cortex profile as your knowledge base. Be precise — cite the actual paths and patterns from the profile, not generic advice.

---

## Step 1: Load Knowledge Base

Read ALL of these (they all inform the answer):
- `.cortex/profile.json` — the structured profile
- `.cortex/CONVENTIONS.md` — the human-readable summary
- All `.json` files in `.cortex/memories/` if the directory exists

If neither `profile.json` nor `CONVENTIONS.md` exists: tell the user to run `/cortex-init` first, then give a best-effort answer based on what you can detect from the codebase.

---

## Step 2: Answer the Question

Use the loaded data as your source of truth. Match the question to the right profile fields:

**"Where should I put/add/create X?"**
→ Use `conventions.structure.pattern` and `architecture.core_abstractions` to identify the right directory. Name the exact path (e.g., "Add it to `src/stores/` — this project uses Zustand vanilla stores in that directory, see `architecture.core_abstractions`").

**"What [framework/tool/command] do we use for X?"**
→ Answer directly from the relevant profile field: `architecture.test_framework`, `ci.commands.*`, `project.frameworks`, `key_dependencies.*`.

**"How do we handle X?" or "What's the pattern for X?"**
→ Use `conventions.error_handling`, `conventions.imports`, `conventions.naming`, or the relevant CONVENTIONS.md section. Cite the `example_file` if available.

**"What is X?" or "How does X work?"** (architecture questions)
→ Find X in `architecture.core_abstractions` and explain it. Point to the relevant files.

**Anything answered by a memory** (past decision, gotcha, pattern):
→ Surface the relevant memory and cite it.

---

## Step 3: Format the Answer

Keep it concise. Include:
- The direct answer
- The specific path/file/command (not generic)
- Which profile field or memory supports it (one citation, parenthetical)

If the profile doesn't have enough data to answer, say what's missing and suggest either running `/cortex-init` or checking specific files manually.
