---
description: Given a task description, find and surface the most relevant files, patterns, and context from this codebase. Also saves the task as the active intent for later verification with /cortex-verify.
argument-hint: Describe the task you want to work on
---

# Cortex Focus

Your task: **$ARGUMENTS**

You are a precision context selector. Your job is to find exactly the files and patterns that matter for this specific task — no more, no less. The output of this command becomes the developer's working context.

---

## Step 1: Load Project Profile

Read `.cortex/profile.json` if it exists. This tells you:
- How the project is structured (feature-based vs layer-based)
- Naming conventions
- Where tests live relative to source
- Core abstractions

If `.cortex/profile.json` does NOT exist, tell the user: "Run `/cortex-init` first to build your project profile. This makes context selection much more accurate." Then proceed with a best-effort generic search.

---

## Step 2: Extract Search Terms

From the task description, identify:
- **Domain terms**: nouns that indicate a feature/module (e.g. "auth", "user", "billing", "payment")
- **Action terms**: what's being done (e.g. "add endpoint", "fix bug", "refactor", "migrate")
- **Technical terms**: specific technologies, patterns, or names mentioned (e.g. "JWT", "OAuth", "PostgreSQL", "Redis")
- **File/function names**: if any specific names are mentioned

---

## Step 3: Tier 1 — Structural Search

Based on the project profile's structure pattern:

**If feature-based structure**: Look for a directory matching the domain terms. Search in `src/<domain>/`, `app/<domain>/`, `packages/<domain>/`, etc.

**If layer-based structure**: Identify which layers are relevant:
- "add endpoint" or "add route" → look in routes/, controllers/, handlers/, api/
- "database" or "model" → look in models/, schemas/, db/, repositories/
- "UI" or "component" → look in components/, views/, pages/

Use Grep to search for the technical terms in likely directories. Use Glob to find files whose names match domain terms.

Score each candidate file:
- Filename matches domain term: **10 points**
- Directory name matches domain term: **7 points**
- File content contains multiple search terms: **5 points**
- File content contains one search term: **2 points**

---

## Step 4: Tier 2 — Import Graph Expansion

For the **top 5 files** from Tier 1 (by score), read them and extract their imports using a simple pattern match:
- TypeScript/JavaScript: `import.*from ['"](.+)['"]` or `require(['"](.+)['"])`
- Python: `^from (.+) import` or `^import (.+)`
- Go: `"(.+)"` inside `import` blocks
- Rust: `use (.+);`

Resolve relative imports to actual file paths. Add those files to the candidate list with score = **parent_score × 0.4** (capped at 8).

Also search for files that **import** the top 5 files (who depends on them). Add those with score = **parent_score × 0.3**.

---

## Step 5: Launch Context Ranker

Take the top 15-20 candidates. Launch the **context-ranker** agent with:
- The task description
- For each candidate: `{path, score, first 30 lines}`

The context-ranker will return a re-ordered list with explanations for why each file is or isn't relevant.

---

## Step 6: Find Test Files

For each source file in the final selection, find its corresponding test file using the project profile's `conventions.structure.test_location` and `test_suffix`. Include them in a separate "Test files" section.

---

## Step 7: Save Active Intent

Write `.cortex/active-intent.json`:

```json
{
  "task": "<the original task description>",
  "captured_at": "<ISO-8601>",
  "context_files": ["<list of all files surfaced>"],
  "implied_requirements": [
    "<break the task into 3-7 specific things that need to happen>"
  ]
}
```

The implied requirements are your interpretation of what completing this task requires. Be specific. For "Add OAuth2 login with Google", the implied requirements would be:
- New login/redirect endpoint for Google OAuth
- OAuth callback endpoint to handle token exchange
- Session creation after successful OAuth
- Error handling for OAuth failures
- Test coverage for the new endpoints

---

## Step 8: Output

Present results in this format:

```
## Cortex Focus: "<task>"

### Primary files — read these first
1. `path/to/file.ts` — <why this is relevant>
2. `path/to/file.ts` — <why this is relevant>
...

### Secondary files — reference as needed
4. `path/to/file.ts` — <why this is relevant>
...

### Test files
7. `path/to/file.test.ts` — test file for #1
...

### Conventions to follow
- <specific pattern from this codebase relevant to the task>
- <naming convention for new files you'll create>
- <error handling pattern to use>
- <import style>

### What this task requires
1. <implied requirement 1>
2. <implied requirement 2>
...

Active intent saved to .cortex/active-intent.json — run /cortex-verify when done.
```

Keep it scannable. The developer will use this as their working context.
