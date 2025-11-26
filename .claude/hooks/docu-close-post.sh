#!/bin/bash
# docu-close-post.sh
# /docu-close 명령어 실행 후 검증

set -euo pipefail

PENDING_COMMITS=".claude/cache/pending-commits.json"

# pending-commits.json 상태 확인
if [ -f "$PENDING_COMMITS" ]; then
  pending_count=$(jq 'length' "$PENDING_COMMITS" 2>/dev/null || echo "0")

  if [ "$pending_count" -gt "0" ]; then
    echo "⚠️ 동기화되지 않은 커밋이 ${pending_count}개 있습니다."
    echo "💡 '/docu-close --sync-only'로 동기화하세요."
  else
    echo "✅ 모든 커밋이 동기화되었습니다."
  fi
else
  echo "✅ pending-commits.json 없음 (정상)"
fi

echo "✅ docu-close 완료"
exit 0
