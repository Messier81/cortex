#!/bin/bash
# Cortex install script
# Installs Cortex commands into any project's .claude/ directory
# Usage: ./install.sh [path/to/project]
#        curl -fsSL https://raw.githubusercontent.com/Messier81/cortex/main/install.sh | bash

set -e

CORTEX_REPO="https://github.com/Messier81/cortex"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BLUE}  Cortex — Experiment Lab for Claude Code${NC}"
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
  # Remote install — clone the repo
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
mkdir -p "$TARGET_DIR/.claude/hooks"

# Copy commands
cp "$SOURCE_DIR/commands/cortex-init.md"       "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-build.md"      "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-auto.md"       "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-sweep.md"      "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-evolve.md"     "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-experiment.md" "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-log.md"        "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-reflect.md"    "$TARGET_DIR/.claude/commands/"
cp "$SOURCE_DIR/commands/cortex-digest.md"     "$TARGET_DIR/.claude/commands/"

# Copy agents
cp "$SOURCE_DIR/agents/convention-scanner.md"  "$TARGET_DIR/.claude/agents/"
cp "$SOURCE_DIR/agents/dependency-mapper.md"   "$TARGET_DIR/.claude/agents/"
cp "$SOURCE_DIR/agents/history-analyzer.md"    "$TARGET_DIR/.claude/agents/"
cp "$SOURCE_DIR/agents/experimenter.md"        "$TARGET_DIR/.claude/agents/"

# Copy hooks
cp "$SOURCE_DIR/hooks/hooks.json"              "$TARGET_DIR/.claude/hooks/"
cp "$SOURCE_DIR/hooks/pre-task-inject.sh"      "$TARGET_DIR/.claude/hooks/"
cp "$SOURCE_DIR/hooks/post-tool-lint.sh"       "$TARGET_DIR/.claude/hooks/"
chmod +x "$TARGET_DIR/.claude/hooks/pre-task-inject.sh"
chmod +x "$TARGET_DIR/.claude/hooks/post-tool-lint.sh"

# Rewrite hook paths to absolute paths so hooks.json works regardless of working directory.
# Uses Python string.replace instead of sed to safely handle paths containing &, |, or spaces.
HOOKS_INSTALL_DIR="$(cd "$TARGET_DIR/.claude/hooks" && pwd)"
python3 -c "
import sys
hooks_file, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
with open(hooks_file) as f:
    content = f.read()
with open(hooks_file, 'w') as f:
    f.write(content.replace(old, new))
" "$TARGET_DIR/.claude/hooks/hooks.json" ".claude/hooks/" "$HOOKS_INSTALL_DIR/"

# Register global hooks in ~/.claude/settings.json using absolute paths.
GLOBAL_SETTINGS="$HOME/.claude/settings.json"
CORTEX_HOOKS_DIR="$(cd "$SOURCE_DIR/hooks" && pwd)"

if [ -f "$GLOBAL_SETTINGS" ]; then
  python3 -c "
import json, sys

settings_file = sys.argv[1]
hooks_dir = sys.argv[2]

with open(settings_file) as f:
    settings = json.load(f)

hooks = settings.setdefault('hooks', {})

hooks['UserPromptSubmit'] = [{'hooks': [{'type': 'command', 'command': hooks_dir + '/pre-task-inject.sh', 'timeout': 3}]}]

post = hooks.get('PostToolUse', [])
# Remove any existing Cortex lint entry (by script name) then re-add with correct path
post = [e for e in post if not any('post-tool-lint' in h.get('command', '') for h in e.get('hooks', []))]
post.append({'matcher': 'Write|Edit|MultiEdit', 'hooks': [{'type': 'command', 'command': hooks_dir + '/post-tool-lint.sh', 'timeout': 10}]})
hooks['PostToolUse'] = post

with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
" "$GLOBAL_SETTINGS" "$CORTEX_HOOKS_DIR"
  echo -e "  ${GREEN}✓${NC} Registered global hooks in $GLOBAL_SETTINGS"
else
  echo -e "  ${YELLOW}⚠${NC}  $GLOBAL_SETTINGS not found — skipping global hook registration"
fi

echo ""
echo -e "${GREEN}Done! Cortex installed into $TARGET_DIR/.claude/${NC}"
echo -e "  9 commands · 4 agents · 2 hooks"
echo ""
echo "Quick start:"
echo ""
echo -e "  1. Open Claude Code in ${GREEN}$TARGET_DIR${NC}"
echo -e "  2. Run ${GREEN}/cortex-init${NC} to scan your project (one-time setup)"
echo -e "  3. Run ${GREEN}/cortex-auto${NC} to start autonomous improvement experiments"
echo ""
echo "Commands:"
echo -e "  ${GREEN}/cortex-init${NC}        Scan project, build profile (run once; --update to refresh)"
echo -e "  ${GREEN}/cortex-build${NC}       Execute a plan step by step with context isolation"
echo -e "  ${GREEN}/cortex-auto${NC}        Autonomous experiment loop with reflexion memory"
echo -e "  ${GREEN}/cortex-sweep${NC}       Best-of-N: generate N candidates, pick the winner"
echo -e "  ${GREEN}/cortex-evolve${NC}      Evolutionary optimization across generations"
echo -e "  ${GREEN}/cortex-experiment${NC}  Single hypothesis → measure → keep or discard"
echo -e "  ${GREEN}/cortex-log${NC}         View experiment history (--patterns for learnings)"
echo -e "  ${GREEN}/cortex-reflect${NC}     Full cross-session intelligence synthesis"
echo -e "  ${GREEN}/cortex-digest${NC}      Quick-reference digest card (daily use)"
echo ""
echo -e "  ${YELLOW}Tip:${NC} Install pctx MCP server for decision tracking and cross-session intelligence."
echo -e "       Cortex works fully without it, but pctx unlocks /cortex-reflect and /cortex-digest."
echo ""
echo -e "Commit ${GREEN}.cortex/profile.json${NC} and ${GREEN}.cortex/CONVENTIONS.md${NC} to share with your team."
echo ""
echo "More info: $CORTEX_REPO"
