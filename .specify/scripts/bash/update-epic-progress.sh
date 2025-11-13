#!/bin/bash

# =============================================================================
# update-epic-progress.sh - Epic 진행 상황 자동 업데이트
# =============================================================================
# 기능: Feature 완료 시 progress.md 자동 업데이트
# 입력: Epic 디렉토리 경로
# 출력: 업데이트된 progress.md
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
if [ $# -lt 1 ]; then
  error_exit "Usage: $0 <epic-directory>"
fi

EPIC_DIR="$1"

# Epic 디렉토리 존재 확인
if [ ! -d "$EPIC_DIR" ]; then
  error_exit "Epic 디렉토리가 존재하지 않습니다: ${EPIC_DIR}"
fi

# progress.md 존재 확인
PROGRESS_FILE="${EPIC_DIR}/progress.md"
if [ ! -f "$PROGRESS_FILE" ]; then
  error_exit "progress.md가 존재하지 않습니다: ${PROGRESS_FILE}"
fi

info_msg "Epic 진행 상황 업데이트 중: ${EPIC_DIR}"

# =============================================================================
# Feature 상태 감지
# =============================================================================
info_msg "Feature 상태 감지 중..."

TOTAL_FEATURES=0
COMPLETED_FEATURES=0
IN_PROGRESS_FEATURES=0
PENDING_FEATURES=0

# features 디렉토리의 모든 Feature 디렉토리 순회
for FEATURE_DIR in "${EPIC_DIR}"/features/*/; do
  if [ ! -d "$FEATURE_DIR" ]; then
    continue
  fi

  TOTAL_FEATURES=$((TOTAL_FEATURES + 1))
  FEATURE_ID=$(basename "$FEATURE_DIR")

  # Feature 완료 여부 확인
  # 1. tasks.md 존재 확인
  # 2. tasks.md에서 완료율 확인
  # 3. yarn test 결과 확인 (선택)
  # 4. yarn build 결과 확인 (선택)

  TASKS_FILE="${FEATURE_DIR}/tasks.md"

  if [ -f "$TASKS_FILE" ]; then
    # tasks.md에서 완료된 task 개수 확인
    TOTAL_TASKS=$(grep -c "^\- \[" "$TASKS_FILE" || echo "0")
    COMPLETED_TASKS=$(grep -c "^\- \[x\]" "$TASKS_FILE" || echo "0")

    if [ "$TOTAL_TASKS" -gt 0 ]; then
      COMPLETION_PERCENT=$((COMPLETED_TASKS * 100 / TOTAL_TASKS))

      if [ "$COMPLETION_PERCENT" -eq 100 ]; then
        # 100% 완료 → 테스트 및 빌드 확인
        # 실제로는 yarn test/build를 실행하지 않고, 완료로 간주
        # (테스트 실행은 Feature 구현 단계에서 이미 수행됨)
        COMPLETED_FEATURES=$((COMPLETED_FEATURES + 1))
        info_msg "Feature ${FEATURE_ID}: ✅ Completed"
      elif [ "$COMPLETION_PERCENT" -gt 0 ]; then
        # 0% < x < 100% → In Progress
        IN_PROGRESS_FEATURES=$((IN_PROGRESS_FEATURES + 1))
        info_msg "Feature ${FEATURE_ID}: 🔄 In Progress (${COMPLETION_PERCENT}%)"
      else
        # 0% → Pending
        PENDING_FEATURES=$((PENDING_FEATURES + 1))
        info_msg "Feature ${FEATURE_ID}: ⬜ Pending"
      fi
    else
      # tasks.md가 비어있으면 Pending
      PENDING_FEATURES=$((PENDING_FEATURES + 1))
      info_msg "Feature ${FEATURE_ID}: ⬜ Pending (no tasks)"
    fi
  else
    # tasks.md가 없으면 Pending
    PENDING_FEATURES=$((PENDING_FEATURES + 1))
    info_msg "Feature ${FEATURE_ID}: ⬜ Pending (no tasks.md)"
  fi
done

# 전체 Feature 개수가 0이면 에러
if [ "$TOTAL_FEATURES" -eq 0 ]; then
  error_exit "Epic에 Feature가 없습니다: ${EPIC_DIR}/features/"
fi

# 완료율 계산
COMPLETION_RATE=$((COMPLETED_FEATURES * 100 / TOTAL_FEATURES))

# Progress Bar 생성 (10칸)
FILLED_BLOCKS=$((COMPLETION_RATE / 10))
EMPTY_BLOCKS=$((10 - FILLED_BLOCKS))
PROGRESS_BAR=""

for ((i=0; i<FILLED_BLOCKS; i++)); do
  PROGRESS_BAR="${PROGRESS_BAR}█"
done

for ((i=0; i<EMPTY_BLOCKS; i++)); do
  PROGRESS_BAR="${PROGRESS_BAR}░"
done

info_msg "Feature 상태: ${COMPLETED_FEATURES}/${TOTAL_FEATURES} 완료 (${COMPLETION_RATE}%)"

# =============================================================================
# progress.md 업데이트
# =============================================================================
info_msg "progress.md 업데이트 중..."

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# 임시 파일 생성
TEMP_FILE=$(mktemp)

# progress.md 읽기 및 업데이트
while IFS= read -r line; do
  # Last Updated 업데이트
  if [[ "$line" =~ ^\>\ Last\ Updated: ]]; then
    echo "> Last Updated: ${TIMESTAMP}" >> "$TEMP_FILE"

  # Total Features 업데이트
  elif [[ "$line" =~ ^\-\ \*\*Total\ Features:\*\* ]]; then
    echo "- **Total Features:** ${TOTAL_FEATURES}" >> "$TEMP_FILE"

  # Completed 업데이트
  elif [[ "$line" =~ ^\-\ \*\*Completed:\*\* ]]; then
    echo "- **Completed:** ${COMPLETED_FEATURES} ✅" >> "$TEMP_FILE"

  # In Progress 업데이트
  elif [[ "$line" =~ ^\-\ \*\*In\ Progress:\*\* ]]; then
    echo "- **In Progress:** ${IN_PROGRESS_FEATURES} 🔄" >> "$TEMP_FILE"

  # Pending 업데이트
  elif [[ "$line" =~ ^\-\ \*\*Pending:\*\* ]]; then
    echo "- **Pending:** ${PENDING_FEATURES} ⬜" >> "$TEMP_FILE"

  # Completion Rate 업데이트
  elif [[ "$line" =~ ^\-\ \*\*Completion\ Rate:\*\* ]]; then
    echo "- **Completion Rate:** ${COMPLETION_RATE}%" >> "$TEMP_FILE"

  # Progress Bar 업데이트
  elif [[ "$line" =~ ^\[.*\]\ [0-9]+% ]]; then
    echo "[${PROGRESS_BAR}] ${COMPLETION_RATE}%" >> "$TEMP_FILE"

  else
    # 그 외 라인은 그대로 유지
    echo "$line" >> "$TEMP_FILE"
  fi
done < "$PROGRESS_FILE"

# 임시 파일을 progress.md로 덮어쓰기
mv "$TEMP_FILE" "$PROGRESS_FILE"

success_msg "progress.md 업데이트 완료"

# =============================================================================
# 완료 메시지
# =============================================================================
echo ""
success_msg "Epic 진행 상황 업데이트 완료!"
echo ""
info_msg "Epic: ${EPIC_DIR}"
info_msg "전체 Features: ${TOTAL_FEATURES}"
info_msg "완료: ${COMPLETED_FEATURES} ✅"
info_msg "진행 중: ${IN_PROGRESS_FEATURES} 🔄"
info_msg "대기 중: ${PENDING_FEATURES} ⬜"
info_msg "완료율: ${COMPLETION_RATE}%"
echo ""
echo -e "${BLUE}Progress Bar: [${PROGRESS_BAR}] ${COMPLETION_RATE}%${NC}"
echo ""

# Epic 완료 확인
if [ "$COMPLETION_RATE" -eq 100 ]; then
  success_msg "🎉 Epic 완료! 모든 Feature가 완료되었습니다."
  echo ""
  echo -e "${BLUE}📋 다음 단계:${NC}"
  echo "1. epic.md의 Status를 'completed'로 업데이트"
  echo "2. 전체 통합 테스트 실행"
  echo "3. 성능 테스트 실행"
  echo "4. 사용자 수용 테스트"
  echo ""
fi

exit 0
