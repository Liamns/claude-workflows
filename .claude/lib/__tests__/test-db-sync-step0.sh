#!/bin/bash

# ============================================================================
# Unit Tests for db-sync.sh - Step 0 (Connection Check)
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"

# Source the db-sync.sh
source "$LIB_DIR/db-sync.sh"

# ============================================================================
# Test Helpers
# ============================================================================

TESTS_PASSED=0
TESTS_FAILED=0

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    if [ "$expected" == "$actual" ]; then
        log_success "PASS: $message"
        ((TESTS_PASSED++))
    else
        log_error "FAIL: $message"
        log_error "  Expected: $expected"
        log_error "  Actual: $actual"
        ((TESTS_FAILED++))
    fi
}

assert_success() {
    local message="$1"
    log_success "PASS: $message"
    ((TESTS_PASSED++))
}

assert_fail() {
    local message="$1"
    log_error "FAIL: $message"
    ((TESTS_FAILED++))
}

# ============================================================================
# Test Cases
# ============================================================================

test_lock_file() {
    echo ""
    log_info "Testing lock file management..."

    # Clean up any existing lock file
    rm -f "$LOCK_FILE"

    # Test 1: Create lock file
    if check_lock_file; then
        assert_success "Lock file created successfully"
    else
        assert_fail "Lock file creation failed"
    fi

    # Test 2: Check lock file exists
    if [ -f "$LOCK_FILE" ]; then
        assert_success "Lock file exists"
    else
        assert_fail "Lock file should exist"
    fi

    # Test 3: Lock file contains PID
    if grep -q "^[0-9]\+$" "$LOCK_FILE"; then
        assert_success "Lock file contains valid PID"
    else
        assert_fail "Lock file should contain PID"
    fi

    # Clean up
    rm -f "$LOCK_FILE"
}

test_parse_env_files() {
    echo ""
    log_info "Testing environment file parsing..."

    # Check if .env and .env.docker exist
    if [ ! -f ".env" ] || [ ! -f ".env.docker" ]; then
        log_warning "SKIP: .env or .env.docker not found (expected in some environments)"
        return 0
    fi

    # Test parsing
    if parse_env_files; then
        assert_success "Environment files parsed successfully"

        # Verify variables are set
        if [ -n "$SOURCE_DB_HOST" ]; then
            assert_success "SOURCE_DB_HOST is set: $SOURCE_DB_HOST"
        else
            assert_fail "SOURCE_DB_HOST should be set"
        fi

        if [ -n "$TARGET_DB_HOST" ]; then
            assert_success "TARGET_DB_HOST is set: $TARGET_DB_HOST"
        else
            assert_fail "TARGET_DB_HOST should be set"
        fi
    else
        assert_fail "Environment file parsing failed"
    fi
}

test_check_db_connection() {
    echo ""
    log_info "Testing DB connection check..."

    # This test requires actual DB to be running
    # We'll skip if env files don't exist
    if [ ! -f ".env" ] || [ ! -f ".env.docker" ]; then
        log_warning "SKIP: .env or .env.docker not found"
        return 0
    fi

    # Parse env files first
    if ! parse_env_files 2>/dev/null; then
        log_warning "SKIP: Could not parse environment files"
        return 0
    fi

    # Try to check source DB connection
    if check_db_connection "$SOURCE_DB_HOST" "$SOURCE_DB_PORT" "$SOURCE_DB_USER" "$SOURCE_DB_NAME" "Source DB" 2>/dev/null; then
        assert_success "Source DB connection check passed"
    else
        log_warning "SKIP: Source DB not available (expected if DB is not running)"
    fi

    # Try to check target DB connection
    if check_db_connection "$TARGET_DB_HOST" "$TARGET_DB_PORT" "$TARGET_DB_USER" "$TARGET_DB_NAME" "Target DB" 2>/dev/null; then
        assert_success "Target DB connection check passed"
    else
        log_warning "SKIP: Target DB not available (expected if DB is not running)"
    fi
}

# ============================================================================
# Run All Tests
# ============================================================================

echo "============================================"
echo "  DB Sync Step 0 Unit Tests"
echo "============================================"

test_lock_file || true
test_parse_env_files || true
test_check_db_connection || true

# ============================================================================
# Test Summary
# ============================================================================

echo ""
echo "============================================"
echo "  Test Results"
echo "============================================"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    log_success "All tests passed!"
    exit 0
else
    log_error "Some tests failed!"
    exit 1
fi
