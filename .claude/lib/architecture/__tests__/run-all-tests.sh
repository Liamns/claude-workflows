#!/bin/bash
# run-all-tests.sh
# Day 3-4 통합 테스트: 모든 Quick Check 테스트 실행 및 성능 측정
#
# Usage: bash run-all-tests.sh

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"

# Source dependencies
source "${LIB_DIR}/../common.sh"

# 결과 저장
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
TOTAL_TIME=0

# 테스트 결과 배열 (bash 3.2 compatible)
TEST_RESULTS=""

# ============================================================================
# 헬퍼 함수
# ============================================================================

# 시간 측정 (초 단위, 소수점 포함)
get_elapsed_time() {
  local start=$1
  local end=$2
  echo "scale=3; ($end - $start) / 1000" | bc
}

# 테스트 실행 함수
run_test_suite() {
  local test_name="$1"
  local test_script="$2"

  echo ""
  echo "=========================================="
  echo "Running: $test_name"
  echo "=========================================="

  # 시작 시간 (밀리초)
  local start_time=$(date +%s%3N 2>/dev/null || echo $(($(date +%s) * 1000)))

  # 테스트 실행
  local exit_code=0
  if bash "$test_script"; then
    exit_code=0
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    exit_code=1
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi

  # 종료 시간
  local end_time=$(date +%s%3N 2>/dev/null || echo $(($(date +%s) * 1000)))

  # 실행 시간 계산
  local elapsed=0
  if command -v bc &> /dev/null; then
    elapsed=$(get_elapsed_time "$start_time" "$end_time")
  else
    elapsed=$((($end_time - $start_time) / 1000))
  fi

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  # 결과 저장 (bash 3.2 compatible)
  local status="✅ PASS"
  if [[ $exit_code -ne 0 ]]; then
    status="❌ FAIL"
  fi

  TEST_RESULTS="${TEST_RESULTS}${test_name}|${status}|${elapsed}s
"

  echo ""
  log_info "$test_name completed in ${elapsed}s"

  return $exit_code
}

# ============================================================================
# 메인 테스트 실행
# ============================================================================

main() {
  echo ""
  echo "=========================================="
  echo "Day 3-4 Integration Tests"
  echo "Quick Check Validation Suite"
  echo "=========================================="
  echo ""
  echo "Running all architecture validation tests..."
  echo ""

  # 전체 시작 시간
  local overall_start=$(date +%s%3N 2>/dev/null || echo $(($(date +%s) * 1000)))

  # 테스트 실행 (계속 진행)
  set +e

  # 1. FSD Quick Check Test
  if [[ -f "${SCRIPT_DIR}/test-quick-check-fsd.sh" ]]; then
    run_test_suite "FSD Architecture" "${SCRIPT_DIR}/test-quick-check-fsd.sh"
  else
    log_warning "FSD test not found"
  fi

  # 2. Clean Architecture Quick Check Test
  if [[ -f "${SCRIPT_DIR}/test-quick-check-clean.sh" ]]; then
    run_test_suite "Clean Architecture" "${SCRIPT_DIR}/test-quick-check-clean.sh"
  else
    log_warning "Clean Architecture test not found"
  fi

  # 3. Hexagonal Architecture Quick Check Test
  if [[ -f "${SCRIPT_DIR}/test-quick-check-hexagonal.sh" ]]; then
    run_test_suite "Hexagonal Architecture" "${SCRIPT_DIR}/test-quick-check-hexagonal.sh"
  else
    log_warning "Hexagonal Architecture test not found"
  fi

  # 4. DDD Architecture Quick Check Test
  if [[ -f "${SCRIPT_DIR}/test-quick-check-ddd.sh" ]]; then
    run_test_suite "DDD Architecture" "${SCRIPT_DIR}/test-quick-check-ddd.sh"
  else
    log_warning "DDD Architecture test not found"
  fi

  # 5. Layered Architecture Quick Check Test
  if [[ -f "${SCRIPT_DIR}/test-quick-check-layered.sh" ]]; then
    run_test_suite "Layered Architecture" "${SCRIPT_DIR}/test-quick-check-layered.sh"
  else
    log_warning "Layered Architecture test not found"
  fi

  # 6. Serverless Architecture Quick Check Test
  if [[ -f "${SCRIPT_DIR}/test-quick-check-serverless.sh" ]]; then
    run_test_suite "Serverless Architecture" "${SCRIPT_DIR}/test-quick-check-serverless.sh"
  else
    log_warning "Serverless Architecture test not found"
  fi

  set -e

  # 전체 종료 시간
  local overall_end=$(date +%s%3N 2>/dev/null || echo $(($(date +%s) * 1000)))

  # 전체 실행 시간
  local total_elapsed=0
  if command -v bc &> /dev/null; then
    total_elapsed=$(get_elapsed_time "$overall_start" "$overall_end")
  else
    total_elapsed=$((($overall_end - $overall_start) / 1000))
  fi

  # ============================================================================
  # 최종 리포트
  # ============================================================================

  echo ""
  echo ""
  echo "=========================================="
  echo "Integration Test Results"
  echo "=========================================="
  echo ""

  # 개별 테스트 결과 출력
  echo "Individual Test Results:"
  echo "----------------------------------------"
  printf "%-30s %-15s %-10s\n" "Test Suite" "Status" "Time"
  echo "----------------------------------------"

  # TEST_RESULTS 파싱 (bash 3.2 compatible)
  while IFS='|' read -r name status time; do
    if [[ -n "$name" ]]; then
      printf "%-30s %-15s %-10s\n" "$name" "$status" "$time"
    fi
  done <<< "$TEST_RESULTS"

  echo "----------------------------------------"
  echo ""

  # 전체 통계
  echo "Overall Statistics:"
  echo "----------------------------------------"
  echo "Total test suites: $TOTAL_TESTS"
  echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
  echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
  echo "Total execution time: ${total_elapsed}s"
  echo ""

  # 성능 평가
  echo "Performance Analysis:"
  echo "----------------------------------------"

  if command -v bc &> /dev/null; then
    local avg_time=$(echo "scale=3; $total_elapsed / $TOTAL_TESTS" | bc)
    echo "Average time per suite: ${avg_time}s"

    # 2초 목표 대비
    if (( $(echo "$avg_time < 2.0" | bc -l) )); then
      echo -e "${GREEN}✓ Performance goal met (<2s per suite)${NC}"
    else
      echo -e "${YELLOW}⚠ Performance goal not met (target: <2s per suite)${NC}"
    fi
  else
    echo "Performance metrics require 'bc' command"
  fi

  echo ""

  # 최종 결과
  if [[ $FAILED_TESTS -eq 0 ]]; then
    log_success "🎉 All integration tests passed!"
    echo ""
    echo "✅ Day 3-4 Quick Check implementation verified successfully"
    echo "✅ All architecture validation rules working correctly"
    echo "✅ Ready for production use"
    echo ""
    return 0
  else
    log_error "❌ $FAILED_TESTS test suite(s) failed"
    echo ""
    echo "Please review the failed tests above and fix any issues."
    echo ""
    return 1
  fi
}

# ============================================================================
# 실행
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
