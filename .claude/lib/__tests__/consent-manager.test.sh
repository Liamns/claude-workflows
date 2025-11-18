#!/bin/bash
# Test suite for consent-manager.sh
# Testing consent management functionality for file creation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Source the module to test (will be created in T009)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONSENT_MANAGER="$SCRIPT_DIR/../document-preview/consent-manager.sh"

# Test helper functions
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  ((TESTS_PASSED++))
  ((TESTS_RUN++))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  echo -e "  ${YELLOW}Expected${NC}: $2"
  echo -e "  ${YELLOW}Got${NC}: $3"
  ((TESTS_FAILED++))
  ((TESTS_RUN++))
}

skip() {
  echo -e "${YELLOW}⊘ SKIP${NC}: $1 (Reason: $2)"
}

# Create test fixture files
setup_test_files() {
  TEST_DIR="/tmp/consent-manager-test-$$"
  mkdir -p "$TEST_DIR"

  # Test file: sample spec for preview
  cat > "$TEST_DIR/sample-spec.md" <<'EOF'
# Sample Specification

## Overview
This is a sample specification document for testing consent management.

## Functional Requirements
- FR-001: Implement feature A
- FR-002: Implement feature B
- FR-003: Implement feature C
EOF

  # Sample preview content
  cat > "$TEST_DIR/sample-preview.txt" <<'EOF'
## 📝 요약

Sample specification for testing. Key features: A, B, C.

---

## 📄 전문

# Sample Specification

## Overview
This is a sample specification document.
EOF
}

cleanup_test_files() {
  rm -rf "$TEST_DIR"
  unset CLAUDE_ENV  # Clean up environment
}

# Test 1: development mode returns AUTO_APPROVE
test_development_mode_auto_approve() {
  if [ ! -f "$CONSENT_MANAGER" ]; then
    skip "test_development_mode_auto_approve" "consent-manager.sh not yet implemented"
    return 0
  fi

  source "$CONSENT_MANAGER"

  # Set development environment
  export CLAUDE_ENV="development"

  local result
  result=$(request_consent "test.md" "Test preview content" 2>/dev/null)
  local exit_code=$?

  if [ "$result" = "AUTO_APPROVE" ] && [ $exit_code -eq 0 ]; then
    pass "Development mode returns AUTO_APPROVE"
  else
    fail "Development mode should return AUTO_APPROVE" "AUTO_APPROVE (exit 0)" "result='$result' (exit $exit_code)"
  fi

  unset CLAUDE_ENV
  return 0
}

# Test 2: production mode behavior
test_production_mode_behavior() {
  if [ ! -f "$CONSENT_MANAGER" ]; then
    skip "test_production_mode_behavior" "consent-manager.sh not yet implemented"
    return 0
  fi

  source "$CONSENT_MANAGER"

  # Set production environment
  export CLAUDE_ENV="production"

  # In production mode, should call AskUserQuestion
  # We can't easily test the actual call, but we can verify it doesn't auto-approve
  # This is more of an integration test - skip for unit tests
  skip "test_production_mode_behavior" "Requires integration testing with AskUserQuestion"

  unset CLAUDE_ENV
  return 0
}

# Test 3: Invalid CLAUDE_ENV defaults to production
test_invalid_env_defaults_to_production() {
  if [ ! -f "$CONSENT_MANAGER" ]; then
    skip "test_invalid_env_defaults_to_production" "consent-manager.sh not yet implemented"
    return 0
  fi

  source "$CONSENT_MANAGER"

  # Set invalid environment
  export CLAUDE_ENV="invalid_mode"

  local validated_env
  validated_env=$(validate_consent_environment 2>/dev/null)

  if [ "$validated_env" = "production" ]; then
    pass "Invalid CLAUDE_ENV defaults to production"
  else
    fail "Invalid environment should default to production" "production" "got: '$validated_env'"
  fi

  unset CLAUDE_ENV
  return 0
}

# Test 4: Unset CLAUDE_ENV defaults to production
test_unset_env_defaults_to_production() {
  if [ ! -f "$CONSENT_MANAGER" ]; then
    skip "test_unset_env_defaults_to_production" "consent-manager.sh not yet implemented"
    return 0
  fi

  source "$CONSENT_MANAGER"

  unset CLAUDE_ENV

  local validated_env
  validated_env=$(validate_consent_environment 2>/dev/null)

  if [ "$validated_env" = "production" ]; then
    pass "Unset CLAUDE_ENV defaults to production"
  else
    fail "Unset environment should default to production" "production" "got: '$validated_env'"
  fi

  return 0
}

# Test 5: Retry count tracking (max 3 attempts)
test_retry_count_limit() {
  if [ ! -f "$CONSENT_MANAGER" ]; then
    skip "test_retry_count_limit" "consent-manager.sh not yet implemented"
    return 0
  fi

  source "$CONSENT_MANAGER"

  # This test would require mocking user input
  # For now, test the validation function
  skip "test_retry_count_limit" "Requires user interaction mocking"

  return 0
}

# Test 6: Valid consent options (approve, modify, reject)
test_valid_consent_options() {
  if [ ! -f "$CONSENT_MANAGER" ]; then
    skip "test_valid_consent_options" "consent-manager.sh not yet implemented"
    return 0
  fi

  source "$CONSENT_MANAGER"

  # Test if validate_consent_response function exists and works
  if declare -f validate_consent_response >/dev/null 2>&1; then
    local valid_options=("approve" "modify" "reject")
    local all_valid=true

    for option in "${valid_options[@]}"; do
      if ! validate_consent_response "$option" 2>/dev/null; then
        all_valid=false
        break
      fi
    done

    # Test invalid option
    if validate_consent_response "invalid_option" 2>/dev/null; then
      all_valid=false
    fi

    if [ "$all_valid" = true ]; then
      pass "Consent options validation works correctly"
    else
      fail "Consent options validation failed" "approve/modify/reject valid, others invalid" "validation logic incorrect"
    fi
  else
    skip "test_valid_consent_options" "validate_consent_response function not found"
  fi

  return 0
}

# Test 7: Empty preview handling
test_empty_preview_handling() {
  if [ ! -f "$CONSENT_MANAGER" ]; then
    skip "test_empty_preview_handling" "consent-manager.sh not yet implemented"
    return 0
  fi

  source "$CONSENT_MANAGER"

  export CLAUDE_ENV="development"

  # Test with empty preview
  local result
  result=$(request_consent "test.md" "" 2>/dev/null)
  local exit_code=$?

  # Should either reject empty preview or handle gracefully
  if [ $exit_code -ne 0 ] || [ -n "$result" ]; then
    pass "Empty preview handled gracefully"
  else
    fail "Empty preview should be handled" "error or valid result" "exit_code=$exit_code, result='$result'"
  fi

  unset CLAUDE_ENV
  return 0
}

# Test 8: Empty file path handling
test_empty_filepath_handling() {
  if [ ! -f "$CONSENT_MANAGER" ]; then
    skip "test_empty_filepath_handling" "consent-manager.sh not yet implemented"
    return 0
  fi

  source "$CONSENT_MANAGER"

  export CLAUDE_ENV="development"

  # Test with empty file path
  local result
  result=$(request_consent "" "Test content" 2>/dev/null)
  local exit_code=$?

  # Should either reject empty path or handle gracefully
  if [ $exit_code -ne 0 ] || [ -n "$result" ]; then
    pass "Empty file path handled gracefully"
  else
    fail "Empty file path should be handled" "error or valid result" "exit_code=$exit_code, result='$result'"
  fi

  unset CLAUDE_ENV
  return 0
}

# Test 9: format_consent_question function
test_format_consent_question() {
  if [ ! -f "$CONSENT_MANAGER" ]; then
    skip "test_format_consent_question" "consent-manager.sh not yet implemented"
    return 0
  fi

  source "$CONSENT_MANAGER"

  # Test if format function exists
  if declare -f format_consent_question >/dev/null 2>&1; then
    local question=$(format_consent_question "test.md" "Sample preview" 2>/dev/null)

    # Should contain file path and preview
    if [[ "$question" =~ "test.md" ]] && [[ "$question" =~ "Sample preview" ]]; then
      pass "format_consent_question includes file path and preview"
    else
      fail "format_consent_question should include inputs" "contains 'test.md' and 'Sample preview'" "got: '$question'"
    fi
  else
    skip "test_format_consent_question" "format_consent_question function not found"
  fi

  return 0
}

# Test 10: Consent response constants
test_consent_response_constants() {
  if [ ! -f "$CONSENT_MANAGER" ]; then
    skip "test_consent_response_constants" "consent-manager.sh not yet implemented"
    return 0
  fi

  source "$CONSENT_MANAGER"

  # Check if constants are defined
  local has_constants=true

  if [ -z "${CONSENT_APPROVE:-}" ]; then has_constants=false; fi
  if [ -z "${CONSENT_MODIFY:-}" ]; then has_constants=false; fi
  if [ -z "${CONSENT_REJECT:-}" ]; then has_constants=false; fi
  if [ -z "${AUTO_APPROVE:-}" ]; then has_constants=false; fi

  if [ "$has_constants" = true ]; then
    pass "Consent response constants are defined"
  else
    fail "Consent response constants should be defined" "CONSENT_APPROVE, CONSENT_MODIFY, CONSENT_REJECT, AUTO_APPROVE" "some missing"
  fi

  return 0
}

# Main test execution
main() {
  echo "========================================="
  echo "Consent Manager Test Suite"
  echo "========================================="
  echo ""

  setup_test_files

  # Run all tests
  echo "Running test 1..." >&2
  test_development_mode_auto_approve
  echo "Running test 2..." >&2
  test_production_mode_behavior
  echo "Running test 3..." >&2
  test_invalid_env_defaults_to_production
  echo "Running test 4..." >&2
  test_unset_env_defaults_to_production
  echo "Running test 5..." >&2
  test_retry_count_limit
  echo "Running test 6..." >&2
  test_valid_consent_options
  echo "Running test 7..." >&2
  test_empty_preview_handling
  echo "Running test 8..." >&2
  test_empty_filepath_handling
  echo "Running test 9..." >&2
  test_format_consent_question
  echo "Running test 10..." >&2
  test_consent_response_constants

  cleanup_test_files

  # Print summary
  echo ""
  echo "========================================="
  echo "Test Results"
  echo "========================================="
  echo "Total tests: $TESTS_RUN"
  echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
  echo -e "${RED}Failed: $TESTS_FAILED${NC}"
  echo ""

  if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
  fi
}

# Run tests
main
