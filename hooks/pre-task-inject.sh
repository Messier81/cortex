#!/bin/bash
# Cortex pre-task context injector
# Reads .cortex/profile.json from the current project and injects a brief
# context hint when the user submits a task-like prompt.

# Read stdin (hook input JSON)
INPUT=$(cat)

# Extract the prompt text (1 python3 call)
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

# Read all profile fields + stale check in a single python3 call.
# Output is one field per line — avoids IFS/tab collapse for empty fields
# (e.g. projects with no frameworks). Each read -r call consumes one line.
{
  read -r PROJECT_NAME
  read -r LANGUAGES
  read -r FRAMEWORKS
  read -r FILE_NAMING
  read -r TEST_CMD
  read -r STALE
} < <(python3 -c "
import json, os, time
try:
    d = json.load(open('$PROFILE_PATH'))
    proj = d.get('project', {})
    conv = d.get('conventions', {})
    ci   = d.get('ci', {}).get('commands', {})
    name     = proj.get('name', 'this project')
    langs    = ', '.join(proj.get('languages', []))
    fws      = ', '.join(proj.get('frameworks', []))
    naming   = conv.get('naming', {}).get('files', '')
    test_cmd = ci.get('test', '')
    mtime    = os.path.getmtime('$PROFILE_PATH')
    stale    = 'stale' if time.time() - mtime > 30*86400 else ''
    for v in [name, langs, fws, naming, test_cmd, stale]:
        print(v)
except:
    for _ in range(6):
        print('')
" 2>/dev/null)

# Build context hint
CONTEXT="[Cortex] Project: $PROJECT_NAME ($LANGUAGES"
if [ -n "$FRAMEWORKS" ]; then
  CONTEXT="$CONTEXT, $FRAMEWORKS"
fi
CONTEXT="$CONTEXT). File naming: $FILE_NAMING."
if [ -n "$TEST_CMD" ]; then
  CONTEXT="$CONTEXT Tests: \`$TEST_CMD\`."
fi
if [ -n "$STALE" ]; then
  CONTEXT="$CONTEXT [Profile is over 30 days old — run /cortex-init --update to refresh.]"
fi

# Check experiment log for session count + most recent pattern (1 python3 call)
LOG_PATH="$(pwd)/.cortex/experiments/log.json"
if [ -f "$LOG_PATH" ]; then
  EXPERIMENT_HINT=$(python3 -c "
import json
try:
    data = json.load(open('$LOG_PATH'))
    sessions = data.get('sessions', [])
    count = len(sessions)
    if count == 0:
        print('')
    else:
        # Find most recent pattern across all sessions (only read patterns_learned, skip attempts)
        latest_pattern = ''
        for s in reversed(sessions):
            patterns = s.get('patterns_learned', [])
            if patterns:
                latest_pattern = str(patterns[0])[:80]
                break
        if latest_pattern:
            print(f'{count} experiment sessions. Recent learning: {latest_pattern}')
        else:
            print(f'{count} experiment sessions logged.')
except:
    print('')
" 2>/dev/null)
  if [ -n "$EXPERIMENT_HINT" ]; then
    CONTEXT="$CONTEXT [Cortex experiments: $EXPERIMENT_HINT]"
  fi
fi

# Output the injected context as a system message (1 python3 call)
python3 -c "
import json, sys
content = sys.argv[1]
print(json.dumps({'type': 'system', 'content': content}))
" "$CONTEXT"
