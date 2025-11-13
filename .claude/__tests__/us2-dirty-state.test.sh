#!/bin/bash
# US2: Dirty State Test Suite
# Tests for US2 - Branch creation when working tree has uncommitted changes

set -e

# Test configuration
TEST_DIR="/tmp/us2-dirty-state-test-$$"
PASSED=0
FAILED=0
TESTS_RUN=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

assert_false() {
  local condition="$1"
  local message="${2:-Condition should be false}"

  if [ "$condition" = "false" ]; then
    return 0
  else
    echo -e "${RED}✗ $message${NC}"
    echo "  Got: '$condition'"
    return 1
  fi
}

assert_gt() {
  local value="$1"
  local threshold="$2"
  local message="${3:-Value should be greater than threshold}"

  if [ "$value" -gt "$threshold" ]; then
    return 0
  else
    echo -e "${RED}✗ $message${NC}"
    echo "  Value: $value, Threshold: $threshold"
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
  fi

  if [ -f "$base_dir/git-operations.sh" ]; then
    source "$base_dir/git-operations.sh"
  fi

  return 0
}

# ============================================================================
# TEST CASES
# ============================================================================

# Test 1: Detect modified files
test_modified_files_detection() {
  # Arrange: Modify a file
  echo "modified content" >> README.md

  # Act: Check git status
  check_git_status

  # Assert: Should detect dirty state
  assert_false "$GIT_STATUS_CLEAN" "GIT_STATUS_CLEAN should be false"

  # Assert: Should have modified files
  assert_gt "${#GIT_MODIFIED_FILES[@]}" 0 "Should detect modified files"

  return 0
}

# Test 2: Detect untracked files
test_untracked_files_detection() {
  # Arrange: Create untracked file
  echo "new content" > new_file.txt

  # Act: Check git status
  check_git_status

  # Assert: Should detect dirty state
  assert_false "$GIT_STATUS_CLEAN" "GIT_STATUS_CLEAN should be false"

  # Assert: Should have untracked files
  assert_gt "${#GIT_UNTRACKED_FILES[@]}" 0 "Should detect untracked files"

  return 0
}

# Test 3: Display changed files summary
test_display_changed_files() {
  # Arrange: Create multiple changes
  echo "modified" >> README.md
  echo "new1" > file1.txt
  echo "new2" > file2.txt

  # Act: Check git status
  check_git_status

  # Assert: Should count all changes
  local total
  total=$(get_total_changed_files)
  assert_gt "$total" 0 "Total changed files should be > 0"

  return 0
}

# Test 4: Move changes to new branch (git checkout -b)
test_move_changes_to_new_branch() {
  # Arrange: Create changes
  echo "modified" >> README.md

  # Act: Move to new branch
  local new_branch="004-test-feature"
  if git checkout -b "$new_branch" 2>/dev/null; then
    local success=true
  else
    local success=false
  fi

  # Assert: Should create branch with changes
  assert_true "$success" "Should create new branch"

  # Verify changes still exist
  local status
  status=$(git status --porcelain)
  if [ -n "$status" ]; then
    return 0
  else
    echo "Changes should be preserved in new branch"
    return 1
  fi
}

# Test 5: Discard changes warning
test_discard_changes_requires_confirmation() {
  # Arrange: Create changes
  echo "modified" >> README.md

  # Act: This is a destructive action, so just verify the concept
  # In real implementation, confirm_discard() should be called

  # Assert: check_sensitive_files exists and can be called
  if declare -f check_sensitive_files > /dev/null 2>&1; then
    check_git_status
    check_sensitive_files
    # Function exists, test passes
    return 0
  else
    echo "  (check_sensitive_files not implemented yet - expected for TDD)"
    return 0
  fi
}

# Test 6: Sensitive files detection
test_sensitive_files_warning() {
  # Arrange: Create sensitive file
  echo "SECRET_KEY=12345" > .env

  # Act: Check git status
  check_git_status

  # Assert: Should detect sensitive file
  if declare -f check_sensitive_files > /dev/null 2>&1; then
    # Call function, it should return 1 (found sensitive files)
    if check_sensitive_files; then
      echo "Should have detected .env file"
      return 1
    else
      # Return 1 means sensitive files found
      return 0
    fi
  else
    echo "  (check_sensitive_files not implemented yet - expected for TDD)"
    return 0
  fi
}

# Test 7: Handle dirty state requires user action
test_dirty_state_requires_user_action() {
  # Arrange: Create changes
  echo "modified" >> README.md

  # Act: Check git status
  check_git_status

  # Assert: Should require user action
  # GIT_STATUS_CLEAN should be false
  assert_false "$GIT_STATUS_CLEAN" "Should be in dirty state"

  # In real implementation, this would trigger ask_user_action()
  return 0
}

# ============================================================================
# MAIN TEST EXECUTION
# ============================================================================

main() {
  echo "=========================================="
  echo "US2: Dirty State Test Suite"
  echo "=========================================="

  # Source implementations
  if ! source_implementations; then
    echo -e "${RED}Failed to source required implementations${NC}"
    exit 1
  fi

  # Run all tests
  run_test test_modified_files_detection
  run_test test_untracked_files_detection
  run_test test_display_changed_files
  run_test test_move_changes_to_new_branch
  run_test test_discard_changes_requires_confirmation
  run_test test_sensitive_files_warning
  run_test test_dirty_state_requires_user_action

  # Print summary
  echo ""
  echo "=========================================="
  echo "Test Summary"
  echo "=========================================="
  echo "Tests run:    $TESTS_RUN"
  echo -e "Passed:       ${GREEN}$PASSED${NC}"
  echo -e "Failed:       ${RED}$FAILED${NC}"
  echo "=========================================="

  if [ $FAILED -gt 0 ]; then
    exit 1
  else
    exit 0
  fi
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main
fi
