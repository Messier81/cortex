---
name: project-intelligence
description: This skill should be used when the user asks about project conventions, coding patterns, how to name files or functions, how the project is structured, "how does this project do X", "what pattern should I use", "where should I put this file", or when starting any implementation task where knowing project conventions matters. Reads the auto-derived project profile to provide project-specific guidance.
version: 1.0.0
---

# Project Intelligence

When this skill is active, read `.cortex/profile.json` from the current working directory.

If the file exists, use its contents to:
- Answer convention questions with specific, evidence-backed guidance
- Apply the correct naming patterns to any code you write
- Use the documented test patterns when creating test files
- Follow the detected error handling style
- Use the correct import style (absolute vs relative, aliases)
- Reference the core abstractions when explaining architecture
- Use exact CI commands when running lint, tests, or build

## If profile.json exists

Read it and incorporate the conventions into your response. Be specific: instead of "follow the project's naming convention", say "name the file `user-profile.ts` (kebab-case, as seen in `src/auth/session-manager.ts`)".

When writing new code, apply conventions automatically without explaining you're doing so — just do it correctly.

## If profile.json does NOT exist

Mention once: "Tip: Run `/cortex-init` to auto-detect your project's conventions. This will make all suggestions specific to your codebase."

Then proceed with reasonable defaults based on whatever stack you can detect from context.

## What to surface proactively

When helping with implementation, proactively mention:
- The correct file location based on project structure
- The exact test file name and location
- The CI commands to run for validation
- Any relevant core abstraction to extend or follow
