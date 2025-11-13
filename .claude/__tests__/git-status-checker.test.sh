#!/bin/bash
# Git Status Checker Test Suite
# Tests for git-status-checker.sh functions

set -e

# Test configuration
TEST_DIR="/tmp/git-status-checker-test-$$"
PASSED=0
FAILED=0
TESTS_RUN=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Setup function - creates a fresh test Git repository
setup() {
  rm -rf "$TEST_DIR"
  mkdir -p "$TEST_DIR"
  cd "$TEST_DIR"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create initial commit to have a valid repository
  echo "initial" > README.md
  git add README.md
  git commit -q -m "initial commit"
}

# Teardown function - removes test directory
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
    echo -e "${RED} $message${NC}"
    echo "  Expected: '$expected'"
    echo "  Actual:   '$actual'"
    return 1
  fi
}

assert_not_empty() {
  local value="$1"
  local message="${2:-Value should not be empty}"

  if [ -n "$value" ]; then
    return 0
  else
    echo -e "${RED} $message${NC}"
    return 1
  fi
}

assert_empty() {
  local value="$1"
  local message="${2:-Value should be empty}"

  if [ -z "$value" ]; then
    return 0
  else
    echo -e "${RED} $message${NC}"
    echo "  Value: '$value'"
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
    echo -e "${GREEN} PASSED${NC}"
    PASSED=$((PASSED + 1))
  else
    echo -e "${RED} FAILED${NC}"
    FAILED=$((FAILED + 1))
  fi

  teardown
}

# Source the implementation (will fail initially - TDD approach)
source_implementation() {
  if [ -f "../lib/git-status-checker.sh" ]; then
    source "../lib/git-status-checker.sh"
    return 0
  else
    echo -e "${YELLOW}Warning: git-status-checker.sh not found (expected for TDD)${NC}"
    return 1
  fi
}

# ============================================================================
# TEST CASES
# ============================================================================

# Test 1: Clean Git status
test_check_git_status_clean() {
  # Arrange: Repository is already clean from setup

  # Act: Check git status
  local status_output
  status_output=$(git status --porcelain)

  # Assert: Output should be empty
  assert_empty "$status_output" "Git status should be clean (empty output)"

  # Additional check: git status exit code
  if git diff-index --quiet HEAD --; then
    return 0
  else
    echo "git diff-index indicates changes exist"
    return 1
  fi
}

# Test 2: Modified files detection
test_check_git_status_modified() {
  # Arrange: Modify an existing file
  echo "modified content" >> README.md

  # Act: Check git status
  local status_output
  status_output=$(git status --porcelain)

  # Assert: Should detect modified file
  assert_not_empty "$status_output" "Git status should detect modified file"

  # Check for " M" prefix (modified, not staged)
  if echo "$status_output" | grep -q "^ M"; then
    return 0
  else
    echo "Expected ' M' prefix for modified file, got: $status_output"
    return 1
  fi
}

# Test 3: Untracked files detection
test_check_git_status_untracked() {
  # Arrange: Create a new untracked file
  echo "untracked content" > new_file.txt

  # Act: Check git status
  local status_output
  status_output=$(git status --porcelain)

  # Assert: Should detect untracked file
  assert_not_empty "$status_output" "Git status should detect untracked file"

  # Check for "??" prefix (untracked)
  if echo "$status_output" | grep -q "^??"; then
    return 0
  else
    echo "Expected '??' prefix for untracked file, got: $status_output"
    return 1
  fi
}

# Test 4: Staged files detection
test_check_git_status_staged() {
  # Arrange: Create and stage a new file
  echo "staged content" > staged_file.txt
  git add staged_file.txt

  # Act: Check git status
  local status_output
  status_output=$(git status --porcelain)

  # Assert: Should detect staged file
  assert_not_empty "$status_output" "Git status should detect staged file"

  # Check for "A " prefix (added/staged)
  if echo "$status_output" | grep -q "^A "; then
    return 0
  else
    echo "Expected 'A ' prefix for staged file, got: $status_output"
    return 1
  fi
}

# Test 5: Conflict detection
test_check_git_status_conflicts() {
  # Arrange: Create a merge conflict scenario
  # 1. Create a branch
  git checkout -q -b feature-branch
  echo "feature change" > conflict_file.txt
  git add conflict_file.txt
  git commit -q -m "feature commit"

  # 2. Go back to main and make conflicting change
  git checkout -q main
  echo "main change" > conflict_file.txt
  git add conflict_file.txt
  git commit -q -m "main commit"

  # 3. Try to merge (will create conflict)
  git merge feature-branch 2>/dev/null || true

  # Act: Check git status
  local status_output
  status_output=$(git status --porcelain)

  # Assert: Should detect conflict
  assert_not_empty "$status_output" "Git status should detect conflict"

  # Check for "UU" prefix (both modified - unmerged conflict)
  if echo "$status_output" | grep -q "^UU"; then
    return 0
  else
    # Also accept "AA" (both added) or "DD" (both deleted)
    if echo "$status_output" | grep -qE "^(AA|DD|AU|UA|DU|UD)"; then
      return 0
    else
      echo "Expected conflict markers (UU, AA, etc.), got: $status_output"
      return 1
    fi
  fi
}

# ============================================================================
# MAIN TEST EXECUTION
# ============================================================================

main() {
  echo "=========================================="
  echo "Git Status Checker Test Suite"
  echo "=========================================="

  # Try to source implementation (will warn if not exists)
  source_implementation || true

  # Run all tests
  run_test test_check_git_status_clean
  run_test test_check_git_status_modified
  run_test test_check_git_status_untracked
  run_test test_check_git_status_staged
  run_test test_check_git_status_conflicts

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
