#!/bin/bash
# Test suite for preview-formatter.sh
# Testing preview formatting functionality

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

# Source the module to test (will be created in T007)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREVIEW_FORMATTER="$SCRIPT_DIR/../document-preview/preview-formatter.sh"

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

# Test 1: Summary and full content separated by ---
test_separator_present() {
  if [ ! -f "$PREVIEW_FORMATTER" ]; then
    skip "test_separator_present" "preview-formatter.sh not yet implemented"
    return
  fi

  source "$PREVIEW_FORMATTER"

  local summary="This is a test summary."
  local full_content="# Full Document\n\nThis is the full content."
  local preview=$(format_preview "$summary" "$full_content")

  if [[ "$preview" =~ "---" ]]; then
    pass "Preview contains separator (---)"
  else
    fail "Preview should contain separator" "contains ---" "not found"
  fi
}

# Test 2: Section headers properly formatted
test_section_headers() {
  if [ ! -f "$PREVIEW_FORMATTER" ]; then
    skip "test_section_headers" "preview-formatter.sh not yet implemented"
    return
  fi

  source "$PREVIEW_FORMATTER"

  local summary="Test summary"
  local full_content="Full content"
  local preview=$(format_preview "$summary" "$full_content")

  # Should have section headers like "## 📝 요약" or "## 📄 전문"
  if [[ "$preview" =~ "##" ]]; then
    pass "Preview contains section headers"
  else
    fail "Preview should contain section headers" "contains ##" "not found"
  fi
}

# Test 3: Markdown syntax preserved
test_markdown_preserved() {
  if [ ! -f "$PREVIEW_FORMATTER" ]; then
    skip "test_markdown_preserved" "preview-formatter.sh not yet implemented"
    return
  fi

  source "$PREVIEW_FORMATTER"

  local summary="Summary with **bold** text"
  local full_content="# Heading\n\n- List item\n- Another item"
  local preview=$(format_preview "$summary" "$full_content")

  # Check if markdown is preserved
  if [[ "$preview" =~ "**bold**" ]] && [[ "$preview" =~ "# Heading" ]] && [[ "$preview" =~ "- List" ]]; then
    pass "Markdown syntax preserved"
  else
    fail "Markdown syntax should be preserved" "contains **bold**, # Heading, - List" "some missing"
  fi
}

# Test 4: Summary appears before full content
test_summary_before_content() {
  if [ ! -f "$PREVIEW_FORMATTER" ]; then
    skip "test_summary_before_content" "preview-formatter.sh not yet implemented"
    return
  fi

  source "$PREVIEW_FORMATTER"

  local summary="SUMMARY_TEXT"
  local full_content="FULL_CONTENT_TEXT"
  local preview=$(format_preview "$summary" "$full_content")

  # Get positions
  local summary_pos=$(echo "$preview" | grep -b -o "SUMMARY_TEXT" | head -1 | cut -d: -f1)
  local content_pos=$(echo "$preview" | grep -b -o "FULL_CONTENT_TEXT" | head -1 | cut -d: -f1)

  if [ -n "$summary_pos" ] && [ -n "$content_pos" ] && [ "$summary_pos" -lt "$content_pos" ]; then
    pass "Summary appears before full content"
  else
    fail "Summary should appear before full content" "summary_pos < content_pos" "order incorrect"
  fi
}

# Test 5: Empty summary handling
test_empty_summary() {
  if [ ! -f "$PREVIEW_FORMATTER" ]; then
    skip "test_empty_summary" "preview-formatter.sh not yet implemented"
    return
  fi

  source "$PREVIEW_FORMATTER"

  local summary=""
  local full_content="Full content here"
  local preview=$(format_preview "$summary" "$full_content" 2>/dev/null)
  local exit_code=$?

  # Should handle empty summary gracefully (either skip summary section or show placeholder)
  if [ $exit_code -eq 0 ]; then
    pass "Empty summary handled gracefully"
  else
    fail "Empty summary should be handled" "exit_code = 0" "exit_code = $exit_code"
  fi
}

# Test 6: Separator placement
test_separator_placement() {
  if [ ! -f "$PREVIEW_FORMATTER" ]; then
    skip "test_separator_placement" "preview-formatter.sh not yet implemented"
    return
  fi

  source "$PREVIEW_FORMATTER"

  local summary="Summary text"
  local full_content="Full text"
  local preview=$(format_preview "$summary" "$full_content")

  # Separator should be between summary and content
  # Extract positions
  if echo "$preview" | grep -q "Summary text"; then
    local before_sep=$(echo "$preview" | sed -n '/Summary text/,/---/p')
    local after_sep=$(echo "$preview" | sed -n '/---/,/Full text/p')

    if [ -n "$before_sep" ] && [ -n "$after_sep" ]; then
      pass "Separator correctly placed between summary and content"
    else
      fail "Separator placement incorrect" "between summary and content" "not found"
    fi
  else
    fail "Could not find summary text in preview" "contains summary" "not found"
  fi
}

# Main test execution
main() {
  echo "========================================="
  echo "Preview Formatter Test Suite"
  echo "========================================="
  echo ""

  # Run all tests
  test_separator_present
  test_section_headers
  test_markdown_preserved
  test_summary_before_content
  test_empty_summary
  test_separator_placement

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
