#!/bin/bash
# test-quick-check.sh
# Quick Check Orchestrator 통합 테스트
#
# Usage: bash test-quick-check.sh

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

# ============================================================================
# 테스트 프로젝트 설정
# ============================================================================

setup_test_projects() {
  # FSD 프로젝트
  local fsd_project="${TEST_DIR}/fsd-project"
  mkdir -p "$fsd_project/src"/{app,pages,features,entities,shared}

  # Clean 프로젝트
  local clean_project="${TEST_DIR}/clean-project"
  mkdir -p "$clean_project/src"/{domain,application,infrastructure,presentation}

  # NestJS 프로젝트
  local nestjs_project="${TEST_DIR}/nestjs-project"
  mkdir -p "$nestjs_project/src"/{users,auth,common}
  touch "$nestjs_project/src/users/users.module.ts"
  touch "$nestjs_project/src/users/users.controller.ts"
  touch "$nestjs_project/src/auth/auth.module.ts"
  touch "$nestjs_project/src/auth/auth.controller.ts"
  touch "$nestjs_project/src/common/common.module.ts"

  # Express 프로젝트
  local express_project="${TEST_DIR}/express-project"
  mkdir -p "$express_project/src"/{routes,controllers,services,models}

  log_success "Test projects created"
}

# ============================================================================
# 테스트 실행
# ============================================================================

run_tests() {
  log_info "Starting Quick Check Orchestrator tests..."
  echo ""

  # 프로젝트 설정
  setup_test_projects

  # ============================================================================
  # 1. Architecture Detection 테스트
  # ============================================================================

  echo -e "${BLUE}1. Architecture Auto-Detection Tests${NC}"

  test_assert \
    "Detects FSD architecture" \
    "bash ${LIB_DIR}/quick-check.sh --path ${TEST_DIR}/fsd-project/src" \
    0

  test_assert \
    "Detects Clean architecture" \
    "bash ${LIB_DIR}/quick-check.sh --path ${TEST_DIR}/clean-project/src" \
    0

  test_assert \
    "Detects NestJS architecture" \
    "bash ${LIB_DIR}/quick-check.sh --path ${TEST_DIR}/nestjs-project/src" \
    0

  test_assert \
    "Detects Express architecture" \
    "bash ${LIB_DIR}/quick-check.sh --path ${TEST_DIR}/express-project/src" \
    0

  echo ""

  # ============================================================================
  # 2. Manual Architecture Selection 테스트
  # ============================================================================

  echo -e "${BLUE}2. Manual Architecture Selection Tests${NC}"

  test_assert \
    "Manual FSD selection works" \
    "bash ${LIB_DIR}/quick-check.sh --arch fsd --path ${TEST_DIR}/fsd-project/src" \
    0

  test_assert \
    "Manual Clean selection works" \
    "bash ${LIB_DIR}/quick-check.sh --arch clean --path ${TEST_DIR}/clean-project/src" \
    0

  test_assert \
    "Manual NestJS selection works" \
    "bash ${LIB_DIR}/quick-check.sh --arch nestjs --path ${TEST_DIR}/nestjs-project/src" \
    0

  echo ""

  # ============================================================================
  # 3. JSON Output 테스트
  # ============================================================================

  echo -e "${BLUE}3. JSON Output Tests${NC}"

  test_assert \
    "JSON output format works" \
    "bash ${LIB_DIR}/quick-check.sh --arch fsd --path ${TEST_DIR}/fsd-project/src --json | jq -e '.architecture == \"fsd\"'" \
    0

  echo ""

  # ============================================================================
  # 4. Error Handling 테스트
  # ============================================================================

  echo -e "${BLUE}4. Error Handling Tests${NC}"

  test_assert \
    "Invalid architecture type fails" \
    "bash ${LIB_DIR}/quick-check.sh --arch invalid" \
    2

  test_assert \
    "Non-existent path fails" \
    "bash ${LIB_DIR}/quick-check.sh --path /nonexistent/path" \
    2

  echo ""

  # ============================================================================
  # 5. Help and Usage 테스트
  # ============================================================================

  echo -e "${BLUE}5. Help and Usage Tests${NC}"

  test_assert \
    "Help option works" \
    "bash ${LIB_DIR}/quick-check.sh --help" \
    0

  echo ""

  # ============================================================================
  # 테스트 결과 요약
  # ============================================================================

  echo ""
  echo "=========================================="
  echo "Test Results Summary"
  echo "=========================================="
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
  echo "=========================================="
  echo "Quick Check Orchestrator Tests"
  echo "=========================================="
  echo ""

  # jq 확인
  if ! command -v jq &> /dev/null; then
    log_warning "jq not found - some tests will be skipped"
  fi

  run_tests
  local result=$?

  if [[ "$result" -eq 0 ]]; then
    log_success "Quick check orchestrator tests completed successfully! 🎉"
    exit 0
  else
    log_error "Quick check orchestrator tests failed"
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
