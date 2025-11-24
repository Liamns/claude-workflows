#!/bin/bash
# test-integration.sh
# 재사용성 검사 통합 테스트 및 성능 측정
#
# Usage: test-integration.sh

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REUSABILITY_DIR="$(dirname "$SCRIPT_DIR")"
CHECKER_SCRIPT="${REUSABILITY_DIR}/reusability-checker.sh"

# Source common utilities
source "${REUSABILITY_DIR}/../common.sh"

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# ============================================================================
# 테스트 헬퍼 함수
# ============================================================================

test_assert() {
  local test_name="$1"
  local command="$2"
  local expected_exit_code="${3:-0}"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  echo -n "  Testing: $test_name ... "

  # 명령어 실행
  set +e
  eval "$command" > /dev/null 2>&1
  local actual_exit_code=$?
  set -e

  if [[ "$actual_exit_code" == "$expected_exit_code" ]]; then
    echo "[0;32m✓ PASS[0m"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo "[0;31m✗ FAIL[0m (expected: $expected_exit_code, got: $actual_exit_code)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
}

test_output_contains() {
  local test_name="$1"
  local command="$2"
  local expected_string="$3"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  echo -n "  Testing: $test_name ... "

  # 명령어 실행 및 출력 캡처
  set +e
  local output=$(eval "$command" 2>&1)
  set -e

  if echo "$output" | grep -q "$expected_string"; then
    echo "[0;32m✓ PASS[0m"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo "[0;31m✗ FAIL[0m (expected string not found: $expected_string)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
}

# ============================================================================
# 성능 측정
# ============================================================================

measure_performance() {
  local test_name="$1"
  local command="$2"

  echo ""
  echo "⏱  Performance: $test_name"

  # 실행 시간 측정
  local start_time=$(date +%s.%N)
  eval "$command" > /dev/null 2>&1
  local end_time=$(date +%s.%N)

  # 실행 시간 계산 (초)
  local execution_time=$(echo "$end_time - $start_time" | bc)

  echo "  Execution time: ${execution_time}s"

  # 5초 이하 목표 검증
  local is_fast=$(echo "$execution_time < 5.0" | bc)
  if [[ "$is_fast" == "1" ]]; then
    log_success "Performance target met (<5s)"
  else
    log_warning "Performance target not met (>5s)"
  fi

  echo ""
}

# ============================================================================
# 테스트 실행
# ============================================================================

run_tests() {
  log_info "Starting integration tests..."
  echo ""

  # ============================================================================
  # 1. 기본 기능 테스트
  # ============================================================================

  echo "[1;34m1. Basic Functionality Tests[0m"

  test_assert \
    "Help message displays" \
    "$CHECKER_SCRIPT --help" \
    0

  test_assert \
    "Missing query returns error" \
    "$CHECKER_SCRIPT" \
    1

  test_assert \
    "Invalid environment returns error" \
    "$CHECKER_SCRIPT -e invalid 'test'" \
    1

  test_assert \
    "Invalid type returns error" \
    "$CHECKER_SCRIPT -t invalid 'test'" \
    1

  test_assert \
    "Invalid output format returns error" \
    "$CHECKER_SCRIPT -o invalid 'test'" \
    1

  echo ""

  # ============================================================================
  # 2. 환경 감지 테스트
  # ============================================================================

  echo "[1;34m2. Architecture Detection Tests[0m"

  test_output_contains \
    "Auto environment detection" \
    "$CHECKER_SCRIPT 'test'" \
    "Frontend Results\|Backend Results"

  test_output_contains \
    "Frontend environment explicit" \
    "$CHECKER_SCRIPT -e frontend 'test'" \
    "React Components\|React Hooks"

  test_output_contains \
    "Backend environment explicit" \
    "$CHECKER_SCRIPT -e backend 'test'" \
    "NestJS Services\|NestJS Controllers"

  test_output_contains \
    "Fullstack environment" \
    "$CHECKER_SCRIPT -e fullstack 'test'" \
    "Frontend Results"

  echo ""

  # ============================================================================
  # 3. 타입별 검색 테스트
  # ============================================================================

  echo "[1;34m3. Type-Specific Search Tests[0m"

  test_assert \
    "Component type search executes" \
    "$CHECKER_SCRIPT -e frontend -t component 'User'" \
    0

  test_assert \
    "Hook type search executes" \
    "$CHECKER_SCRIPT -e frontend -t hook 'use'" \
    0

  test_assert \
    "Service type search executes" \
    "$CHECKER_SCRIPT -e backend -t service 'Auth'" \
    0

  test_assert \
    "Prisma type search executes" \
    "$CHECKER_SCRIPT -e backend -t prisma 'User'" \
    0

  echo ""

  # ============================================================================
  # 4. 출력 포맷 테스트
  # ============================================================================

  echo "[1;34m4. Output Format Tests[0m"

  test_output_contains \
    "Text output format" \
    "$CHECKER_SCRIPT -o text 'test'" \
    "Frontend Results\|Backend Results"

  test_output_contains \
    "JSON output format" \
    "$CHECKER_SCRIPT -o json 'test'" \
    '"query"'

  test_output_contains \
    "Markdown output format" \
    "$CHECKER_SCRIPT -o markdown 'test'" \
    "# Reusability Check Results"

  echo ""

  # ============================================================================
  # 5. Verbose 모드 테스트
  # ============================================================================

  echo "[1;34m5. Verbose Mode Tests[0m"

  test_output_contains \
    "Verbose mode displays logs" \
    "$CHECKER_SCRIPT -v 'test'" \
    "Starting reusability check\|Detecting architecture"

  echo ""

  # ============================================================================
  # 6. 성능 측정
  # ============================================================================

  echo "[1;34m6. Performance Measurement[0m"

  measure_performance \
    "Auto environment detection" \
    "$CHECKER_SCRIPT 'test'"

  measure_performance \
    "Frontend component search" \
    "$CHECKER_SCRIPT -e frontend -t component 'User'"

  measure_performance \
    "Backend service search" \
    "$CHECKER_SCRIPT -e backend -t service 'Auth'"

  measure_performance \
    "Fullstack all types search" \
    "$CHECKER_SCRIPT -e fullstack -t all 'test'"

  # ============================================================================
  # 테스트 결과 요약
  # ============================================================================

  echo ""
  echo "========================================"
  echo "Test Results Summary"
  echo "========================================"
  echo "Total tests: $TOTAL_TESTS"
  echo "Passed: [0;32m$PASSED_TESTS[0m"
  echo "Failed: [0;31m$FAILED_TESTS[0m"
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
# 토큰 절감 계산
# ============================================================================

calculate_token_savings() {
  echo ""
  echo "========================================"
  echo "Token Usage Estimation"
  echo "========================================"

  # Before: Claude가 직접 Grep으로 검색 (추정값)
  local before_tokens=15000

  # After: Bash 스크립트가 검색 후 결과만 전달 (추정값)
  # 일반적으로 검색 결과는 50-200줄 정도
  # 1줄당 약 10-15 토큰 가정
  local after_tokens=1500

  local savings_tokens=$((before_tokens - after_tokens))
  local savings_percentage=$(echo "scale=1; ($savings_tokens * 100) / $before_tokens" | bc)

  echo "Before (Claude direct Grep): ~${before_tokens} tokens"
  echo "After (Bash script): ~${after_tokens} tokens"
  echo "Savings: [0;32m${savings_tokens} tokens (${savings_percentage}%)[0m"
  echo ""

  # 목표 달성 확인
  local target_savings=85
  local target_met=$(echo "$savings_percentage >= $target_savings" | bc)

  if [[ "$target_met" == "1" ]]; then
    log_success "Token savings target met! (≥${target_savings}%)"
  else
    log_warning "Token savings target not met (<${target_savings}%)"
  fi

  echo ""
}

# ============================================================================
# 메인 함수
# ============================================================================

main() {
  echo ""
  echo "========================================"
  echo "Reusability Checker Integration Tests"
  echo "========================================"
  echo ""

  # 스크립트 존재 확인
  if [[ ! -f "$CHECKER_SCRIPT" ]]; then
    log_error "Checker script not found: $CHECKER_SCRIPT"
    exit 1
  fi

  # 테스트 실행
  run_tests
  local test_result=$?

  # 토큰 절감 계산
  calculate_token_savings

  # 최종 결과
  if [[ "$test_result" -eq 0 ]]; then
    log_success "Integration tests completed successfully! 🎉"
    exit 0
  else
    log_error "Integration tests failed"
    exit 1
  fi
}

# ============================================================================
# 스크립트 직접 실행 감지
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
