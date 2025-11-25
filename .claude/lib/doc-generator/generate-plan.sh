#!/bin/bash
# generate-plan.sh
# Feature Implementation Plan 문서 자동 생성 스크립트
# Epic 006 - Feature 003: Template-based Document Generation

set -euo pipefail

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 사용법 출력
usage() {
  cat <<EOF
Usage: bash .claude/lib/doc-generator/generate-plan.sh [OPTIONS]

Feature Implementation Plan 문서를 템플릿 기반으로 자동 생성합니다.

Options:
  --epic-id ID          Epic ID (예: 006) [필수]
  --feature-id ID       Feature ID (예: 003) [필수]
  --feature-name NAME   Feature 이름 (예: "Template Generation") [필수]
  -h, --help            이 도움말 표시

Examples:
  bash .claude/lib/doc-generator/generate-plan.sh \\
    --epic-id 006 \\
    --feature-id 003 \\
    --feature-name "Template Generation"

Output:
  .specify/epics/{EPIC_ID}/features/{FEATURE_ID}-{feature-name-slug}/plan.md
EOF
}

# 파라미터 파싱
EPIC_ID=""
FEATURE_ID=""
FEATURE_NAME=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --epic-id)
      EPIC_ID="$2"
      shift 2
      ;;
    --feature-id)
      FEATURE_ID="$2"
      shift 2
      ;;
    --feature-name)
      FEATURE_NAME="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo -e "${RED}❌ Unknown option: $1${NC}"
      usage
      exit 1
      ;;
  esac
done

# 필수 파라미터 검증
if [[ -z "$EPIC_ID" || -z "$FEATURE_ID" || -z "$FEATURE_NAME" ]]; then
  echo -e "${RED}❌ Error: --epic-id, --feature-id, --feature-name are required${NC}"
  echo ""
  usage
  exit 1
fi

# Feature 이름을 slug로 변환
FEATURE_NAME_SLUG=$(echo "$FEATURE_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')

# 경로 설정
TEMPLATE_DIR=".specify/templates"
TEMPLATE_FILE="${TEMPLATE_DIR}/plan-template.md"
OUTPUT_DIR=".specify/epics/${EPIC_ID}/features/${FEATURE_ID}-${FEATURE_NAME_SLUG}"
OUTPUT_FILE="${OUTPUT_DIR}/plan.md"

# 템플릿 파일 존재 확인
if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo -e "${RED}❌ Error: Template file not found: $TEMPLATE_FILE${NC}"
  exit 1
fi

# 출력 디렉토리 생성
mkdir -p "$OUTPUT_DIR"

# 변수 치환
echo -e "${BLUE}📄 Generating plan.md...${NC}"
echo ""
echo -e "  Epic ID:       ${GREEN}${EPIC_ID}${NC}"
echo -e "  Feature ID:    ${GREEN}${FEATURE_ID}${NC}"
echo -e "  Feature Name:  ${GREEN}${FEATURE_NAME}${NC}"
echo ""
echo -e "  Output:        ${YELLOW}${OUTPUT_FILE}${NC}"
echo ""

# 변수 치환 (기본 메타데이터만)
sed -e "s/{Feature Name}/${FEATURE_NAME}/g" \
    "$TEMPLATE_FILE" > "$OUTPUT_FILE"

# 결과 확인
if [[ -f "$OUTPUT_FILE" ]]; then
  FILE_SIZE=$(wc -l < "$OUTPUT_FILE")
  echo -e "${GREEN}✅ plan.md generated successfully!${NC}"
  echo -e "   📝 Lines: ${FILE_SIZE}"
  echo ""
  echo -e "${BLUE}Next steps:${NC}"
  echo -e "  1. Review and edit: ${YELLOW}${OUTPUT_FILE}${NC}"
  echo -e "  2. Fill in Technical Foundation details"
  echo -e "  3. Complete Constitution Check"
  echo -e "  4. Define Source Code Structure"
  echo -e "  5. Generate tasks.md: ${YELLOW}bash .claude/lib/doc-generator/generate-tasks.sh${NC}"
  echo ""
else
  echo -e "${RED}❌ Error: Failed to generate plan.md${NC}"
  exit 1
fi
