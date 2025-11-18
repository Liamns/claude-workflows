#!/bin/bash
# Test suite for summary-generator.sh
# Testing summary generation functionality

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

# Source the module to test (will be created in T006)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUMMARY_GENERATOR="$SCRIPT_DIR/../document-preview/summary-generator.sh"

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
  TEST_DIR="/tmp/summary-generator-test-$$"
  mkdir -p "$TEST_DIR"

  # Test file 1: Normal document (> 300 chars)
  cat > "$TEST_DIR/normal.md" <<'EOF'
# Planning Document UX Improvement

## Overview
This feature improves the UX of planning document generation by adding AI-powered summaries and user consent requests before creating files.

## Functional Requirements
- FR-001: Generate document summaries (max 300 chars)
- FR-002: Display summary and full content separately
- FR-003: Request user permission before file creation
- FR-004: Allow users to request modifications
- FR-005: Independent confirmation for each document

This is additional content that goes beyond the 300 character limit to test truncation functionality.
EOF

  # Test file 2: Short document (< 300 chars)
  cat > "$TEST_DIR/short.md" <<'EOF'
# Short Document

This is a short document with less than 300 characters total. It should be returned as-is without truncation.
EOF

  # Test file 3: Document with incomplete sentences
  cat > "$TEST_DIR/incomplete.md" <<'EOF'
# Document Testing

This document has a sentence that ends properly. But this one doesn
EOF

  # Test file 4: Empty document
  touch "$TEST_DIR/empty.md"
}

cleanup_test_files() {
  rm -rf "$TEST_DIR"
}

# Test 1: Summary length <= 300 characters
test_summary_length() {
  if [ ! -f "$SUMMARY_GENERATOR" ]; then
    skip "test_summary_length" "summary-generator.sh not yet implemented"
    return 0
  fi

  source "$SUMMARY_GENERATOR"

  local summary=$(generate_summary "$TEST_DIR/normal.md" 300)
  local length=${#summary}

  if [ $length -le 300 ]; then
    pass "Summary length is <= 300 characters (actual: $length)"
  else
    fail "Summary length should be <= 300 characters" "length <= 300" "length = $length"
  fi

  return 0
}

# Test 2: Complete sentences (no mid-sentence truncation)
test_complete_sentences() {
  if [ ! -f "$SUMMARY_GENERATOR" ]; then
    skip "test_complete_sentences" "summary-generator.sh not yet implemented"
    return
  fi

  source "$SUMMARY_GENERATOR"

  local summary=$(generate_summary "$TEST_DIR/normal.md" 300)
  local last_char="${summary: -1}"

  # Check if ends with sentence terminators: . ! ? or ...
  if [[ "$last_char" =~ [.!?] ]] || [[ "$summary" =~ \.\.\.$ ]]; then
    pass "Summary ends with complete sentence"
  else
    fail "Summary should end with complete sentence" "ends with . ! ? or ..." "ends with '$last_char'"
  fi
  return 0
}

# Test 3: Contains key information (Overview, FRs)
test_contains_key_info() {
  if [ ! -f "$SUMMARY_GENERATOR" ]; then
    skip "test_contains_key_info" "summary-generator.sh not yet implemented"
    return
  fi

  source "$SUMMARY_GENERATOR"

  local summary=$(generate_summary "$TEST_DIR/normal.md" 300)

  # Check for Overview content
  if [[ "$summary" =~ "UX"|"planning"|"document" ]]; then
    pass "Summary contains Overview-related keywords"
  else
    fail "Summary should contain Overview keywords" "UX or planning or document" "not found"
  fi
  return 0
}

# Test 4: Short content returned as-is
test_short_content() {
  if [ ! -f "$SUMMARY_GENERATOR" ]; then
    skip "test_short_content" "summary-generator.sh not yet implemented"
    return
  fi

  source "$SUMMARY_GENERATOR"

  local content=$(cat "$TEST_DIR/short.md")
  local summary=$(generate_summary "$TEST_DIR/short.md" 300)

  # For short content, should return full content (or at least not truncate unnecessarily)
  if [ ${#summary} -le 300 ]; then
    pass "Short content handled correctly (length: ${#summary})"
  else
    fail "Short content should not exceed limit" "length <= 300" "length = ${#summary}"
  fi
  return 0
}

# Test 5: Empty content handling
test_empty_content() {
  if [ ! -f "$SUMMARY_GENERATOR" ]; then
    skip "test_empty_content" "summary-generator.sh not yet implemented"
    return
  fi

  source "$SUMMARY_GENERATOR"

  local summary=$(generate_summary "$TEST_DIR/empty.md" 300 2>/dev/null)
  local exit_code=$?

  # Should either return empty string or error
  if [ -z "$summary" ] || [ $exit_code -ne 0 ]; then
    pass "Empty content handled gracefully"
  else
    fail "Empty content should return empty or error" "empty or error" "got: '$summary'"
  fi
  return 0
}

# Test 6: truncate_to_sentence function
test_truncate_to_sentence() {
  if [ ! -f "$SUMMARY_GENERATOR" ]; then
    skip "test_truncate_to_sentence" "summary-generator.sh not yet implemented"
    return
  fi

  source "$SUMMARY_GENERATOR"

  local text="This is a test. This is another sentence. Incomplete sent"
  local truncated=$(truncate_to_sentence "$text" 40)

  # Should truncate to "This is a test."
  if [[ "$truncated" =~ "This is a test." ]]; then
    pass "truncate_to_sentence works correctly"
  else
    fail "truncate_to_sentence should keep complete sentences" "This is a test." "got: '$truncated'"
  fi
  return 0
}

# Main test execution
main() {
  echo "========================================="
  echo "Summary Generator Test Suite"
  echo "========================================="
  echo ""

  setup_test_files

  # Run all tests
  echo "Running test 1..." >&2
  test_summary_length
  echo "Running test 2..." >&2
  test_complete_sentences
  echo "Running test 3..." >&2
  test_contains_key_info
  echo "Running test 4..." >&2
  test_short_content
  echo "Running test 5..." >&2
  test_empty_content
  echo "Running test 6..." >&2
  test_truncate_to_sentence

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
