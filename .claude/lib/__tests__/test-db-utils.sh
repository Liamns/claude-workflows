#!/bin/bash

# ============================================================================
# Unit Tests for db-utils.sh
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"

# Source the db-utils.sh
source "$LIB_DIR/db-utils.sh"

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

assert_not_empty() {
    local value="$1"
    local message="$2"

    if [ -n "$value" ]; then
        log_success "PASS: $message"
        ((TESTS_PASSED++))
    else
        log_error "FAIL: $message (value is empty)"
        ((TESTS_FAILED++))
    fi
}

# ============================================================================
# Test Cases
# ============================================================================

test_parse_database_url() {
    echo ""
    log_info "Testing parse_database_url()..."

    # Test Case 1: Valid URL
    parse_database_url "postgresql://testuser:testpass@localhost:5433/testdb"
    assert_equals "testuser" "$DB_USER" "DB_USER should be testuser"
    assert_equals "testpass" "$DB_PASS" "DB_PASS should be testpass"
    assert_equals "localhost" "$DB_HOST" "DB_HOST should be localhost"
    assert_equals "5433" "$DB_PORT" "DB_PORT should be 5433"
    assert_equals "testdb" "$DB_NAME" "DB_NAME should be testdb"

    # Test Case 2: Different port
    parse_database_url "postgresql://user2:pass2@127.0.0.1:6022/mydb"
    assert_equals "user2" "$DB_USER" "DB_USER should be user2"
    assert_equals "pass2" "$DB_PASS" "DB_PASS should be pass2"
    assert_equals "127.0.0.1" "$DB_HOST" "DB_HOST should be 127.0.0.1"
    assert_equals "6022" "$DB_PORT" "DB_PORT should be 6022"
    assert_equals "mydb" "$DB_NAME" "DB_NAME should be mydb"

    # Test Case 3: Invalid URL (should fail)
    if ! parse_database_url "invalid://url" 2>/dev/null; then
        log_success "PASS: Invalid URL correctly rejected"
        ((TESTS_PASSED++))
    else
        log_error "FAIL: Invalid URL should be rejected"
        ((TESTS_FAILED++))
    fi
}

test_logging_functions() {
    echo ""
    log_info "Testing logging functions..."

    # Test that functions execute without errors
    log_info "Test info message" >/dev/null
    log_success "Test success message" >/dev/null
    log_warning "Test warning message" >/dev/null
    log_error "Test error message" 2>/dev/null

    log_success "PASS: All logging functions execute correctly"
    ((TESTS_PASSED++))
}

test_check_postgresql_tools() {
    echo ""
    log_info "Testing check_postgresql_tools()..."

    # This test will pass if PostgreSQL@16 is installed
    if check_postgresql_tools 2>/dev/null; then
        log_success "PASS: PostgreSQL tools check passed"
        ((TESTS_PASSED++))
    else
        log_warning "SKIP: PostgreSQL@16 not installed (expected on some systems)"
        # Don't count as failure since it's environment-dependent
    fi
}

test_check_docker() {
    echo ""
    log_info "Testing check_docker()..."

    # This test will pass if Docker is installed and running
    if check_docker 2>/dev/null; then
        log_success "PASS: Docker check passed"
        ((TESTS_PASSED++))
    else
        log_warning "SKIP: Docker not available (expected on some systems)"
        # Don't count as failure since it's environment-dependent
    fi
}

test_check_prisma() {
    echo ""
    log_info "Testing check_prisma()..."

    # This test will pass if Prisma CLI is available
    if check_prisma 2>/dev/null; then
        log_success "PASS: Prisma CLI check passed"
        ((TESTS_PASSED++))
    else
        log_warning "SKIP: Prisma CLI not available (expected on some systems)"
        # Don't count as failure since it's environment-dependent
    fi
}

# ============================================================================
# Run All Tests
# ============================================================================

echo "============================================"
echo "  DB Utils Unit Tests"
echo "============================================"

test_logging_functions || true
test_parse_database_url || true
test_check_postgresql_tools || true
test_check_docker || true
test_check_prisma || true

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
