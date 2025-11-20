#!/bin/bash

# notion-active-tasks.sh
# 여러 Notion 작업을 동시에 추적하고 관리하는 라이브러리

set -euo pipefail

ACTIVE_TASKS_FILE=".claude/cache/active-tasks.json"
CURRENT_PAGE_FILE=".claude/cache/current-notion-page.txt"

# active-tasks.json 초기화
init_active_tasks() {
  if [ ! -f "$ACTIVE_TASKS_FILE" ]; then
    echo "[]" > "$ACTIVE_TASKS_FILE"
  fi
}

# 작업 추가
# Usage: add_active_task "page_id" "title" "priority" "task_status" "channel" "feature_group"
add_active_task() {
  local page_id="$1"
  local title="$2"
  local priority="$3"
  local task_status="$4"
  local channel="$5"
  local feature_group="$6"

  init_active_tasks

  # KST 시간
  local now=$(TZ='Asia/Seoul' date +%Y-%m-%dT%H:%M:%S)
  local today=$(TZ='Asia/Seoul' date +%Y-%m-%d)

  # 기존 작업인지 확인
  local existing=$(jq --arg id "$page_id" '.[] | select(.page_id == $id)' "$ACTIVE_TASKS_FILE")

  if [ -z "$existing" ]; then
    # 새 작업 추가
    local new_task=$(cat <<EOF
{
  "page_id": "$page_id",
  "title": "$title",
  "priority": "$priority",
  "status": "$task_status",
  "channel": "$channel",
  "feature_group": "$feature_group",
  "started_at": "$today",
  "last_active": "$now"
}
EOF
)

    jq --argjson task "$new_task" '. += [$task]' "$ACTIVE_TASKS_FILE" > "${ACTIVE_TASKS_FILE}.tmp"
    mv "${ACTIVE_TASKS_FILE}.tmp" "$ACTIVE_TASKS_FILE"

    echo "✅ 작업 추가: $title"
  else
    # 기존 작업 업데이트
    jq --arg id "$page_id" \
       --arg task_status "$task_status" \
       --arg now "$now" \
       '(.[] | select(.page_id == $id) | .status) = $task_status |
        (.[] | select(.page_id == $id) | .last_active) = $now' \
       "$ACTIVE_TASKS_FILE" > "${ACTIVE_TASKS_FILE}.tmp"
    mv "${ACTIVE_TASKS_FILE}.tmp" "$ACTIVE_TASKS_FILE"

    echo "✅ 작업 업데이트: $title"
  fi
}

# 작업 제거
# Usage: remove_active_task "page_id"
remove_active_task() {
  local page_id="$1"

  init_active_tasks

  jq --arg id "$page_id" 'del(.[] | select(.page_id == $id))' "$ACTIVE_TASKS_FILE" > "${ACTIVE_TASKS_FILE}.tmp"
  mv "${ACTIVE_TASKS_FILE}.tmp" "$ACTIVE_TASKS_FILE"

  echo "✅ 작업 제거됨"
}

# 현재 활성 작업 설정
# Usage: set_current_task "page_id"
set_current_task() {
  local page_id="$1"

  echo "$page_id" > "$CURRENT_PAGE_FILE"

  # last_active 업데이트
  local now=$(TZ='Asia/Seoul' date +%Y-%m-%dT%H:%M:%S)

  init_active_tasks

  jq --arg id "$page_id" \
     --arg now "$now" \
     '(.[] | select(.page_id == $id) | .last_active) = $now' \
     "$ACTIVE_TASKS_FILE" > "${ACTIVE_TASKS_FILE}.tmp"
  mv "${ACTIVE_TASKS_FILE}.tmp" "$ACTIVE_TASKS_FILE"
}

# 현재 활성 작업 조회
# Returns: page_id or empty
get_current_task() {
  if [ -f "$CURRENT_PAGE_FILE" ]; then
    cat "$CURRENT_PAGE_FILE"
  fi
}

# 모든 활성 작업 조회 (우선순위순 정렬)
# Returns: JSON array
list_active_tasks() {
  init_active_tasks

  # 우선순위 정렬: P0 > P1 > P2 > P3
  jq 'sort_by(
    if .priority == "P0" then 0
    elif .priority == "P1" then 1
    elif .priority == "P2" then 2
    elif .priority == "P3" then 3
    else 4 end
  )' "$ACTIVE_TASKS_FILE"
}

# 특정 작업 정보 조회
# Usage: get_task_info "page_id"
# Returns: JSON object
get_task_info() {
  local page_id="$1"

  init_active_tasks

  jq --arg id "$page_id" '.[] | select(.page_id == $id)' "$ACTIVE_TASKS_FILE"
}

# 다음 추천 작업 조회 (우선순위 기반)
# Returns: JSON object
recommend_next_task() {
  init_active_tasks

  local current_id=$(get_current_task)

  # 추천 로직:
  # 1. 현재 작업이 아닌 것
  # 2. P0 우선
  # 3. 같은 우선순위면 "대기" 상태 우선
  # 4. 같은 feature_group 우선

  jq --arg current "$current_id" '
    map(select(.page_id != $current)) |
    sort_by(
      (if .priority == "P0" then 0
       elif .priority == "P1" then 1
       elif .priority == "P2" then 2
       elif .priority == "P3" then 3
       else 4 end),
      (if .status == "대기" then 0
       elif .status == "개발중" then 1
       elif .status == "테스트중" then 2
       else 3 end)
    ) | .[0]
  ' "$ACTIVE_TASKS_FILE"
}

# 작업 개수
count_active_tasks() {
  init_active_tasks

  jq 'length' "$ACTIVE_TASKS_FILE"
}

# 상태별 작업 개수
# Usage: count_tasks_by_status "대기"
count_tasks_by_status() {
  local task_status="$1"

  init_active_tasks

  jq --arg task_status "$task_status" '[.[] | select(.status == $task_status)] | length' "$ACTIVE_TASKS_FILE"
}

# 우선순위별 작업 개수
# Usage: count_tasks_by_priority "P0"
count_tasks_by_priority() {
  local priority="$1"

  init_active_tasks

  jq --arg priority "$priority" '[.[] | select(.priority == $priority)] | length' "$ACTIVE_TASKS_FILE"
}
