#!/bin/bash
# Command Context Manager
# Manages command execution context across sessions
# Usage: Source this file and call save_context(), load_context(), clear_context(), has_context()

# ==============================================================================
# Source Common Functions
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/git-status-checker.sh"

# ==============================================================================
# Configuration
# ==============================================================================
CONTEXT_FILE=".claude/cache/command-context.json"
CONTEXT_LOCK_FILE=".claude/cache/command-context.lock"
LOCK_TIMEOUT=5  # seconds

# ==============================================================================
# JSON Schema Definition
# ==============================================================================
# CommandContext interface:
# {
#   "command": "string",           # Command name (e.g., "major", "minor")
#   "workflow_type": "string",     # "Epic" | "Major" | "Minor" | "Micro"
#   "state": "string",             # "planning" | "approved" | "implementing" | "completed"
#   "data": {                      # Command-specific data
#     "feature_id": "string",      # e.g., "002-slash-command-ux"
#     "spec_path": "string",       # Path to spec.md
#     "plan_path": "string",       # Path to plan.md
#     "tasks_path": "string",      # Path to tasks.md
#     "current_phase": "number",   # Current phase number
#     "current_task": "string"     # Current task ID
#   },
#   "timestamp": "string",         # ISO 8601 timestamp
#   "user_inputs": {}              # User responses from AskUserQuestion
# }

# ==============================================================================
# Lock Management
# ==============================================================================

# @description: Acquire lock for context file access
# @return: 0 if lock acquired, 1 if timeout
acquire_lock() {
  local attempts=0
  local max_attempts=$((LOCK_TIMEOUT * 10))  # Check every 0.1s

  while [ $attempts -lt $max_attempts ]; do
    if mkdir "$CONTEXT_LOCK_FILE" 2>/dev/null; then
      # Lock acquired
      return 0
    fi

    # Wait and retry
    sleep 0.1
    ((attempts++))
  done

  error_msg "Failed to acquire lock after ${LOCK_TIMEOUT}s"
  return 1
}

# @description: Release lock
release_lock() {
  if [ -d "$CONTEXT_LOCK_FILE" ]; then
    rmdir "$CONTEXT_LOCK_FILE" 2>/dev/null
  fi
}

# ==============================================================================
# Core Functions
# ==============================================================================

# @description: Save command execution context
# @param: command - Command name
# @param: workflow_type - Workflow type
# @param: state - Current state
# @param: data_json - JSON string of data object
# @param: user_inputs_json - JSON string of user inputs (optional)
# @return: 0 if success, 1 if error
# @example: save_context "major" "Major" "planning" '{"feature_id":"002"}' '{}'
save_context() {
  local command="$1"
  local workflow_type="$2"
  local state="$3"
  local data_json="$4"
  local user_inputs_json="$5"

  # Set default if empty
  if [[ -z "$user_inputs_json" ]]; then
    user_inputs_json="{}"
  fi

  # Validate parameters
  if [[ -z "$command" || -z "$workflow_type" || -z "$state" || -z "$data_json" ]]; then
    error_msg "Missing required parameters for save_context"
    error_msg "Usage: save_context <command> <workflow_type> <state> <data_json> [user_inputs_json]"
    return 1
  fi

  # Validate JSON
  if ! echo "$data_json" | jq empty 2>/dev/null; then
    error_msg "Invalid JSON in data_json parameter"
    return 1
  fi

  if ! echo "$user_inputs_json" | jq empty 2>/dev/null; then
    error_msg "Invalid JSON in user_inputs_json parameter"
    return 1
  fi

  # Acquire lock
  if ! acquire_lock; then
    return 1
  fi

  # Generate timestamp
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Create context JSON
  local context_json
  context_json=$(jq -n \
    --arg cmd "$command" \
    --arg wf "$workflow_type" \
    --arg st "$state" \
    --argjson data "$data_json" \
    --argjson inputs "$user_inputs_json" \
    --arg ts "$timestamp" \
    '{
      command: $cmd,
      workflow_type: $wf,
      state: $st,
      data: $data,
      timestamp: $ts,
      user_inputs: $inputs
    }')

  # Ensure directory exists
  mkdir -p "$(dirname "$CONTEXT_FILE")"

  # Write to file
  if echo "$context_json" | jq '.' > "$CONTEXT_FILE" 2>/dev/null; then
    chmod 644 "$CONTEXT_FILE"
    release_lock
    success_msg "Context saved: $command ($state)"
    return 0
  else
    release_lock
    error_msg "Failed to write context file"
    return 1
  fi
}

# @description: Load command execution context
# @output: JSON context object to stdout
# @return: 0 if success, 1 if no context or error
load_context() {
  # Check if context file exists
  if [[ ! -f "$CONTEXT_FILE" ]]; then
    error_msg "No context file found"
    return 1
  fi

  # Acquire lock
  if ! acquire_lock; then
    return 1
  fi

  # Read and validate JSON
  local context_json
  if context_json=$(jq '.' "$CONTEXT_FILE" 2>/dev/null); then
    release_lock
    echo "$context_json"
    return 0
  else
    release_lock
    error_msg "Invalid or corrupted context file"
    return 1
  fi
}

# @description: Clear command execution context
# @return: 0 if success, 1 if error
clear_context() {
  # Acquire lock
  if ! acquire_lock; then
    return 1
  fi

  # Remove context file
  if [[ -f "$CONTEXT_FILE" ]]; then
    if rm "$CONTEXT_FILE" 2>/dev/null; then
      release_lock
      success_msg "Context cleared"
      return 0
    else
      release_lock
      error_msg "Failed to remove context file"
      return 1
    fi
  else
    release_lock
    info_msg "No context to clear"
    return 0
  fi
}

# @description: Check if context exists
# @return: 0 if context exists, 1 if not
has_context() {
  [[ -f "$CONTEXT_FILE" ]]
}

# ==============================================================================
# Utility Functions
# ==============================================================================

# @description: Get specific field from context
# @param: field - JSON path (e.g., ".command", ".data.feature_id")
# @output: Field value to stdout
# @return: 0 if success, 1 if error
get_context_field() {
  local field="$1"

  if [[ -z "$field" ]]; then
    error_msg "Field parameter required"
    return 1
  fi

  if ! has_context; then
    error_msg "No context exists"
    return 1
  fi

  local context
  context=$(load_context) || return 1

  echo "$context" | jq -r "$field"
}

# @description: Update specific field in context
# @param: field - JSON path (e.g., ".state")
# @param: value - New value
# @return: 0 if success, 1 if error
update_context_field() {
  local field="$1"
  local value="$2"

  if [[ -z "$field" || -z "$value" ]]; then
    error_msg "Field and value parameters required"
    return 1
  fi

  if ! has_context; then
    error_msg "No context exists"
    return 1
  fi

  # Acquire lock
  if ! acquire_lock; then
    return 1
  fi

  # Load current context
  local context
  context=$(jq '.' "$CONTEXT_FILE" 2>/dev/null) || {
    release_lock
    error_msg "Failed to load context"
    return 1
  }

  # Update field
  local updated_context
  updated_context=$(echo "$context" | jq "$field = \"$value\"") || {
    release_lock
    error_msg "Failed to update field"
    return 1
  }

  # Write back
  if echo "$updated_context" | jq '.' > "$CONTEXT_FILE" 2>/dev/null; then
    release_lock
    success_msg "Context updated: $field = $value"
    return 0
  else
    release_lock
    error_msg "Failed to write updated context"
    return 1
  fi
}

# @description: Display context in human-readable format
show_context() {
  if ! has_context; then
    info_msg "No active context"
    return 1
  fi

  local context
  context=$(load_context) || return 1

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Command Context"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "$context" | jq -r '
    "Command:       \(.command)",
    "Workflow:      \(.workflow_type)",
    "State:         \(.state)",
    "Timestamp:     \(.timestamp)",
    "",
    "Data:",
    (.data | to_entries[] | "  \(.key): \(.value)"),
    "",
    "User Inputs:",
    (if (.user_inputs | length) > 0 then
      (.user_inputs | to_entries[] | "  \(.key): \(.value)")
    else
      "  (none)"
    end)
  '
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ==============================================================================
# Self-Test
# ==============================================================================

# @description: Run self-tests for all functions
# @return: 0 if all tests pass, 1 if any test fails
run_self_tests() {
  local tests_passed=0
  local tests_failed=0

  info_msg "Running Command Context Manager self-tests..."
  echo ""

  # Cleanup before tests
  rm -f .claude/cache/command-context.json 2>/dev/null
  rmdir .claude/cache/command-context.lock 2>/dev/null

  # Test 1: save_context
  echo "Test 1: save_context"
  local test_data='{"feature_id":"test-001"}'
  local test_inputs='{"complexity":"8"}'
  if save_context "major" "Major" "planning" "$test_data" "$test_inputs" >/dev/null 2>&1; then
    if [[ -f "$CONTEXT_FILE" ]]; then
      success_msg "✓ save_context OK"
      ((tests_passed++))
    else
      error_msg "✗ save_context failed (file not created)"
      ((tests_failed++))
    fi
  else
    error_msg "✗ save_context failed"
    ((tests_failed++))
  fi
  echo ""

  # Test 2: load_context
  echo "Test 2: load_context"
  local loaded_context
  if loaded_context=$(load_context 2>/dev/null); then
    local cmd
    cmd=$(echo "$loaded_context" | jq -r '.command')
    if [[ "$cmd" == "major" ]]; then
      success_msg "✓ load_context OK"
      ((tests_passed++))
    else
      error_msg "✗ load_context failed (wrong data)"
      ((tests_failed++))
    fi
  else
    error_msg "✗ load_context failed"
    ((tests_failed++))
  fi
  echo ""

  # Test 3: has_context
  echo "Test 3: has_context"
  if has_context; then
    success_msg "✓ has_context OK"
    ((tests_passed++))
  else
    error_msg "✗ has_context failed"
    ((tests_failed++))
  fi
  echo ""

  # Test 4: get_context_field
  echo "Test 4: get_context_field"
  local feature_id
  if feature_id=$(get_context_field ".data.feature_id" 2>/dev/null); then
    if [[ "$feature_id" == "test-001" ]]; then
      success_msg "✓ get_context_field OK"
      ((tests_passed++))
    else
      error_msg "✗ get_context_field failed (wrong value: $feature_id)"
      ((tests_failed++))
    fi
  else
    error_msg "✗ get_context_field failed"
    ((tests_failed++))
  fi
  echo ""

  # Test 5: clear_context
  echo "Test 5: clear_context"
  if clear_context >/dev/null 2>&1; then
    if ! has_context; then
      success_msg "✓ clear_context OK"
      ((tests_passed++))
    else
      error_msg "✗ clear_context failed (file still exists)"
      ((tests_failed++))
    fi
  else
    error_msg "✗ clear_context failed"
    ((tests_failed++))
  fi
  echo ""

  # Summary
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test Results: $tests_passed passed, $tests_failed failed"

  if [[ $tests_failed -eq 0 ]]; then
    success_msg "All tests passed! ✓"
    return 0
  else
    error_msg "Some tests failed! ✗"
    return 1
  fi
}

# ==============================================================================
# Main (for testing)
# ==============================================================================

# If script is executed directly (not sourced), run self-tests
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_self_tests
  exit $?
fi
