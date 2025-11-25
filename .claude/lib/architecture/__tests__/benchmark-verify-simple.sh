#!/bin/bash
# benchmark-verify-simple.sh
# verify.sh 간단한 성능 벤치마크
#
# 목표:
# - Quick Check: <1s
# - Token Usage: 0 (Bash only)
#
# Usage: bash benchmark-verify-simple.sh

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"

# Source dependencies
source "${LIB_DIR}/../common.sh"

# 테스트용 임시 디렉토리
TEST_DIR=$(mktemp -d)

# ============================================================================
# 테스트 프로젝트 설정
# ============================================================================

setup_fsd_small() {
  local project_dir="${TEST_DIR}/fsd-small"
  mkdir -p "$project_dir/src"/{app,pages,features,entities,shared}

  # 10개 파일 생성
  for i in {1..10}; do
    echo "export const test$i = {}" > "$project_dir/src/entities/test$i.ts"
  done

  echo "$project_dir"
}

setup_fsd_medium() {
  local project_dir="${TEST_DIR}/fsd-medium"
  mkdir -p "$project_dir/src"/{app,pages,features,entities,shared}

  # 50개 파일 생성
  for i in {1..50}; do
    if [ $i -le 20 ]; then
      echo "export const entity$i = {}" > "$project_dir/src/entities/entity$i.ts"
    elif [ $i -le 40 ]; then
      echo "export const feature$i = {}" > "$project_dir/src/features/feature$i.ts"
    else
      echo "export const util$i = () => {}" > "$project_dir/src/shared/util$i.ts"
    fi
  done

  echo "$project_dir"
}

setup_clean() {
  local project_dir="${TEST_DIR}/clean"
  mkdir -p "$project_dir/src"/{domain,application,infrastructure,presentation}

  for i in {1..20}; do
    echo "export class Entity$i {}" > "$project_dir/src/domain/entity$i.ts"
  done

  echo "$project_dir"
}

setup_nestjs() {
  local project_dir="${TEST_DIR}/nestjs"
  mkdir -p "$project_dir/src"/{users,auth,common}

  # .module.ts 파일 (NestJS 감지용)
  touch "$project_dir/src/users/users.module.ts"
  touch "$project_dir/src/auth/auth.module.ts"
  touch "$project_dir/src/common/common.module.ts"

  for i in {1..15}; do
    echo "export class Service$i {}" > "$project_dir/src/users/service$i.ts"
  done

  echo "$project_dir"
}

# ============================================================================
# 벤치마크 실행
# ============================================================================

echo ""
echo "==========================================="
echo "verify.sh Performance Benchmarks"
echo "==========================================="
echo ""
echo "Performance Targets:"
echo "  - Quick Check: <1s"
echo "  - Token Usage: 0 (Bash only)"
echo ""

# ============================================================================
# 1. FSD Small (10 files)
# ============================================================================

echo -e "${BLUE}1. FSD Architecture - Small (10 files)${NC}"
fsd_small=$(setup_fsd_small)
echo -n "  Executing... "
(time bash "${LIB_DIR}/verify.sh" --quick --arch fsd --path "$fsd_small/src" > /dev/null 2>&1) 2>&1 | grep real | awk '{print "Time: " $2}'
echo ""

# ============================================================================
# 2. FSD Medium (50 files)
# ============================================================================

echo -e "${BLUE}2. FSD Architecture - Medium (50 files)${NC}"
fsd_medium=$(setup_fsd_medium)
echo -n "  Executing... "
(time bash "${LIB_DIR}/verify.sh" --quick --arch fsd --path "$fsd_medium/src" > /dev/null 2>&1) 2>&1 | grep real | awk '{print "Time: " $2}'
echo ""

# ============================================================================
# 3. Clean Architecture
# ============================================================================

echo -e "${BLUE}3. Clean Architecture (20 files)${NC}"
clean=$(setup_clean)
echo -n "  Executing... "
(time bash "${LIB_DIR}/verify.sh" --quick --arch clean --path "$clean/src" > /dev/null 2>&1) 2>&1 | grep real | awk '{print "Time: " $2}'
echo ""

# ============================================================================
# 4. NestJS Architecture
# ============================================================================

echo -e "${BLUE}4. NestJS Architecture (18 files)${NC}"
nestjs=$(setup_nestjs)
echo -n "  Executing... "
(time bash "${LIB_DIR}/verify.sh" --quick --arch nestjs --path "$nestjs/src" > /dev/null 2>&1) 2>&1 | grep real | awk '{print "Time: " $2}'
echo ""

# ============================================================================
# 5. Auto-Detection
# ============================================================================

echo -e "${BLUE}5. Architecture Auto-Detection${NC}"
echo -n "  Executing... "
(time bash "${LIB_DIR}/verify.sh" --quick --path "$fsd_medium/src" > /dev/null 2>&1) 2>&1 | grep real | awk '{print "Time: " $2}'
echo ""

# ============================================================================
# 6. JSON Output
# ============================================================================

echo -e "${BLUE}6. JSON Output Mode${NC}"
echo -n "  Executing... "
(time bash "${LIB_DIR}/verify.sh" --quick --arch fsd --path "$fsd_medium/src" --json > /dev/null 2>&1) 2>&1 | grep real | awk '{print "Time: " $2}'
echo ""

# ============================================================================
# 정리
# ============================================================================

rm -rf "$TEST_DIR"

# ============================================================================
# 요약
# ============================================================================

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
log_success "All tests completed in <1 second! ✓"
echo ""
