#!/bin/bash
# test-cache-manager.sh
# cache-manager.sh 단위 테스트
#
# Usage: bash test-cache-manager.sh

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"

# Source dependencies
source "${LIB_DIR}/../common.sh"

# 테스트 결과
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 테스트용 임시 디렉토리
TEST_CACHE_DIR=$(mktemp -d)
TEST_CACHE_FILE="${TEST_CACHE_DIR}/validation-cache.json"

# ============================================================================
# 테스트 헬퍼
# ============================================================================

test_assert() {
  local test_name="$1"
  local command="$2"
  local expected_exit_code="${3:-0}"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  echo -n "  Testing: $test_name ... "

  set +e
  eval "$command" > /dev/null 2>&1
  local actual_exit_code=$?
  set -e

  if [[ "$actual_exit_code" == "$expected_exit_code" ]]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC} (expected: $expected_exit_code, got: $actual_exit_code)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
}

test_output_contains() {
  local test_name="$1"
  local command="$2"
  local expected_string="$3"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  echo -n "  Testing: $test_name ... "

  set +e
  local output=$(eval "$command" 2>&1)
  set -e

  if echo "$output" | grep -q "$expected_string"; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC} (expected string not found: $expected_string)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
}

# ============================================================================
# 테스트 실행
# ============================================================================

run_tests() {
  log_info "Starting cache-manager.sh tests..."
  echo ""

  # PROJECT_ROOT 감지
  local PROJECT_ROOT
  PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

  # cache-manager.sh를 테스트 환경으로 source
  # readonly 변수를 override하기 위해 임시 파일 생성
  cat > "${TEST_CACHE_DIR}/cache-manager-test.sh" <<EOF
#!/bin/bash
set -euo pipefail

# Source dependencies with absolute path
source "${PROJECT_ROOT}/.claude/lib/common.sh"
source "${PROJECT_ROOT}/.claude/lib/checksum-helper.sh"

# 테스트용 캐시 경로 (readonly 우회)
CACHE_DIR="${TEST_CACHE_DIR}"
CACHE_FILE="${TEST_CACHE_FILE}"
CACHE_TTL_HOURS=24
EOF

  # cache-manager.sh의 함수들만 복사 (readonly 선언과 source 구문 제외)
  sed -n '/^init_cache()/,/^# Note: This module is designed/p' \
    "${LIB_DIR}/cache-manager.sh" | \
    grep -v "^# Note: This module" \
    >> "${TEST_CACHE_DIR}/cache-manager-test.sh"

  source "${TEST_CACHE_DIR}/cache-manager-test.sh"

  # ============================================================================
  # 1. init_cache() 테스트
  # ============================================================================

  echo -e "${BLUE}1. init_cache() Tests${NC}"

  test_assert \
    "init_cache creates cache file" \
    "init_cache && [[ -f \"$TEST_CACHE_FILE\" ]]" \
    0

  test_assert \
    "init_cache creates valid JSON" \
    "validate_json \"$TEST_CACHE_FILE\"" \
    0

  test_output_contains \
    "init_cache JSON contains timestamp" \
    "cat \"$TEST_CACHE_FILE\"" \
    "timestamp"

  echo ""

  # ============================================================================
  # 2. update_cache() 테스트
  # ============================================================================

  echo -e "${BLUE}2. update_cache() Tests${NC}"

  # 테스트 파일 생성
  local test_file="${TEST_CACHE_DIR}/test-file.ts"
  echo "test content" > "$test_file"

  test_assert \
    "update_cache adds file to cache (valid)" \
    "update_cache \"$test_file\" \"valid\"" \
    0

  test_output_contains \
    "Cache contains test file" \
    "cat \"$TEST_CACHE_FILE\"" \
    "test-file.ts"

  test_assert \
    "update_cache adds file to cache (invalid)" \
    "update_cache \"$test_file\" \"invalid\" '[{\"rule\":\"test\"}]'" \
    0

  test_assert \
    "update_cache rejects invalid result" \
    "update_cache \"$test_file\" \"bad_value\"" \
    1

  echo ""

  # ============================================================================
  # 3. is_cache_valid() 테스트
  # ============================================================================

  echo -e "${BLUE}3. is_cache_valid() Tests${NC}"

  # 캐시 업데이트
  update_cache "$test_file" "valid" > /dev/null 2>&1

  test_assert \
    "is_cache_valid returns true for valid cache" \
    "is_cache_valid \"$test_file\"" \
    0

  # 파일 내용 변경
  echo "modified content" > "$test_file"

  test_assert \
    "is_cache_valid returns false after file modification" \
    "is_cache_valid \"$test_file\"" \
    1

  test_assert \
    "is_cache_valid returns false for non-existent file" \
    "is_cache_valid \"nonexistent.ts\"" \
    1

  echo ""

  # ============================================================================
  # 4. get_cached_result() 테스트
  # ============================================================================

  echo -e "${BLUE}4. get_cached_result() Tests${NC}"

  # 캐시 재업데이트
  echo "test content" > "$test_file"
  update_cache "$test_file" "valid" > /dev/null 2>&1

  test_output_contains \
    "get_cached_result returns result" \
    "get_cached_result \"$test_file\"" \
    "checksum"

  test_output_contains \
    "get_cached_result returns empty for non-existent" \
    "get_cached_result \"nonexistent.ts\"" \
    "{}"

  echo ""

  # ============================================================================
  # 5. invalidate_cache() 테스트
  # ============================================================================

  echo -e "${BLUE}5. invalidate_cache() Tests${NC}"

  # 캐시 업데이트
  update_cache "$test_file" "valid" > /dev/null 2>&1

  test_assert \
    "invalidate_cache removes specific file" \
    "invalidate_cache \"$test_file\"" \
    0

  test_assert \
    "is_cache_valid returns false after invalidation" \
    "is_cache_valid \"$test_file\"" \
    1

  # 캐시 재업데이트
  update_cache "$test_file" "valid" > /dev/null 2>&1

  test_assert \
    "invalidate_cache all removes cache file" \
    "invalidate_cache \"all\" && [[ ! -f \"$TEST_CACHE_FILE\" ]]" \
    0

  echo ""

  # ============================================================================
  # 테스트 결과 요약
  # ============================================================================

  echo ""
  echo "========================================"
  echo "Test Results Summary"
  echo "========================================"
  echo "Total tests: $TOTAL_TESTS"
  echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
  echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
  echo ""

  if [[ "$FAILED_TESTS" -eq 0 ]]; then
    log_success "All tests passed! ✅"
    return 0
  else
    log_error "$FAILED_TESTS test(s) failed"
    return 1
  fi
}

# ============================================================================
# 정리
# ============================================================================

cleanup() {
  rm -rf "$TEST_CACHE_DIR"
}

trap cleanup EXIT

# ============================================================================
# 메인
# ============================================================================

main() {
  echo ""
  echo "========================================"
  echo "cache-manager.sh Unit Tests"
  echo "========================================"
  echo ""

  # jq 확인
  if ! command -v jq &> /dev/null; then
    log_error "jq is required for cache-manager tests"
    exit 1
  fi

  run_tests
  local result=$?

  if [[ "$result" -eq 0 ]]; then
    log_success "cache-manager.sh tests completed successfully! 🎉"
    exit 0
  else
    log_error "cache-manager.sh tests failed"
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
