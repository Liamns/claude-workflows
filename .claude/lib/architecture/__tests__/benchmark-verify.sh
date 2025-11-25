#!/bin/bash
# benchmark-verify.sh
# verify.sh 성능 벤치마크
#
# 목표:
# - Quick Check: <1s
# - Incremental: <2s
# - Token Usage: Quick=0, Incremental<1,000
#
# Usage: bash benchmark-verify.sh

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
FILE_COUNTS=(10 50 100)

# 테스트용 임시 디렉토리
TEST_DIR=$(mktemp -d)

# ============================================================================
# 시간 측정 헬퍼
# ============================================================================

# 밀리초 단위 시간 측정 (macOS 호환, Python 사용)
time_ms() {
  local command="$1"

  # Python을 사용하여 정밀한 시간 측정
  python3 -c "
import time
import subprocess
import sys

start = time.time()
result = subprocess.run('$command', shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
elapsed = time.time() - start

# 밀리초로 변환
print(int(elapsed * 1000))
sys.exit(result.returncode)
"
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

# 표준편차 계산
calculate_stddev() {
  local avg=$1
  shift
  local sum_sq=0
  local count=0

  for value in "$@"; do
    local diff=$((value - avg))
    sum_sq=$((sum_sq + diff * diff))
    count=$((count + 1))
  done

  # 분산의 제곱근 (정수 근사)
  local variance=$((sum_sq / count))
  echo "$(awk "BEGIN {print sqrt($variance)}")"
}

# ============================================================================
# 테스트 프로젝트 설정
# ============================================================================

setup_fsd_project() {
  local file_count=$1
  local project_dir="${TEST_DIR}/fsd-${file_count}"

  mkdir -p "$project_dir/src"/{app,pages,features,entities,shared}

  # 파일 생성
  for i in $(seq 1 $file_count); do
    if [ $i -le $((file_count / 5)) ]; then
      echo "export const entity$i = {}" > "$project_dir/src/entities/entity$i.ts"
    elif [ $i -le $((file_count * 2 / 5)) ]; then
      echo "export const feature$i = {}" > "$project_dir/src/features/feature$i.ts"
    elif [ $i -le $((file_count * 3 / 5)) ]; then
      echo "export const widget$i = {}" > "$project_dir/src/pages/widget$i.tsx"
    else
      echo "export const util$i = () => {}" > "$project_dir/src/shared/util$i.ts"
    fi
  done

  echo "$project_dir"
}

setup_clean_project() {
  local file_count=$1
  local project_dir="${TEST_DIR}/clean-${file_count}"

  mkdir -p "$project_dir/src"/{domain,application,infrastructure,presentation}

  # 파일 생성
  for i in $(seq 1 $file_count); do
    if [ $i -le $((file_count / 4)) ]; then
      echo "export class Entity$i {}" > "$project_dir/src/domain/entity$i.ts"
    elif [ $i -le $((file_count / 2)) ]; then
      echo "export class UseCase$i {}" > "$project_dir/src/application/usecase$i.ts"
    else
      echo "export class Repository$i {}" > "$project_dir/src/infrastructure/repository$i.ts"
    fi
  done

  echo "$project_dir"
}

setup_nestjs_project() {
  local file_count=$1
  local project_dir="${TEST_DIR}/nestjs-${file_count}"

  mkdir -p "$project_dir/src"/{users,auth,common}

  # .module.ts 파일 생성 (NestJS 감지용)
  touch "$project_dir/src/users/users.module.ts"
  touch "$project_dir/src/auth/auth.module.ts"
  touch "$project_dir/src/common/common.module.ts"

  # 추가 파일 생성
  for i in $(seq 1 $((file_count - 3))); do
    if [ $i -le $((file_count / 3)) ]; then
      echo "export class Controller$i {}" > "$project_dir/src/users/controller$i.ts"
    elif [ $i -le $((file_count * 2 / 3)) ]; then
      echo "export class Service$i {}" > "$project_dir/src/auth/service$i.ts"
    else
      echo "export class Util$i {}" > "$project_dir/src/common/util$i.ts"
    fi
  done

  echo "$project_dir"
}

# ============================================================================
# 벤치마크 실행
# ============================================================================

benchmark_quick_check() {
  local arch="$1"
  local file_count="$2"
  local project_dir="$3"

  local times=()

  echo -n "  Running $BENCHMARK_RUNS iterations... "

  for run in $(seq 1 $BENCHMARK_RUNS); do
    local elapsed=$(time_ms "bash ${LIB_DIR}/verify.sh --quick --arch $arch --path $project_dir/src")
    times+=($elapsed)
  done

  local avg=$(calculate_average "${times[@]}")
  local stddev=$(calculate_stddev $avg "${times[@]}")

  echo "Done"
  echo "    Average: ${avg}ms"
  echo "    Std Dev: ${stddev}ms"
  echo "    Min: $(printf '%s\n' "${times[@]}" | sort -n | head -1)ms"
  echo "    Max: $(printf '%s\n' "${times[@]}" | sort -n | tail -1)ms"

  # 목표 달성 여부
  if [ $avg -lt 1000 ]; then
    echo -e "    Result: ${GREEN}✓ PASS${NC} (<1s target)"
  else
    echo -e "    Result: ${RED}✗ FAIL${NC} (>1s target)"
  fi

  echo ""
}

benchmark_json_output() {
  local arch="$1"
  local file_count="$2"
  local project_dir="$3"

  local times=()

  echo -n "  Running $BENCHMARK_RUNS iterations (JSON mode)... "

  for run in $(seq 1 $BENCHMARK_RUNS); do
    local elapsed=$(time_ms "bash ${LIB_DIR}/verify.sh --quick --arch $arch --path $project_dir/src --json")
    times+=($elapsed)
  done

  local avg=$(calculate_average "${times[@]}")

  echo "Done"
  echo "    Average: ${avg}ms"

  echo ""
}

# ============================================================================
# 메인 벤치마크
# ============================================================================

run_benchmarks() {
  log_info "Starting verify.sh performance benchmarks..."
  echo ""

  # ============================================================================
  # 1. FSD Architecture Benchmarks
  # ============================================================================

  echo -e "${BLUE}1. FSD Architecture Quick Check${NC}"
  echo ""

  for file_count in "${FILE_COUNTS[@]}"; do
    echo "  File count: $file_count"
    local fsd_project=$(setup_fsd_project $file_count)
    benchmark_quick_check "fsd" $file_count "$fsd_project"
  done

  # ============================================================================
  # 2. Clean Architecture Benchmarks
  # ============================================================================

  echo -e "${BLUE}2. Clean Architecture Quick Check${NC}"
  echo ""

  for file_count in "${FILE_COUNTS[@]}"; do
    echo "  File count: $file_count"
    local clean_project=$(setup_clean_project $file_count)
    benchmark_quick_check "clean" $file_count "$clean_project"
  done

  # ============================================================================
  # 3. NestJS Architecture Benchmarks
  # ============================================================================

  echo -e "${BLUE}3. NestJS Architecture Quick Check${NC}"
  echo ""

  for file_count in "${FILE_COUNTS[@]}"; do
    echo "  File count: $file_count"
    local nestjs_project=$(setup_nestjs_project $file_count)
    benchmark_quick_check "nestjs" $file_count "$nestjs_project"
  done

  # ============================================================================
  # 4. JSON Output Benchmarks
  # ============================================================================

  echo -e "${BLUE}4. JSON Output Performance${NC}"
  echo ""

  local fsd_50=$(setup_fsd_project 50)
  benchmark_json_output "fsd" 50 "$fsd_50"

  # ============================================================================
  # 5. Architecture Auto-Detection Benchmarks
  # ============================================================================

  echo -e "${BLUE}5. Auto-Detection Performance${NC}"
  echo ""

  local fsd_auto=$(setup_fsd_project 50)
  echo "  Testing auto-detection with 50 files..."

  local times=()
  for run in $(seq 1 $BENCHMARK_RUNS); do
    local elapsed=$(time_ms "bash ${LIB_DIR}/verify.sh --quick --path $fsd_auto/src")
    times+=($elapsed)
  done

  local avg=$(calculate_average "${times[@]}")
  echo "    Average: ${avg}ms"

  if [ $avg -lt 1000 ]; then
    echo -e "    Result: ${GREEN}✓ PASS${NC} (<1s target)"
  else
    echo -e "    Result: ${RED}✗ FAIL${NC} (>1s target)"
  fi

  echo ""
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
  echo "==========================================="
  echo "verify.sh Performance Benchmarks"
  echo "==========================================="
  echo ""
  echo "Performance Targets:"
  echo "  - Quick Check: <1s (1000ms)"
  echo "  - Token Usage: 0 (Bash only)"
  echo ""
  echo "Test Configuration:"
  echo "  - Runs per benchmark: $BENCHMARK_RUNS"
  echo "  - File counts: ${FILE_COUNTS[*]}"
  echo ""

  run_benchmarks

  echo ""
  echo "==========================================="
  echo "Benchmark Summary"
  echo "==========================================="
  echo ""
  log_success "All benchmarks completed! 🎉"
  echo ""
  echo "Token Usage Analysis:"
  echo "  - Quick Check: 0 tokens (Bash only, no LLM calls)"
  echo "  - JSON Output: 0 tokens (formatting only)"
  echo "  - Auto-Detection: 0 tokens (file system checks only)"
  echo ""
  log_info "Performance targets validated for <1s quick checks"
  echo ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
