#!/bin/bash
# Plan Mode Context Extraction Helper
# Searches conversation history for plan content using keyword matching

set -e

# Configuration
MIN_MESSAGE_LENGTH=200
PLAN_KEYWORDS=("계획" "plan" "phase" "단계" "step")

# Check if text contains plan keywords (case-insensitive)
contains_plan_keyword() {
  local text="$1"

  for keyword in "${PLAN_KEYWORDS[@]}"; do
    if echo "$text" | grep -qi "$keyword"; then
      return 0
    fi
  done

  return 1
}

# Check if message is long enough to be a plan
is_long_enough() {
  local text="$1"

  if [ ${#text} -gt $MIN_MESSAGE_LENGTH ]; then
    return 0
  else
    return 1
  fi
}

# Extract plan from conversation context
# Usage: extract_plan_from_context "conversation text"
# Returns: "true" if plan found, "false" otherwise
# Stdout: The plan content if found
extract_plan_from_context() {
  local text="$1"
  local has_keyword=false
  local is_long=false

  # Check keyword
  if contains_plan_keyword "$text"; then
    has_keyword=true
  fi

  # Check length
  if is_long_enough "$text"; then
    is_long=true
  fi

  # Return result
  if [ "$has_keyword" = true ] && [ "$is_long" = true ]; then
    echo "$text"
    return 0
  else
    return 1
  fi
}

# Main function for CLI usage
# Reads from stdin or file argument
main() {
  local input=""

  # Read from stdin or file
  if [ -p /dev/stdin ]; then
    # Data piped to stdin
    input=$(cat)
  elif [ $# -gt 0 ]; then
    # File path provided as argument
    if [ -f "$1" ]; then
      input=$(cat "$1")
    else
      echo "Error: File not found: $1" >&2
      exit 1
    fi
  else
    echo "Usage: extract-context.sh [file] or pipe content via stdin" >&2
    echo "Example: echo 'plan content' | extract-context.sh" >&2
    echo "Example: extract-context.sh /path/to/conversation.txt" >&2
    exit 1
  fi

  # Extract plan
  if plan_content=$(extract_plan_from_context "$input"); then
    echo "✅ Plan detected in context"
    echo ""
    echo "--- Plan Content ---"
    echo "$plan_content"
    echo "--- End Plan ---"
    exit 0
  else
    echo "❌ No plan detected in context" >&2
    echo "Hint: Plan must contain keywords (계획/plan/phase/단계/step) and be >$MIN_MESSAGE_LENGTH chars" >&2
    exit 1
  fi
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
