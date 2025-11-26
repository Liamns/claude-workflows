#!/bin/bash
# PostHook: /implement 완료 후 변경사항 확인
# Exit codes: 항상 0 (통과)

set -e

echo "" >&2
echo "📊 변경사항 확인 중..." >&2

# 변경된 파일 확인
changed_files=$(git diff --name-only 2>/dev/null || echo "")
changed_count=$(echo "$changed_files" | grep -v '^$' | wc -l | tr -d ' ')

if [ "$changed_count" -eq 0 ]; then
  echo "ℹ️  변경된 파일이 없습니다" >&2
else
  echo "✅ 변경된 파일: ${changed_count}개" >&2
  echo "" >&2
  echo "$changed_files" | head -10 | sed 's/^/   - /' >&2

  if [ "$changed_count" -gt 10 ]; then
    echo "   ... ($(($changed_count - 10))개 더)" >&2
  fi
fi

echo "" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
echo "✅ 구현이 완료되었습니다" >&2
echo "" >&2
echo "**다음 단계**:" >&2
echo "1. tasks.md 또는 fix-analysis.md에서 완료한 작업 확인" >&2
echo "2. 체크박스 업데이트 (\`[ ]\` → \`[x]\`)" >&2
echo "3. \`/review\` - 코드 품질 검토 (권장)" >&2
echo "4. 테스트 실행 및 검증" >&2
echo "5. 커밋 준비" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

# 항상 성공
exit 0
