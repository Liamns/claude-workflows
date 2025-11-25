#!/usr/bin/env bash
# Integration Test for Document Gate
# Feature 005: Document Gate - 문서 완성도 검증 시스템
#
# Usage: bash test-document-gate-integration.sh

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

# Path to document-gate.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCUMENT_GATE_SH="$SCRIPT_DIR/document-gate.sh"

# Test directories
PROJECT_ROOT="/Users/hk/Documents/claude-workflow"
FEATURE_004_DIR="$PROJECT_ROOT/.specify/epics/006-token-optimization-hybrid/features/004-project-indexing"
FEATURE_005_DIR="$PROJECT_ROOT/.specify/epics/006-token-optimization-hybrid/features/005-document-gate"

# Test data directory
TEST_DIR="/tmp/document-gate-integration-$$"

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
  echo ""
}

# Assert functions
assert_exit_code() {
  local actual_code="$1"
  local expected_code="$2"
  local message="${3:-}"

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

# Print test report
print_report() {
  echo ""
  echo "=========================================="
  echo "Integration Test Results"
  echo "=========================================="
  echo -e "Tests run:    ${BLUE}$TESTS_RUN${NC}"
  echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
  echo ""

  if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}✅ All integration tests passed!${NC}"
    return 0
  else
    echo -e "${RED}❌ Some integration tests failed${NC}"
    return 1
  fi
}

# ============================================
# Integration Test Cases
# ============================================

# Test 1: Complete feature documents (should pass)
test_complete_feature() {
  echo -e "${YELLOW}[TEST 1]${NC} Complete feature documents (Feature 004)"

  # Create complete feature documents
  mkdir -p "$TEST_DIR/complete-feature"

  cat > "$TEST_DIR/complete-feature/spec.md" << 'EOF'
## 📋 Feature 정보
Feature information

## 🎯 Overview
Overview content

## 🎬 User Scenarios & Testing
Testing scenarios

## 🔍 Key Entities
Key entities

## ✅ Success Criteria
Success criteria
EOF

  cat > "$TEST_DIR/complete-feature/plan.md" << 'EOF'
## Technical Foundation
Foundation

## Constitution Check
Constitution

## Phase 1: Design Artifacts
Design

## Implementation Phases
Implementation

## Performance Targets
Performance
EOF

  cat > "$TEST_DIR/complete-feature/tasks.md" << 'EOF'
## Phase 1:
Phase 1 tasks

### Tests (Write FIRST - TDD)
Test tasks

### Implementation (AFTER tests)
Implementation tasks
EOF

  # Run document-gate
  set +e
  bash "$DOCUMENT_GATE_SH" "$TEST_DIR/complete-feature" > /dev/null 2>&1
  local exit_code=$?
  set -e

  # Should pass (exit 0)
  assert_exit_code "$exit_code" 0 "Complete documents should pass validation"
}

# Test 2: Missing file (should fail with exit 1)
test_missing_file() {
  echo -e "\n${YELLOW}[TEST 2]${NC} Missing file (tasks.md)"

  # Create feature with missing tasks.md
  mkdir -p "$TEST_DIR/missing-file"
  echo "# Spec" > "$TEST_DIR/missing-file/spec.md"
  echo "# Plan" > "$TEST_DIR/missing-file/plan.md"

  # Run document-gate
  set +e
  bash "$DOCUMENT_GATE_SH" "$TEST_DIR/missing-file" > /dev/null 2>&1
  local exit_code=$?
  set -e

  # Should fail (exit 1)
  assert_exit_code "$exit_code" 1 "Missing file should fail with exit code 1"
}

# Test 3: Placeholder found (should fail with exit 2)
test_placeholder_found() {
  echo -e "\n${YELLOW}[TEST 3]${NC} Placeholder found"

  # Create feature with placeholder
  mkdir -p "$TEST_DIR/placeholder"
  echo "Replace {placeholder} here" > "$TEST_DIR/placeholder/spec.md"
  echo "# Plan" > "$TEST_DIR/placeholder/plan.md"
  echo "# Tasks" > "$TEST_DIR/placeholder/tasks.md"

  # Run document-gate
  set +e
  bash "$DOCUMENT_GATE_SH" "$TEST_DIR/placeholder" > /dev/null 2>&1
  local exit_code=$?
  set -e

  # Should fail (exit 2)
  assert_exit_code "$exit_code" 2 "Placeholder should fail with exit code 2"
}

# Test 4: Missing sections (should fail with exit 3)
test_missing_sections() {
  echo -e "\n${YELLOW}[TEST 4]${NC} Missing required sections"

  # Create feature with missing sections
  mkdir -p "$TEST_DIR/missing-sections"
  echo "# Incomplete spec" > "$TEST_DIR/missing-sections/spec.md"
  echo "# Incomplete plan" > "$TEST_DIR/missing-sections/plan.md"
  echo "# Incomplete tasks" > "$TEST_DIR/missing-sections/tasks.md"

  # Run document-gate
  set +e
  bash "$DOCUMENT_GATE_SH" "$TEST_DIR/missing-sections" > /dev/null 2>&1
  local exit_code=$?
  set -e

  # Should fail (exit 3)
  assert_exit_code "$exit_code" 3 "Missing sections should fail with exit code 3"
}

# ============================================
# Main Test Runner
# ============================================

main() {
  echo -e "${BLUE}=========================================="
  echo "Document Gate - Integration Tests"
  echo -e "==========================================${NC}"

  setup

  # Run tests (allow failures - collect results)
  test_complete_feature || true
  test_missing_file || true
  test_placeholder_found || true
  test_missing_sections || true

  # Print report
  print_report
}

# Run tests
main
