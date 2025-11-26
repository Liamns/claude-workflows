#!/bin/bash
# PostHook: /plan-major 완료 후 문서 검증
# Exit codes: 0=통과, 2=차단

set -e

echo "" >&2
echo "🔍 문서 검증 중..." >&2

# 현재 디렉토리에서 문서 찾기
FEATURE_DIR=$(pwd)

# 필수 문서 확인
REQUIRED_DOCS=("spec.md" "plan.md" "tasks.md")
missing_docs=()

for doc in "${REQUIRED_DOCS[@]}"; do
  if [ ! -f "$doc" ]; then
    missing_docs+=("$doc")
  fi
done

if [ ${#missing_docs[@]} -gt 0 ]; then
  echo "" >&2
  echo "❌ [차단] 필수 문서가 생성되지 않았습니다:" >&2
  for doc in "${missing_docs[@]}"; do
    echo "   - $doc" >&2
  done
  echo "" >&2
  echo "문서 생성을 완료한 후 다시 시도해주세요." >&2
  exit 2
fi

# 최소 파일 크기 검증
# - spec.md > 1KB: 요구사항 명세는 최소 1단락 이상의 내용이 필요합니다
# - plan.md > 1KB: Phase별 구현 계획이 최소 3개 이상 필요합니다
# - tasks.md > 500B: 작업 체크리스트가 최소 5개 이상 권장됩니다
if [ -f "spec.md" ]; then
  spec_size=$(wc -c < "spec.md" | tr -d ' ')
  if [ "$spec_size" -lt 1024 ]; then
    echo "" >&2
    echo "❌ [차단] spec.md가 너무 작습니다 (${spec_size} bytes < 1KB)" >&2
    echo "내용을 충분히 작성해주세요." >&2
    exit 2
  fi
fi

if [ -f "plan.md" ]; then
  plan_size=$(wc -c < "plan.md" | tr -d ' ')
  if [ "$plan_size" -lt 1024 ]; then
    echo "" >&2
    echo "❌ [차단] plan.md가 너무 작습니다 (${plan_size} bytes < 1KB)" >&2
    echo "내용을 충분히 작성해주세요." >&2
    exit 2
  fi
fi

if [ -f "tasks.md" ]; then
  tasks_size=$(wc -c < "tasks.md" | tr -d ' ')
  if [ "$tasks_size" -lt 500 ]; then
    echo "" >&2
    echo "❌ [차단] tasks.md가 너무 작습니다 (${tasks_size} bytes < 500B)" >&2
    echo "작업 체크리스트를 작성해주세요." >&2
    exit 2
  fi
fi

# Placeholder 확인
placeholder_pattern='\{placeholder\}|TODO:|FIXME:'
placeholder_found=false

for doc in "${REQUIRED_DOCS[@]}"; do
  if grep -E "$placeholder_pattern" "$doc" >/dev/null 2>&1; then
    echo "" >&2
    echo "❌ [차단] $doc에 미완성 플레이스홀더가 남아있습니다:" >&2
    grep -n -E "$placeholder_pattern" "$doc" | head -5 | sed 's/^/   /' >&2
    placeholder_found=true
  fi
done

if [ "$placeholder_found" = true ]; then
  echo "" >&2
  echo "문서를 완성한 후 다시 시도해주세요." >&2
  exit 2
fi

# 필수 섹션 확인
echo "   ✓ spec.md 존재" >&2
echo "   ✓ plan.md 존재" >&2
echo "   ✓ tasks.md 존재" >&2
echo "   ✓ 파일 크기 적절" >&2
echo "   ✓ Placeholder 없음" >&2

echo "" >&2
echo "✅ 모든 검증 통과" >&2

# 통과
exit 0
