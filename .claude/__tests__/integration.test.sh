#!/bin/bash
# Integration Test Suite
# End-to-end tests for branch state management integration

set -e

# Test configuration
TEST_DIR="/tmp/integration-test-$$"
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

  # Create initial commit on main
  echo "initial" > README.md
  git add README.md
  git commit -q -m "initial commit"
  git branch -M main 2>/dev/null || true
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
# INTEGRATION TEST CASES
# ============================================================================

# Test 1: Complete workflow - clean state
test_complete_workflow_clean() {
  # Simulate complete workflow from clean state

  # Step 1: Check git status
  check_git_status

  # Step 2: Handle branch creation
  if handle_branch_creation "001-test-feature" > /dev/null 2>&1; then
    local creation_success=true
  else
    local creation_success=false
  fi

  # Assert: Should create branch successfully
  assert_true "$creation_success" "Should create branch in clean state"

  # Verify we're on the new branch
  local current_branch
  current_branch=$(git branch --show-current)
  assert_equals "001-test-feature" "$current_branch" "Should be on new branch"

  return 0
}

# Test 2: Complete workflow - dirty state with commit
test_complete_workflow_dirty_commit() {
  # Simulate workflow with dirty state

  # Create changes
  echo "modified" >> README.md

  # Step 1: Check git status
  check_git_status

  # Verify dirty state
  assert_true "$([[ "$GIT_STATUS_CLEAN" = "false" ]] && echo true || echo false)" \
    "Should detect dirty state"

  # Step 2: Handle branch creation (will auto-commit with default action)
  if handle_branch_creation "002-test-feature" > /dev/null 2>&1; then
    local creation_success=true
  else
    local creation_success=false
  fi

  # Assert: Should create branch after handling dirty state
  assert_true "$creation_success" "Should handle dirty state and create branch"

  return 0
}

# Test 3: Parallel work scenario
test_parallel_work_scenario() {
  # Simulate parallel work: creating Feature 003 while on Feature 002

  # Setup: Create Epic and Feature 002
  git checkout -b "001-epic-test" -q
  echo "epic file" > epic.txt
  git add epic.txt
  git commit -q -m "epic commit"

  git checkout -b "002-feature-auth" -q
  echo "feature file" > auth.txt
  git add auth.txt
  git commit -q -m "feature commit"

  # Now create Feature 003 (should branch from Epic)
  check_git_status

  if handle_branch_creation "003-feature-payment" > /dev/null 2>&1; then
    local creation_success=true
  else
    local creation_success=false
  fi

  # Assert: Should create branch from Epic
  assert_true "$creation_success" "Should create branch in parallel work"

  # Verify we're on new branch
  local current_branch
  current_branch=$(git branch --show-current)
  assert_equals "003-feature-payment" "$current_branch" "Should be on new branch"

  # Verify branch is based on Epic (has epic.txt but not auth.txt)
  if [ -f "epic.txt" ] && [ ! -f "auth.txt" ]; then
    return 0
  else
    echo "Branch should be based on Epic"
    return 1
  fi
}

# Test 4: Library loading test
test_library_loading() {
  # Test that all libraries can be loaded successfully

  # All libraries should already be loaded by source_implementations
  # Just verify key functions exist

  declare -f check_git_status > /dev/null || return 1
  declare -f get_branch_info > /dev/null || return 1
  declare -f handle_branch_creation > /dev/null || return 1
  declare -f auto_commit > /dev/null || return 1
  declare -f auto_stash > /dev/null || return 1

  return 0
}

# Test 5: Error recovery test
test_error_recovery() {
  # Test that errors are handled gracefully

  # Try to create branch with empty name
  check_git_status

  if handle_branch_creation "" 2>/dev/null; then
    echo "Should fail with empty branch name"
    return 1
  fi

  # Working tree should still be in original state
  local current_branch
  current_branch=$(git branch --show-current)

  if [ "$current_branch" = "main" ]; then
    return 0
  else
    echo "Should remain on original branch after error"
    return 1
  fi
}

# Test 6: Multiple branch creation
test_multiple_branch_creation() {
  # Test creating multiple branches in sequence

  check_git_status
  handle_branch_creation "001-first" > /dev/null 2>&1

  git checkout main -q
  check_git_status
  handle_branch_creation "002-second" > /dev/null 2>&1

  git checkout main -q
  check_git_status
  handle_branch_creation "003-third" > /dev/null 2>&1

  # Verify all branches exist
  local branch_count
  branch_count=$(git branch | grep -E "00[123]-(first|second|third)" | wc -l)

  if [ "$branch_count" -eq 3 ]; then
    return 0
  else
    echo "Should have created 3 branches, found $branch_count"
    return 1
  fi
}

# Test 7: Stash workflow integration
test_stash_workflow() {
  # Create dirty state
  echo "modified" >> README.md

  check_git_status

  # Manually test stash workflow
  local stash_msg
  stash_msg=$(generate_stash_message "004-test")

  if auto_stash "$stash_msg" > /dev/null 2>&1; then
    local stash_success=true
  else
    local stash_success=false
  fi

  assert_true "$stash_success" "Should stash successfully"

  # Verify working tree is clean after stash
  check_git_status
  assert_true "$GIT_STATUS_CLEAN" "Working tree should be clean after stash"

  return 0
}

# Test 8: Complete integration scenario
test_complete_integration_scenario() {
  # Simulate a complete real-world scenario

  # 1. Start on main, create Epic
  check_git_status
  handle_branch_creation "001-epic-feature" > /dev/null 2>&1

  # 2. Add some work to Epic
  echo "epic work" > epic.txt
  git add epic.txt
  git commit -q -m "epic work"

  # 3. Create Feature 002 from Epic
  check_git_status
  handle_branch_creation "002-feature-a" > /dev/null 2>&1

  # 4. Add work to Feature 002
  echo "feature a work" > feature-a.txt
  git add feature-a.txt
  git commit -q -m "feature a work"

  # 5. While on Feature 002, create Feature 003 (parallel work)
  check_git_status
  handle_branch_creation "003-feature-b" > /dev/null 2>&1

  # Verify final state
  local current_branch
  current_branch=$(git branch --show-current)
  assert_equals "003-feature-b" "$current_branch" "Should be on Feature 003"

  # Verify Feature 003 has epic work but not feature-a work
  if [ -f "epic.txt" ] && [ ! -f "feature-a.txt" ]; then
    return 0
  else
    echo "Feature 003 should branch from Epic"
    return 1
  fi
}

# ============================================================================
# MAIN TEST EXECUTION
# ============================================================================

main() {
  echo "=========================================="
  echo "Integration Test Suite"
  echo "=========================================="

  # Source implementations
  if ! source_implementations; then
    echo -e "${RED}Failed to source required implementations${NC}"
    exit 1
  fi

  # Run all tests
  run_test test_library_loading
  run_test test_complete_workflow_clean
  run_test test_complete_workflow_dirty_commit
  run_test test_parallel_work_scenario
  run_test test_error_recovery
  run_test test_multiple_branch_creation
  run_test test_stash_workflow
  run_test test_complete_integration_scenario

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
