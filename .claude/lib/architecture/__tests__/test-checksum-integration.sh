#!/bin/bash
# test-checksum-integration.sh
# checksum-helper.sh 통합 테스트
#
# Usage: bash test-checksum-integration.sh

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
TEST_DIR=$(mktemp -d)

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

test_output_match() {
  local test_name="$1"
  local command="$2"
  local expected_pattern="$3"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  echo -n "  Testing: $test_name ... "

  set +e
  local output=$(eval "$command" 2>&1)
  set -e

  if [[ "$output" =~ $expected_pattern ]]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC} (pattern not matched: $expected_pattern)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
}

# ============================================================================
# 테스트 실행
# ============================================================================

run_tests() {
  log_info "Starting checksum integration tests..."
  echo ""

  # checksum-helper.sh source
  source "${LIB_DIR}/../checksum-helper.sh"

  # ============================================================================
  # 1. calculate_sha256() 기본 기능 테스트
  # ============================================================================

  echo -e "${BLUE}1. calculate_sha256() Basic Tests${NC}"

  # 1-1. 테스트 파일 생성
  local test_file="${TEST_DIR}/test-file.txt"
  echo "Hello, World!" > "$test_file"

  test_assert \
    "calculate_sha256 succeeds for existing file" \
    "calculate_sha256 '$test_file'" \
    0

  # 1-2. 체크섬 형식 검증 (64자 hex string)
  test_output_match \
    "calculate_sha256 returns 64-char hex string" \
    "calculate_sha256 '$test_file'" \
    "^[a-f0-9]{64}$"

  # 1-3. 동일 파일의 체크섬 일관성
  local checksum1=$(calculate_sha256 "$test_file")
  local checksum2=$(calculate_sha256 "$test_file")

  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -n "  Testing: calculate_sha256 returns consistent checksums ... "
  if [[ "$checksum1" == "$checksum2" ]]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC} (checksums differ)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi

  # 1-4. 파일 변경 시 체크섬 변경
  echo "Modified content" >> "$test_file"
  local checksum3=$(calculate_sha256 "$test_file")

  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -n "  Testing: calculate_sha256 detects file changes ... "
  if [[ "$checksum1" != "$checksum3" ]]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC} (checksums should differ)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi

  # 1-5. 존재하지 않는 파일
  test_assert \
    "calculate_sha256 fails for non-existent file" \
    "calculate_sha256 '/nonexistent/file.txt'" \
    1

  # 1-6. 빈 경로
  test_assert \
    "calculate_sha256 fails for empty path" \
    "calculate_sha256 ''" \
    1

  echo ""

  # ============================================================================
  # 2. cache-manager.sh 통합 테스트
  # ============================================================================

  echo -e "${BLUE}2. cache-manager.sh Integration Tests${NC}"

  # 테스트용 캐시 설정
  local TEST_CACHE_DIR="${TEST_DIR}/cache"
  local TEST_CACHE_FILE="${TEST_CACHE_DIR}/validation-cache.json"

  # cache-manager.sh 로드 (테스트 환경)
  cat > "${TEST_DIR}/cache-test.sh" <<EOF
#!/bin/bash
set -euo pipefail

source "${LIB_DIR}/../common.sh"
source "${LIB_DIR}/../checksum-helper.sh"

CACHE_DIR="${TEST_CACHE_DIR}"
CACHE_FILE="${TEST_CACHE_FILE}"
CACHE_TTL_HOURS=24
EOF

  # cache-manager.sh 함수들 복사
  sed -n '/^init_cache()/,/^# Note: This module is designed/p' \
    "${LIB_DIR}/cache-manager.sh" | \
    grep -v "^# Note: This module" \
    >> "${TEST_DIR}/cache-test.sh"

  source "${TEST_DIR}/cache-test.sh"

  # 2-1. 캐시 초기화
  test_assert \
    "init_cache creates cache" \
    "init_cache" \
    0

  # 2-2. update_cache에서 체크섬 계산
  local test_ts="${TEST_DIR}/test.ts"
  echo "export const test = {}" > "$test_ts"

  test_assert \
    "update_cache calculates checksum" \
    "update_cache '$test_ts' 'valid' '[]'" \
    0

  # 2-3. 캐시된 체크섬 확인
  local cached_checksum=$(jq -r ".files[\"$test_ts\"].checksum" "$TEST_CACHE_FILE")

  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -n "  Testing: cached checksum is valid hex string ... "
  if [[ "$cached_checksum" =~ ^[a-f0-9]{64}$ ]]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC} (invalid checksum: $cached_checksum)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi

  # 2-4. is_cache_valid에서 체크섬 비교
  test_assert \
    "is_cache_valid uses checksum comparison" \
    "is_cache_valid '$test_ts'" \
    0

  # 2-5. 파일 수정 후 캐시 무효화 감지
  echo "// modified" >> "$test_ts"
  test_assert \
    "is_cache_valid detects file changes via checksum" \
    "is_cache_valid '$test_ts'" \
    1

  echo ""

  # ============================================================================
  # 3. 크로스 플랫폼 호환성 테스트
  # ============================================================================

  echo -e "${BLUE}3. Cross-Platform Compatibility Tests${NC}"

  # 3-1. SHA256 도구 감지
  test_assert \
    "detect_sha256_tool finds available tool" \
    "detect_sha256_tool" \
    0

  local sha_tool=$(detect_sha256_tool)

  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -n "  Testing: SHA256 tool is available ($sha_tool) ... "
  if [[ -n "$sha_tool" ]]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi

  # 3-2. 알려진 체크섬 검증 (echo "test" | shasum -a 256)
  # "test" (with newline)의 SHA256: 4d967a30111bf29f0eba01c448b375c1629b2fed01cdfcc3aed91f1b57d5dd5e
  # "test\n"의 SHA256: f2ca1bb6c7e907d06dafe4687e579fce76b37e4e93b7605022da52e6ccc26fd2
  echo -n "test" > "${TEST_DIR}/known.txt"
  local known_checksum="9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"
  local actual_checksum=$(calculate_sha256 "${TEST_DIR}/known.txt")

  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -n "  Testing: checksum matches known value ... "
  if [[ "$actual_checksum" == "$known_checksum" ]]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC} (expected: $known_checksum, got: $actual_checksum)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi

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
  rm -rf "$TEST_DIR"
}

trap cleanup EXIT

# ============================================================================
# 메인
# ============================================================================

main() {
  echo ""
  echo "========================================"
  echo "checksum-helper.sh Integration Tests"
  echo "========================================"
  echo ""

  # jq 확인
  if ! command -v jq &> /dev/null; then
    log_error "jq is required for integration tests"
    exit 1
  fi

  run_tests
  local result=$?

  if [[ "$result" -eq 0 ]]; then
    log_success "checksum integration tests completed successfully! 🎉"
    exit 0
  else
    log_error "checksum integration tests failed"
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
