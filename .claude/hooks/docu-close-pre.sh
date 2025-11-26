#!/bin/bash
# docu-close-pre.sh
# /docu-close 명령어 실행 전 검증

set -euo pipefail

ACTIVE_TASKS=".claude/cache/active-tasks.json"
CURRENT_PAGE=".claude/cache/current-notion-page.txt"

# 1. active-tasks.json 존재 확인
if [ ! -f "$ACTIVE_TASKS" ]; then
  echo "❌ active-tasks.json이 없습니다."
  echo "💡 '/docu-start'로 먼저 작업을 시작하세요."
  exit 2  # 차단
fi

# 2. 활성 작업 존재 확인
task_count=$(jq 'length' "$ACTIVE_TASKS" 2>/dev/null || echo "0")

if [ "$task_count" -eq "0" ]; then
  echo "❌ 완료할 작업이 없습니다."
  echo "💡 '/docu-start'로 먼저 작업을 시작하세요."
  exit 2  # 차단
fi

# 3. 현재 활성 작업 확인
if [ -f "$CURRENT_PAGE" ]; then
  current_id=$(cat "$CURRENT_PAGE")

  if [ -n "$current_id" ]; then
    # 해당 작업이 active-tasks에 있는지 확인
    exists=$(jq --arg id "$current_id" '[.[] | select(.page_id == $id)] | length' "$ACTIVE_TASKS")

    if [ "$exists" -eq "0" ]; then
      echo "⚠️ 현재 활성 작업이 목록에 없습니다."
      echo "💡 '/docu-list'로 작업을 확인하고 '/docu-switch'로 전환하세요."
      # 경고만, 차단하지 않음
    fi
  fi
fi

echo "✅ docu-close 준비 완료 (활성 작업: ${task_count}개)"
exit 0
