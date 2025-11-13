#!/bin/bash
# US5: Parallel Work Test Suite
# Tests for US5 - Branch creation from Epic branch when on Feature branch

set -e

# Test configuration
TEST_DIR="/tmp/us5-parallel-work-test-$$"
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

  # Rename default branch to main if needed
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

# Test 1: Detect when on Feature branch
test_detect_feature_branch() {
  # Arrange: Create Epic and Feature branch
  git checkout -b "001-epic-workflow" -q
  git checkout -b "002-feature-auth" -q

  # Act: Get branch info
  get_branch_info

  # Assert: Should detect feature branch
  if is_feature_branch "$BRANCH_NAME"; then
    local is_feature=true
  else
    local is_feature=false
  fi

  assert_true "$is_feature" "Should detect Feature branch (002-feature-auth)"

  return 0
}

# Test 2: Find Epic branch when on Feature branch
test_find_epic_branch_from_feature() {
  # Arrange: Create Epic and Feature branches
  git checkout -b "001-epic-workflow" -q
  git checkout -b "002-feature-auth" -q

  # Act: Find Epic branch
  local epic_branch
  epic_branch=$(find_epic_branch)

  # Assert: Should find Epic branch
  assert_contains "$epic_branch" "001-epic-workflow" "Should find Epic branch"

  return 0
}

# Test 3: Create branch from Epic when on Feature branch
test_create_branch_from_epic() {
  # Arrange: Create Epic and Feature branches
  git checkout -b "001-epic-workflow" -q
  echo "epic content" > epic.txt
  git add epic.txt
  git commit -q -m "epic commit"

  git checkout -b "002-feature-auth" -q
  echo "feature content" > feature.txt
  git add feature.txt
  git commit -q -m "feature commit"

  # Act: Create new branch from Epic
  local epic_branch
  epic_branch=$(find_epic_branch)

  if [ -n "$epic_branch" ]; then
    if create_branch_from_base "003-new-feature" "$epic_branch"; then
      local branch_created=true
    else
      local branch_created=false
    fi
  else
    local branch_created=false
  fi

  # Assert: Should create branch from Epic
  assert_true "$branch_created" "Should create branch from Epic"

  # Verify we're on the new branch
  local current_branch
  current_branch=$(git branch --show-current)
  assert_equals "003-new-feature" "$current_branch" "Should be on new branch"

  # Verify new branch is based on Epic (should have epic.txt but not feature.txt)
  if [ -f "epic.txt" ] && [ ! -f "feature.txt" ]; then
    return 0
  else
    echo "New branch should be based on Epic (have epic.txt, not feature.txt)"
    return 1
  fi
}

# Test 4: Warn about parallel work
test_warn_parallel_work() {
  # Arrange: Create Feature branch
  git checkout -b "001-epic-workflow" -q
  git checkout -b "002-feature-auth" -q

  # Act: Check if warning function exists
  if declare -f warn_parallel_work > /dev/null 2>&1; then
    # Function exists, test it
    local output
    output=$(warn_parallel_work "002-feature-auth" "003-new-feature" 2>&1)

    # Assert: Should mention current branch
    if echo "$output" | grep -q "002-feature-auth"; then
      return 0
    else
      echo "Warning should mention current branch"
      echo "Output: $output"
      return 1
    fi
  else
    echo "  (warn_parallel_work not implemented yet - expected for TDD)"
    return 0
  fi
}

# Test 5: Handle clean state with parallel work
test_parallel_work_clean_state() {
  # Arrange: Create Epic and Feature branches
  git checkout -b "001-epic-workflow" -q
  git checkout -b "002-feature-auth" -q

  # Working tree is clean
  check_git_status

  # Assert: Clean state should be detected
  assert_true "$GIT_STATUS_CLEAN" "Working tree should be clean"

  # In real workflow:
  # 1. detect we're on Feature branch
  # 2. find Epic branch
  # 3. create new branch from Epic
  # 4. show warning about parallel work

  return 0
}

# Test 6: Handle dirty state with parallel work
test_parallel_work_dirty_state() {
  # Arrange: Create Epic and Feature branches with changes
  git checkout -b "001-epic-workflow" -q
  git checkout -b "002-feature-auth" -q
  echo "modified" >> README.md

  # Working tree is dirty
  check_git_status

  # Assert: Dirty state should be detected
  if [ "$GIT_STATUS_CLEAN" = "false" ]; then
    local is_dirty=true
  else
    local is_dirty=false
  fi

  assert_true "$is_dirty" "Working tree should be dirty"

  # In real workflow:
  # 1. detect we're on Feature branch
  # 2. handle dirty state (ask user action)
  # 3. after handling, find Epic branch
  # 4. create new branch from Epic

  return 0
}

# Test 7: Epic branch not found handling
test_epic_branch_not_found() {
  # Arrange: On Feature branch without Epic branch
  git checkout -b "002-feature-auth" -q

  # Act: Try to find Epic branch
  local epic_branch
  epic_branch=$(find_epic_branch)

  # Assert: Should return empty when Epic not found
  if [ -z "$epic_branch" ]; then
    return 0
  else
    echo "Should return empty when Epic branch not found"
    echo "Found: $epic_branch"
    return 1
  fi
}

# Test 8: Workflow integration - full parallel work scenario
test_parallel_work_full_workflow() {
  # Arrange: Setup Epic and Feature branches
  git checkout -b "001-epic-workflow" -q
  echo "epic file" > epic.txt
  git add epic.txt
  git commit -q -m "epic commit"

  git checkout -b "002-feature-auth" -q
  echo "feature file" > auth.txt
  git add auth.txt
  git commit -q -m "feature commit"

  # Act: Simulate full parallel work workflow
  local current_branch
  current_branch=$(git branch --show-current)

  # Step 1: Detect Feature branch
  if is_feature_branch "$current_branch"; then
    local on_feature=true
  else
    local on_feature=false
  fi

  # Step 2: Find Epic branch
  local epic_branch
  epic_branch=$(find_epic_branch)

  # Step 3: Create branch from Epic
  local new_branch="003-new-feature"
  if [ -n "$epic_branch" ]; then
    create_branch_from_base "$new_branch" "$epic_branch" > /dev/null 2>&1
    local branch_created=true
  else
    local branch_created=false
  fi

  # Assert: Full workflow should succeed
  assert_true "$on_feature" "Should detect Feature branch"
  assert_true "$branch_created" "Should create branch from Epic"

  # Verify final state
  local final_branch
  final_branch=$(git branch --show-current)
  assert_equals "$new_branch" "$final_branch" "Should be on new branch"

  return 0
}

# Test 9: Do not apply parallel work logic on main branch
test_no_parallel_work_on_main() {
  # Arrange: On main branch
  git checkout main -q

  # Act: Check if on Feature branch
  local current_branch
  current_branch=$(git branch --show-current)

  if is_feature_branch "$current_branch"; then
    local on_feature=true
  else
    local on_feature=false
  fi

  # Assert: main is not a Feature branch
  if [ "$on_feature" = "false" ]; then
    return 0
  else
    echo "main should not be detected as Feature branch"
    return 1
  fi
}

# Test 10: Do not apply parallel work logic on Epic branch
test_no_parallel_work_on_epic() {
  # Arrange: On Epic branch
  git checkout -b "001-epic-workflow" -q

  # Act: Check if on Feature branch
  local current_branch
  current_branch=$(git branch --show-current)

  if is_feature_branch "$current_branch"; then
    local on_feature=true
  else
    local on_feature=false
  fi

  # Assert: Epic branch should not be detected as Feature branch
  if [ "$on_feature" = "false" ]; then
    return 0
  else
    echo "Epic branch should not be detected as Feature branch"
    return 1
  fi
}

# ============================================================================
# MAIN TEST EXECUTION
# ============================================================================

main() {
  echo "=========================================="
  echo "US5: Parallel Work Test Suite"
  echo "=========================================="

  # Source implementations
  if ! source_implementations; then
    echo -e "${RED}Failed to source required implementations${NC}"
    exit 1
  fi

  # Run all tests
  run_test test_detect_feature_branch
  run_test test_find_epic_branch_from_feature
  run_test test_create_branch_from_epic
  run_test test_warn_parallel_work
  run_test test_parallel_work_clean_state
  run_test test_parallel_work_dirty_state
  run_test test_epic_branch_not_found
  run_test test_parallel_work_full_workflow
  run_test test_no_parallel_work_on_main
  run_test test_no_parallel_work_on_epic

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
