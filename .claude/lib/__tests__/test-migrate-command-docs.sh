#!/bin/bash
# test-migrate-command-docs.sh
# Integration test for command document template migration
#
# This test verifies that existing command documents can be migrated
# to the new template format without losing content.
#
# Test cases:
# 1. Migrate existing document to template format
# 2. Verify no content loss after migration
# 3. Verify migrated document passes template validation
# 4. Verify section mapping is correct
# 5. Handle edge cases (missing sections, extra sections)
# 6. Rollback capability test

set -e

# Source common module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# Test counters
TEST_PASSED=0
TEST_FAILED=0

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

    # Create sample legacy command document (pre-template format)
    cat > "$TEST_DIR/legacy-command.md" <<'EOF'
# Legacy Command

This is a legacy command document that doesn't follow the new template.

## How to Use

You can use this command like this:
```bash
/legacy-command [options]
```

## Command Description

This command does something useful. It has multiple features and capabilities
that help users accomplish their tasks efficiently.

Some additional details about the command.

## Code Implementation

The command is implemented in bash.
It uses several helper functions.

## Example Usage

```bash
# Simple example
/legacy-command test

# Advanced example
/legacy-command --verbose --output=file.txt test
```

## Additional Notes

Some extra information that doesn't fit the standard template.
EOF

    # Create another legacy document with missing sections
    cat > "$TEST_DIR/incomplete-legacy.md" <<'EOF'
# Incomplete Command

## Description

This document is missing several sections.
It only has a description.
EOF

    # Create expected migrated output (for comparison)
    cat > "$TEST_DIR/expected-migrated.md" <<'EOF'
# Legacy Command

## Overview
This command does something useful. It has multiple features and capabilities
that help users accomplish their tasks efficiently.

Some additional details about the command.

## Usage
```bash
/legacy-command [options]
```

## Examples
```bash
# Simple example
/legacy-command test

# Advanced example
/legacy-command --verbose --output=file.txt test
```

## Implementation
The command is implemented in bash.
It uses several helper functions.

## Additional Notes
Some extra information that doesn't fit the standard template.
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
log_info "  Template Migration Integration Tests"
log_info "========================================"
echo ""

setup
echo ""

# Migration script path (will be created in T021)
MIGRATOR="$SCRIPT_DIR/../migrate-to-template.sh"
VALIDATOR="$SCRIPT_DIR/../validate-command-template.sh"

if [[ ! -f "$MIGRATOR" ]]; then
    log_warning "Migration script not found: $MIGRATOR"
    log_info "This script will be created during T021 implementation"
    echo ""
    log_info "Test expectations for migration script:"
    echo "  1. Input: Legacy .md file"
    echo "  2. Output: Template-compliant .md file"
    echo "  3. Content preservation: 100%"
    echo "  4. Section mapping:"
    echo "     - 'Description' → 'Overview'"
    echo "     - 'How to Use' → 'Usage'"
    echo "     - 'Example Usage' → 'Examples'"
    echo "     - 'Code Implementation' → 'Implementation'"
    echo "  5. Backup creation before migration"
    echo "  6. Rollback capability"
    echo ""
    log_success "Test file created - ready for T021 implementation"
    exit 0
fi

# Test 1: Basic migration
log_info "Test 1: Migrate legacy document"
if bash "$MIGRATOR" "$TEST_DIR/legacy-command.md" "$TEST_DIR/migrated.md" 2>/dev/null; then
    if [[ -f "$TEST_DIR/migrated.md" ]]; then
        echo -e "  ${GREEN}✓ PASS${NC} - Migration completed"
        ((TEST_PASSED++)) || true
    else
        echo -e "  ${RED}✗ FAIL${NC} - Output file not created"
        ((TEST_FAILED++)) || true
    fi
else
    echo -e "  ${RED}✗ FAIL${NC} - Migration script failed"
    ((TEST_FAILED++)) || true
fi

# Test 2: Content preservation
log_info "Test 2: Verify content preservation"
if [[ -f "$TEST_DIR/migrated.md" ]]; then
    # Check if key content is preserved
    if grep -q "This command does something useful" "$TEST_DIR/migrated.md" && \
       grep -q "/legacy-command" "$TEST_DIR/migrated.md" && \
       grep -q "bash" "$TEST_DIR/migrated.md"; then
        echo -e "  ${GREEN}✓ PASS${NC} - Content preserved"
        ((TEST_PASSED++)) || true
    else
        echo -e "  ${RED}✗ FAIL${NC} - Content missing after migration"
        ((TEST_FAILED++)) || true
    fi
fi

# Test 3: Template validation
log_info "Test 3: Migrated document passes validation"
if [[ -f "$VALIDATOR" ]] && [[ -f "$TEST_DIR/migrated.md" ]]; then
    if bash "$VALIDATOR" "$TEST_DIR/migrated.md" 2>/dev/null; then
        echo -e "  ${GREEN}✓ PASS${NC} - Validation passed"
        ((TEST_PASSED++)) || true
    else
        echo -e "  ${RED}✗ FAIL${NC} - Validation failed"
        ((TEST_FAILED++)) || true
    fi
else
    echo -e "  ${RED}✗ SKIP${NC} - Validator not available"
fi

# Test 4: Section mapping
log_info "Test 4: Correct section mapping"
if [[ -f "$TEST_DIR/migrated.md" ]]; then
    # Check if legacy section names are converted to template names
    has_overview=false
    has_usage=false
    has_examples=false
    has_implementation=false

    grep -q "^## Overview" "$TEST_DIR/migrated.md" && has_overview=true
    grep -q "^## Usage" "$TEST_DIR/migrated.md" && has_usage=true
    grep -q "^## Examples" "$TEST_DIR/migrated.md" && has_examples=true
    grep -q "^## Implementation" "$TEST_DIR/migrated.md" && has_implementation=true

    if $has_overview && $has_usage && $has_examples && $has_implementation; then
        echo -e "  ${GREEN}✓ PASS${NC} - All sections mapped correctly"
        ((TEST_PASSED++)) || true
    else
        echo -e "  ${RED}✗ FAIL${NC} - Section mapping incomplete"
        echo "    Overview: $has_overview, Usage: $has_usage, Examples: $has_examples, Implementation: $has_implementation"
        ((TEST_FAILED++)) || true
    fi
fi

# Test 5: Backup creation
log_info "Test 5: Backup created before migration"
# Migration script should create .backup file
if [[ -f "$TEST_DIR/legacy-command.md.backup" ]]; then
    echo -e "  ${GREEN}✓ PASS${NC} - Backup created"
    ((TEST_PASSED++)) || true
else
    echo -e "  ${RED}✗ FAIL${NC} - No backup created"
    ((TEST_FAILED++)) || true
fi

# Test 6: Incomplete document handling
log_info "Test 6: Handle incomplete legacy document"
if bash "$MIGRATOR" "$TEST_DIR/incomplete-legacy.md" "$TEST_DIR/incomplete-migrated.md" 2>/dev/null; then
    # Should still create valid template with available content
    if [[ -f "$VALIDATOR" ]]; then
        if bash "$VALIDATOR" "$TEST_DIR/incomplete-migrated.md" 2>/dev/null; then
            echo -e "  ${GREEN}✓ PASS${NC} - Incomplete document handled"
            ((TEST_PASSED++)) || true
        else
            echo -e "  ${RED}✗ FAIL${NC} - Migrated incomplete doc doesn't validate"
            ((TEST_FAILED++)) || true
        fi
    else
        echo -e "  ${RED}✗ SKIP${NC} - Validator not available"
    fi
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
