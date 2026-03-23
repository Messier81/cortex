#!/bin/bash
# Cortex pre-task context injector
# Reads .cortex/profile.json from the current project and injects a brief
# context hint when the user submits a task-like prompt.

# Read stdin (hook input JSON)
INPUT=$(cat)

# Extract the prompt text
PROMPT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('prompt',''))" 2>/dev/null)

# Only inject if:
# 1. .cortex/profile.json exists in the current directory
# 2. The prompt looks like a task (>10 words and contains action verbs)
PROFILE_PATH="$(pwd)/.cortex/profile.json"

if [ ! -f "$PROFILE_PATH" ]; then
  exit 0
fi

WORD_COUNT=$(echo "$PROMPT" | wc -w | tr -d ' ')
if [ "$WORD_COUNT" -lt 10 ]; then
  exit 0
fi

# Check for action verbs that suggest this is a task
ACTION_VERBS="add|create|implement|fix|update|refactor|migrate|build|write|make|change|remove|delete|move|rename|extract|integrate"
HAS_ACTION=$(echo "$PROMPT" | grep -iE "\b($ACTION_VERBS)\b" | head -1)

if [ -z "$HAS_ACTION" ]; then
  exit 0
fi

# Read key facts from profile
PROJECT_NAME=$(python3 -c "import json; d=json.load(open('$PROFILE_PATH')); print(d.get('project',{}).get('name','this project'))" 2>/dev/null)
LANGUAGES=$(python3 -c "import json; d=json.load(open('$PROFILE_PATH')); print(', '.join(d.get('project',{}).get('languages',[])))" 2>/dev/null)
FRAMEWORKS=$(python3 -c "import json; d=json.load(open('$PROFILE_PATH')); print(', '.join(d.get('project',{}).get('frameworks',[])))" 2>/dev/null)
FILE_NAMING=$(python3 -c "import json; d=json.load(open('$PROFILE_PATH')); print(d.get('conventions',{}).get('naming',{}).get('files',''))" 2>/dev/null)
TEST_CMD=$(python3 -c "import json; d=json.load(open('$PROFILE_PATH')); print(d.get('ci',{}).get('commands',{}).get('test',''))" 2>/dev/null)

# Build context hint
CONTEXT="[Cortex] Project: $PROJECT_NAME ($LANGUAGES"
if [ -n "$FRAMEWORKS" ]; then
  CONTEXT="$CONTEXT, $FRAMEWORKS"
fi
CONTEXT="$CONTEXT). File naming: $FILE_NAMING."
if [ -n "$TEST_CMD" ]; then
  CONTEXT="$CONTEXT Tests: \`$TEST_CMD\`."
fi
CONTEXT="$CONTEXT Run \`/cortex-focus\` for full context selection."

# Output the injected context as a system message
echo "{\"type\": \"system\", \"content\": \"$CONTEXT\"}"
