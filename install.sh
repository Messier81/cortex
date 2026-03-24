#!/bin/bash
# Cortex install script
# Installs Cortex commands into any project's .claude/ directory
# Usage: ./install.sh [path/to/project]
#        curl -fsSL https://raw.githubusercontent.com/cortex-cc/cortex/main/install.sh | bash

set -e

CORTEX_REPO="https://github.com/Messier81/cortex"
CORTEX_RAW="https://raw.githubusercontent.com/Messier81/cortex/main"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BLUE}  Cortex — Adaptive Project Intelligence${NC}"
echo -e "${BLUE}  for Claude Code${NC}"
echo ""

# Determine target directory
TARGET_DIR="${1:-$(pwd)}"

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: Directory $TARGET_DIR does not exist."
  exit 1
fi

echo -e "Installing into: ${GREEN}$TARGET_DIR${NC}"
echo ""

# If running from curl (no local files), download from GitHub
# If running locally (files exist next to this script), use them
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/commands/cortex-init.md" ]; then
  # Local install
  SOURCE_DIR="$SCRIPT_DIR"
  echo -e "${YELLOW}Using local files from $SOURCE_DIR${NC}"
else
  # Remote install — clone the repo (more reliable than downloading individual files)
  echo "Cloning Cortex from GitHub..."
  TMPDIR_CORTEX=$(mktemp -d)
  trap "rm -rf $TMPDIR_CORTEX" EXIT

  if ! git clone --depth=1 "$CORTEX_REPO" "$TMPDIR_CORTEX/cortex" 2>/dev/null; then
    echo "Error: Could not clone $CORTEX_REPO"
    echo "Try: git clone $CORTEX_REPO && cd cortex && ./install.sh"
    exit 1
  fi

  SOURCE_DIR="$TMPDIR_CORTEX/cortex"
fi

# Warn on reinstall
if [ -f "$TARGET_DIR/.claude/commands/cortex-init.md" ]; then
  echo -e "${YELLOW}Cortex is already installed in this project.${NC}"
  printf "Overwrite existing Cortex files? [y/N] "
  read -r CONFIRM
  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Aborted. Existing installation unchanged."
    exit 0
  fi
fi

# Create target directories
mkdir -p "$TARGET_DIR/.claude/commands"
mkdir -p "$TARGET_DIR/.claude/agents"
mkdir -p "$TARGET_DIR/.claude/skills/project-intelligence"
mkdir -p "$TARGET_DIR/.claude/hooks"

# Copy commands
cp "$SOURCE_DIR/commands/cortex-init.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-focus.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-verify.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-update.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-ask.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-remember.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-recall.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-risk.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-plan.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-build.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-review.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-debug.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-ship.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-quick.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-auto.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-sweep.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-evolve.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-experiment.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-log.md" "$TARGET_DIR/.claude/commands/"

# Copy agents
cp "$SOURCE_DIR/agents/convention-scanner.md" "$TARGET_DIR/.claude/agents/"
cp "$SOURCE_DIR/agents/dependency-mapper.md" "$TARGET_DIR/.claude/agents/"
cp "$SOURCE_DIR/agents/history-analyzer.md" "$TARGET_DIR/.claude/agents/"
cp "$SOURCE_DIR/agents/context-ranker.md" "$TARGET_DIR/.claude/agents/"
cp "$SOURCE_DIR/agents/intent-verifier.md" "$TARGET_DIR/.claude/agents/"
cp "$SOURCE_DIR/agents/risk-assessor.md" "$TARGET_DIR/.claude/agents/"
cp "$SOURCE_DIR/agents/planner.md" "$TARGET_DIR/.claude/agents/"
cp "$SOURCE_DIR/agents/executor.md" "$TARGET_DIR/.claude/agents/"
cp "$SOURCE_DIR/agents/code-reviewer.md" "$TARGET_DIR/.claude/agents/"
cp "$SOURCE_DIR/agents/debugger.md" "$TARGET_DIR/.claude/agents/"
cp "$SOURCE_DIR/agents/experimenter.md" "$TARGET_DIR/.claude/agents/"

# Copy hooks and skills
cp "$SOURCE_DIR/hooks/hooks.json" "$TARGET_DIR/.claude/hooks/"
cp "$SOURCE_DIR/hooks/pre-task-inject.sh" "$TARGET_DIR/.claude/hooks/"
cp "$SOURCE_DIR/hooks/post-tool-lint.sh" "$TARGET_DIR/.claude/hooks/"
chmod +x "$TARGET_DIR/.claude/hooks/pre-task-inject.sh"
chmod +x "$TARGET_DIR/.claude/hooks/post-tool-lint.sh"

# Rewrite hook paths to absolute paths so hooks.json works regardless of working directory
HOOKS_INSTALL_DIR="$(cd "$TARGET_DIR/.claude/hooks" && pwd)"
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s|\.claude/hooks/|$HOOKS_INSTALL_DIR/|g" "$TARGET_DIR/.claude/hooks/hooks.json"
else
  sed -i "s|\.claude/hooks/|$HOOKS_INSTALL_DIR/|g" "$TARGET_DIR/.claude/hooks/hooks.json"
fi
cp "$SOURCE_DIR/skills/project-intelligence/SKILL.md" "$TARGET_DIR/.claude/skills/project-intelligence/"

echo ""
echo -e "${GREEN}Done! Cortex installed into $TARGET_DIR/.claude/${NC}"
echo -e "  19 commands, 11 agents, 1 skill, 2 hooks"
echo ""
echo "Quick start:"
echo ""
echo -e "  1. Open Claude Code in ${GREEN}$TARGET_DIR${NC}"
echo -e "  2. Run ${GREEN}/cortex-init${NC} to analyze your project (one-time)"
echo -e "  3. Run ${GREEN}/cortex-plan <task>${NC} to plan your next feature"
echo -e "  4. Run ${GREEN}/cortex-build${NC} to execute the plan step by step"
echo -e "  5. Run ${GREEN}/cortex-ship${NC} to review, commit, push, and open a PR"
echo ""
echo "All commands:"
echo -e "  ${GREEN}/cortex-plan${NC}     Plan a task with structured requirements and TDD steps"
echo -e "  ${GREEN}/cortex-build${NC}    Execute the active plan step by step"
echo -e "  ${GREEN}/cortex-review${NC}   Two-stage review: spec compliance + code quality"
echo -e "  ${GREEN}/cortex-debug${NC}    Systematic hypothesis-driven debugging"
echo -e "  ${GREEN}/cortex-ship${NC}     Push branch and create a PR"
echo -e "  ${GREEN}/cortex-quick${NC}    Fast path for small tasks"
echo -e "  ${GREEN}/cortex-focus${NC}    Find the right files for a task"
echo -e "  ${GREEN}/cortex-verify${NC}   Verify changes against original intent"
echo -e "  ${GREEN}/cortex-risk${NC}     Classify blast radius of pending changes"
echo -e "  ${GREEN}/cortex-update${NC}   Rescan changed files and patch the profile"
echo -e "  ${GREEN}/cortex-ask${NC}      Ask questions about your project"
echo -e "  ${GREEN}/cortex-remember${NC} Save decisions and gotchas for future sessions"
echo -e "  ${GREEN}/cortex-recall${NC}   Search saved memories by keyword"
echo ""
echo -e "Commit ${GREEN}.cortex/profile.json${NC} and ${GREEN}.cortex/CONVENTIONS.md${NC} to share with your team."
echo ""
echo "More info: $CORTEX_REPO"
