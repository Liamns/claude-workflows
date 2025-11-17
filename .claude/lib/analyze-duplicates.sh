#!/bin/bash
# analyze-duplicates.sh
# Analyzes bash scripts to find duplicate function definitions
# Compatible with bash 3.2+

set -e

# Usage: analyze-duplicates.sh [directory]
# Default directory: .claude/lib

SCAN_DIR="${1:-.claude/lib}"

if [ ! -d "$SCAN_DIR" ]; then
  echo "Error: Directory not found: $SCAN_DIR" >&2
  exit 1
fi

# Temporary files
TEMP_FUNCS="/tmp/claude-funcs-$$.txt"
TEMP_DUPES="/tmp/claude-dupes-$$.txt"
trap "rm -f $TEMP_FUNCS $TEMP_DUPES" EXIT

# Step 1: Extract all function definitions from .sh files
find "$SCAN_DIR" -name "*.sh" -type f | while read -r script_file; do
  # Skip test files
  if [[ "$script_file" == *"/__tests__/"* ]]; then
    continue
  fi

  # Extract function names (both "function name()" and "name()" formats)
  # Pattern 1: function function_name() or function function_name {
  grep -E '^[[:space:]]*function[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*' "$script_file" 2>/dev/null | \
    sed -E 's/^[[:space:]]*function[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*).*/\1/' | \
    while read -r func_name; do
      echo "$func_name|$script_file"
    done

  # Pattern 2: function_name() {
  grep -E '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*\(\)' "$script_file" 2>/dev/null | \
    sed -E 's/^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)\(\).*/\1/' | \
    while read -r func_name; do
      # Skip common shell keywords
      case "$func_name" in
        if|then|else|elif|fi|for|while|do|done|case|esac|function) continue ;;
      esac
      echo "$func_name|$script_file"
    done
done | sort > "$TEMP_FUNCS"

# Step 2: Find duplicates (function names that appear more than once)
cut -d'|' -f1 "$TEMP_FUNCS" | sort | uniq -c | awk '$1 > 1 {print $2}' > "$TEMP_DUPES"

# Step 3: Output JSON
echo "["

first=true
while read -r func_name; do
  # Get count and files for this function
  count=$(grep "^${func_name}|" "$TEMP_FUNCS" | wc -l | tr -d ' ')
  files=$(grep "^${func_name}|" "$TEMP_FUNCS" | cut -d'|' -f2)

  # Add comma if not first element
  if [ "$first" = false ]; then
    echo ","
  fi
  first=false

  # Convert files to JSON array
  files_json=$(echo "$files" | jq -R -s 'split("\n") | map(select(length > 0))')

  jq -n \
    --arg name "$func_name" \
    --arg count "$count" \
    --argjson files "$files_json" \
    '{
      functionName: $name,
      count: ($count | tonumber),
      files: $files
    }' | sed 's/^/  /'
done < "$TEMP_DUPES"

echo ""
echo "]"

exit 0
