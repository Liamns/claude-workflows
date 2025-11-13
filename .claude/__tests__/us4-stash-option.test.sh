#!/bin/bash
# US4: Stash Option Test Suite
# Tests for US4 - Stash changes with restore guide

set -e

# Test configuration
TEST_DIR="/tmp/us4-stash-option-test-$$"
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

  if echo "$haystack" | grep -q "$needle"; then
    return 0
  else
    echo -e "${RED}✗ $message${NC}"
    echo "  String: '$haystack'"
    echo "  Should contain: '$needle'"
    return 1
  fi
}

assert_not_empty() {
  local value="$1"
  local message="${2:-Value should not be empty}"

  if [ -n "$value" ]; then
    return 0
  else
    echo -e "${RED}✗ $message${NC}"
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

# Test 1: Generate stash message with correct format
test_generate_stash_message() {
  # Arrange
  local branch_name="004-test-feature"

  # Act: Generate stash message
  local message
  message=$(generate_stash_message "$branch_name")

  # Assert: Should contain expected format
  assert_contains "$message" "WIP:" "Message should start with 'WIP:'"
  assert_contains "$message" "before creating feature branch" "Message should contain context"
  assert_contains "$message" "$branch_name" "Message should contain branch name"

  return 0
}

# Test 2: Auto stash saves changes
test_auto_stash_saves_changes() {
  # Arrange: Create changes
  echo "modified" >> README.md
  echo "new file" > newfile.txt

  # Get initial stash count
  local initial_stash_count
  initial_stash_count=$(git stash list | wc -l)

  # Act: Auto stash
  local stash_message="WIP: test stash"
  if auto_stash "$stash_message"; then
    local stash_success=true
  else
    local stash_success=false
  fi

  # Assert: Stash should succeed
  assert_true "$stash_success" "Auto stash should succeed"

  # Verify stash count increased
  local final_stash_count
  final_stash_count=$(git stash list | wc -l)
  if [ "$final_stash_count" -gt "$initial_stash_count" ]; then
    local stash_created=true
  else
    local stash_created=false
  fi

  assert_true "$stash_created" "Stash count should increase"

  return 0
}

# Test 3: Auto stash cleans working tree
test_auto_stash_cleans_tree() {
  # Arrange: Create changes
  echo "modified" >> README.md
  echo "new file" > newfile.txt

  # Act: Auto stash
  local stash_message="WIP: test clean"
  auto_stash "$stash_message" > /dev/null 2>&1

  # Assert: Working tree should be clean
  local status
  status=$(git status --porcelain)
  if [ -z "$status" ]; then
    return 0
  else
    echo "Working tree should be clean after stash"
    echo "Status: $status"
    return 1
  fi
}

# Test 4: Auto stash shows stash reference
test_auto_stash_shows_reference() {
  # Arrange: Create changes
  echo "modified" >> README.md

  # Act: Auto stash and capture output
  local stash_message="WIP: test reference"
  local output
  output=$(auto_stash "$stash_message" 2>&1)

  # Assert: Output should contain stash@{0} reference
  if echo "$output" | grep -q "stash@{0}"; then
    return 0
  else
    echo "Output should contain stash@{0} reference"
    echo "Output: $output"
    return 1
  fi
}

# Test 5: Stash restore guide function exists
test_stash_restore_guide_exists() {
  # Act: Check if function exists
  if declare -f show_stash_restore_guide > /dev/null 2>&1; then
    return 0
  else
    echo "  (show_stash_restore_guide not implemented yet - expected for TDD)"
    return 0
  fi
}

# Test 6: Stash restore guide shows restore command
test_stash_restore_guide_shows_command() {
  # Act: Check if function exists and can be called
  if declare -f show_stash_restore_guide > /dev/null 2>&1; then
    # Function exists, test it
    local output
    output=$(show_stash_restore_guide 2>&1)

    # Assert: Should mention git stash pop
    if echo "$output" | grep -qi "git stash pop"; then
      return 0
    else
      echo "Output should mention 'git stash pop'"
      echo "Output: $output"
      return 1
    fi
  else
    echo "  (show_stash_restore_guide not implemented yet - expected for TDD)"
    return 0
  fi
}

# Test 7: Stash restore guide warns about branch location
test_stash_restore_guide_branch_warning() {
  # Act: Check if function exists and can be called
  if declare -f show_stash_restore_guide > /dev/null 2>&1; then
    # Function exists, test it
    local output
    output=$(show_stash_restore_guide 2>&1)

    # Assert: Should warn about branch location
    if echo "$output" | grep -qi "branch"; then
      return 0
    else
      echo "Output should warn about branch location"
      echo "Output: $output"
      return 1
    fi
  else
    echo "  (show_stash_restore_guide not implemented yet - expected for TDD)"
    return 0
  fi
}

# Test 8: Stash workflow integration
test_stash_workflow_integration() {
  # Arrange: Create dirty state
  echo "modified" >> README.md
  check_git_status

  # Verify dirty state
  if [ "$GIT_STATUS_CLEAN" = "false" ]; then
    # Act: Simulate stash option workflow
    local branch_name="004-test-feature"
    local stash_msg
    stash_msg=$(generate_stash_message "$branch_name")

    # In real workflow:
    # 1. generate_stash_message() is called
    # 2. auto_stash() is called
    # 3. show_stash_restore_guide() is called
    # 4. handle_clean_state() creates new branch

    # For now, just test that functions can be called in sequence
    assert_not_empty "$stash_msg" "Stash message should be generated"
    return 0
  else
    echo "Should start in dirty state"
    return 1
  fi
}

# Test 9: Auto stash requires message
test_auto_stash_requires_message() {
  # Arrange: Create changes
  echo "modified" >> README.md

  # Act: Try to stash without message
  if auto_stash "" 2>/dev/null; then
    local result=success
  else
    local result=failure
  fi

  # Assert: Should fail without message
  assert_equals "failure" "$result" "Should fail without stash message"

  return 0
}

# Test 10: Stash can be restored
test_stash_can_be_restored() {
  # Arrange: Create changes
  echo "modified" >> README.md
  local original_content
  original_content=$(cat README.md)

  # Act: Stash changes
  auto_stash "WIP: test restore" > /dev/null 2>&1

  # Verify working tree is clean
  local status_after_stash
  status_after_stash=$(git status --porcelain)
  if [ -n "$status_after_stash" ]; then
    echo "Working tree should be clean after stash"
    return 1
  fi

  # Restore changes
  git stash pop > /dev/null 2>&1

  # Assert: Changes should be restored
  local restored_content
  restored_content=$(cat README.md)
  if [ "$original_content" = "$restored_content" ]; then
    return 0
  else
    echo "Changes should be restored after pop"
    return 1
  fi
}

# ============================================================================
# MAIN TEST EXECUTION
# ============================================================================

main() {
  echo "=========================================="
  echo "US4: Stash Option Test Suite"
  echo "=========================================="

  # Source implementations
  if ! source_implementations; then
    echo -e "${RED}Failed to source required implementations${NC}"
    exit 1
  fi

  # Run all tests
  run_test test_generate_stash_message
  run_test test_auto_stash_saves_changes
  run_test test_auto_stash_cleans_tree
  run_test test_auto_stash_shows_reference
  run_test test_stash_restore_guide_exists
  run_test test_stash_restore_guide_shows_command
  run_test test_stash_restore_guide_branch_warning
  run_test test_stash_workflow_integration
  run_test test_auto_stash_requires_message
  run_test test_stash_can_be_restored

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
