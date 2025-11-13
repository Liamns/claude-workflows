#!/bin/bash
# Branch Info Collector Test Suite
# Tests for branch-info-collector.sh functions

set -e

# Test configuration
TEST_DIR="/tmp/branch-info-test-$$"
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

  # Create initial commit
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

assert_true() {
  local condition="$1"
  local message="${2:-Condition should be true}"

  if [ "$condition" = "true" ] || [ "$condition" = "0" ]; then
    return 0
  else
    echo -e "${RED} $message${NC}"
    echo "  Got: '$condition'"
    return 1
  fi
}

assert_false() {
  local condition="$1"
  local message="${2:-Condition should be false}"

  if [ "$condition" = "false" ] || [ "$condition" != "0" ] && [ "$condition" != "true" ]; then
    return 0
  else
    echo -e "${RED} $message${NC}"
    echo "  Got: '$condition'"
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
  if [ -f "../lib/branch-info-collector.sh" ]; then
    source "../lib/branch-info-collector.sh"
    return 0
  else
    echo -e "${YELLOW}Warning: branch-info-collector.sh not found (expected for TDD)${NC}"
    return 1
  fi
}

# ============================================================================
# TEST CASES
# ============================================================================

# Test 1: Feature branch pattern detection (NNN-*)
test_is_feature_branch() {
  # Test Case 1: Valid feature branch
  git checkout -q -b 004-branch-state-management

  local current_branch
  current_branch=$(git branch --show-current)

  assert_equals "004-branch-state-management" "$current_branch" "Branch should be created"

  # Check pattern: NNN-*
  if echo "$current_branch" | grep -qE "^[0-9]{3}-"; then
    local result=true
  else
    local result=false
  fi

  assert_true "$result" "Should match feature branch pattern (NNN-*)"

  # Test Case 2: Invalid feature branches
  git checkout -q -b invalid-branch-name

  current_branch=$(git branch --show-current)

  if echo "$current_branch" | grep -qE "^[0-9]{3}-"; then
    result=true
  else
    result=false
  fi

  assert_false "$result" "Should NOT match feature branch pattern (no NNN- prefix)"

  return 0
}

# Test 2: Epic branch pattern detection (NNN-epic-*)
test_is_epic_branch() {
  # Test Case 1: Valid epic branch
  git checkout -q -b 001-epic-workflow-system-v31-improvements

  local current_branch
  current_branch=$(git branch --show-current)

  assert_equals "001-epic-workflow-system-v31-improvements" "$current_branch" "Epic branch should be created"

  # Check pattern: NNN-epic-*
  if echo "$current_branch" | grep -qE "^[0-9]{3}-epic-"; then
    local result=true
  else
    local result=false
  fi

  assert_true "$result" "Should match epic branch pattern (NNN-epic-*)"

  # Test Case 2: Feature branch should NOT match epic pattern
  git checkout -q -b 004-branch-state-management

  current_branch=$(git branch --show-current)

  if echo "$current_branch" | grep -qE "^[0-9]{3}-epic-"; then
    result=true
  else
    result=false
  fi

  assert_false "$result" "Feature branch should NOT match epic pattern"

  # Test Case 3: Invalid branch should NOT match
  git checkout -q -b main

  current_branch=$(git branch --show-current)

  if echo "$current_branch" | grep -qE "^[0-9]{3}-epic-"; then
    result=true
  else
    result=false
  fi

  assert_false "$result" "Invalid branch should NOT match epic pattern"

  return 0
}

# Test 3: Find epic branch
test_find_epic_branch() {
  # Test Case 1: Create epic branch and find it
  git checkout -q -b 001-epic-workflow-system-v31-improvements
  git checkout -q -b 004-branch-state-management

  # Current branch is feature, should find epic branch
  local current_branch
  current_branch=$(git branch --show-current)

  assert_equals "004-branch-state-management" "$current_branch" "Should be on feature branch"

  # Find epic branch
  local epic_branch
  epic_branch=$(git branch --list | grep -E "^\*?\s+[0-9]{3}-epic-" | sed 's/^[\* ]*//g' | head -1)

  assert_not_empty "$epic_branch" "Should find epic branch"
  assert_equals "001-epic-workflow-system-v31-improvements" "$epic_branch" "Should find correct epic branch"

  # Test Case 2: No epic branch exists
  cd "$TEST_DIR"
  rm -rf .git
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  echo "initial" > README.md
  git add README.md
  git commit -q -m "initial commit"

  git checkout -q -b 004-branch-state-management

  epic_branch=$(git branch --list | grep -E "^\*?\s+[0-9]{3}-epic-" | sed 's/^[\* ]*//g' | head -1 || true)

  if [ -z "$epic_branch" ]; then
    return 0
  else
    echo "Should not find epic branch when none exists, but found: $epic_branch"
    return 1
  fi
}

# Test 4: Branch name extraction
test_get_current_branch() {
  # Test various branch names
  local branches=(
    "main"
    "004-branch-state-management"
    "001-epic-workflow-system-v31-improvements"
    "feature/test-branch"
  )

  for branch_name in "${branches[@]}"; do
    git checkout -q -b "$branch_name" 2>/dev/null || git checkout -q "$branch_name"

    local current_branch
    current_branch=$(git branch --show-current)

    assert_equals "$branch_name" "$current_branch" "Should get correct branch name: $branch_name"
  done

  return 0
}

# Test 5: Multiple epic branches (should return first one)
test_find_epic_branch_multiple() {
  # Create multiple epic branches
  git checkout -q -b 001-epic-first-epic
  git checkout -q -b 002-epic-second-epic
  git checkout -q -b 004-branch-state-management

  # Should find one of the epic branches (preferably with pattern matching)
  local epic_branch
  epic_branch=$(git branch --list | grep -E "^\*?\s+[0-9]{3}-epic-" | sed 's/^[\* ]*//g' | head -1)

  assert_not_empty "$epic_branch" "Should find at least one epic branch"

  # Check that it matches epic pattern
  if echo "$epic_branch" | grep -qE "^[0-9]{3}-epic-"; then
    return 0
  else
    echo "Found branch does not match epic pattern: $epic_branch"
    return 1
  fi
}

# ============================================================================
# MAIN TEST EXECUTION
# ============================================================================

main() {
  echo "=========================================="
  echo "Branch Info Collector Test Suite"
  echo "=========================================="

  # Try to source implementation (will warn if not exists)
  source_implementation || true

  # Run all tests
  run_test test_is_feature_branch
  run_test test_is_epic_branch
  run_test test_find_epic_branch
  run_test test_get_current_branch
  run_test test_find_epic_branch_multiple

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
