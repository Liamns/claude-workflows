#!/bin/bash
# docu-start-post.sh
# /docu-start 명령어 실행 후 검증

set -euo pipefail

ACTIVE_TASKS=".claude/cache/active-tasks.json"

# active-tasks.json 확인
if [ ! -f "$ACTIVE_TASKS" ]; then
  echo "⚠️ active-tasks.json이 없습니다."
  exit 0  # 경고만 출력, 차단하지 않음
fi

# 작업 수 확인
task_count=$(jq 'length' "$ACTIVE_TASKS" 2>/dev/null || echo "0")

if [ "$task_count" -eq "0" ]; then
  echo "ℹ️ 등록된 작업이 없습니다. (--search 모드일 수 있음)"
  exit 0
fi

echo "✅ 활성 작업: ${task_count}개"
exit 0
