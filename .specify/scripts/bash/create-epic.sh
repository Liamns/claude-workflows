#!/bin/bash

# =============================================================================
# create-epic.sh - Epic 디렉토리 구조 생성 및 템플릿 복사
# =============================================================================
# 기능: Epic 디렉토리 구조 생성, 템플릿 변수 치환 및 복사
# 입력: Epic 이름, Epic 번호, Feature 목록
# 출력: .specify/specs/NNN-epic-name/ 구조
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
# 함수: 에러 메시지 출력 및 종료
# =============================================================================
error_exit() {
  echo -e "${RED}❌ Error: $1${NC}" >&2
  exit 1
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
if [ $# -lt 2 ]; then
  error_exit "Usage: $0 <epic-name> <epic-number> [feature1,feature2,...]"
fi

EPIC_NAME="$1"
EPIC_NUMBER="$2"
FEATURES="$3"  # 쉼표로 구분된 Feature 목록 (예: "001-oauth,002-jwt,003-permissions")

# Epic 디렉토리 경로
EPIC_DIR=".specify/specs/${EPIC_NUMBER}-epic-${EPIC_NAME}"

# 템플릿 디렉토리
TEMPLATE_DIR=".specify/templates"

# =============================================================================
# 전제조건 확인
# =============================================================================
info_msg "전제조건 확인 중..."

# .specify 디렉토리 존재 확인
if [ ! -d ".specify" ]; then
  error_exit ".specify 디렉토리가 없습니다. /start를 먼저 실행하세요."
fi

# 템플릿 파일 존재 확인
if [ ! -f "${TEMPLATE_DIR}/epic-template.md" ]; then
  error_exit "Epic 템플릿이 없습니다: ${TEMPLATE_DIR}/epic-template.md"
fi

if [ ! -f "${TEMPLATE_DIR}/roadmap-template.md" ]; then
  error_exit "Roadmap 템플릿이 없습니다: ${TEMPLATE_DIR}/roadmap-template.md"
fi

if [ ! -f "${TEMPLATE_DIR}/progress-template.md" ]; then
  error_exit "Progress 템플릿이 없습니다: ${TEMPLATE_DIR}/progress-template.md"
fi

success_msg "전제조건 확인 완료"

# =============================================================================
# Epic 디렉토리 구조 생성
# =============================================================================
info_msg "Epic 디렉토리 생성 중: ${EPIC_DIR}"

# Epic 디렉토리 생성
mkdir -p "${EPIC_DIR}"
mkdir -p "${EPIC_DIR}/features"

success_msg "Epic 디렉토리 생성 완료"

# =============================================================================
# Feature 디렉토리 생성
# =============================================================================
if [ -n "$FEATURES" ]; then
  info_msg "Feature 디렉토리 생성 중..."

  # 쉼표로 구분된 Feature 목록 파싱
  IFS=',' read -ra FEATURE_ARRAY <<< "$FEATURES"

  for FEATURE in "${FEATURE_ARRAY[@]}"; do
    FEATURE=$(echo "$FEATURE" | xargs)  # 공백 제거
    FEATURE_DIR="${EPIC_DIR}/features/${FEATURE}"

    mkdir -p "${FEATURE_DIR}"

    # Feature spec.md 템플릿 생성
    if [ -f "${TEMPLATE_DIR}/spec-template.md" ]; then
      cp "${TEMPLATE_DIR}/spec-template.md" "${FEATURE_DIR}/spec.md"
      success_msg "Feature 디렉토리 생성: ${FEATURE}"
    else
      # spec-template.md가 없으면 기본 템플릿 생성
      cat > "${FEATURE_DIR}/spec.md" <<EOF
# ${FEATURE}

## Metadata
- Feature ID: ${FEATURE}
- Epic ID: ${EPIC_NUMBER}
- Created: $(date +%Y-%m-%d)
- Status: pending
- Priority: P1
- Estimated Duration: TBD
- Dependencies: []

## Overview

This Feature is part of the **${EPIC_NAME}** Epic.

## User Scenarios & Testing

TBD

## Functional Requirements

- FR-001: TBD

## Key Entities

TBD

## Success Criteria

TBD

## Notes

Implement this Feature using the Major workflow:
\`\`\`bash
cd ${EPIC_DIR}/features/${FEATURE}
/major "${FEATURE}"
\`\`\`
EOF
      success_msg "Feature 디렉토리 생성 (기본 템플릿): ${FEATURE}"
    fi
  done
else
  warn_msg "Feature 목록이 비어있습니다. 수동으로 추가하세요."
fi

# =============================================================================
# epic.md 생성 (템플릿 복사)
# =============================================================================
info_msg "epic.md 생성 중..."

cp "${TEMPLATE_DIR}/epic-template.md" "${EPIC_DIR}/epic.md"

# 변수 치환
TODAY=$(date +%Y-%m-%d)
sed -i.bak "s/{EPIC_NAME}/${EPIC_NAME}/g" "${EPIC_DIR}/epic.md" 2>/dev/null || \
  sed -i '' "s/{EPIC_NAME}/${EPIC_NAME}/g" "${EPIC_DIR}/epic.md"

sed -i.bak "s/{EPIC_ID}/${EPIC_NUMBER}/g" "${EPIC_DIR}/epic.md" 2>/dev/null || \
  sed -i '' "s/{EPIC_ID}/${EPIC_NUMBER}/g" "${EPIC_DIR}/epic.md"

sed -i.bak "s/{CREATED_DATE}/${TODAY}/g" "${EPIC_DIR}/epic.md" 2>/dev/null || \
  sed -i '' "s/{CREATED_DATE}/${TODAY}/g" "${EPIC_DIR}/epic.md"

sed -i.bak "s/{PRIORITY}/P1/g" "${EPIC_DIR}/epic.md" 2>/dev/null || \
  sed -i '' "s/{PRIORITY}/P1/g" "${EPIC_DIR}/epic.md"

sed -i.bak "s/{ESTIMATED_DURATION}/2-3주/g" "${EPIC_DIR}/epic.md" 2>/dev/null || \
  sed -i '' "s/{ESTIMATED_DURATION}/2-3주/g" "${EPIC_DIR}/epic.md"

# .bak 파일 제거
rm -f "${EPIC_DIR}/epic.md.bak"

success_msg "epic.md 생성 완료"

# =============================================================================
# roadmap.md 생성 (템플릿 복사)
# =============================================================================
info_msg "roadmap.md 생성 중..."

cp "${TEMPLATE_DIR}/roadmap-template.md" "${EPIC_DIR}/roadmap.md"

# 변수 치환
sed -i.bak "s/{EPIC_NAME}/${EPIC_NAME}/g" "${EPIC_DIR}/roadmap.md" 2>/dev/null || \
  sed -i '' "s/{EPIC_NAME}/${EPIC_NAME}/g" "${EPIC_DIR}/roadmap.md"

# .bak 파일 제거
rm -f "${EPIC_DIR}/roadmap.md.bak"

success_msg "roadmap.md 생성 완료"

# =============================================================================
# progress.md 생성 (템플릿 복사)
# =============================================================================
info_msg "progress.md 생성 중..."

cp "${TEMPLATE_DIR}/progress-template.md" "${EPIC_DIR}/progress.md"

# 변수 치환
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
FEATURE_COUNT=$(echo "$FEATURES" | tr ',' '\n' | wc -l | xargs)

sed -i.bak "s/{EPIC_NAME}/${EPIC_NAME}/g" "${EPIC_DIR}/progress.md" 2>/dev/null || \
  sed -i '' "s/{EPIC_NAME}/${EPIC_NAME}/g" "${EPIC_DIR}/progress.md"

sed -i.bak "s/{LAST_UPDATED}/${TIMESTAMP}/g" "${EPIC_DIR}/progress.md" 2>/dev/null || \
  sed -i '' "s/{LAST_UPDATED}/${TIMESTAMP}/g" "${EPIC_DIR}/progress.md"

sed -i.bak "s/{TOTAL_FEATURES}/${FEATURE_COUNT}/g" "${EPIC_DIR}/progress.md" 2>/dev/null || \
  sed -i '' "s/{TOTAL_FEATURES}/${FEATURE_COUNT}/g" "${EPIC_DIR}/progress.md"

sed -i.bak "s/{COMPLETED_COUNT}/0/g" "${EPIC_DIR}/progress.md" 2>/dev/null || \
  sed -i '' "s/{COMPLETED_COUNT}/0/g" "${EPIC_DIR}/progress.md"

sed -i.bak "s/{IN_PROGRESS_COUNT}/0/g" "${EPIC_DIR}/progress.md" 2>/dev/null || \
  sed -i '' "s/{IN_PROGRESS_COUNT}/0/g" "${EPIC_DIR}/progress.md"

sed -i.bak "s/{PENDING_COUNT}/${FEATURE_COUNT}/g" "${EPIC_DIR}/progress.md" 2>/dev/null || \
  sed -i '' "s/{PENDING_COUNT}/${FEATURE_COUNT}/g" "${EPIC_DIR}/progress.md"

sed -i.bak "s/{COMPLETION_RATE}/0/g" "${EPIC_DIR}/progress.md" 2>/dev/null || \
  sed -i '' "s/{COMPLETION_RATE}/0/g" "${EPIC_DIR}/progress.md"

sed -i.bak "s/{PROGRESS_BAR}/░░░░░░░░░░/g" "${EPIC_DIR}/progress.md" 2>/dev/null || \
  sed -i '' "s/{PROGRESS_BAR}/░░░░░░░░░░/g" "${EPIC_DIR}/progress.md"

sed -i.bak "s/{EPIC_START_DATE}/${TODAY}/g" "${EPIC_DIR}/progress.md" 2>/dev/null || \
  sed -i '' "s/{EPIC_START_DATE}/${TODAY}/g" "${EPIC_DIR}/progress.md"

# .bak 파일 제거
rm -f "${EPIC_DIR}/progress.md.bak"

success_msg "progress.md 생성 완료"

# =============================================================================
# Git 브랜치 생성
# =============================================================================
info_msg "Git 브랜치 생성 중..."

BRANCH_NAME="${EPIC_NUMBER}-epic-${EPIC_NAME}"

if git rev-parse --git-dir > /dev/null 2>&1; then
  # Git 저장소인 경우 브랜치 생성
  if git checkout -b "${BRANCH_NAME}" 2>/dev/null; then
    success_msg "Git 브랜치 생성: ${BRANCH_NAME}"
  else
    warn_msg "Git 브랜치가 이미 존재하거나 생성할 수 없습니다: ${BRANCH_NAME}"
  fi
else
  warn_msg "Git 저장소가 아닙니다. 브랜치 생성을 건너뜁니다."
fi

# =============================================================================
# 완료 메시지
# =============================================================================
echo ""
success_msg "Epic 구조 생성 완료!"
echo ""
info_msg "Epic 디렉토리: ${EPIC_DIR}"
info_msg "Feature 개수: ${FEATURE_COUNT}"
info_msg "Branch: ${BRANCH_NAME}"
echo ""
echo -e "${BLUE}📋 다음 단계:${NC}"
echo "1. Epic 문서 검토:"
echo "   cat ${EPIC_DIR}/epic.md"
echo "   cat ${EPIC_DIR}/roadmap.md"
echo "   cat ${EPIC_DIR}/progress.md"
echo ""
echo "2. Feature 구현 시작:"
echo "   cd ${EPIC_DIR}/features/{feature-id}/"
echo "   /major \"{feature-name}\""
echo ""
echo "3. Epic 검증:"
echo "   bash .specify/scripts/bash/validate-epic.sh ${EPIC_DIR}"
echo ""

exit 0
