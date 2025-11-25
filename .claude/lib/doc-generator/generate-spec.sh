#!/bin/bash
# generate-spec.sh
# Feature Specification 8 êŸ ›1 §lΩ∏
# Epic 006 - Feature 003: Template-based Document Generation

set -euo pipefail

# …¡ X
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ¨©ï ú%
usage() {
  cat <<EOF
Usage: bash .claude/lib/doc-generator/generate-spec.sh [OPTIONS]

Feature Specification 8| \ø 0<\ êŸ ›1i»‰.

Options:
  --epic-id ID          Epic ID (: 006) [D]
  --feature-id ID       Feature ID (: 003) [D]
  --feature-name NAME   Feature tÑ (: "Template Generation") [D]
  --branch NAME         Git úX tÑ (: 006-template-generation) [ ›]
  --priority LEVEL      ∞  (P1, P2, P3+) [0¯: P1]
  --duration DAYS       ¡ 0 (: 7|) [0¯: 7|]
  --status STATUS       ¡‹ (Draft, Planning, In Progress) [0¯: Draft]
  -h, --help            t ƒ¿– \‹

Examples:
  # 0¯ ¨©
  bash .claude/lib/doc-generator/generate-spec.sh \\
    --epic-id 006 \\
    --feature-id 003 \\
    --feature-name "Template Generation"

  # ®‡ 5X ¿
  bash .claude/lib/doc-generator/generate-spec.sh \\
    --epic-id 006 \\
    --feature-id 003 \\
    --feature-name "Template Generation" \\
    --branch 006-template-generation \\
    --priority P1 \\
    --duration "14|" \\
    --status Planning

Output:
  .specify/epics/{EPIC_ID}/features/{FEATURE_ID}-{feature-name-slug}/spec.md
EOF
}

# |¯0 Ò
EPIC_ID=""
FEATURE_ID=""
FEATURE_NAME=""
BRANCH=""
PRIORITY="P1"
DURATION="7|"
STATUS="Draft"

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
    --branch)
      BRANCH="$2"
      shift 2
      ;;
    --priority)
      PRIORITY="$2"
      shift 2
      ;;
    --duration)
      DURATION="$2"
      shift 2
      ;;
    --status)
      STATUS="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo -e "${RED}L Unknown option: $1${NC}"
      usage
      exit 1
      ;;
  esac
done

# D |¯0 Äù
if [[ -z "$EPIC_ID" || -z "$FEATURE_ID" || -z "$FEATURE_NAME" ]]; then
  echo -e "${RED}L Error: --epic-id, --feature-id, --feature-name are required${NC}"
  echo ""
  usage
  exit 1
fi

# 0¯ úX tÑ ›1
if [[ -z "$BRANCH" ]]; then
  # Feature tÑD slug\ ¿X (å8ê, ı1D Xt<\)
  FEATURE_NAME_SLUG=$(echo "$FEATURE_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
  BRANCH="${FEATURE_ID}-${FEATURE_NAME_SLUG}"
fi

# ¨ †‹
DATE=$(date +%Y-%m-%d)

# Ω\ $
TEMPLATE_DIR=".specify/templates"
TEMPLATE_FILE="${TEMPLATE_DIR}/spec-template.md"
OUTPUT_DIR=".specify/epics/${EPIC_ID}/features/${FEATURE_ID}-${FEATURE_NAME_SLUG}"
OUTPUT_FILE="${OUTPUT_DIR}/spec.md"

# \ø | t¨ Ux
if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo -e "${RED}L Error: Template file not found: $TEMPLATE_FILE${NC}"
  exit 1
fi

# ú% 	†¨ ›1
mkdir -p "$OUTPUT_DIR"

# \ø }0  ¿ XX
echo -e "${BLUE}=ƒ Generating spec.md...${NC}"
echo ""
echo -e "  Epic ID:       ${GREEN}${EPIC_ID}${NC}"
echo -e "  Feature ID:    ${GREEN}${FEATURE_ID}${NC}"
echo -e "  Feature Name:  ${GREEN}${FEATURE_NAME}${NC}"
echo -e "  Branch:        ${GREEN}${BRANCH}${NC}"
echo -e "  Priority:      ${GREEN}${PRIORITY}${NC}"
echo -e "  Duration:      ${GREEN}${DURATION}${NC}"
echo -e "  Status:        ${GREEN}${STATUS}${NC}"
echo -e "  Date:          ${GREEN}${DATE}${NC}"
echo ""
echo -e "  Output:        ${YELLOW}${OUTPUT_FILE}${NC}"
echo ""

# ¿ XX (sed| ¨©XÏ \øX t§@T| ‰ <\ XX)
sed -e "s/{Feature Name}/${FEATURE_NAME}/g" \
    -e "s/{NNN-feature-name}/${BRANCH}/g" \
    -e "s/{YYYY-MM-DD}/${DATE}/g" \
    -e "s/{P1\/P2\/P3+}/${PRIORITY}/g" \
    -e "s/{N|}/${DURATION}/g" \
    -e "s/Status: Draft/Status: ${STATUS}/g" \
    "$TEMPLATE_FILE" > "$OUTPUT_FILE"

# ∞¸ Ux
if [[ -f "$OUTPUT_FILE" ]]; then
  FILE_SIZE=$(wc -l < "$OUTPUT_FILE")
  echo -e "${GREEN} spec.md generated successfully!${NC}"
  echo -e "   =› Lines: ${FILE_SIZE}"
  echo ""
  echo -e "${BLUE}Next steps:${NC}"
  echo -e "  1. Review and edit: ${YELLOW}${OUTPUT_FILE}${NC}"
  echo -e "  2. Fill in User Scenarios and Requirements"
  echo -e "  3. Define Success Criteria"
  echo -e "  4. Generate plan.md:  ${YELLOW}bash .claude/lib/doc-generator/generate-plan.sh${NC}"
  echo -e "  5. Generate tasks.md: ${YELLOW}bash .claude/lib/doc-generator/generate-tasks.sh${NC}"
  echo ""
else
  echo -e "${RED}L Error: Failed to generate spec.md${NC}"
  exit 1
fi
