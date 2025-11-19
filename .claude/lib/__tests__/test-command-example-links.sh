#!/usr/bin/env bash
# test-command-example-links.sh
# Phase 7 Task 7.6: 명령어 파일의 예시 링크 검증

set -euo pipefail

# 색상 코드
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# 카운터
total_links=0
valid_links=0
broken_links=0

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  Command Example Links 검증                                  ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# 작업 디렉토리
project_root="/Users/hk/Documents/claude-workflow"
commands_dir="$project_root/.claude/commands"
examples_dir="$project_root/.claude/docs/command-examples"

# 검증할 명령어 파일
declare -a command_files=(
  "major.md"
  "minor.md"
  "micro.md"
)

echo -e "${BLUE}[1/4]${NC} 명령어 파일에서 예시 링크 추출 중..."
echo ""

for cmd_file in "${command_files[@]}"; do
  cmd_path="$commands_dir/$cmd_file"
  cmd_name=$(basename "$cmd_file" .md)

  if [[ ! -f "$cmd_path" ]]; then
    echo -e "${RED}✗${NC} $cmd_file 파일을 찾을 수 없습니다"
    continue
  fi

  # ../docs/command-examples/ 패턴의 링크 추출
  # 마크다운 링크 형식: [text](../docs/command-examples/file.md)
  links=$(grep -o '\.\./docs/command-examples/[^)]*\.md' "$cmd_path" || true)

  if [[ -z "$links" ]]; then
    echo -e "${YELLOW}⚠${NC}  /$cmd_name - 예시 링크 없음"
    continue
  fi

  while IFS= read -r link; do
    ((total_links++))

    # 상대 경로를 절대 경로로 변환
    # ../docs/command-examples/file.md -> /path/to/project/.claude/docs/command-examples/file.md
    target_file=$(echo "$link" | sed "s|\.\./docs/command-examples/|$examples_dir/|")

    if [[ -f "$target_file" ]]; then
      echo -e "${GREEN}✓${NC} /$cmd_name → $(basename "$target_file")"
      ((valid_links++))
    else
      echo -e "${RED}✗${NC} /$cmd_name → $(basename "$target_file") ${RED}(없음)${NC}"
      ((broken_links++))
    fi
  done <<< "$links"
done

echo ""
echo -e "${BLUE}[2/4]${NC} 예시 파일 존재 여부 확인 중..."
echo ""

# 예상되는 예시 파일 목록
declare -a expected_examples=(
  "major-examples.md"
  "major-document-templates.md"
  "major-troubleshooting.md"
  "minor-examples.md"
  "minor-document-templates.md"
  "minor-troubleshooting.md"
  "micro-examples.md"
  "micro-troubleshooting.md"
)

missing_files=0
for example_file in "${expected_examples[@]}"; do
  if [[ -f "$examples_dir/$example_file" ]]; then
    echo -e "${GREEN}✓${NC} $example_file 존재"
  else
    echo -e "${RED}✗${NC} $example_file ${RED}없음${NC}"
    ((missing_files++))
  fi
done

echo ""
echo -e "${BLUE}[3/4]${NC} README.md 검증 중..."
echo ""

readme_path="$examples_dir/README.md"
if [[ -f "$readme_path" ]]; then
  echo -e "${GREEN}✓${NC} README.md 존재"

  # README.md에 모든 예시 파일이 언급되는지 확인
  readme_mentions=0
  for example_file in "${expected_examples[@]}"; do
    if grep -qF "$example_file" "$readme_path"; then
      ((readme_mentions++))
    fi
  done
  echo -e "${GREEN}✓${NC} README.md에 $readme_mentions/8 파일 언급됨"
else
  echo -e "${RED}✗${NC} README.md 없음"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}[4/4]${NC} 검증 결과 요약"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "총 링크 수:       $total_links"
echo -e "${GREEN}✓ 유효한 링크:${NC}    $valid_links"
echo -e "${RED}✗ 깨진 링크:${NC}      $broken_links"
echo "예시 파일 누락:   $missing_files/8"
echo ""

if [[ $broken_links -eq 0 && $missing_files -eq 0 ]]; then
  success_rate=100
  echo -e "${GREEN}성공률:${NC}           ${success_rate}%"
  echo ""
  echo -e "${GREEN}✅ 모든 링크가 유효하고 예시 파일이 존재합니다!${NC}"
  echo ""
  exit 0
else
  if [[ $total_links -gt 0 ]]; then
    success_rate=$(awk "BEGIN {printf \"%.1f\", ($valid_links/$total_links)*100}")
  else
    success_rate=0
  fi
  echo -e "${YELLOW}성공률:${NC}           ${success_rate}%"
  echo ""
  echo -e "${RED}❌ 일부 링크가 깨졌거나 파일이 누락되었습니다.${NC}"
  echo ""
  exit 1
fi
