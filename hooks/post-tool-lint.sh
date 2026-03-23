#!/bin/bash
# Cortex post-tool lint runner
# Runs the project's lint-fix command after Write/Edit tool calls to catch
# formatting issues immediately rather than at commit time.

# Read stdin (hook input JSON)
INPUT=$(cat)

# Extract tool name
TOOL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null)

# Only run after Write or Edit
if [[ "$TOOL" != "Write" && "$TOOL" != "Edit" ]]; then
  exit 0
fi

# Only if .cortex/profile.json exists
PROFILE_PATH="$(pwd)/.cortex/profile.json"
if [ ! -f "$PROFILE_PATH" ]; then
  exit 0
fi

# Get lint-fix command from profile
LINT_FIX=$(python3 -c "
import json
try:
    d = json.load(open('$PROFILE_PATH'))
    cmd = d.get('ci', {}).get('commands', {}).get('lint_fix', '')
    print(cmd or '')
except:
    print('')
" 2>/dev/null)

if [ -z "$LINT_FIX" ]; then
  exit 0
fi

# Get the file that was written/edited
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
# Try tool_input.file_path (Write) or tool_input.file_path (Edit)
inp = d.get('tool_input', {})
print(inp.get('file_path', ''))
" 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only lint source files (skip config, json, markdown, etc.)
EXT="${FILE_PATH##*.}"
SOURCE_EXTS="ts tsx js jsx mjs cjs py rb go rs java kt swift"
IS_SOURCE=false
for ext in $SOURCE_EXTS; do
  if [ "$EXT" = "$ext" ]; then
    IS_SOURCE=true
    break
  fi
done

if [ "$IS_SOURCE" = false ]; then
  exit 0
fi

# Run lint-fix silently — don't block if it fails
eval "$LINT_FIX" > /dev/null 2>&1 || true

exit 0
