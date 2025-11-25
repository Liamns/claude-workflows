#!/bin/bash
# benchmark-cache.sh
# 캐시 및 증분 검증 성능 벤치마크
#
# Usage: bash benchmark-cache.sh

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"

# Source dependencies
source "${LIB_DIR}/../common.sh"

# 벤치마크 설정
BENCHMARK_RUNS=10
TEST_FILE_COUNT=50

# 테스트용 임시 디렉토리
TEST_DIR=$(mktemp -d)
TEST_GIT_REPO="${TEST_DIR}/test-repo"
TEST_CACHE_DIR="${TEST_DIR}/cache"
TEST_CACHE_FILE="${TEST_CACHE_DIR}/validation-cache.json"

# ============================================================================
# 시간 측정 헬퍼
# ============================================================================

# 밀리초 단위 시간 측정
time_ms() {
  local command="$1"

  local start_time=$(date +%s%N)
  eval "$command" > /dev/null 2>&1
  local end_time=$(date +%s%N)

  # 나노초를 밀리초로 변환
  local elapsed_ns=$((end_time - start_time))
  local elapsed_ms=$((elapsed_ns / 1000000))

  echo "$elapsed_ms"
}

# 평균 계산
calculate_average() {
  local sum=0
  local count=0

  for value in "$@"; do
    sum=$((sum + value))
    count=$((count + 1))
  done

  echo $((sum / count))
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

  # 테스트 파일 생성 (50개)
  mkdir -p src/entities src/features src/shared
  for i in $(seq 1 $TEST_FILE_COUNT); do
    if [ $i -le 20 ]; then
      echo "export const entity$i = {}" > "src/entities/entity$i.ts"
    elif [ $i -le 40 ]; then
      echo "export const feature$i = {}" > "src/features/feature$i.ts"
    else
      echo "export const shared$i = {}" > "src/shared/shared$i.ts"
    fi
  done

  git add .
  git commit -m "Initial commit" > /dev/null 2>&1

  log_success "Git test repository created with $TEST_FILE_COUNT files"
}

# ============================================================================
# 캐시 시스템 로드
# ============================================================================

load_cache_system() {
  # 테스트용 캐시 환경 설정
  local PROJECT_ROOT
  PROJECT_ROOT=$(cd "${LIB_DIR}/../.." && pwd)

  cat > "${TEST_DIR}/cache-env.sh" <<EOF
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
    >> "${TEST_DIR}/cache-env.sh"

  # incremental.sh 함수들
  sed -n '/^get_changed_files()/,/^# Note: This module is designed/p' \
    "${LIB_DIR}/incremental.sh" | \
    grep -v "^# Note: This module" | \
    sed '/^log_debug() {/,/^}/d' \
    >> "${TEST_DIR}/cache-env.sh"

  source "${TEST_DIR}/cache-env.sh"
}

# ============================================================================
# 벤치마크 1: 캐시 초기화
# ============================================================================

benchmark_cache_init() {
  log_info "Benchmark 1: Cache Initialization"

  local times=()

  for i in $(seq 1 $BENCHMARK_RUNS); do
    # 캐시 삭제
    rm -rf "$TEST_CACHE_DIR"

    # 시간 측정
    local elapsed=$(time_ms "init_cache")
    times+=($elapsed)

    echo -n "."
  done

  echo ""

  local avg=$(calculate_average "${times[@]}")
  echo "  Average: ${avg}ms"
  echo "  Target: <500ms"

  if [ $avg -lt 500 ]; then
    log_success "✓ Cache init: ${avg}ms (PASS)"
  else
    log_warning "⚠ Cache init: ${avg}ms (SLOW)"
  fi

  echo ""
}

# ============================================================================
# 벤치마크 2: 캐시 히트 (is_cache_valid)
# ============================================================================

benchmark_cache_hit() {
  log_info "Benchmark 2: Cache Hit (is_cache_valid)"

  # 캐시 준비
  init_cache > /dev/null 2>&1
  local test_file="src/entities/entity1.ts"
  update_cache "$test_file" "valid" "[]" > /dev/null 2>&1

  local times=()

  for i in $(seq 1 $BENCHMARK_RUNS); do
    local elapsed=$(time_ms "is_cache_valid '$test_file'")
    times+=($elapsed)
    echo -n "."
  done

  echo ""

  local avg=$(calculate_average "${times[@]}")
  echo "  Average: ${avg}ms"
  echo "  Target: <500ms"

  if [ $avg -lt 500 ]; then
    log_success "✓ Cache hit: ${avg}ms (PASS)"
  else
    log_warning "⚠ Cache hit: ${avg}ms (SLOW)"
  fi

  echo ""
}

# ============================================================================
# 벤치마크 3: 캐시 미스 (파일 변경 감지)
# ============================================================================

benchmark_cache_miss() {
  log_info "Benchmark 3: Cache Miss (file change detection)"

  # 캐시 준비
  init_cache > /dev/null 2>&1
  local test_file="src/entities/entity2.ts"
  update_cache "$test_file" "valid" "[]" > /dev/null 2>&1

  local times=()

  for i in $(seq 1 $BENCHMARK_RUNS); do
    # 파일 수정 (캐시 무효화)
    echo "// modified $i" >> "$test_file"

    local elapsed=$(time_ms "is_cache_valid '$test_file'")
    times+=($elapsed)

    # 캐시 재설정
    update_cache "$test_file" "valid" "[]" > /dev/null 2>&1
    echo -n "."
  done

  echo ""

  local avg=$(calculate_average "${times[@]}")
  echo "  Average: ${avg}ms"
  echo "  Target: <2000ms"

  if [ $avg -lt 2000 ]; then
    log_success "✓ Cache miss: ${avg}ms (PASS)"
  else
    log_warning "⚠ Cache miss: ${avg}ms (SLOW)"
  fi

  echo ""
}

# ============================================================================
# 벤치마크 4: 증분 검증 (캐시 있음)
# ============================================================================

benchmark_incremental_with_cache() {
  log_info "Benchmark 4: Incremental Validation (with cache)"

  # 캐시 준비 - 모든 파일 캐시
  init_cache > /dev/null 2>&1
  for file in src/**/*.ts; do
    if [ -f "$file" ]; then
      update_cache "$file" "valid" "[]" > /dev/null 2>&1
    fi
  done

  # 파일 1개 수정
  echo "// modified" >> "src/entities/entity3.ts"

  # 검증 함수
  validate_pass() {
    return 0
  }

  local times=()

  for i in $(seq 1 $BENCHMARK_RUNS); do
    local elapsed=$(time_ms "run_incremental_validation 'HEAD' 'validate_pass'")
    times+=($elapsed)
    echo -n "."
  done

  echo ""

  local avg=$(calculate_average "${times[@]}")
  echo "  Average: ${avg}ms"
  echo "  Target: <2000ms"

  if [ $avg -lt 2000 ]; then
    log_success "✓ Incremental (cached): ${avg}ms (PASS)"
  else
    log_warning "⚠ Incremental (cached): ${avg}ms (SLOW)"
  fi

  echo ""
}

# ============================================================================
# 벤치마크 5: 증분 검증 (캐시 없음)
# ============================================================================

benchmark_incremental_no_cache() {
  log_info "Benchmark 5: Incremental Validation (no cache)"

  # 캐시 삭제
  rm -rf "$TEST_CACHE_DIR"
  init_cache > /dev/null 2>&1

  # 파일 5개 수정
  for i in $(seq 1 5); do
    echo "// modified" >> "src/entities/entity$i.ts"
  done

  # 검증 함수
  validate_pass() {
    return 0
  }

  local times=()

  for i in $(seq 1 $BENCHMARK_RUNS); do
    # 캐시 초기화
    rm -rf "$TEST_CACHE_DIR"
    init_cache > /dev/null 2>&1

    local elapsed=$(time_ms "run_incremental_validation 'HEAD' 'validate_pass'")
    times+=($elapsed)
    echo -n "."
  done

  echo ""

  local avg=$(calculate_average "${times[@]}")
  echo "  Average: ${avg}ms"
  echo "  Target: <2000ms (5 files)"

  if [ $avg -lt 2000 ]; then
    log_success "✓ Incremental (no cache, 5 files): ${avg}ms (PASS)"
  else
    log_warning "⚠ Incremental (no cache, 5 files): ${avg}ms (SLOW)"
  fi

  echo ""
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
  echo "Cache & Incremental Validation Benchmark"
  echo "========================================"
  echo ""

  log_info "Configuration:"
  echo "  Benchmark runs: $BENCHMARK_RUNS"
  echo "  Test files: $TEST_FILE_COUNT"
  echo ""

  # Git 환경 설정
  setup_git_repo

  # 캐시 시스템 로드
  load_cache_system

  echo ""

  # 벤치마크 실행
  benchmark_cache_init
  benchmark_cache_hit
  benchmark_cache_miss
  benchmark_incremental_with_cache
  benchmark_incremental_no_cache

  # 결과 요약
  echo "========================================"
  echo "Benchmark Summary"
  echo "========================================"
  echo ""
  log_success "All benchmarks completed! 🎉"
  echo ""
  echo "Performance Targets:"
  echo "  ✓ Cache init: <500ms"
  echo "  ✓ Cache hit: <500ms"
  echo "  ✓ Cache miss: <2000ms"
  echo "  ✓ Incremental validation: <2000ms"
  echo ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
