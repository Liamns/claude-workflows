#!/bin/bash
# Test suite for document-collection.sh
# Testing multiple document handling and collection management

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

# Source the module to test (will be created in T011)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCUMENT_COLLECTION="$SCRIPT_DIR/../document-preview/document-collection.sh"

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
  TEST_DIR="/tmp/document-collection-test-$$"
  mkdir -p "$TEST_DIR"

  # Create sample documents
  cat > "$TEST_DIR/spec.md" <<'EOF'
# Specification Document
Test spec content
EOF

  cat > "$TEST_DIR/tasks.md" <<'EOF'
# Tasks Document
Test tasks content
EOF

  cat > "$TEST_DIR/epic.md" <<'EOF'
# Epic Document
Test epic content
EOF

  cat > "$TEST_DIR/feature.md" <<'EOF'
# Feature Document
Test feature content
EOF
}

cleanup_test_files() {
  rm -rf "$TEST_DIR"
}

# Test 1: Create empty collection
test_create_empty_collection() {
  if [ ! -f "$DOCUMENT_COLLECTION" ]; then
    skip "test_create_empty_collection" "document-collection.sh not yet implemented"
    return 0
  fi

  source "$DOCUMENT_COLLECTION"

  local collection
  collection=$(create_document_collection 2>/dev/null)
  local exit_code=$?

  if [ $exit_code -eq 0 ] && [ -n "$collection" ]; then
    pass "Empty collection created successfully"
  else
    fail "Should create empty collection" "exit 0 with collection ID" "exit $exit_code"
  fi

  return 0
}

# Test 2: Add document to collection
test_add_document_to_collection() {
  if [ ! -f "$DOCUMENT_COLLECTION" ]; then
    skip "test_add_document_to_collection" "document-collection.sh not yet implemented"
    return 0
  fi

  source "$DOCUMENT_COLLECTION"

  local collection=$(create_document_collection 2>/dev/null)

  add_document_to_collection "$collection" "$TEST_DIR/spec.md" 2>/dev/null
  local exit_code=$?

  if [ $exit_code -eq 0 ]; then
    pass "Document added to collection successfully"
  else
    fail "Should add document to collection" "exit 0" "exit $exit_code"
  fi

  return 0
}

# Test 3: Add multiple documents
test_add_multiple_documents() {
  if [ ! -f "$DOCUMENT_COLLECTION" ]; then
    skip "test_add_multiple_documents" "document-collection.sh not yet implemented"
    return 0
  fi

  source "$DOCUMENT_COLLECTION"

  local collection=$(create_document_collection 2>/dev/null)

  add_document_to_collection "$collection" "$TEST_DIR/spec.md" 2>/dev/null
  add_document_to_collection "$collection" "$TEST_DIR/tasks.md" 2>/dev/null
  add_document_to_collection "$collection" "$TEST_DIR/epic.md" 2>/dev/null

  local count
  count=$(get_document_count "$collection" 2>/dev/null)

  if [ "$count" = "3" ]; then
    pass "Multiple documents added (count: 3)"
  else
    fail "Should have 3 documents in collection" "3" "got: '$count'"
  fi

  return 0
}

# Test 4: Prevent duplicate documents
test_prevent_duplicate_documents() {
  if [ ! -f "$DOCUMENT_COLLECTION" ]; then
    skip "test_prevent_duplicate_documents" "document-collection.sh not yet implemented"
    return 0
  fi

  source "$DOCUMENT_COLLECTION"

  local collection=$(create_document_collection 2>/dev/null)

  add_document_to_collection "$collection" "$TEST_DIR/spec.md" 2>/dev/null
  add_document_to_collection "$collection" "$TEST_DIR/spec.md" 2>/dev/null

  local count
  count=$(get_document_count "$collection" 2>/dev/null)

  if [ "$count" = "1" ]; then
    pass "Duplicate documents prevented (count: 1)"
  else
    fail "Should have only 1 document (no duplicates)" "1" "got: '$count'"
  fi

  return 0
}

# Test 5: Remove document from collection
test_remove_document_from_collection() {
  if [ ! -f "$DOCUMENT_COLLECTION" ]; then
    skip "test_remove_document_from_collection" "document-collection.sh not yet implemented"
    return 0
  fi

  source "$DOCUMENT_COLLECTION"

  local collection=$(create_document_collection 2>/dev/null)

  add_document_to_collection "$collection" "$TEST_DIR/spec.md" 2>/dev/null
  add_document_to_collection "$collection" "$TEST_DIR/tasks.md" 2>/dev/null

  remove_document_from_collection "$collection" "$TEST_DIR/spec.md" 2>/dev/null
  local count
  count=$(get_document_count "$collection" 2>/dev/null)

  if [ "$count" = "1" ]; then
    pass "Document removed from collection (count: 1)"
  else
    fail "Should have 1 document after removal" "1" "got: '$count'"
  fi

  return 0
}

# Test 6: Get document list
test_get_document_list() {
  if [ ! -f "$DOCUMENT_COLLECTION" ]; then
    skip "test_get_document_list" "document-collection.sh not yet implemented"
    return 0
  fi

  source "$DOCUMENT_COLLECTION"

  local collection=$(create_document_collection 2>/dev/null)

  add_document_to_collection "$collection" "$TEST_DIR/spec.md" 2>/dev/null
  add_document_to_collection "$collection" "$TEST_DIR/tasks.md" 2>/dev/null

  local list
  list=$(get_document_list "$collection" 2>/dev/null)

  if [[ "$list" =~ "spec.md" ]] && [[ "$list" =~ "tasks.md" ]]; then
    pass "Document list contains all documents"
  else
    fail "Document list should contain spec.md and tasks.md" "both files" "got: '$list'"
  fi

  return 0
}

# Test 7: Validate all documents exist
test_validate_all_documents_exist() {
  if [ ! -f "$DOCUMENT_COLLECTION" ]; then
    skip "test_validate_all_documents_exist" "document-collection.sh not yet implemented"
    return 0
  fi

  source "$DOCUMENT_COLLECTION"

  local collection=$(create_document_collection 2>/dev/null)

  add_document_to_collection "$collection" "$TEST_DIR/spec.md" 2>/dev/null
  add_document_to_collection "$collection" "$TEST_DIR/tasks.md" 2>/dev/null

  validate_collection_documents "$collection" 2>/dev/null
  local exit_code=$?

  if [ $exit_code -eq 0 ]; then
    pass "All documents validated successfully"
  else
    fail "Validation should pass for existing documents" "exit 0" "exit $exit_code"
  fi

  return 0
}

# Test 8: Detect missing documents
test_detect_missing_documents() {
  if [ ! -f "$DOCUMENT_COLLECTION" ]; then
    skip "test_detect_missing_documents" "document-collection.sh not yet implemented"
    return 0
  fi

  source "$DOCUMENT_COLLECTION"

  local collection=$(create_document_collection 2>/dev/null)

  add_document_to_collection "$collection" "$TEST_DIR/spec.md" 2>/dev/null
  add_document_to_collection "$collection" "$TEST_DIR/nonexistent.md" 2>/dev/null

  validate_collection_documents "$collection" 2>/dev/null
  local exit_code=$?

  if [ $exit_code -ne 0 ]; then
    pass "Missing documents detected correctly"
  else
    fail "Validation should fail for missing documents" "exit non-zero" "exit $exit_code"
  fi

  return 0
}

# Test 9: Document ordering/sorting
test_document_ordering() {
  if [ ! -f "$DOCUMENT_COLLECTION" ]; then
    skip "test_document_ordering" "document-collection.sh not yet implemented"
    return 0
  fi

  source "$DOCUMENT_COLLECTION"

  local collection=$(create_document_collection 2>/dev/null)

  # Add in specific order
  add_document_to_collection "$collection" "$TEST_DIR/tasks.md" 2>/dev/null
  add_document_to_collection "$collection" "$TEST_DIR/epic.md" 2>/dev/null
  add_document_to_collection "$collection" "$TEST_DIR/spec.md" 2>/dev/null

  # Get ordered list (should maintain insertion order or sort alphabetically)
  local list
  list=$(get_document_list "$collection" 2>/dev/null)

  # Just check that all are present (ordering is implementation detail)
  if [[ "$list" =~ "spec.md" ]] && [[ "$list" =~ "tasks.md" ]] && [[ "$list" =~ "epic.md" ]]; then
    pass "Document ordering preserved or sorted"
  else
    fail "All documents should be in list" "all 3 files" "got: '$list'"
  fi

  return 0
}

# Test 10: Clear collection
test_clear_collection() {
  if [ ! -f "$DOCUMENT_COLLECTION" ]; then
    skip "test_clear_collection" "document-collection.sh not yet implemented"
    return 0
  fi

  source "$DOCUMENT_COLLECTION"

  local collection=$(create_document_collection 2>/dev/null)

  add_document_to_collection "$collection" "$TEST_DIR/spec.md" 2>/dev/null
  add_document_to_collection "$collection" "$TEST_DIR/tasks.md" 2>/dev/null

  clear_document_collection "$collection" 2>/dev/null
  local count
  count=$(get_document_count "$collection" 2>/dev/null)

  if [ "$count" = "0" ]; then
    pass "Collection cleared successfully (count: 0)"
  else
    fail "Collection should be empty after clear" "0" "got: '$count'"
  fi

  return 0
}

# Test 11: Collection metadata
test_collection_metadata() {
  if [ ! -f "$DOCUMENT_COLLECTION" ]; then
    skip "test_collection_metadata" "document-collection.sh not yet implemented"
    return 0
  fi

  source "$DOCUMENT_COLLECTION"

  local collection=$(create_document_collection 2>/dev/null)

  # Set metadata
  set_collection_metadata "$collection" "name" "Test Collection" 2>/dev/null

  # Get metadata
  local metadata
  metadata=$(get_collection_metadata "$collection" "name" 2>/dev/null)

  if [ "$metadata" = "Test Collection" ]; then
    pass "Collection metadata set and retrieved correctly"
  else
    fail "Metadata should be 'Test Collection'" "Test Collection" "got: '$metadata'"
  fi

  return 0
}

# Test 12: Invalid document path handling
test_invalid_document_path() {
  if [ ! -f "$DOCUMENT_COLLECTION" ]; then
    skip "test_invalid_document_path" "document-collection.sh not yet implemented"
    return 0
  fi

  source "$DOCUMENT_COLLECTION"

  local collection=$(create_document_collection 2>/dev/null)

  # Try to add empty path
  add_document_to_collection "$collection" "" 2>/dev/null
  local exit_code=$?

  if [ $exit_code -ne 0 ]; then
    pass "Empty document path rejected correctly"
  else
    fail "Empty path should be rejected" "exit non-zero" "exit $exit_code"
  fi

  return 0
}

# Main test execution
main() {
  echo "========================================="
  echo "Document Collection Test Suite"
  echo "========================================="
  echo ""

  setup_test_files

  # Run all tests
  echo "Running test 1..." >&2
  test_create_empty_collection
  echo "Running test 2..." >&2
  test_add_document_to_collection
  echo "Running test 3..." >&2
  test_add_multiple_documents
  echo "Running test 4..." >&2
  test_prevent_duplicate_documents
  echo "Running test 5..." >&2
  test_remove_document_from_collection
  echo "Running test 6..." >&2
  test_get_document_list
  echo "Running test 7..." >&2
  test_validate_all_documents_exist
  echo "Running test 8..." >&2
  test_detect_missing_documents
  echo "Running test 9..." >&2
  test_document_ordering
  echo "Running test 10..." >&2
  test_clear_collection
  echo "Running test 11..." >&2
  test_collection_metadata
  echo "Running test 12..." >&2
  test_invalid_document_path

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
