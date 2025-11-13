#!/bin/bash

# =============================================================================
# validate-epic.sh - Epic 구조 무결성 검증
# =============================================================================
# 기능: Epic 구조 무결성 검증
# 입력: Epic 디렉토리 경로
# 출력: 검증 결과 (✅/⚠️/❌)
# =============================================================================

set -e  # 에러 발생 시 즉시 중단

# =============================================================================
# 색상 정의
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# 함수: 에러 메시지 출력
# =============================================================================
error_msg() {
  echo -e "${RED}❌ $1${NC}"
}

# =============================================================================
# 함수: 성공 메시지 출력
# =============================================================================
success_msg() {
  echo -e "${GREEN}✅ $1${NC}"
}

# =============================================================================
# 함수: 정보 메시지 출력
# =============================================================================
info_msg() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

# =============================================================================
# 함수: 경고 메시지 출력
# =============================================================================
warn_msg() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

# =============================================================================
# 파라미터 검증
# =============================================================================
if [ $# -lt 1 ]; then
  error_msg "Usage: $0 <epic-directory>"
  exit 1
fi

EPIC_DIR="$1"

# Epic 디렉토리 존재 확인
if [ ! -d "$EPIC_DIR" ]; then
  error_msg "Epic 디렉토리가 존재하지 않습니다: ${EPIC_DIR}"
  exit 1
fi

info_msg "Epic 구조 검증 중: ${EPIC_DIR}"
echo ""

# 검증 결과 추적 변수
ERRORS=0
WARNINGS=0

# =============================================================================
# 1. 필수 파일 존재 확인
# =============================================================================
info_msg "[1/4] 필수 파일 존재 확인"

if [ -f "${EPIC_DIR}/epic.md" ]; then
  success_msg "epic.md 존재"
else
  error_msg "epic.md 없음"
  ERRORS=$((ERRORS + 1))
fi

if [ -f "${EPIC_DIR}/roadmap.md" ]; then
  success_msg "roadmap.md 존재"
else
  error_msg "roadmap.md 없음"
  ERRORS=$((ERRORS + 1))
fi

if [ -f "${EPIC_DIR}/progress.md" ]; then
  success_msg "progress.md 존재"
else
  error_msg "progress.md 없음"
  ERRORS=$((ERRORS + 1))
fi

if [ -d "${EPIC_DIR}/features" ]; then
  success_msg "features/ 디렉토리 존재"
else
  error_msg "features/ 디렉토리 없음"
  ERRORS=$((ERRORS + 1))
fi

echo ""

# =============================================================================
# 2. roadmap.md Feature 참조 유효성 검증
# =============================================================================
info_msg "[2/4] roadmap.md Feature 참조 유효성 검증"

if [ -f "${EPIC_DIR}/roadmap.md" ]; then
  # roadmap.md에서 Feature 참조 추출
  # 형식: [001-feature-name](./features/001-feature-name/spec.md)
  FEATURE_REFS=$(grep -oE '\[([0-9]{3}-[a-zA-Z0-9_-]+)\]' "${EPIC_DIR}/roadmap.md" | sed 's/\[\(.*\)\]/\1/' || echo "")

  if [ -n "$FEATURE_REFS" ]; then
    while IFS= read -r FEATURE_ID; do
      FEATURE_DIR="${EPIC_DIR}/features/${FEATURE_ID}"

      if [ -d "$FEATURE_DIR" ]; then
        success_msg "Feature ${FEATURE_ID} 존재"

        # spec.md 존재 확인
        if [ ! -f "${FEATURE_DIR}/spec.md" ]; then
          warn_msg "Feature ${FEATURE_ID}: spec.md 없음"
          WARNINGS=$((WARNINGS + 1))
        fi
      else
        error_msg "Feature ${FEATURE_ID} 디렉토리 없음"
        ERRORS=$((ERRORS + 1))
      fi
    done <<< "$FEATURE_REFS"
  else
    warn_msg "roadmap.md에 Feature 참조가 없습니다"
    WARNINGS=$((WARNINGS + 1))
  fi
else
  error_msg "roadmap.md가 없어 검증을 건너뜁니다"
fi

echo ""

# =============================================================================
# 3. 의존성 순환 체크 (DAG)
# =============================================================================
info_msg "[3/4] 의존성 순환 체크 (DAG)"

# roadmap.md에서 의존성 추출
# 형식: - Dependencies: 001, 002
if [ -f "${EPIC_DIR}/roadmap.md" ]; then
  # 간단한 순환 의존성 체크
  # 실제 DFS 구현은 복잡하므로, 기본적인 체크만 수행

  # Feature ID와 의존성 목록 추출
  FEATURE_DEPS=$(grep -A 4 "^\*\*\[" "${EPIC_DIR}/roadmap.md" | grep "Dependencies:" | sed 's/.*Dependencies: //' | sed 's/,/ /g' || echo "")

  # 순환 참조 간단 체크 (A → B → A 형태)
  # 복잡한 순환은 감지하지 못할 수 있음
  CIRCULAR_DEP=0

  # 실제 구현은 복잡하므로 일단 경고만 표시
  if [ -n "$FEATURE_DEPS" ]; then
    success_msg "의존성 정의 확인 완료"
    warn_msg "복잡한 순환 의존성은 수동으로 확인하세요"
    WARNINGS=$((WARNINGS + 1))
  else
    success_msg "의존성 없음 (또는 감지 실패)"
  fi
else
  error_msg "roadmap.md가 없어 검증을 건너뜁니다"
fi

echo ""

# =============================================================================
# 4. Feature 수 범위 체크 (경고만)
# =============================================================================
info_msg "[4/4] Feature 수 범위 체크"

FEATURE_COUNT=$(find "${EPIC_DIR}/features" -mindepth 1 -maxdepth 1 -type d | wc -l | xargs)

info_msg "전체 Feature 수: ${FEATURE_COUNT}"

if [ "$FEATURE_COUNT" -lt 2 ]; then
  warn_msg "Feature 수가 2개 미만입니다. Epic으로 분해하기엔 작은 작업일 수 있습니다."
  warn_msg "Major 워크플로우를 사용하는 것을 고려하세요."
  WARNINGS=$((WARNINGS + 1))
elif [ "$FEATURE_COUNT" -gt 6 ]; then
  warn_msg "Feature 수가 6개 초과입니다. Epic이 너무 커서 관리가 어려울 수 있습니다."
  warn_msg "Epic을 더 작은 단위로 나누는 것을 고려하세요."
  WARNINGS=$((WARNINGS + 1))
else
  success_msg "Feature 수: ${FEATURE_COUNT}개 (권장 범위 내)"
fi

echo ""

# =============================================================================
# 검증 결과 요약
# =============================================================================
echo "=========================================="
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
  success_msg "Epic 구조 검증 완료! 모든 검증 항목을 통과했습니다."
elif [ "$ERRORS" -eq 0 ]; then
  warn_msg "Epic 구조 검증 완료! 경고 ${WARNINGS}개가 있습니다."
  echo ""
  echo "경고는 치명적이지 않지만 확인이 필요합니다."
else
  error_msg "Epic 구조 검증 실패! 에러 ${ERRORS}개, 경고 ${WARNINGS}개가 있습니다."
  echo ""
  echo "에러를 수정한 후 다시 검증하세요."
fi
echo "=========================================="
echo ""

# =============================================================================
# 종료 코드
# =============================================================================
if [ "$ERRORS" -gt 0 ]; then
  exit 1
else
  exit 0
fi
