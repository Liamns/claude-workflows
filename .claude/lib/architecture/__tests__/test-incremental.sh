#!/bin/bash
# test-incremental.sh
# incremental.sh 단위 테스트
#
# Usage: bash test-incremental.sh

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
TEST_GIT_REPO="${TEST_DIR}/test-repo"
TEST_CACHE_DIR="${TEST_DIR}/cache"
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

test_output_count() {
  local test_name="$1"
  local command="$2"
  local expected_count="$3"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  echo -n "  Testing: $test_name ... "

  set +e
  local output=$(eval "$command" 2>&1)
  local actual_count=$(echo "$output" | grep -v "^$" | wc -l | tr -d ' ')
  set -e

  if [[ "$actual_count" == "$expected_count" ]]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC} (expected: $expected_count, got: $actual_count)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
}

# ============================================================================
# Git 환경 설정
# ============================================================================

setup_git_repo() {
  mkdir -p "$TEST_GIT_REPO"
  cd "$TEST_GIT_REPO"

  # Git 초기화
  git init > /dev/null 2>&1
  git config user.email "test@example.com"
  git config user.name "Test User"

  # 초기 커밋
  mkdir -p src/entities/user src/features/auth
  echo "export const userModel = {}" > src/entities/user/model.ts
  echo "export const authService = {}" > src/features/auth/service.ts
  git add .
  git commit -m "Initial commit" > /dev/null 2>&1

  log_success "Git test repository created: $TEST_GIT_REPO"
}

# ============================================================================
# 테스트 실행
# ============================================================================

run_tests() {
  log_info "Starting incremental.sh tests..."
  echo ""

  # PROJECT_ROOT 감지 (테스트 저장소 생성 전에 저장)
  local PROJECT_ROOT
  PROJECT_ROOT=$(cd "${LIB_DIR}/../.." && pwd)

  # Git 테스트 저장소 설정
  setup_git_repo

  # incremental.sh를 테스트 환경으로 source
  cat > "${TEST_DIR}/incremental-test.sh" <<EOF
#!/bin/bash
set -euo pipefail

# Source dependencies with absolute paths
source "${PROJECT_ROOT}/lib/common.sh"
source "${PROJECT_ROOT}/lib/checksum-helper.sh"

# 테스트용 캐시 경로
CACHE_DIR="${TEST_CACHE_DIR}"
CACHE_FILE="${TEST_CACHE_FILE}"
CACHE_TTL_HOURS=24

# cache-manager.sh 함수들 로드
EOF

  # cache-manager.sh의 함수들만 복사
  sed -n '/^init_cache()/,/^# Note: This module is designed/p' \
    "${LIB_DIR}/cache-manager.sh" | \
    grep -v "^# Note: This module" \
    >> "${TEST_DIR}/incremental-test.sh"

  # incremental.sh의 함수들 복사
  sed -n '/^get_changed_files()/,/^# Note: This module is designed/p' \
    "${LIB_DIR}/incremental.sh" | \
    grep -v "^# Note: This module" \
    >> "${TEST_DIR}/incremental-test.sh"

  # 테스트 스크립트 source
  source "${TEST_DIR}/incremental-test.sh"

  # 캐시 초기화
  init_cache > /dev/null 2>&1

  # ============================================================================
  # 1. get_changed_files() 테스트
  # ============================================================================

  echo -e "${BLUE}1. get_changed_files() Tests${NC}"

  # 1-1. 변경 사항 없을 때
  test_output_count \
    "get_changed_files returns empty for clean repo" \
    "get_changed_files" \
    "0"

  # 1-2. Unstaged changes
  echo "// modified" >> src/entities/user/model.ts
  test_output_contains \
    "get_changed_files detects unstaged changes" \
    "get_changed_files" \
    "src/entities/user/model.ts"

  # 1-3. Staged changes
  git add src/entities/user/model.ts
  test_output_contains \
    "get_changed_files detects staged changes" \
    "get_changed_files" \
    "src/entities/user/model.ts"

  # 1-4. Untracked files
  echo "export const newFile = {}" > src/entities/user/new-file.ts
  test_output_contains \
    "get_changed_files detects untracked files" \
    "get_changed_files" \
    "new-file.ts"

  # Reset for next tests
  git reset > /dev/null 2>&1
  git checkout -- src/entities/user/model.ts > /dev/null 2>&1
  rm -f src/entities/user/new-file.ts

  echo ""

  # ============================================================================
  # 2. get_affected_files() 테스트
  # ============================================================================

  echo -e "${BLUE}2. get_affected_files() Tests${NC}"

  # 2-1. Import 관계 생성
  echo "import { userModel } from '../entities/user/model'" > src/features/auth/index.ts
  git add src/features/auth/index.ts
  git commit -m "Add import" > /dev/null 2>&1

  test_output_contains \
    "get_affected_files finds files importing the changed file" \
    "get_affected_files 'src/entities/user/model.ts' 'src'" \
    "auth/index.ts"

  # 2-2. 영향 받는 파일 없을 때
  test_output_count \
    "get_affected_files returns empty for isolated file" \
    "get_affected_files 'src/features/auth/service.ts' 'src'" \
    "0"

  # 2-3. 존재하지 않는 디렉토리
  test_assert \
    "get_affected_files handles non-existent directory" \
    "get_affected_files 'test.ts' 'nonexistent'" \
    0

  echo ""

  # ============================================================================
  # 3. is_file_in_cache() 테스트
  # ============================================================================

  echo -e "${BLUE}3. is_file_in_cache() Tests${NC}"

  # 3-1. 캐시에 없는 파일
  test_assert \
    "is_file_in_cache returns false for non-cached file" \
    "is_file_in_cache 'src/entities/user/model.ts'" \
    1

  # 3-2. 캐시에 추가 후 확인
  update_cache "src/entities/user/model.ts" "valid" "[]" > /dev/null 2>&1
  test_assert \
    "is_file_in_cache returns true for cached file" \
    "is_file_in_cache 'src/entities/user/model.ts'" \
    0

  # 3-3. 파일 수정 후 캐시 무효화
  echo "// modified again" >> src/entities/user/model.ts
  test_assert \
    "is_file_in_cache returns false after file modification" \
    "is_file_in_cache 'src/entities/user/model.ts'" \
    1

  # Reset
  git checkout -- src/entities/user/model.ts > /dev/null 2>&1

  echo ""

  # ============================================================================
  # 4. run_incremental_validation() 통합 테스트
  # ============================================================================

  echo -e "${BLUE}4. run_incremental_validation() Tests${NC}"

  # 4-1. 검증 함수 정의
  validate_always_pass() {
    return 0
  }

  validate_always_fail() {
    return 1
  }

  # 4-2. 변경 사항 없을 때
  test_assert \
    "run_incremental_validation skips when no changes" \
    "run_incremental_validation 'HEAD' 'validate_always_pass'" \
    0

  # 4-3. 변경 파일 검증 (성공)
  echo "// test change" >> src/entities/user/model.ts

  # Manual test instead of test_assert (for debugging)
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -n "  Testing: run_incremental_validation succeeds with passing validation ... "
  if run_incremental_validation 'HEAD' 'validate_always_pass' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi

  # 4-4. 캐시 확인 (검증 후 캐시됨)
  test_assert \
    "run_incremental_validation caches validation result" \
    "is_file_in_cache 'src/entities/user/model.ts'" \
    0

  # 4-5. 캐시된 파일은 재검증 스킵
  # (이미 캐시되어 있으므로 validate_always_fail을 사용해도 성공)
  test_assert \
    "run_incremental_validation uses cache" \
    "run_incremental_validation 'HEAD' 'validate_always_fail'" \
    0

  # 4-6. 캐시 무효화 후 검증 실패
  invalidate_cache "src/entities/user/model.ts" > /dev/null 2>&1

  # Manual test (for debugging)
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -n "  Testing: run_incremental_validation fails with failing validation ... "
  if run_incremental_validation 'HEAD' 'validate_always_fail' > /dev/null 2>&1; then
    echo -e "${RED}✗ FAIL${NC} (expected failure, got success)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  else
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  fi

  # Reset
  git checkout -- src/entities/user/model.ts > /dev/null 2>&1

  # 4-7. 검증 함수 없을 때
  test_assert \
    "run_incremental_validation fails without validation function" \
    "run_incremental_validation 'HEAD' ''" \
    1

  # 4-8. 존재하지 않는 검증 함수
  test_assert \
    "run_incremental_validation fails with non-existent function" \
    "run_incremental_validation 'HEAD' 'nonexistent_function'" \
    1

  echo ""

  # ============================================================================
  # 5. 에러 케이스 테스트
  # ============================================================================

  echo -e "${BLUE}5. Error Cases Tests${NC}"

  # 5-1. Non-git repository
  cd "$TEST_DIR"
  mkdir -p non-git-dir
  cd non-git-dir
  test_assert \
    "get_changed_files handles non-git repository" \
    "get_changed_files" \
    1

  # 5-2. Empty file path
  cd "$TEST_GIT_REPO"
  test_assert \
    "is_file_in_cache handles empty path" \
    "is_file_in_cache ''" \
    1

  test_assert \
    "get_affected_files handles empty path" \
    "get_affected_files '' 'src'" \
    1

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
  echo "incremental.sh Unit Tests"
  echo "========================================"
  echo ""

  # jq 확인
  if ! command -v jq &> /dev/null; then
    log_error "jq is required for incremental tests"
    exit 1
  fi

  # git 확인
  if ! command -v git &> /dev/null; then
    log_error "git is required for incremental tests"
    exit 1
  fi

  run_tests
  local result=$?

  if [[ "$result" -eq 0 ]]; then
    log_success "incremental.sh tests completed successfully! 🎉"
    exit 0
  else
    log_error "incremental.sh tests failed"
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
