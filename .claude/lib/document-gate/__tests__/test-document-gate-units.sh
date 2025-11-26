#!/usr/bin/env bash
# Test Framework for Document Gate
# Feature 005: Document Gate - 문서 완성도 검증 시스템
#
# Usage: bash test-document-gate-units.sh

# Note: Do not use 'set -e' in test framework
# Tests may fail, but we want to continue running all tests
set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test data directory
TEST_DIR="/tmp/document-gate-test-$$"

# Path to document-gate.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCUMENT_GATE_SH="$SCRIPT_DIR/document-gate.sh"

# Cleanup on exit
cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Setup test environment
setup() {
  mkdir -p "$TEST_DIR"
  echo -e "${BLUE}[SETUP]${NC} Test directory: $TEST_DIR"
  echo -e "${BLUE}[SETUP]${NC} Document Gate script: $DOCUMENT_GATE_SH"

  # Source the document-gate.sh functions
  if [ -f "$DOCUMENT_GATE_SH" ]; then
    source "$DOCUMENT_GATE_SH"
  else
    echo -e "${RED}ERROR: document-gate.sh not found${NC}"
    exit 1
  fi
}

# Assert functions
assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="${3:-}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ "$actual" = "$expected" ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} $message"
    echo -e "  Expected: '$expected'"
    echo -e "  Actual:   '$actual'"
    return 1
  fi
}

assert_file_exists() {
  local file="$1"
  local message="${2:-File should exist: $file}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ -f "$file" ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} $message"
    return 1
  fi
}

assert_file_not_exists() {
  local file="$1"
  local message="${2:-File should not exist: $file}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ ! -f "$file" ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} $message"
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-String should contain: $needle}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$haystack" == *"$needle"* ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} $message"
    echo -e "  Haystack: '$haystack'"
    echo -e "  Needle:   '$needle'"
    return 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-String should not contain: $needle}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$haystack" != *"$needle"* ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} $message"
    return 1
  fi
}

assert_exit_code() {
  local actual_code="$1"
  local expected_code="$2"
  local message="${3:-Exit code should be $expected_code}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ "$actual_code" -eq "$expected_code" ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} $message"
    echo -e "  Expected: $expected_code"
    echo -e "  Actual:   $actual_code"
    return 1
  fi
}

# Test helper: Create test files
create_test_file() {
  local file="$1"
  local content="$2"
  echo "$content" > "$file"
}

# Print test report
print_report() {
  echo ""
  echo "=========================================="
  echo "Test Results"
  echo "=========================================="
  echo -e "Tests run:    ${BLUE}$TESTS_RUN${NC}"
  echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
  echo ""

  if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    return 0
  else
    echo -e "${RED}❌ Some tests failed${NC}"
    return 1
  fi
}

# ============================================
# Test Cases (TDD - These will fail initially)
# ============================================

# T002: 파일 존재 검증 테스트
test_validate_file_existence_all_present() {
  echo -e "\n${YELLOW}[TEST]${NC} T002: File existence validation - all files present"

  # Setup: Create all required files
  mkdir -p "$TEST_DIR/feature-001"
  create_test_file "$TEST_DIR/feature-001/spec.md" "# Spec"
  create_test_file "$TEST_DIR/feature-001/plan.md" "# Plan"
  create_test_file "$TEST_DIR/feature-001/tasks.md" "# Tasks"

  # Test: Call validate_file_existence
  set +e  # Allow function to fail
  validate_file_existence "$TEST_DIR/feature-001"
  local exit_code=$?
  set -e

  # Assert: Should return 0 (success)
  assert_exit_code "$exit_code" 0 "All files present should return success (0)"
}

test_validate_file_existence_missing_file() {
  echo -e "\n${YELLOW}[TEST]${NC} T002: File existence validation - missing file"

  # Setup: Create only spec.md and plan.md (missing tasks.md)
  mkdir -p "$TEST_DIR/feature-002"
  create_test_file "$TEST_DIR/feature-002/spec.md" "# Spec"
  create_test_file "$TEST_DIR/feature-002/plan.md" "# Plan"

  # Test: Call validate_file_existence
  set +e  # Allow function to fail
  validate_file_existence "$TEST_DIR/feature-002"
  local exit_code=$?
  set -e

  # Assert: Should return 1 (failure)
  assert_exit_code "$exit_code" 1 "Missing tasks.md should return failure (1)"
}

# T003: 플레이스홀더 감지 테스트
test_validate_placeholders_found() {
  echo -e "\n${YELLOW}[TEST]${NC} T003: Placeholder detection - placeholders found"

  # Setup: Create feature with placeholder
  mkdir -p "$TEST_DIR/feature-003"
  create_test_file "$TEST_DIR/feature-003/spec.md" "Replace {placeholder} here"
  create_test_file "$TEST_DIR/feature-003/plan.md" "# Plan"
  create_test_file "$TEST_DIR/feature-003/tasks.md" "# Tasks"

  # Test: Call validate_placeholders
  set +e
  validate_placeholders "$TEST_DIR/feature-003"
  local exit_code=$?
  set -e

  # Assert: Should return 2 (placeholder found)
  assert_exit_code "$exit_code" 2 "Placeholders found should return 2"
}

test_validate_placeholders_not_found() {
  echo -e "\n${YELLOW}[TEST]${NC} T003: Placeholder detection - no placeholders"

  # Setup: Create feature without placeholders
  mkdir -p "$TEST_DIR/feature-004"
  create_test_file "$TEST_DIR/feature-004/spec.md" "This is complete content"
  create_test_file "$TEST_DIR/feature-004/plan.md" "# Plan"
  create_test_file "$TEST_DIR/feature-004/tasks.md" "# Tasks"

  # Test: Call validate_placeholders
  set +e
  validate_placeholders "$TEST_DIR/feature-004"
  local exit_code=$?
  set -e

  # Assert: Should return 0 (no placeholders)
  assert_exit_code "$exit_code" 0 "No placeholders should return 0"
}

test_validate_placeholders_in_code_block() {
  echo -e "\n${YELLOW}[TEST]${NC} T011: Placeholder detection - code block exclusion"

  # Setup: Create file with placeholders in code block (should be ignored)
  mkdir -p "$TEST_DIR/feature-005"
  create_test_file "$TEST_DIR/feature-005/spec.md" '# Normal text
Replace {placeholder} here

# Code block
```json
{"key": "{value}"}
```'
  create_test_file "$TEST_DIR/feature-005/plan.md" "# Plan"
  create_test_file "$TEST_DIR/feature-005/tasks.md" "# Tasks"

  # Test: Call validate_placeholders and capture output
  set +e
  local output
  output=$(validate_placeholders "$TEST_DIR/feature-005" 2>&1)
  local exit_code=$?
  set -e

  # Assert 1: Should return 2 (placeholder found in normal text)
  assert_exit_code "$exit_code" 2 "Should detect placeholder in normal text (exit 2)"

  # Assert 2: Output should NOT contain line 6 (code block content)
  # Line 6 is: {"key": "{value}"}
  if [[ "$output" != *'Line 6'* ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} Code block content excluded from detection"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} Code block content should be excluded"
    echo -e "  Output contains: Line 6 (code block)"
  fi
  TESTS_RUN=$((TESTS_RUN + 1))

  # Assert 3: Output should contain line 2 (normal text placeholder)
  assert_contains "$output" "Line 2" "Should detect placeholder at Line 2 (normal text)"
}

# T004: 필수 섹션 검증 테스트
test_validate_required_sections_all_present() {
  echo -e "\n${YELLOW}[TEST]${NC} T004: Required sections - all present"

  # Setup: Create feature with all required sections
  mkdir -p "$TEST_DIR/feature-006"
  create_test_file "$TEST_DIR/feature-006/spec.md" '## 📋 Feature 정보
## 🎯 Overview
## 🎬 User Scenarios & Testing
## 🔍 Key Entities
## ✅ Success Criteria'
  create_test_file "$TEST_DIR/feature-006/plan.md" '## Technical Foundation
## Constitution Check
## Phase 1: Design Artifacts
## Implementation Phases
## Performance Targets'
  create_test_file "$TEST_DIR/feature-006/tasks.md" '## Phase 1:
### Tests (Write FIRST - TDD)
### Implementation (AFTER tests)'

  # Test: Call validate_required_sections
  set +e
  validate_required_sections "$TEST_DIR/feature-006"
  local exit_code=$?
  set -e

  # Assert: Should return 0 (all sections present)
  assert_exit_code "$exit_code" 0 "All required sections should return 0"
}

test_validate_required_sections_missing() {
  echo -e "\n${YELLOW}[TEST]${NC} T004: Required sections - missing sections"

  # Setup: Create feature with missing sections
  mkdir -p "$TEST_DIR/feature-007"
  create_test_file "$TEST_DIR/feature-007/spec.md" '## 📋 Feature 정보
## 🎯 Overview'
  create_test_file "$TEST_DIR/feature-007/plan.md" "# Incomplete plan"
  create_test_file "$TEST_DIR/feature-007/tasks.md" "# Incomplete tasks"

  # Test: Call validate_required_sections
  set +e
  validate_required_sections "$TEST_DIR/feature-007"
  local exit_code=$?
  set -e

  # Assert: Should return 3 (missing sections)
  assert_exit_code "$exit_code" 3 "Missing sections should return 3"
}

# ============================================
# Main Test Runner
# ============================================

main() {
  echo -e "${BLUE}=========================================="
  echo "Document Gate - Unit Tests"
  echo -e "==========================================${NC}"

  setup

  # Run tests (allow failures - collect results)
  test_validate_file_existence_all_present || true
  test_validate_file_existence_missing_file || true
  test_validate_placeholders_found || true
  test_validate_placeholders_not_found || true
  test_validate_placeholders_in_code_block || true
  test_validate_required_sections_all_present || true
  test_validate_required_sections_missing || true

  # Print report
  print_report
}

# Run tests
main
