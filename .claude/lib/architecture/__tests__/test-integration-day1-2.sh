#!/bin/bash
# test-integration-day1-2.sh
# Day 1-2 통합 테스트: cache-manager + incremental + checksum
#
# Usage: bash test-integration-day1-2.sh

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

test_value_equals() {
  local test_name="$1"
  local actual="$2"
  local expected="$3"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  echo -n "  Testing: $test_name ... "

  if [[ "$actual" == "$expected" ]]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC} (expected: $expected, got: $actual)"
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

  # FSD 구조 생성
  mkdir -p src/entities/user src/entities/product
  mkdir -p src/features/auth src/features/cart
  mkdir -p src/shared/ui src/shared/api

  # Entity 파일
  cat > src/entities/user/model.ts <<'EOF'
export interface User {
  id: string;
  name: string;
}

export const userModel = {};
EOF

  cat > src/entities/product/model.ts <<'EOF'
export interface Product {
  id: string;
  name: string;
  price: number;
}

export const productModel = {};
EOF

  # Feature 파일
  cat > src/features/auth/service.ts <<'EOF'
import { userModel } from '../../entities/user/model';

export const authService = {
  login: () => userModel,
};
EOF

  cat > src/features/cart/service.ts <<'EOF'
import { productModel } from '../../entities/product/model';

export const cartService = {
  addToCart: (product: any) => productModel,
};
EOF

  # Shared 파일
  cat > src/shared/api/client.ts <<'EOF'
export const apiClient = {
  get: (url: string) => {},
  post: (url: string, data: any) => {},
};
EOF

  git add .
  git commit -m "Initial FSD structure" > /dev/null 2>&1

  log_success "Test Git repository created with FSD structure"
}

# ============================================================================
# 시스템 로드
# ============================================================================

load_system() {
  local PROJECT_ROOT
  PROJECT_ROOT=$(cd "${LIB_DIR}/../.." && pwd)

  cat > "${TEST_DIR}/system-env.sh" <<EOF
#!/bin/bash
set -euo pipefail

source "${PROJECT_ROOT}/lib/common.sh"
source "${PROJECT_ROOT}/lib/checksum-helper.sh"

CACHE_DIR="${TEST_CACHE_DIR}"
CACHE_FILE="${TEST_CACHE_FILE}"
CACHE_TTL_HOURS=24

log_debug() {
  return 0
}
EOF

  # cache-manager.sh 함수들
  sed -n '/^init_cache()/,/^# Note: This module is designed/p' \
    "${LIB_DIR}/cache-manager.sh" | \
    grep -v "^# Note: This module" \
    >> "${TEST_DIR}/system-env.sh"

  # incremental.sh 함수들
  sed -n '/^get_changed_files()/,/^# Note: This module is designed/p' \
    "${LIB_DIR}/incremental.sh" | \
    grep -v "^# Note: This module" | \
    sed '/^log_debug() {/,/^}/d' \
    >> "${TEST_DIR}/system-env.sh"

  source "${TEST_DIR}/system-env.sh"
}

# ============================================================================
# Mock 검증 함수들
# ============================================================================

# 항상 성공하는 검증
mock_validate_pass() {
  local file="$1"
  return 0
}

# 항상 실패하는 검증
mock_validate_fail() {
  local file="$1"
  return 1
}

# Entity 레이어 검증 (entities는 다른 레이어를 import하지 않아야 함)
mock_validate_entity_layer() {
  local file="$1"

  if [[ ! "$file" =~ /entities/ ]]; then
    return 0
  fi

  # entities가 features나 shared를 import하면 안 됨
  if grep -q "from.*features" "$file" 2>/dev/null; then
    return 1
  fi

  if grep -q "from.*shared" "$file" 2>/dev/null; then
    return 1
  fi

  return 0
}

# ============================================================================
# 통합 테스트 시나리오
# ============================================================================

run_integration_tests() {
  log_info "Starting Day 1-2 integration tests..."
  echo ""

  # PROJECT_ROOT 미리 설정
  local PROJECT_ROOT
  PROJECT_ROOT=$(cd "${LIB_DIR}/../.." && pwd)

  # Git 저장소 설정
  setup_git_repo

  # 시스템 로드
  load_system

  # ============================================================================
  # Scenario 1: 초기 전체 검증 (캐시 없음)
  # ============================================================================

  echo -e "${BLUE}Scenario 1: Initial Full Validation (No Cache)${NC}"

  # 1-1. 캐시 초기화
  test_assert \
    "Initialize cache" \
    "init_cache" \
    0

  # 1-2. 캐시 파일 존재 확인
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -n "  Testing: Cache file created ... "
  if [[ -f "$TEST_CACHE_FILE" ]]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi

  # 1-3. 모든 파일 검증 및 캐시 (시뮬레이션)
  local validation_count=0
  while IFS= read -r file; do
    if [[ -f "$file" ]] && [[ "$file" =~ \.(ts|tsx)$ ]]; then
      if mock_validate_entity_layer "$file"; then
        update_cache "$file" "valid" "[]" > /dev/null 2>&1
        validation_count=$((validation_count + 1))
      fi
    fi
  done < <(find src -type f -name "*.ts" 2>/dev/null)

  test_value_equals \
    "All files validated and cached" \
    "$validation_count" \
    "5"

  echo ""

  # ============================================================================
  # Scenario 2: 증분 검증 - 파일 1개 수정 (캐시 활용)
  # ============================================================================

  echo -e "${BLUE}Scenario 2: Incremental Validation (1 File Changed)${NC}"

  # 2-1. 파일 수정
  echo "// Modified for testing" >> src/entities/user/model.ts

  # 2-2. 변경된 파일 감지
  local changed_files=$(get_changed_files "HEAD")

  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -n "  Testing: Detect changed file ... "
  if echo "$changed_files" | grep -q "user/model.ts"; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi

  # 2-3. 영향받은 파일 감지 (auth/service.ts가 user/model.ts를 import)
  local affected_files=$(get_affected_files "src/entities/user/model.ts" "src")

  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -n "  Testing: Detect affected files ... "
  if echo "$affected_files" | grep -q "auth/service.ts"; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi

  # 2-4. 증분 검증 실행
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -n "  Testing: Run incremental validation ... "
  if run_incremental_validation "HEAD" "mock_validate_entity_layer" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi

  # 2-5. 변경된 파일의 캐시가 업데이트되었는지 확인
  test_assert \
    "Changed file cache updated" \
    "is_cache_valid 'src/entities/user/model.ts'" \
    0

  echo ""

  # ============================================================================
  # Scenario 3: 레이어 규칙 위반 감지
  # ============================================================================

  echo -e "${BLUE}Scenario 3: Layer Rule Violation Detection${NC}"

  # 3-1. Entity가 Feature를 import (규칙 위반)
  echo "import { authService } from '../../features/auth/service';" >> src/entities/user/model.ts

  # 3-2. 캐시 무효화 확인
  test_assert \
    "Cache invalidated after violation" \
    "is_cache_valid 'src/entities/user/model.ts'" \
    1

  # 3-3. 검증 실패 확인
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -n "  Testing: Validation fails for layer violation ... "
  if mock_validate_entity_layer "src/entities/user/model.ts"; then
    echo -e "${RED}✗ FAIL${NC} (should have failed)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  else
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  fi

  # 3-4. 증분 검증도 실패해야 함
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -n "  Testing: Incremental validation detects violation ... "
  if run_incremental_validation "HEAD" "mock_validate_entity_layer" > /dev/null 2>&1; then
    echo -e "${RED}✗ FAIL${NC} (should have failed)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  else
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  fi

  # Cleanup: 규칙 위반 제거
  git checkout -- src/entities/user/model.ts > /dev/null 2>&1

  echo ""

  # ============================================================================
  # Scenario 4: 여러 파일 동시 수정
  # ============================================================================

  echo -e "${BLUE}Scenario 4: Multiple Files Changed${NC}"

  # 4-1. 여러 파일 수정
  echo "// Modified" >> src/entities/product/model.ts
  echo "// Modified" >> src/features/cart/service.ts
  echo "// Modified" >> src/shared/api/client.ts

  # 4-2. 모든 변경 파일 감지
  local changed_count=$(get_changed_files "HEAD" | wc -l | tr -d ' ')

  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -n "  Testing: Detect multiple changed files ... "
  if [[ "$changed_count" -ge 3 ]]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC} (expected: >=3, got: $changed_count)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi

  # 4-3. 증분 검증 (여러 파일)
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -n "  Testing: Incremental validation for multiple files ... "
  if run_incremental_validation "HEAD" "mock_validate_pass" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi

  echo ""

  # ============================================================================
  # Scenario 5: 체크섬 기반 캐시 무효화
  # ============================================================================

  echo -e "${BLUE}Scenario 5: Checksum-Based Cache Invalidation${NC}"

  # 5-1. 파일 캐싱
  update_cache "src/shared/api/client.ts" "valid" "[]" > /dev/null 2>&1

  # 5-2. 캐시 유효성 확인
  test_assert \
    "Cache valid after update" \
    "is_cache_valid 'src/shared/api/client.ts'" \
    0

  # 5-3. 파일 내용 변경 (체크섬 변경)
  echo "export const newFunction = () => {};" >> src/shared/api/client.ts

  # 5-4. 체크섬 불일치로 캐시 무효화
  test_assert \
    "Cache invalidated by checksum mismatch" \
    "is_cache_valid 'src/shared/api/client.ts'" \
    1

  # 5-5. 새 체크섬으로 재캐싱
  update_cache "src/shared/api/client.ts" "valid" "[]" > /dev/null 2>&1

  test_assert \
    "Cache valid with new checksum" \
    "is_cache_valid 'src/shared/api/client.ts'" \
    0

  echo ""

  # ============================================================================
  # Scenario 6: 캐시 TTL 테스트 (시뮬레이션)
  # ============================================================================

  echo -e "${BLUE}Scenario 6: Cache TTL Validation${NC}"

  # 6-1. 캐시 엔트리의 last_checked 확인
  local cache_timestamp=$(jq -r '.files["src/shared/api/client.ts"].last_checked' "$TEST_CACHE_FILE" 2>/dev/null)

  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -n "  Testing: Cache entry has last_checked timestamp ... "
  if [[ -n "$cache_timestamp" ]] && [[ "$cache_timestamp" != "null" ]]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi

  # 6-2. 캐시 만료 시뮬레이션 (과거 last_checked로 변경)
  # ISO 8601 형식으로 25시간 전 타임스탬프 생성
  local expired_timestamp=$(date -u -v-25H +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "25 hours ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
  jq --arg ts "$expired_timestamp" '.files["src/shared/api/client.ts"].last_checked = $ts' \
    "$TEST_CACHE_FILE" > "${TEST_CACHE_FILE}.tmp" 2>/dev/null
  mv "${TEST_CACHE_FILE}.tmp" "$TEST_CACHE_FILE"

  # 6-3. 만료된 캐시는 무효
  test_assert \
    "Expired cache is invalid" \
    "is_cache_valid 'src/shared/api/client.ts'" \
    1

  echo ""

  # ============================================================================
  # Scenario 7: Import 그래프 순회
  # ============================================================================

  echo -e "${BLUE}Scenario 7: Import Graph Traversal${NC}"

  # 7-1. 새 파일 생성 (여러 import 관계)
  cat > src/entities/user/repository.ts <<'EOF'
import { User } from './model';
import { apiClient } from '../../shared/api/client';

export const userRepository = {
  getUser: (id: string) => apiClient.get(`/users/${id}`),
};
EOF

  cat > src/features/auth/repository.ts <<'EOF'
import { userRepository } from '../../entities/user/repository';

export const authRepository = {
  getCurrentUser: () => userRepository.getUser('me'),
};
EOF

  git add .
  git commit -m "Add repository layer" > /dev/null 2>&1

  # 7-2. user/repository 수정 시 auth/repository도 영향받아야 함
  echo "// Modified" >> src/entities/user/repository.ts

  local affected=$(get_affected_files "src/entities/user/repository.ts" "src")

  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -n "  Testing: Import graph finds downstream dependencies ... "
  if echo "$affected" | grep -q "auth/repository.ts"; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi

  echo ""

  # ============================================================================
  # 테스트 결과 요약
  # ============================================================================

  echo ""
  echo "========================================"
  echo "Integration Test Results Summary"
  echo "========================================"
  echo "Total tests: $TOTAL_TESTS"
  echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
  echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
  echo ""

  if [[ "$FAILED_TESTS" -eq 0 ]]; then
    log_success "All integration tests passed! ✅"
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
  cd /
  rm -rf "$TEST_DIR"
}

trap cleanup EXIT

# ============================================================================
# 메인
# ============================================================================

main() {
  echo ""
  echo "========================================"
  echo "Day 1-2 Integration Tests"
  echo "Cache + Incremental + Checksum System"
  echo "========================================"
  echo ""

  # jq 확인
  if ! command -v jq &> /dev/null; then
    log_error "jq is required for integration tests"
    exit 1
  fi

  # git 확인
  if ! command -v git &> /dev/null; then
    log_error "git is required for integration tests"
    exit 1
  fi

  run_integration_tests
  local result=$?

  if [[ "$result" -eq 0 ]]; then
    log_success "Day 1-2 integration tests completed successfully! 🎉"
    echo ""
    echo "Summary:"
    echo "  ✓ Cache system with SHA256 checksum"
    echo "  ✓ Incremental validation with Git diff"
    echo "  ✓ Import graph traversal"
    echo "  ✓ Layer rule validation"
    echo "  ✓ Cache TTL management"
    echo "  ✓ Multi-file change handling"
    echo ""
    exit 0
  else
    log_error "Day 1-2 integration tests failed"
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
