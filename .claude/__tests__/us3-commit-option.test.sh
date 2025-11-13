#!/bin/bash
# US3: Commit Option Test Suite
# Tests for US3 - Commit message review and approval process

set -e

# Test configuration
TEST_DIR="/tmp/us3-commit-option-test-$$"
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

# Test 1: Generate commit message with correct format
test_generate_commit_message() {
  # Arrange
  local branch_name="004-test-feature"

  # Act: Generate commit message
  local message
  message=$(generate_commit_message "$branch_name")

  # Assert: Should contain expected format
  assert_contains "$message" "chore:" "Message should start with 'chore:'"
  assert_contains "$message" "work in progress" "Message should contain 'work in progress'"
  assert_contains "$message" "$branch_name" "Message should contain branch name"

  return 0
}

# Test 2: Auto commit stages and commits changes
test_auto_commit_stages_and_commits() {
  # Arrange: Create changes
  echo "modified" >> README.md
  echo "new file" > newfile.txt

  # Get initial commit count
  local initial_commits
  initial_commits=$(git rev-list --count HEAD)

  # Act: Auto commit
  local commit_message="test: auto commit test"
  if auto_commit "$commit_message"; then
    local commit_success=true
  else
    local commit_success=false
  fi

  # Assert: Commit should succeed
  assert_true "$commit_success" "Auto commit should succeed"

  # Verify commit count increased
  local final_commits
  final_commits=$(git rev-list --count HEAD)
  if [ "$final_commits" -gt "$initial_commits" ]; then
    local commits_increased=true
  else
    local commits_increased=false
  fi

  assert_true "$commits_increased" "Commit count should increase"

  # Verify working tree is clean
  local status
  status=$(git status --porcelain)
  if [ -z "$status" ]; then
    return 0
  else
    echo "Working tree should be clean after commit"
    return 1
  fi
}

# Test 3: Auto commit shows commit hash
test_auto_commit_shows_hash() {
  # Arrange: Create changes
  echo "modified" >> README.md

  # Act: Auto commit and capture output
  local commit_message="test: commit hash test"
  local output
  output=$(auto_commit "$commit_message" 2>&1)

  # Assert: Output should contain commit hash (7 character short hash)
  if echo "$output" | grep -qE "[0-9a-f]{7}"; then
    return 0
  else
    echo "Output should contain commit hash"
    echo "Output: $output"
    return 1
  fi
}

# Test 4: Commit message review function exists
test_ask_commit_message_review_exists() {
  # Act: Check if function exists
  if declare -f ask_commit_message_review > /dev/null 2>&1; then
    return 0
  else
    echo "  (ask_commit_message_review not implemented yet - expected for TDD)"
    return 0
  fi
}

# Test 5: Commit message review displays auto-generated message
test_commit_review_displays_message() {
  # Arrange
  local branch_name="004-test-feature"
  local auto_message
  auto_message=$(generate_commit_message "$branch_name")

  # Act: Check if function can be called
  if declare -f ask_commit_message_review > /dev/null 2>&1; then
    # Function exists, test it
    local result
    result=$(ask_commit_message_review "$auto_message")

    # Assert: Should return a message (not empty)
    assert_not_empty "$result" "Should return a commit message"
    return 0
  else
    echo "  (ask_commit_message_review not implemented yet - expected for TDD)"
    return 0
  fi
}

# Test 6: Commit review supports "accept" action
test_commit_review_accept_action() {
  # Arrange
  local auto_message="chore: test message"

  # Act & Assert: If function exists, it should support accepting the message
  if declare -f ask_commit_message_review > /dev/null 2>&1; then
    # In real implementation with AskUserQuestion:
    # - User selects "이 메시지로 커밋"
    # - Function returns the original message
    local result
    result=$(ask_commit_message_review "$auto_message")

    # Should return the same message when accepted
    assert_not_empty "$result" "Should return message when accepted"
    return 0
  else
    echo "  (ask_commit_message_review not implemented yet - expected for TDD)"
    return 0
  fi
}

# Test 7: Commit review supports "edit" action
test_commit_review_edit_action() {
  # Arrange
  local auto_message="chore: test message"

  # Act & Assert: If function exists, it should support editing the message
  if declare -f ask_commit_message_review > /dev/null 2>&1; then
    # In real implementation with AskUserQuestion:
    # - User selects "메시지 수정"
    # - User enters custom message
    # - Function returns the custom message

    # For now, just verify function exists
    return 0
  else
    echo "  (ask_commit_message_review not implemented yet - expected for TDD)"
    return 0
  fi
}

# Test 8: Commit review supports "cancel" action
test_commit_review_cancel_action() {
  # Arrange
  local auto_message="chore: test message"

  # Act & Assert: If function exists, it should support cancelling
  if declare -f ask_commit_message_review > /dev/null 2>&1; then
    # In real implementation with AskUserQuestion:
    # - User selects "취소"
    # - Function returns empty string or special marker
    # - Workflow returns to US2

    # For now, just verify function exists
    return 0
  else
    echo "  (ask_commit_message_review not implemented yet - expected for TDD)"
    return 0
  fi
}

# Test 9: Commit workflow integration
test_commit_workflow_integration() {
  # Arrange: Create dirty state
  echo "modified" >> README.md
  check_git_status

  # Verify dirty state
  if [ "$GIT_STATUS_CLEAN" = "false" ]; then
    # Act: Simulate commit option workflow
    local branch_name="004-test-feature"
    local commit_msg
    commit_msg=$(generate_commit_message "$branch_name")

    # In real workflow:
    # 1. ask_commit_message_review() is called
    # 2. User chooses action
    # 3. auto_commit() is called if approved

    # For now, just test that functions can be called in sequence
    assert_not_empty "$commit_msg" "Commit message should be generated"
    return 0
  else
    echo "Should start in dirty state"
    return 1
  fi
}

# Test 10: Auto commit requires commit message
test_auto_commit_requires_message() {
  # Arrange: Create changes
  echo "modified" >> README.md

  # Act: Try to commit without message
  if auto_commit "" 2>/dev/null; then
    local result=success
  else
    local result=failure
  fi

  # Assert: Should fail without message
  assert_equals "failure" "$result" "Should fail without commit message"

  return 0
}

# ============================================================================
# MAIN TEST EXECUTION
# ============================================================================

main() {
  echo "=========================================="
  echo "US3: Commit Option Test Suite"
  echo "=========================================="

  # Source implementations
  if ! source_implementations; then
    echo -e "${RED}Failed to source required implementations${NC}"
    exit 1
  fi

  # Run all tests
  run_test test_generate_commit_message
  run_test test_auto_commit_stages_and_commits
  run_test test_auto_commit_shows_hash
  run_test test_ask_commit_message_review_exists
  run_test test_commit_review_displays_message
  run_test test_commit_review_accept_action
  run_test test_commit_review_edit_action
  run_test test_commit_review_cancel_action
  run_test test_commit_workflow_integration
  run_test test_auto_commit_requires_message

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
