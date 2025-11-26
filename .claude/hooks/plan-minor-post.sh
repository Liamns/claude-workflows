#!/bin/bash
# PostHook: /plan-minor 완료 후 문서 검증
# Exit codes: 0=통과, 2=차단

set -e

echo "" >&2
echo "🔍 문서 검증 중..." >&2

# 현재 디렉토리에서 문서 찾기
FIX_DIR=$(pwd)

# 필수 문서 확인
if [ ! -f "fix-analysis.md" ]; then
  echo "" >&2
  echo "❌ [차단] fix-analysis.md가 생성되지 않았습니다" >&2
  echo "" >&2
  echo "문서 생성을 완료한 후 다시 시도해주세요." >&2
  exit 2
fi

# 최소 파일 크기 검증
# - fix-analysis.md > 200B: 증상, 근본 원인, 수정 계획 등 최소한의 분석 내용이 필요합니다
analysis_size=$(wc -c < "fix-analysis.md" | tr -d ' ')
if [ "$analysis_size" -lt 200 ]; then
  echo "" >&2
  echo "❌ [차단] fix-analysis.md가 너무 작습니다 (${analysis_size} bytes < 200B)" >&2
  echo "내용을 충분히 작성해주세요." >&2
  exit 2
fi

# Placeholder 확인
placeholder_pattern='\{placeholder\}|TODO:|FIXME:'
if grep -E "$placeholder_pattern" "fix-analysis.md" >/dev/null 2>&1; then
  echo "" >&2
  echo "❌ [차단] fix-analysis.md에 미완성 플레이스홀더가 남아있습니다:" >&2
  grep -n -E "$placeholder_pattern" "fix-analysis.md" | head -5 | sed 's/^/   /' >&2
  echo "" >&2
  echo "문서를 완성한 후 다시 시도해주세요." >&2
  exit 2
fi

# 필수 섹션 확인
REQUIRED_SECTIONS=("## 증상" "## 근본 원인" "## 영향 범위" "## 수정 계획" "## 작업 체크리스트" "## 테스트 계획")
missing_sections=()

for section in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -q "^$section" "fix-analysis.md"; then
    missing_sections+=("$section")
  fi
done

if [ ${#missing_sections[@]} -gt 0 ]; then
  echo "" >&2
  echo "❌ [차단] fix-analysis.md에 필수 섹션이 누락되었습니다:" >&2
  for section in "${missing_sections[@]}"; do
    echo "   - $section" >&2
  done
  echo "" >&2
  echo "누락된 섹션을 추가한 후 다시 시도해주세요." >&2
  exit 2
fi

# 체크박스 확인 (작업 체크리스트에 최소 1개 이상)
checkbox_count=$(grep -c "^[[:space:]]*- \[ \]" "fix-analysis.md" 2>/dev/null || echo 0)
if [ "$checkbox_count" -eq 0 ]; then
  echo "" >&2
  echo "⚠️  경고: 작업 체크리스트에 체크박스가 없습니다" >&2
  echo "구현할 작업을 체크박스 형식으로 추가하는 것을 권장합니다." >&2
  # 경고만, 차단하지 않음
fi

echo "   ✓ fix-analysis.md 존재" >&2
echo "   ✓ 파일 크기 적절 (${analysis_size} bytes)" >&2
echo "   ✓ Placeholder 없음" >&2
echo "   ✓ 필수 섹션 존재" >&2
if [ "$checkbox_count" -gt 0 ]; then
  echo "   ✓ 체크박스 ${checkbox_count}개" >&2
fi

echo "" >&2
echo "✅ 모든 검증 통과" >&2

# 통과
exit 0
