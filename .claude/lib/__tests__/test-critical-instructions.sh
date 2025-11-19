#!/usr/bin/env bash
# test-critical-instructions.sh
# Phase 6 Task 6.5: CRITICAL INSTRUCTION 적용 검증

set -euo pipefail

# 색상 코드
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# 카운터
total_commands=0
with_instructions=0
without_instructions=0

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  CRITICAL INSTRUCTION 적용 검증                              ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# .claude/commands/ 디렉토리의 모든 .md 파일 확인
commands_dir="/Users/hk/Documents/claude-workflow/.claude/commands"

for cmd_file in "$commands_dir"/*.md; do
  if [[ ! -f "$cmd_file" ]]; then
    continue
  fi

  cmd_name=$(basename "$cmd_file" .md)
  ((total_commands++))

  # CRITICAL INSTRUCTION 패턴 확인 (fixed string으로 검색)
  if grep -qF "Claude를 위한 필수 지시사항:" "$cmd_file"; then
    echo -e "${GREEN}✓${NC} /$cmd_name - CRITICAL INSTRUCTION 있음"
    ((with_instructions++))
  else
    echo -e "${RED}✗${NC} /$cmd_name - CRITICAL INSTRUCTION 없음"
    ((without_instructions++))
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "총 명령어:        $total_commands"
echo -e "${GREEN}✓ 적용 완료:${NC}      $with_instructions"
echo -e "${RED}✗ 적용 필요:${NC}      $without_instructions"

if [[ $without_instructions -eq 0 ]]; then
  success_rate=100
  echo -e "${GREEN}성공률:${NC}           ${success_rate}%"
  echo ""
  echo -e "${GREEN}✅ 모든 명령어에 CRITICAL INSTRUCTION이 적용되었습니다!${NC}"
  echo ""
  exit 0
else
  success_rate=$(awk "BEGIN {printf \"%.1f\", ($with_instructions/$total_commands)*100}")
  echo -e "${YELLOW}성공률:${NC}           ${success_rate}%"
  echo ""
  echo -e "${YELLOW}⚠️  일부 명령어에 CRITICAL INSTRUCTION이 없습니다.${NC}"
  echo ""
  exit 1
fi
