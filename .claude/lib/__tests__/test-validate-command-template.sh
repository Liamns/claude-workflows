#!/bin/bash
# test-validate-command-template.sh
# Unit test for command template validation
#
# Tests the validate-command-template.sh script which checks if command
# documentation files conform to the required template structure.
#
# Expected template sections:
# 1. Overview - Command description
# 2. Usage - How to use the command
# 3. Examples - Usage examples
# 4. Implementation - Internal details
#
# Test cases:
# 1. Valid template with all required sections → PASS
# 2. Missing required section (e.g., Overview) → FAIL
# 3. Wrong section order → FAIL
# 4. Calculate compliance score (0-100%)
# 5. Empty file → FAIL
# 6. Malformed markdown → FAIL

set -e

# Source common module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# Test counters
TEST_PASSED=0
TEST_FAILED=0

# Colors are already defined in common.sh
# GREEN, RED, NC are readonly variables from common.sh

# ════════════════════════════════════════════════════════════════════════════
# Helper Functions
# ════════════════════════════════════════════════════════════════════════════

run_test() {
    local test_name="$1"
    local test_cmd="$2"
    local expected_exit_code="${3:-0}"

    echo -n "  Testing: $test_name... "

    if eval "$test_cmd" > /dev/null 2>&1; then
        actual_exit_code=0
    else
        actual_exit_code=$?
    fi

    if [[ $actual_exit_code -eq $expected_exit_code ]]; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((TEST_PASSED++)) || true
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo "    Expected exit code: $expected_exit_code, Got: $actual_exit_code"
        ((TEST_FAILED++)) || true
        return 1
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# Setup Test Environment
# ════════════════════════════════════════════════════════════════════════════

setup() {
    log_info "Setting up test environment..."

    # Create temp directory
    TEST_DIR=$(mktemp -d)
    log_info "Test directory: $TEST_DIR"

    # Create valid template file
    cat > "$TEST_DIR/valid-template.md" <<'EOF'
# Command Name

## Overview
This is a sample command that does something useful.
It provides functionality for testing purposes.

## Usage
```bash
/command [options] <args>
```

Options:
- --help: Show help message
- --verbose: Enable verbose mode

## Examples
```bash
# Example 1: Basic usage
/command test

# Example 2: With options
/command --verbose test
```

## Implementation
The command is implemented using bash scripts.
It follows the standard command structure.
EOF

    # Create template with missing Overview section
    cat > "$TEST_DIR/missing-overview.md" <<'EOF'
# Command Name

## Usage
```bash
/command [options]
```

## Examples
```bash
/command test
```

## Implementation
Implementation details here.
EOF

    # Create template with wrong section order
    cat > "$TEST_DIR/wrong-order.md" <<'EOF'
# Command Name

## Usage
Usage details here.

## Overview
Overview should come first!

## Examples
Examples here.

## Implementation
Implementation here.
EOF

    # Create empty file
    touch "$TEST_DIR/empty.md"

    # Create malformed markdown (no header)
    cat > "$TEST_DIR/malformed.md" <<'EOF'
This is not a proper markdown file.
No headers at all.
Just plain text.
EOF

    # Create minimal valid template (for score testing)
    cat > "$TEST_DIR/minimal.md" <<'EOF'
# Minimal

## Overview
Brief overview.

## Usage
Basic usage.
EOF

    log_success "Test environment setup complete"
}

# ════════════════════════════════════════════════════════════════════════════
# Cleanup Test Environment
# ════════════════════════════════════════════════════════════════════════════

cleanup() {
    if [[ -n "${TEST_DIR:-}" ]] && [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
        log_info "Cleaned up test directory"
    fi
}

trap cleanup EXIT

# ════════════════════════════════════════════════════════════════════════════
# Test Cases
# ════════════════════════════════════════════════════════════════════════════

echo ""
log_info "========================================"
log_info "  Template Validation Unit Tests"
log_info "========================================"
echo ""

setup
echo ""

# Validator script path
VALIDATOR="$SCRIPT_DIR/../validate-command-template.sh"

# Test 1: Valid template with all required sections
log_info "Test 1: Valid template with all required sections"
if [[ -f "$VALIDATOR" ]]; then
    run_test "All sections present" \
        "bash '$VALIDATOR' '$TEST_DIR/valid-template.md'" \
        0
else
    log_warning "Validator not found: $VALIDATOR (will be created in T020)"
    echo "  Skipping Test 1-6 (validator not implemented yet)"
    echo ""
fi

if [[ -f "$VALIDATOR" ]]; then
    # Test 2: Missing required section
    log_info "Test 2: Missing required section (Overview)"
    run_test "Missing Overview" \
        "bash '$VALIDATOR' '$TEST_DIR/missing-overview.md'" \
        1

    # Test 3: Wrong section order
    log_info "Test 3: Wrong section order"
    run_test "Incorrect order" \
        "bash '$VALIDATOR' '$TEST_DIR/wrong-order.md'" \
        1

    # Test 4: Calculate compliance score
    log_info "Test 4: Compliance score calculation"
    if bash "$VALIDATOR" --score "$TEST_DIR/valid-template.md" > /dev/null 2>&1; then
        score=$(bash "$VALIDATOR" --score "$TEST_DIR/valid-template.md" 2>/dev/null)
        if [[ "$score" -eq 100 ]]; then
            echo -e "  ${GREEN}✓ PASS${NC} - Score: $score%"
            ((TEST_PASSED++)) || true
        else
            echo -e "  ${RED}✗ FAIL${NC} - Expected 100%, Got: $score%"
            ((TEST_FAILED++)) || true
        fi
    else
        echo -e "  ${RED}✗ FAIL${NC} - Score calculation failed"
        ((TEST_FAILED++)) || true
    fi

    # Test 5: Empty file
    log_info "Test 5: Empty file"
    run_test "Empty markdown" \
        "bash '$VALIDATOR' '$TEST_DIR/empty.md'" \
        1

    # Test 6: Malformed markdown
    log_info "Test 6: Malformed markdown (no headers)"
    run_test "No headers" \
        "bash '$VALIDATOR' '$TEST_DIR/malformed.md'" \
        1
fi

# ════════════════════════════════════════════════════════════════════════════
# Test Summary
# ════════════════════════════════════════════════════════════════════════════

echo ""
log_info "========================================"
log_info "  Test Summary"
log_info "========================================"
echo "  Total Tests: $((TEST_PASSED + TEST_FAILED))"
echo -e "  ${GREEN}Passed: $TEST_PASSED${NC}"
echo -e "  ${RED}Failed: $TEST_FAILED${NC}"
echo ""

if [[ $TEST_FAILED -eq 0 ]]; then
    log_success "All tests passed! ✓"
    exit 0
else
    log_error "$TEST_FAILED test(s) failed"
    exit 1
fi
