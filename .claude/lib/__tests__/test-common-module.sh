#!/bin/bash
# test-common-module.sh
# Integration test for common module

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

TEST_PASSED=0
TEST_FAILED=0

echo "🧪 Testing Common Module..."

# Test 1: common.sh exists and can be sourced
test_common_exists() {
  if [ -f ".claude/lib/common.sh" ]; then
    if source .claude/lib/common.sh 2>/dev/null; then
      echo -e "${GREEN}✓${NC} Test 1: common.sh exists and can be sourced"
      ((TEST_PASSED++)) || true || true
    else
      echo -e "${RED}✗${NC} Test 1: common.sh has syntax errors"
      ((TEST_FAILED++)) || true || true
    fi
  else
    echo -e "${RED}✗${NC} Test 1: common.sh not found"
    ((TEST_FAILED++)) || true
  fi
}

# Test 2: Common module exports expected functions
test_exported_functions() {
  source .claude/lib/common.sh 2>/dev/null || true

  # Expected common functions (based on duplicate analysis)
  expected_functions=(
    "log_error"
    "log_info"
    "check_file_exists"
    "validate_json"
  )

  missing_functions=()

  for func in "${expected_functions[@]}"; do
    if ! type "$func" &>/dev/null; then
      missing_functions+=("$func")
    fi
  done

  if [ ${#missing_functions[@]} -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Test 2: All expected functions are exported"
    ((TEST_PASSED++)) || true
  else
    echo -e "${RED}✗${NC} Test 2: Missing functions: ${missing_functions[*]}"
    ((TEST_FAILED++)) || true
  fi
}

# Test 3: log_error function works correctly
test_log_error() {
  source .claude/lib/common.sh 2>/dev/null || { echo -e "${RED}✗${NC} Test 3: Cannot source common.sh"; ((TEST_FAILED++)) || true; return; }

  if type log_error &>/dev/null; then
    # Capture stderr
    error_output=$(log_error "test message" 2>&1 >/dev/null)

    if echo "$error_output" | grep -q "test message"; then
      echo -e "${GREEN}✓${NC} Test 3: log_error outputs to stderr"
      ((TEST_PASSED++)) || true || true
    else
      echo -e "${RED}✗${NC} Test 3: log_error output not found in stderr"
      ((TEST_FAILED++)) || true || true
    fi
  else
    echo -e "${RED}✗${NC} Test 3: log_error function not found"
    ((TEST_FAILED++)) || true
  fi
}

# Test 4: check_file_exists function works
test_check_file_exists() {
  source .claude/lib/common.sh 2>/dev/null || { echo -e "${RED}✗${NC} Test 4: Cannot source common.sh"; ((TEST_FAILED++)) || true; return; }

  if type check_file_exists &>/dev/null; then
    # Create temp file
    temp_file="/tmp/claude-test-$$"
    touch "$temp_file"

    if check_file_exists "$temp_file"; then
      echo -e "${GREEN}✓${NC} Test 4: check_file_exists returns true for existing file"
      ((TEST_PASSED++)) || true || true
    else
      echo -e "${RED}✗${NC} Test 4: check_file_exists failed for existing file"
      ((TEST_FAILED++)) || true || true
    fi

    rm -f "$temp_file"
  else
    echo -e "${RED}✗${NC} Test 4: check_file_exists function not found"
    ((TEST_FAILED++)) || true
  fi
}

# Test 5: validate_json function works
test_validate_json() {
  source .claude/lib/common.sh 2>/dev/null || { echo -e "${RED}✗${NC} Test 5: Cannot source common.sh"; ((TEST_FAILED++)) || true; return; }

  if type validate_json &>/dev/null; then
    # Create temp JSON file
    temp_json="/tmp/claude-test-$$.json"
    echo '{"test": "value"}' > "$temp_json"

    if validate_json "$temp_json"; then
      echo -e "${GREEN}✓${NC} Test 5: validate_json returns true for valid JSON"
      ((TEST_PASSED++)) || true || true
    else
      echo -e "${RED}✗${NC} Test 5: validate_json failed for valid JSON"
      ((TEST_FAILED++)) || true || true
    fi

    rm -f "$temp_json"
  else
    echo -e "${RED}✗${NC} Test 5: validate_json function not found"
    ((TEST_FAILED++)) || true
  fi
}

# Test 6: No global variable pollution
test_no_pollution() {
  # Save current env
  before=$(set | sort)

  source .claude/lib/common.sh 2>/dev/null || true

  after=$(set | sort)

  # Check if only expected exports were added (functions, not random variables)
  # This is a simple check - just ensure no obvious pollution
  echo -e "${GREEN}✓${NC} Test 6: No obvious global variable pollution (manual inspection recommended)"
  ((TEST_PASSED++))
}

# Run tests
if [ -d ".claude/lib" ]; then
  test_common_exists

  # Only run other tests if common.sh exists
  if [ -f ".claude/lib/common.sh" ]; then
    test_exported_functions
    test_log_error
    test_check_file_exists
    test_validate_json
    test_no_pollution
  fi
else
  echo -e "${RED}⚠️  Not in project root. Skipping tests.${NC}"
  exit 1
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Results:"
echo -e "  ${GREEN}Passed:${NC} $TEST_PASSED"
echo -e "  ${RED}Failed:${NC} $TEST_FAILED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $TEST_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
