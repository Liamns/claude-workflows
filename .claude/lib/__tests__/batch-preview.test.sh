#!/bin/bash
# Test suite for batch-preview.sh
# Testing batch preview generation for multiple documents

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

# Source the module to test (will be created in T013)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BATCH_PREVIEW="$SCRIPT_DIR/../document-preview/batch-preview.sh"

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
  TEST_DIR="/tmp/batch-preview-test-$$"
  mkdir -p "$TEST_DIR"

  # Document 1: spec.md
  cat > "$TEST_DIR/spec.md" <<'EOF'
# Specification Document

## Overview
This is a sample specification for batch preview testing.

## Functional Requirements
- FR-001: Generate batch previews
- FR-002: Handle multiple documents
- FR-003: Error handling for individual failures
EOF

  # Document 2: tasks.md
  cat > "$TEST_DIR/tasks.md" <<'EOF'
# Tasks Document

## Overview
Task list for batch preview implementation.

## Task List
- T001: Create batch preview generator
- T002: Test batch processing
- T003: Optimize performance
EOF

  # Document 3: epic.md
  cat > "$TEST_DIR/epic.md" <<'EOF'
# Epic Document

## Overview
Epic for planning document UX improvement.

## Features
- Feature 1: Document summaries
- Feature 2: User consent
- Feature 3: Batch processing
EOF

  # Document 4: Empty file (edge case)
  touch "$TEST_DIR/empty.md"

  # Document 5: Very long content
  cat > "$TEST_DIR/long.md" <<'EOF'
# Long Document

## Overview
This is a very long document with extensive content for testing truncation and performance.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
EOF
  # Add more content
  for i in {1..10}; do
    echo "Section $i: More content here..." >> "$TEST_DIR/long.md"
  done
}

cleanup_test_files() {
  rm -rf "$TEST_DIR"
}

# Test 1: Generate batch preview for single document
test_batch_preview_single_document() {
  if [ ! -f "$BATCH_PREVIEW" ]; then
    skip "test_batch_preview_single_document" "batch-preview.sh not yet implemented"
    return 0
  fi

  source "$BATCH_PREVIEW"

  # Source dependencies
  source "$SCRIPT_DIR/../document-preview/document-collection.sh" 2>/dev/null || true
  source "$SCRIPT_DIR/../document-preview/summary-generator.sh" 2>/dev/null || true
  source "$SCRIPT_DIR/../document-preview/preview-formatter.sh" 2>/dev/null || true

  local collection=$(create_document_collection 2>/dev/null)
  add_document_to_collection "$collection" "$TEST_DIR/spec.md" 2>/dev/null

  local result
  result=$(generate_batch_preview "$collection" 2>/dev/null)
  local exit_code=$?

  if [ $exit_code -eq 0 ] && [ -n "$result" ]; then
    pass "Batch preview generated for single document"
  else
    fail "Should generate batch preview" "exit 0 with result" "exit $exit_code"
  fi

  return 0
}

# Test 2: Generate batch preview for multiple documents
test_batch_preview_multiple_documents() {
  if [ ! -f "$BATCH_PREVIEW" ]; then
    skip "test_batch_preview_multiple_documents" "batch-preview.sh not yet implemented"
    return 0
  fi

  source "$BATCH_PREVIEW"

  # Source dependencies
  source "$SCRIPT_DIR/../document-preview/document-collection.sh" 2>/dev/null || true

  local collection=$(create_document_collection 2>/dev/null)
  add_document_to_collection "$collection" "$TEST_DIR/spec.md" 2>/dev/null
  add_document_to_collection "$collection" "$TEST_DIR/tasks.md" 2>/dev/null
  add_document_to_collection "$collection" "$TEST_DIR/epic.md" 2>/dev/null

  local result
  result=$(generate_batch_preview "$collection" 2>/dev/null)
  local exit_code=$?

  if [ $exit_code -eq 0 ] && [ -n "$result" ]; then
    pass "Batch preview generated for multiple documents"
  else
    fail "Should generate batch preview for 3 documents" "exit 0 with result" "exit $exit_code"
  fi

  return 0
}

# Test 3: Empty collection handling
test_batch_preview_empty_collection() {
  if [ ! -f "$BATCH_PREVIEW" ]; then
    skip "test_batch_preview_empty_collection" "batch-preview.sh not yet implemented"
    return 0
  fi

  source "$BATCH_PREVIEW"

  # Source dependencies
  source "$SCRIPT_DIR/../document-preview/document-collection.sh" 2>/dev/null || true

  local collection=$(create_document_collection 2>/dev/null)

  local result
  result=$(generate_batch_preview "$collection" 2>/dev/null)
  local exit_code=$?

  # Should either return empty result or error
  if [ $exit_code -ne 0 ] || [ -z "$result" ]; then
    pass "Empty collection handled gracefully"
  else
    fail "Empty collection should be handled" "empty or error" "got result: '$result'"
  fi

  return 0
}

# Test 4: Individual document failure doesn't stop batch
test_batch_preview_partial_failure() {
  if [ ! -f "$BATCH_PREVIEW" ]; then
    skip "test_batch_preview_partial_failure" "batch-preview.sh not yet implemented"
    return 0
  fi

  source "$BATCH_PREVIEW"

  # Source dependencies
  source "$SCRIPT_DIR/../document-preview/document-collection.sh" 2>/dev/null || true

  local collection=$(create_document_collection 2>/dev/null)
  add_document_to_collection "$collection" "$TEST_DIR/spec.md" 2>/dev/null
  add_document_to_collection "$collection" "$TEST_DIR/nonexistent.md" 2>/dev/null  # This will fail
  add_document_to_collection "$collection" "$TEST_DIR/tasks.md" 2>/dev/null

  local result
  result=$(generate_batch_preview "$collection" 2>/dev/null)
  local exit_code=$?

  # Should succeed with partial results (2 out of 3)
  # or fail gracefully
  if [ $exit_code -eq 0 ] || [ -n "$result" ]; then
    pass "Partial failure handled gracefully"
  else
    fail "Partial failure should not stop batch" "success or partial result" "exit $exit_code"
  fi

  return 0
}

# Test 5: Preview result format
test_batch_preview_result_format() {
  if [ ! -f "$BATCH_PREVIEW" ]; then
    skip "test_batch_preview_result_format" "batch-preview.sh not yet implemented"
    return 0
  fi

  source "$BATCH_PREVIEW"

  # Source dependencies
  source "$SCRIPT_DIR/../document-preview/document-collection.sh" 2>/dev/null || true

  local collection=$(create_document_collection 2>/dev/null)
  add_document_to_collection "$collection" "$TEST_DIR/spec.md" 2>/dev/null

  local result
  result=$(generate_batch_preview "$collection" 2>/dev/null)

  # Result should contain file path and preview content
  if [[ "$result" =~ "spec.md" ]]; then
    pass "Preview result contains file path"
  else
    fail "Result should contain file path" "contains 'spec.md'" "got: '$result'"
  fi

  return 0
}

# Test 6: Get preview for specific document from batch
test_get_document_preview_from_batch() {
  if [ ! -f "$BATCH_PREVIEW" ]; then
    skip "test_get_document_preview_from_batch" "batch-preview.sh not yet implemented"
    return 0
  fi

  source "$BATCH_PREVIEW"

  # Source dependencies
  source "$SCRIPT_DIR/../document-preview/document-collection.sh" 2>/dev/null || true

  local collection=$(create_document_collection 2>/dev/null)
  add_document_to_collection "$collection" "$TEST_DIR/spec.md" 2>/dev/null
  add_document_to_collection "$collection" "$TEST_DIR/tasks.md" 2>/dev/null

  # Generate batch preview first
  local batch_result
  batch_result=$(generate_batch_preview "$collection" 2>/dev/null)

  # Get specific document preview
  if declare -f get_document_preview_from_batch >/dev/null 2>&1; then
    local preview
    preview=$(get_document_preview_from_batch "$batch_result" "$TEST_DIR/spec.md" 2>/dev/null)

    if [ -n "$preview" ]; then
      pass "Retrieved specific document preview from batch"
    else
      fail "Should retrieve specific preview" "non-empty preview" "empty"
    fi
  else
    skip "get_document_preview_from_batch" "function not implemented"
  fi

  return 0
}

# Test 7: Batch preview progress tracking
test_batch_preview_progress() {
  if [ ! -f "$BATCH_PREVIEW" ]; then
    skip "test_batch_preview_progress" "batch-preview.sh not yet implemented"
    return 0
  fi

  source "$BATCH_PREVIEW"

  # This would require callback or logging mechanism
  skip "test_batch_preview_progress" "Progress tracking requires callback implementation"

  return 0
}

# Test 8: Batch preview with custom max_length
test_batch_preview_custom_max_length() {
  if [ ! -f "$BATCH_PREVIEW" ]; then
    skip "test_batch_preview_custom_max_length" "batch-preview.sh not yet implemented"
    return 0
  fi

  source "$BATCH_PREVIEW"

  # Source dependencies
  source "$SCRIPT_DIR/../document-preview/document-collection.sh" 2>/dev/null || true

  local collection=$(create_document_collection 2>/dev/null)
  add_document_to_collection "$collection" "$TEST_DIR/long.md" 2>/dev/null

  # Generate with custom max_length (e.g., 150)
  local result
  result=$(generate_batch_preview "$collection" 150 2>/dev/null)
  local exit_code=$?

  if [ $exit_code -eq 0 ]; then
    pass "Batch preview with custom max_length generated"
  else
    fail "Should generate with custom max_length" "exit 0" "exit $exit_code"
  fi

  return 0
}

# Test 9: Concurrent processing (if supported)
test_batch_preview_concurrent() {
  if [ ! -f "$BATCH_PREVIEW" ]; then
    skip "test_batch_preview_concurrent" "batch-preview.sh not yet implemented"
    return 0
  fi

  source "$BATCH_PREVIEW"

  skip "test_batch_preview_concurrent" "Concurrent processing is optional feature"

  return 0
}

# Test 10: Batch preview result caching
test_batch_preview_caching() {
  if [ ! -f "$BATCH_PREVIEW" ]; then
    skip "test_batch_preview_caching" "batch-preview.sh not yet implemented"
    return 0
  fi

  source "$BATCH_PREVIEW"

  skip "test_batch_preview_caching" "Caching is optional feature"

  return 0
}

# Main test execution
main() {
  echo "========================================="
  echo "Batch Preview Test Suite"
  echo "========================================="
  echo ""

  setup_test_files

  # Run all tests
  echo "Running test 1..." >&2
  test_batch_preview_single_document
  echo "Running test 2..." >&2
  test_batch_preview_multiple_documents
  echo "Running test 3..." >&2
  test_batch_preview_empty_collection
  echo "Running test 4..." >&2
  test_batch_preview_partial_failure
  echo "Running test 5..." >&2
  test_batch_preview_result_format
  echo "Running test 6..." >&2
  test_get_document_preview_from_batch
  echo "Running test 7..." >&2
  test_batch_preview_progress
  echo "Running test 8..." >&2
  test_batch_preview_custom_max_length
  echo "Running test 9..." >&2
  test_batch_preview_concurrent
  echo "Running test 10..." >&2
  test_batch_preview_caching

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
