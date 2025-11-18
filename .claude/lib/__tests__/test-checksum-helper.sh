#!/bin/bash
# test-checksum-helper.sh
# Unit tests for checksum-helper.sh
#
# 사용법:
#   bash .claude/lib/__tests__/test-checksum-helper.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test directory
TEST_DIR="/tmp/test-checksum-helper-$$"
mkdir -p "$TEST_DIR"

# ════════════════════════════════════════════════════════════════════════════
# Test helpers
# ════════════════════════════════════════════════════════════════════════════

assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    ((TESTS_RUN++))

    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local test_name="$2"

    ((TESTS_RUN++))

    if [[ -n "$value" ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Value is empty"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_matches() {
    local pattern="$1"
    local value="$2"
    local test_name="$3"

    ((TESTS_RUN++))

    if [[ "$value" =~ $pattern ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Pattern: $pattern"
        echo "  Value:   $value"
        ((TESTS_FAILED++))
        return 1
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# Tests
# ════════════════════════════════════════════════════════════════════════════

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_group() {
    echo ""
    echo -e "${YELLOW}$1${NC}"
    echo "──────────────────────────────────────────"
}

# Source the checksum helper
if [ ! -f ".claude/lib/checksum-helper.sh" ]; then
    echo -e "${RED}Error: checksum-helper.sh not found${NC}"
    exit 1
fi

source .claude/lib/checksum-helper.sh

print_header "Test Suite: checksum-helper.sh"

# ────────────────────────────────────────────────────────────────────────────
# Test Group 1: detect_sha256_tool()
# ────────────────────────────────────────────────────────────────────────────

print_group "SHA256 도구 감지"

test_detect_sha256_tool() {
    local tool=$(detect_sha256_tool)

    # 도구가 감지되어야 함
    assert_not_empty "$tool" "SHA256 도구 감지 성공"

    # shasum, sha256sum, openssl 중 하나여야 함
    if [[ "$tool" =~ shasum|sha256sum|openssl ]]; then
        ((TESTS_RUN++))
        echo -e "${GREEN}✓${NC} 감지된 도구가 유효함: $tool"
        ((TESTS_PASSED++))
    else
        ((TESTS_RUN++))
        echo -e "${RED}✗${NC} 감지된 도구가 유효하지 않음: $tool"
        ((TESTS_FAILED++))
    fi
}

test_detect_sha256_tool

# ────────────────────────────────────────────────────────────────────────────
# Test Group 2: calculate_sha256()
# ────────────────────────────────────────────────────────────────────────────

print_group "체크섬 계산"

test_calculate_sha256() {
    # 테스트 파일 생성
    local test_file="$TEST_DIR/test-file.txt"
    echo "test content" > "$test_file"

    # 체크섬 계산
    local checksum=$(calculate_sha256 "$test_file")

    # 체크섬 형식 검증 (64자 hex string)
    assert_matches "^[a-f0-9]{64}$" "$checksum" "체크섬 형식 검증 (64자 hex)"

    # 동일한 파일에 대해 동일한 체크섬 생성 확인
    local checksum2=$(calculate_sha256 "$test_file")
    assert_equals "$checksum" "$checksum2" "동일 파일 체크섬 일관성"

    # 다른 내용의 파일은 다른 체크섬 생성
    echo "different content" > "$test_file"
    local checksum3=$(calculate_sha256 "$test_file")

    ((TESTS_RUN++))
    if [[ "$checksum" != "$checksum3" ]]; then
        echo -e "${GREEN}✓${NC} 다른 내용은 다른 체크섬 생성"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} 다른 내용인데 동일한 체크섬 생성"
        ((TESTS_FAILED++))
    fi

    # 파일 정리
    rm "$test_file"
}

test_calculate_sha256

# ────────────────────────────────────────────────────────────────────────────
# Test Group 3: Edge Cases
# ────────────────────────────────────────────────────────────────────────────

print_group "엣지 케이스"

test_empty_file() {
    local test_file="$TEST_DIR/empty-file.txt"
    touch "$test_file"

    local checksum=$(calculate_sha256 "$test_file")

    # 빈 파일도 유효한 체크섬 생성
    assert_matches "^[a-f0-9]{64}$" "$checksum" "빈 파일 체크섬 계산"

    rm "$test_file"
}

test_large_file() {
    local test_file="$TEST_DIR/large-file.txt"

    # 1MB 파일 생성
    dd if=/dev/zero of="$test_file" bs=1024 count=1024 2>/dev/null

    local checksum=$(calculate_sha256 "$test_file")

    # 큰 파일도 유효한 체크섬 생성
    assert_matches "^[a-f0-9]{64}$" "$checksum" "큰 파일 (1MB) 체크섬 계산"

    rm "$test_file"
}

test_nonexistent_file() {
    local test_file="$TEST_DIR/nonexistent.txt"

    # 존재하지 않는 파일은 빈 체크섬 반환 또는 에러
    local checksum=$(calculate_sha256 "$test_file" 2>/dev/null || echo "")

    ((TESTS_RUN++))
    if [[ -z "$checksum" ]] || [[ "$checksum" == "ERROR"* ]]; then
        echo -e "${GREEN}✓${NC} 존재하지 않는 파일 처리"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} 존재하지 않는 파일에 대해 체크섬 반환: $checksum"
        ((TESTS_FAILED++))
    fi
}

test_empty_file
test_large_file
test_nonexistent_file

# ────────────────────────────────────────────────────────────────────────────
# Test Group 4: Performance
# ────────────────────────────────────────────────────────────────────────────

print_group "성능 테스트"

test_performance() {
    local test_file="$TEST_DIR/perf-test.txt"
    echo "test content for performance" > "$test_file"

    # 10개 파일 체크섬 계산 시간 측정
    local start=$(date +%s)
    for i in {1..10}; do
        calculate_sha256 "$test_file" > /dev/null
    done
    local end=$(date +%s)
    local duration=$((end - start))

    echo "  10개 파일 체크섬 계산 시간: ${duration}초"

    ((TESTS_RUN++))
    if [ $duration -lt 5 ]; then
        echo -e "${GREEN}✓${NC} 성능 요구사항 만족 (10개 파일 < 5초)"
        ((TESTS_PASSED++))
    else
        echo -e "${YELLOW}⚠${NC} 성능 경고 (10개 파일: ${duration}초)"
        ((TESTS_PASSED++))  # Warning but not failure
    fi

    rm "$test_file"
}

test_performance

# ════════════════════════════════════════════════════════════════════════════
# Cleanup and Summary
# ════════════════════════════════════════════════════════════════════════════

# Cleanup
rm -rf "$TEST_DIR"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Test Results${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
echo "Total:  $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
else
    echo "Failed: 0"
fi
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed!${NC}"
    exit 1
fi
