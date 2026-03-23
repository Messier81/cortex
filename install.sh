#!/bin/bash
# Cortex install script
# Installs Cortex commands into any project's .claude/ directory
# Usage: ./install.sh [path/to/project]
#        curl -fsSL https://raw.githubusercontent.com/cortex-cc/cortex/main/install.sh | bash

set -e

CORTEX_REPO="https://github.com/cortex-cc/cortex"
CORTEX_RAW="https://raw.githubusercontent.com/cortex-cc/cortex/main"

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

# Create target directories
mkdir -p "$TARGET_DIR/.claude/commands"
mkdir -p "$TARGET_DIR/.claude/agents"
mkdir -p "$TARGET_DIR/.claude/skills/project-intelligence"

# Copy files
cp "$SOURCE_DIR/commands/cortex-init.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-focus.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-verify.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/agents/convention-scanner.md" "$TARGET_DIR/.claude/agents/"
cp "$SOURCE_DIR/agents/dependency-mapper.md" "$TARGET_DIR/.claude/agents/"
cp "$SOURCE_DIR/agents/history-analyzer.md" "$TARGET_DIR/.claude/agents/"
cp "$SOURCE_DIR/agents/context-ranker.md" "$TARGET_DIR/.claude/agents/"
cp "$SOURCE_DIR/agents/intent-verifier.md" "$TARGET_DIR/.claude/agents/"
cp "$SOURCE_DIR/skills/project-intelligence/SKILL.md" "$TARGET_DIR/.claude/skills/project-intelligence/"

echo ""
echo -e "${GREEN}Done! Cortex installed into $TARGET_DIR/.claude/${NC}"
echo ""
echo "Next steps:"
echo ""
echo -e "  1. Open Claude Code in ${GREEN}$TARGET_DIR${NC}"
echo -e "  2. Run ${GREEN}/cortex-init${NC} to analyze your project"
echo -e "  3. Before any task, run ${GREEN}/cortex-focus <task description>${NC}"
echo -e "  4. After implementation, run ${GREEN}/cortex-verify${NC} to check your work"
echo ""
echo -e "Commit ${GREEN}.cortex/profile.json${NC} and ${GREEN}.cortex/CONVENTIONS.md${NC} to share with your team."
echo ""
echo "More info: $CORTEX_REPO"
