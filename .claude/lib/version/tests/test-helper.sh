#!/bin/bash
# test-helper.sh
# 테스트 헬퍼 함수

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 테스트 카운터
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# 테스트 이름
TEST_NAME=""

# 테스트 시작
test_start() {
    TEST_NAME="$1"
    echo ""
    echo "────────────────────────────────────────"
    echo "Test: $TEST_NAME"
    echo "────────────────────────────────────────"
}

# Assertion 함수
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [ "$expected" = "$actual" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓${NC} $message"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}✗${NC} $message"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
}

assert_contains() {
    local substring="$1"
    local text="$2"
    local message="${3:-String should contain substring}"

    TESTS_RUN=$((TESTS_RUN + 1))

    if echo "$text" | grep -q "$substring"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓${NC} $message"
        echo "  Substring: $substring"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}✗${NC} $message"
        echo "  Substring: $substring"
        echo "  Text:      $text"
        return 1
    fi
}

assert_exit_code() {
    local expected_code="$1"
    local actual_code="$2"
    local message="${3:-Exit code mismatch}"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [ "$expected_code" -eq "$actual_code" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓${NC} $message"
        echo "  Exit code: $actual_code"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}✗${NC} $message"
        echo "  Expected: $expected_code"
        echo "  Actual:   $actual_code"
        return 1
    fi
}

assert_file_exists() {
    local filepath="$1"
    local message="${2:-File should exist}"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [ -f "$filepath" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓${NC} $message"
        echo "  File: $filepath"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}✗${NC} $message"
        echo "  File: $filepath (not found)"
        return 1
    fi
}

# 테스트 요약
test_summary() {
    echo ""
    echo "════════════════════════════════════════"
    echo "Test Summary"
    echo "════════════════════════════════════════"
    echo "Total:  $TESTS_RUN"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

    if [ $TESTS_FAILED -eq 0 ]; then
        echo ""
        echo -e "${GREEN}All tests passed! ✓${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}Some tests failed! ✗${NC}"
        return 1
    fi
}
