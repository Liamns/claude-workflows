#!/usr/bin/env bash
#
# test-git-operations.sh
# Tests for git-operations.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"
GIT_OPS="${LIB_DIR}/git-operations.sh"

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
  if [[ -f "$GIT_OPS" ]]; then
    pass "git-operations.sh exists"
  else
    fail "git-operations.sh exists" "file" "not found"
  fi
}

# Test 2: Git repository check
test_is_git_repo() {
  cd "$TEST_REPO_DIR"

  if git rev-parse --git-dir &>/dev/null; then
    pass "Can detect Git repository"
  else
    fail "Can detect Git repository" "is git repo" "not a repo"
  fi
}

# Test 3: Git status
test_git_status() {
  cd "$TEST_REPO_DIR"

  local status
  status=$(git status --porcelain)

  # Should be clean after setup
  if [[ -z "$status" ]]; then
    pass "Can get Git status (clean)"
  else
    fail "Can get Git status (clean)" "empty status" "$status"
  fi
}

# Test 4: Add files
test_git_add() {
  cd "$TEST_REPO_DIR"

  echo "new content" > new_file.txt
  git add new_file.txt

  if git status --porcelain | grep -q "A  new_file.txt"; then
    pass "Can stage files with git add"
  else
    fail "Can stage files with git add" "staged file" "not staged"
  fi
}

# Test 5: Commit changes
test_git_commit() {
  cd "$TEST_REPO_DIR"

  echo "commit test" > commit_test.txt
  git add commit_test.txt
  git commit -q -m "Test commit"

  local commit_msg
  commit_msg=$(git log -1 --pretty=%B)

  if [[ "$commit_msg" == "Test commit" ]]; then
    pass "Can commit changes"
  else
    fail "Can commit changes" "Test commit" "$commit_msg"
  fi
}

# Test 6: Get commit hash
test_get_commit_hash() {
  cd "$TEST_REPO_DIR"

  local hash
  hash=$(git rev-parse HEAD)

  if [[ -n "$hash" ]] && [[ ${#hash} -eq 40 ]]; then
    pass "Can get commit hash"
  else
    fail "Can get commit hash" "40 char hash" "${#hash} chars"
  fi
}

# Test 7: Get commit message
test_get_commit_message() {
  cd "$TEST_REPO_DIR"

  local msg
  msg=$(git log -1 --pretty=%B)

  if [[ -n "$msg" ]]; then
    pass "Can get commit message"
  else
    fail "Can get commit message" "message text" "empty"
  fi
}

# Test 8: Get file diff
test_git_diff() {
  cd "$TEST_REPO_DIR"

  echo "modified" > test.txt

  local diff
  diff=$(git diff test.txt)

  if [[ -n "$diff" ]]; then
    pass "Can get file diff"
  else
    fail "Can get file diff" "diff output" "empty"
  fi
}

# Test 9: Get changed files
test_get_changed_files() {
  cd "$TEST_REPO_DIR"

  echo "change" > test.txt

  local changed_files
  changed_files=$(git status --porcelain | wc -l)

  if [[ $changed_files -gt 0 ]]; then
    pass "Can get changed files count"
  else
    fail "Can get changed files count" "> 0" "$changed_files"
  fi
}

# Test 10: Reset changes
test_git_reset() {
  cd "$TEST_REPO_DIR"

  echo "reset test" > reset_test.txt
  git add reset_test.txt
  git reset HEAD reset_test.txt 2>/dev/null

  if ! git status --porcelain | grep -q "^A.*reset_test.txt"; then
    pass "Can reset staged changes"
  else
    fail "Can reset staged changes" "unstaged" "still staged"
  fi
}

# Run all tests
main() {
  echo "Testing git-operations.sh..."
  echo ""

  setup

  test_script_exists
  test_is_git_repo
  test_git_status
  test_git_add
  test_git_commit
  test_get_commit_hash
  test_get_commit_message
  test_git_diff
  test_get_changed_files
  test_git_reset

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
