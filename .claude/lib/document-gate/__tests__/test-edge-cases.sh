#!/bin/bash

# Edge Case Tests for Document Gate
# Tests: Empty files, large files, special characters, code-block-only files

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCUMENT_GATE_SH="$SCRIPT_DIR/../document-gate.sh"
TEST_DIR="/tmp/test-edge-cases-$$"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
assert_exit_code() {
  local actual=$1
  local expected=$2
  local message=$3

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ "$actual" -eq "$expected" ]; then
    echo -e "  ${GREEN}✓${NC} $message"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "  ${RED}✗${NC} $message"
    echo -e "    Expected: $expected"
    echo -e "    Actual:   $actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

cleanup() {
  rm -rf "$TEST_DIR"
}

trap cleanup EXIT

# Setup
mkdir -p "$TEST_DIR"

echo "=========================================="
echo "Edge Case Tests - Document Gate"
echo "=========================================="
echo ""

#############################################
# Test 1: Empty files
#############################################

test_empty_files() {
  echo -e "\n${YELLOW}[TEST 1]${NC} Empty files"

  # Create feature with empty files
  mkdir -p "$TEST_DIR/empty-files"
  touch "$TEST_DIR/empty-files/spec.md"
  touch "$TEST_DIR/empty-files/plan.md"
  touch "$TEST_DIR/empty-files/tasks.md"

  # Run document-gate
  set +e
  bash "$DOCUMENT_GATE_SH" "$TEST_DIR/empty-files" > /dev/null 2>&1
  local exit_code=$?
  set -e

  # Empty files should fail with exit code 3 (missing required sections)
  assert_exit_code "$exit_code" 3 "Empty files should fail with missing sections"
}

#############################################
# Test 2: Large files (1000+ lines)
#############################################

test_large_files() {
  echo -e "\n${YELLOW}[TEST 2]${NC} Large files (1000+ lines)"

  # Create feature directory
  mkdir -p "$TEST_DIR/large-files"

  # Create large spec.md (1500 lines)
  {
    echo "## 📋 Feature 정보"
    echo "Feature info"
    echo ""
    echo "## 🎯 Overview"
    echo "Overview content"
    echo ""
    echo "## 🎬 User Scenarios & Testing"
    echo "Testing scenarios"
    echo ""

    # Add 1400 filler lines
    for i in {1..1400}; do
      echo "Line $i content"
    done

    echo ""
    echo "## 🔍 Key Entities"
    echo "Key entities"
    echo ""
    echo "## ✅ Success Criteria"
    echo "Success criteria"
  } > "$TEST_DIR/large-files/spec.md"

  # Create normal plan.md
  {
    echo "## Technical Foundation"
    echo "Foundation"
    echo "## Constitution Check"
    echo "Constitution"
    echo "## Phase 1: Design Artifacts"
    echo "Design"
    echo "## Implementation Phases"
    echo "Implementation"
    echo "## Performance Targets"
    echo "Performance"
  } > "$TEST_DIR/large-files/plan.md"

  # Create normal tasks.md
  {
    echo "## Phase 1:"
    echo "Phase 1 tasks"
    echo "### Tests (Write FIRST - TDD)"
    echo "Test tasks"
    echo "### Implementation (AFTER tests)"
    echo "Implementation tasks"
  } > "$TEST_DIR/large-files/tasks.md"

  # Run document-gate with performance measurement
  set +e
  local start_time=$(date +%s)
  bash "$DOCUMENT_GATE_SH" "$TEST_DIR/large-files" > /dev/null 2>&1
  local exit_code=$?
  local end_time=$(date +%s)
  local elapsed=$((end_time - start_time))
  set -e

  # Should pass (all sections present)
  assert_exit_code "$exit_code" 0 "Large files should pass validation"

  # Performance check: should complete in < 2 seconds (relaxed for macOS)
  if [ "$elapsed" -le 2 ]; then
    echo -e "  ${GREEN}✓${NC} Performance: ${elapsed}s (<= 2s target)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "  ${RED}✗${NC} Performance: ${elapsed}s (exceeds 2s target)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

#############################################
# Test 3: Special characters in content
#############################################

test_special_characters() {
  echo -e "\n${YELLOW}[TEST 3]${NC} Special characters in content"

  # Create feature directory
  mkdir -p "$TEST_DIR/special-chars"

  # Create spec.md with special characters
  cat > "$TEST_DIR/special-chars/spec.md" << 'EOF'
## 📋 Feature 정보
Feature with special chars: $, *, &, |, <, >, \, ", '

## 🎯 Overview
Unicode: 한글, 日本語, 中文, Emoji: 🚀 🎉 ✅

## 🎬 User Scenarios & Testing
Regex special chars: ^, $, *, +, ?, ., [, ], {, }, (, ), |, \

## 🔍 Key Entities
Escape sequences: \n, \t, \r, \\, \", \'

## ✅ Success Criteria
Success criteria
EOF

  # Create plan.md
  cat > "$TEST_DIR/special-chars/plan.md" << 'EOF'
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

  # Create tasks.md
  cat > "$TEST_DIR/special-chars/tasks.md" << 'EOF'
## Phase 1:
Phase 1 tasks

### Tests (Write FIRST - TDD)
Test tasks

### Implementation (AFTER tests)
Implementation tasks
EOF

  # Run document-gate
  set +e
  bash "$DOCUMENT_GATE_SH" "$TEST_DIR/special-chars" > /dev/null 2>&1
  local exit_code=$?
  set -e

  # Should pass (all sections present, special chars are valid content)
  assert_exit_code "$exit_code" 0 "Special characters should not cause failures"
}

#############################################
# Test 4: Code block only files
#############################################

test_code_block_only() {
  echo -e "\n${YELLOW}[TEST 4]${NC} Code block only files"

  # Create feature directory
  mkdir -p "$TEST_DIR/code-only"

  # Create spec.md with only code blocks
  cat > "$TEST_DIR/code-only/spec.md" << 'EOF'
## 📋 Feature 정보
Feature info

## 🎯 Overview
Overview content

## 🎬 User Scenarios & Testing

```javascript
function example() {
  const placeholder = "{value}";
  // TODO: implement this
  return placeholder;
}
```

## 🔍 Key Entities

```json
{
  "entity": "{entity_id}",
  "status": "TODO"
}
```

## ✅ Success Criteria
Success criteria
EOF

  # Create plan.md
  cat > "$TEST_DIR/code-only/plan.md" << 'EOF'
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

  # Create tasks.md
  cat > "$TEST_DIR/code-only/tasks.md" << 'EOF'
## Phase 1:
Phase 1 tasks

### Tests (Write FIRST - TDD)
Test tasks

### Implementation (AFTER tests)
Implementation tasks
EOF

  # Run document-gate
  set +e
  bash "$DOCUMENT_GATE_SH" "$TEST_DIR/code-only" > /dev/null 2>&1
  local exit_code=$?
  set -e

  # Should pass (placeholders in code blocks are ignored)
  assert_exit_code "$exit_code" 0 "Placeholders in code blocks should be ignored"
}

#############################################
# Test 5: Mixed code blocks and text placeholders
#############################################

test_mixed_content() {
  echo -e "\n${YELLOW}[TEST 5]${NC} Mixed code blocks and text placeholders"

  # Create feature directory
  mkdir -p "$TEST_DIR/mixed"

  # Create spec.md with both code blocks and text placeholders
  cat > "$TEST_DIR/mixed/spec.md" << 'EOF'
## 📋 Feature 정보
Feature info

## 🎯 Overview
Overview content

## 🎬 User Scenarios & Testing

Normal text with {placeholder} - should be detected

```javascript
// This {placeholder} should be ignored
const code = "{value}";
```

Another TODO: in text - should be detected

```bash
# TODO: implement this - should be ignored
```

## 🔍 Key Entities
Key entities

## ✅ Success Criteria
Success criteria
EOF

  # Create plan.md
  cat > "$TEST_DIR/mixed/plan.md" << 'EOF'
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

  # Create tasks.md
  cat > "$TEST_DIR/mixed/tasks.md" << 'EOF'
## Phase 1:
Phase 1 tasks

### Tests (Write FIRST - TDD)
Test tasks

### Implementation (AFTER tests)
Implementation tasks
EOF

  # Run document-gate
  set +e
  bash "$DOCUMENT_GATE_SH" "$TEST_DIR/mixed" > /dev/null 2>&1
  local exit_code=$?
  set -e

  # Should fail with exit code 2 (placeholders in text detected)
  assert_exit_code "$exit_code" 2 "Text placeholders should be detected even with code blocks"
}

#############################################
# Test 6: Only whitespace in files
#############################################

test_whitespace_only() {
  echo -e "\n${YELLOW}[TEST 6]${NC} Only whitespace in files"

  # Create feature directory
  mkdir -p "$TEST_DIR/whitespace"

  # Create files with only whitespace
  printf "   \n\n\t\t\n   \n" > "$TEST_DIR/whitespace/spec.md"
  printf "   \n\n\t\t\n   \n" > "$TEST_DIR/whitespace/plan.md"
  printf "   \n\n\t\t\n   \n" > "$TEST_DIR/whitespace/tasks.md"

  # Run document-gate
  set +e
  bash "$DOCUMENT_GATE_SH" "$TEST_DIR/whitespace" > /dev/null 2>&1
  local exit_code=$?
  set -e

  # Should fail with exit code 3 (missing sections)
  assert_exit_code "$exit_code" 3 "Whitespace-only files should fail validation"
}

#############################################
# Test 7: Nested code blocks
#############################################

test_nested_code_blocks() {
  echo -e "\n${YELLOW}[TEST 7]${NC} Nested code blocks in markdown"

  # Create feature directory
  mkdir -p "$TEST_DIR/nested"

  # Create spec.md with nested code blocks (markdown in code blocks)
  cat > "$TEST_DIR/nested/spec.md" << 'EOF'
## 📋 Feature 정보
Feature info

## 🎯 Overview
Overview content

## 🎬 User Scenarios & Testing

Example of markdown file:

```markdown
# Example Document

Replace {placeholder} with actual value

TODO: Complete this section
```

The above placeholders should be ignored (in code block).

## 🔍 Key Entities
Key entities

## ✅ Success Criteria
Success criteria
EOF

  # Create plan.md
  cat > "$TEST_DIR/nested/plan.md" << 'EOF'
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

  # Create tasks.md
  cat > "$TEST_DIR/nested/tasks.md" << 'EOF'
## Phase 1:
Phase 1 tasks

### Tests (Write FIRST - TDD)
Test tasks

### Implementation (AFTER tests)
Implementation tasks
EOF

  # Run document-gate
  set +e
  bash "$DOCUMENT_GATE_SH" "$TEST_DIR/nested" > /dev/null 2>&1
  local exit_code=$?
  set -e

  # Should pass (nested placeholders in code blocks are ignored)
  assert_exit_code "$exit_code" 0 "Nested code blocks should be handled correctly"
}

#############################################
# Run all tests
#############################################

test_empty_files
test_large_files
test_special_characters
test_code_block_only
test_mixed_content
test_whitespace_only
test_nested_code_blocks

#############################################
# Summary
#############################################

echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo ""
echo "Tests run:    $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
  echo -e "${GREEN}✅ All edge case tests passed!${NC}"
  exit 0
else
  echo -e "${RED}❌ Some tests failed${NC}"
  exit 1
fi
