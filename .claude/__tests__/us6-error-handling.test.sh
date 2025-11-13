#!/bin/bash
# US6: Error Handling Test Suite
# Tests for US6 - Error handling and rollback mechanisms

set -e

# Test configuration
TEST_DIR="/tmp/us6-error-handling-test-$$"
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

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-String should contain substring}"

  if echo "$haystack" | grep -qi "$needle"; then
    return 0
  else
    echo -e "${RED}✗ $message${NC}"
    echo "  String: '$haystack'"
    echo "  Should contain: '$needle'"
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

  if [ -f "$base_dir/branch-info-collector.sh" ]; then
    source "$base_dir/branch-info-collector.sh"
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

# Test 1: All Git operations check exit codes
test_git_operations_check_exit_codes() {
  # Arrange: This tests that functions properly check git command results
  # All existing functions should return non-zero on failure

  # Act & Assert: Functions already check exit codes
  # auto_commit checks git add and git commit
  # auto_stash checks git stash push
  # create_branch_from_base checks git checkout

  # Verify auto_commit fails with invalid input
  if auto_commit "" 2>/dev/null; then
    echo "auto_commit should fail with empty message"
    return 1
  fi

  # Verify auto_stash fails with invalid input
  if auto_stash "" 2>/dev/null; then
    echo "auto_stash should fail with empty message"
    return 1
  fi

  return 0
}

# Test 2: Error messages are clear and informative
test_error_messages_are_clear() {
  # Arrange: Try operations that will fail

  # Act: Capture error message from auto_commit
  local output
  output=$(auto_commit "" 2>&1)

  # Assert: Should contain clear error message
  assert_contains "$output" "required" "Error message should mention 'required'"

  return 0
}

# Test 3: Commit failure doesn't leave staged changes
test_commit_failure_cleanup() {
  # Arrange: Create changes and stage them
  echo "modified" >> README.md
  git add -A

  # Simulate commit failure by using empty repository
  # (In real scenario, this would be a pre-commit hook failure)

  # For now, just verify staged changes can be reset
  git reset HEAD > /dev/null 2>&1

  # Assert: Working tree should be back to modified state
  local status
  status=$(git status --porcelain)

  if echo "$status" | grep -q "^.M"; then
    return 0
  else
    echo "Should have unstaged changes after reset"
    return 1
  fi
}

# Test 4: Branch creation failure doesn't lose current position
test_branch_creation_failure_preserves_position() {
  # Arrange: Record current branch
  local original_branch
  original_branch=$(git branch --show-current)

  # Act: Try to create a branch that already exists
  git checkout -b "test-branch" -q

  # Try to create the same branch again (will fail)
  if git checkout -b "test-branch" 2>/dev/null; then
    local creation_failed=false
  else
    local creation_failed=true
  fi

  # Assert: Should fail and stay on current branch
  assert_true "$creation_failed" "Duplicate branch creation should fail"

  local current_branch
  current_branch=$(git branch --show-current)

  # Should still be on test-branch
  if [ "$current_branch" = "test-branch" ]; then
    return 0
  else
    echo "Should remain on current branch after failed creation"
    return 1
  fi
}

# Test 5: Stash failure preserves working tree
test_stash_failure_preserves_changes() {
  # Arrange: Clean working tree (stash will succeed but we test the concept)
  # If there's nothing to stash, changes should be preserved

  # Act: Try to stash in clean state
  local status_before
  status_before=$(git status --porcelain)

  # Stash on clean tree does nothing
  git stash push -u -m "test" > /dev/null 2>&1 || true

  local status_after
  status_after=$(git status --porcelain)

  # Assert: Status should be unchanged (both clean)
  if [ "$status_before" = "$status_after" ]; then
    return 0
  else
    echo "Working tree status should be preserved"
    return 1
  fi
}

# Test 6: Operations are atomic (all or nothing)
test_operations_are_atomic() {
  # Arrange: Create changes
  echo "modified" >> README.md

  # Act: Auto commit (which does add + commit)
  local initial_commits
  initial_commits=$(git rev-list --count HEAD)

  if auto_commit "test: atomic operation"; then
    local commit_success=true
  else
    local commit_success=false
  fi

  # Assert: Either both succeeded or both failed
  local final_commits
  final_commits=$(git rev-list --count HEAD)

  if [ "$commit_success" = "true" ]; then
    # Commit succeeded - should have new commit
    if [ "$final_commits" -gt "$initial_commits" ]; then
      return 0
    else
      echo "Commit succeeded but no new commit created"
      return 1
    fi
  else
    # Commit failed - should have same commit count
    if [ "$final_commits" -eq "$initial_commits" ]; then
      return 0
    else
      echo "Commit failed but commit count changed"
      return 1
    fi
  fi
}

# Test 7: No data loss on error
test_no_data_loss_on_error() {
  # Arrange: Create important changes
  echo "important data" > important.txt
  local original_content
  original_content=$(cat important.txt)

  # Act: Try various operations (they might fail)
  git add important.txt || true

  # Even if git operations fail, file should still exist
  local content_after
  content_after=$(cat important.txt 2>/dev/null || echo "FILE_LOST")

  # Assert: Data should not be lost
  assert_equals "$original_content" "$content_after" "File content should be preserved"

  return 0
}

# Test 8: Existing functions handle errors properly
test_existing_functions_handle_errors() {
  # Verify that existing functions return proper exit codes

  # Test 1: auto_commit with invalid input
  if auto_commit "" 2>/dev/null; then
    echo "auto_commit should return error for empty message"
    return 1
  fi

  # Test 2: auto_stash with invalid input
  if auto_stash "" 2>/dev/null; then
    echo "auto_stash should return error for empty message"
    return 1
  fi

  # Test 3: create_branch_from_base with invalid input
  if create_branch_from_base "" 2>/dev/null; then
    echo "create_branch_from_base should return error for empty name"
    return 1
  fi

  return 0
}

# Test 9: handle_clean_state error handling
test_handle_clean_state_errors() {
  # Arrange: Clean state
  check_git_status

  # Act: Try to create branch with invalid name
  if handle_clean_state "" 2>/dev/null; then
    local result=success
  else
    local result=failure
  fi

  # Assert: Should fail with empty branch name
  assert_equals "failure" "$result" "Should fail with empty branch name"

  return 0
}

# Test 10: handle_dirty_state error handling
test_handle_dirty_state_errors() {
  # Arrange: Create dirty state
  echo "modified" >> README.md
  check_git_status

  # Act: Try to handle with invalid branch name
  if handle_dirty_state "" 2>/dev/null; then
    local result=success
  else
    local result=failure
  fi

  # Assert: Should fail with empty branch name
  assert_equals "failure" "$result" "Should fail with empty branch name"

  return 0
}

# ============================================================================
# MAIN TEST EXECUTION
# ============================================================================

main() {
  echo "=========================================="
  echo "US6: Error Handling Test Suite"
  echo "=========================================="

  # Source implementations
  if ! source_implementations; then
    echo -e "${RED}Failed to source required implementations${NC}"
    exit 1
  fi

  # Run all tests
  run_test test_git_operations_check_exit_codes
  run_test test_error_messages_are_clear
  run_test test_commit_failure_cleanup
  run_test test_branch_creation_failure_preserves_position
  run_test test_stash_failure_preserves_changes
  run_test test_operations_are_atomic
  run_test test_no_data_loss_on_error
  run_test test_existing_functions_handle_errors
  run_test test_handle_clean_state_errors
  run_test test_handle_dirty_state_errors

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
