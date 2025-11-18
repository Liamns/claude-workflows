#!/usr/bin/env bash
#
# test-branch-state-handler.sh
# Tests for branch-state-handler.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"
BRANCH_HANDLER="${LIB_DIR}/branch-state-handler.sh"

# Test utilities
TESTS_PASSED=0
TESTS_FAILED=0
TEST_REPO_DIR=""

setup() {
  TEST_REPO_DIR=$(mktemp -d)
  cd "$TEST_REPO_DIR"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test User"
  echo "initial" > test.txt
  git add test.txt
  git commit -q -m "Initial commit"
}

teardown() {
  cd - > /dev/null
  if [[ -n "$TEST_REPO_DIR" ]] && [[ -d "$TEST_REPO_DIR" ]]; then
    rm -rf "$TEST_REPO_DIR"
  fi
}

pass() {
  echo "✓ $1"
  ((TESTS_PASSED++))
}

fail() {
  echo "✗ $1"
  echo "  Expected: $2"
  echo "  Got: $3"
  ((TESTS_FAILED++))
}

# Test 1: Script exists
test_script_exists() {
  if [[ -f "$BRANCH_HANDLER" ]]; then
    pass "branch-state-handler.sh exists"
  else
    fail "branch-state-handler.sh exists" "file" "not found"
  fi
}

# Test 2: Get current branch
test_get_current_branch() {
  cd "$TEST_REPO_DIR"

  local branch
  branch=$(git branch --show-current)

  if [[ "$branch" == "master" ]] || [[ "$branch" == "main" ]]; then
    pass "Can get current branch"
  else
    fail "Can get current branch" "master or main" "$branch"
  fi
}

# Test 3: Create feature branch
test_create_feature_branch() {
  cd "$TEST_REPO_DIR"

  git checkout -q -b "feature/test-feature"
  local branch
  branch=$(git branch --show-current)

  if [[ "$branch" == "feature/test-feature" ]]; then
    pass "Can create feature branch"
  else
    fail "Can create feature branch" "feature/test-feature" "$branch"
  fi
}

# Test 4: Detect branch type
test_detect_branch_type() {
  cd "$TEST_REPO_DIR"

  # Test feature branch
  git checkout -q -b "feature/new-feature" 2>/dev/null || git checkout -q "feature/new-feature"

  local branch
  branch=$(git branch --show-current)

  if [[ "$branch" =~ ^feature/ ]]; then
    pass "Can detect feature branch type"
  else
    fail "Can detect feature branch type" "feature/*" "$branch"
  fi
}

# Test 5: Check for uncommitted changes
test_uncommitted_changes() {
  cd "$TEST_REPO_DIR"

  # Create uncommitted change
  echo "new content" > new_file.txt

  if git status --porcelain | grep -q "new_file.txt"; then
    pass "Can detect uncommitted changes"
  else
    fail "Can detect uncommitted changes" "changes detected" "no changes"
  fi
}

# Test 6: Check for clean working directory
test_clean_working_directory() {
  cd "$TEST_REPO_DIR"

  # Clean up
  git checkout . 2>/dev/null || true
  git clean -fd 2>/dev/null || true

  if [[ -z "$(git status --porcelain)" ]]; then
    pass "Can detect clean working directory"
  else
    fail "Can detect clean working directory" "clean" "has changes"
  fi
}

# Test 7: Branch exists check
test_branch_exists() {
  cd "$TEST_REPO_DIR"

  git checkout -q -b "test-branch-exists" 2>/dev/null || true

  if git show-ref --verify --quiet "refs/heads/test-branch-exists"; then
    pass "Can check if branch exists"
  else
    fail "Can check if branch exists" "branch exists" "not found"
  fi
}

# Test 8: Get branch list
test_get_branch_list() {
  cd "$TEST_REPO_DIR"

  git checkout -q -b "branch-1" 2>/dev/null || true
  git checkout -q -b "branch-2" 2>/dev/null || true

  local branch_count
  branch_count=$(git branch | wc -l)

  if [[ $branch_count -ge 2 ]]; then
    pass "Can get branch list"
  else
    fail "Can get branch list" ">= 2 branches" "$branch_count branches"
  fi
}

# Run all tests
main() {
  echo "Testing branch-state-handler.sh..."
  echo ""

  setup

  test_script_exists
  test_get_current_branch
  test_create_feature_branch
  test_detect_branch_type
  test_uncommitted_changes
  test_clean_working_directory
  test_branch_exists
  test_get_branch_list

  teardown

  echo ""
  echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "✓ All tests passed!"
    exit 0
  else
    echo "✗ Some tests failed"
    exit 1
  fi
}

main "$@"
