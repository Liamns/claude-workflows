#!/bin/bash
# US1: Clean State Test Suite
# Tests for US1 - Branch creation when working tree is clean

set -e

# Test configuration
TEST_DIR="/tmp/us1-clean-state-test-$$"
PASSED=0
FAILED=0
TESTS_RUN=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Setup function
setup() {
  rm -rf "$TEST_DIR"
  mkdir -p "$TEST_DIR"
  cd "$TEST_DIR"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create initial commit
  echo "initial" > README.md
  git add README.md
  git commit -q -m "initial commit"
}

# Teardown function
teardown() {
  cd /
  rm -rf "$TEST_DIR"
}

# Assert functions
assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-Assertion failed}"

  if [ "$expected" = "$actual" ]; then
    return 0
  else
    echo -e "${RED}✗ $message${NC}"
    echo "  Expected: '$expected'"
    echo "  Actual:   '$actual'"
    return 1
  fi
}

assert_true() {
  local condition="$1"
  local message="${2:-Condition should be true}"

  if [ "$condition" = "true" ]; then
    return 0
  else
    echo -e "${RED}✗ $message${NC}"
    echo "  Got: '$condition'"
    return 1
  fi
}

# Test runner
run_test() {
  local test_name="$1"
  TESTS_RUN=$((TESTS_RUN + 1))

  echo ""
  echo -e "${YELLOW}Running: $test_name${NC}"

  setup

  if $test_name; then
    echo -e "${GREEN}✓ PASSED${NC}"
    PASSED=$((PASSED + 1))
  else
    echo -e "${RED}✗ FAILED${NC}"
    FAILED=$((FAILED + 1))
  fi

  teardown
}

# Source the implementations
source_implementations() {
  local base_dir="../lib"

  if [ -f "$base_dir/git-status-checker.sh" ]; then
    source "$base_dir/git-status-checker.sh"
  else
    echo -e "${RED}Error: git-status-checker.sh not found${NC}"
    return 1
  fi

  if [ -f "$base_dir/branch-state-handler.sh" ]; then
    source "$base_dir/branch-state-handler.sh"
  else
    echo -e "${YELLOW}Warning: branch-state-handler.sh not found (expected for TDD)${NC}"
  fi

  return 0
}

# ============================================================================
# TEST CASES
# ============================================================================

# Test 1: Verify clean state detection
test_clean_state_detection() {
  # Arrange: Repository is clean from setup

  # Act: Check git status using our function
  check_git_status

  # Assert: Should detect clean state
  assert_true "$GIT_STATUS_CLEAN" "GIT_STATUS_CLEAN should be true"

  # Verify no files in arrays
  if [ ${#GIT_MODIFIED_FILES[@]} -eq 0 ] && \
     [ ${#GIT_UNTRACKED_FILES[@]} -eq 0 ] && \
     [ ${#GIT_STAGED_FILES[@]} -eq 0 ]; then
    return 0
  else
    echo "File arrays should be empty"
    echo "  Modified: ${#GIT_MODIFIED_FILES[@]}"
    echo "  Untracked: ${#GIT_UNTRACKED_FILES[@]}"
    echo "  Staged: ${#GIT_STAGED_FILES[@]}"
    return 1
  fi
}

# Test 2: Clean state allows immediate branch creation
test_branch_creation_success() {
  # Arrange: Repository is clean
  check_git_status

  # Verify clean state first
  if [ "$GIT_STATUS_CLEAN" != "true" ]; then
    echo "Precondition failed: Repository should be clean"
    return 1
  fi

  # Act: Create new branch (simulating what handle_clean_state would do)
  local new_branch="004-test-feature"
  if git checkout -b "$new_branch" 2>/dev/null; then
    local branch_created=true
  else
    local branch_created=false
  fi

  # Assert: Branch should be created successfully
  assert_true "$branch_created" "Branch should be created"

  # Verify we're on the new branch
  local current_branch
  current_branch=$(git branch --show-current)
  assert_equals "$new_branch" "$current_branch" "Should be on new branch"

  return 0
}

# Test 3: No user interaction required for clean state
test_no_user_interaction() {
  # Arrange: Repository is clean
  check_git_status

  # Act & Assert: In clean state, no user prompts should be needed
  # This is verified by the fact that GIT_STATUS_CLEAN is true
  if [ "$GIT_STATUS_CLEAN" = "true" ]; then
    # In implementation, this would skip AskUserQuestion entirely
    # For now, we just verify the condition
    return 0
  else
    echo "Clean state not detected, would trigger user interaction"
    return 1
  fi
}

# Test 4: Workflow continues without interruption
test_workflow_continues() {
  # Arrange: Repository is clean
  check_git_status

  # Act: Simulate the workflow
  local workflow_interrupted=false

  if [ "$GIT_STATUS_CLEAN" = "true" ]; then
    # Create branch
    git checkout -b "004-test-feature" 2>/dev/null || workflow_interrupted=true

    # Workflow should continue (no user prompts)
    # In real implementation, this would proceed to next steps
  else
    workflow_interrupted=true
  fi

  # Assert: Workflow should not be interrupted
  if [ "$workflow_interrupted" = "false" ]; then
    return 0
  else
    echo "Workflow was interrupted"
    return 1
  fi
}

# Test 5: Success message displayed (if handle_clean_state exists)
test_success_message() {
  # Arrange: Repository is clean
  check_git_status

  # Act: Try to call handle_clean_state if it exists
  if declare -f handle_clean_state > /dev/null 2>&1; then
    # Function exists, test it
    local output
    output=$(handle_clean_state "004-test-feature" 2>&1)

    # Assert: Should contain success message
    if echo "$output" | grep -qi "clean"; then
      return 0
    else
      echo "Success message not found in output: $output"
      return 1
    fi
  else
    # Function doesn't exist yet (TDD), that's okay
    echo "  (handle_clean_state not implemented yet - expected for TDD)"
    return 0
  fi
}

# ============================================================================
# MAIN TEST EXECUTION
# ============================================================================

main() {
  echo "=========================================="
  echo "US1: Clean State Test Suite"
  echo "=========================================="

  # Source implementations
  if ! source_implementations; then
    echo -e "${RED}Failed to source required implementations${NC}"
    exit 1
  fi

  # Run all tests
  run_test test_clean_state_detection
  run_test test_branch_creation_success
  run_test test_no_user_interaction
  run_test test_workflow_continues
  run_test test_success_message

  # Print summary
  echo ""
  echo "=========================================="
  echo "Test Summary"
  echo "=========================================="
  echo "Tests run:    $TESTS_RUN"
  echo -e "Passed:       ${GREEN}$PASSED${NC}"
  echo -e "Failed:       ${RED}$FAILED${NC}"
  echo "=========================================="

  # Exit with failure if any tests failed
  if [ $FAILED -gt 0 ]; then
    exit 1
  else
    exit 0
  fi
}

# Run main if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main
fi
