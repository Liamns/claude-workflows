#!/bin/bash
# PreHook: /implement 실행 전 미완료 작업 탐지 및 선택
# Exit codes: 0=성공(계속), 2=차단

set -e

echo "🔍 미완료 작업 탐색 중..." >&2

# 탐색 범위 정의
SEARCH_PATHS=(
  ".specify/features"
  ".specify/epics/*/features"
  ".specify/fixes"
)

# 미완료 작업 저장 배열
declare -a INCOMPLETE_DIRS=()

# 각 경로 탐색
# glob 패턴 확장 (nullglob 활성화로 매칭 없으면 빈 리스트)
shopt -s nullglob
for base_path in "${SEARCH_PATHS[@]}"; do
  for dir in $base_path/*/; do
    # 디렉토리 존재 확인
    if [ ! -d "$dir" ]; then
      continue
    fi

    # tasks.md 또는 fix-analysis.md 확인
    doc_file=""
    if [ -f "$dir/tasks.md" ]; then
      doc_file="$dir/tasks.md"
    elif [ -f "$dir/fix-analysis.md" ]; then
      doc_file="$dir/fix-analysis.md"
    else
      continue
    fi

    # 미완료 task 확인 (- [ ] 패턴, optional 제외)
    incomplete_count=$(grep -c "^[[:space:]]*- \[ \]" "$doc_file" 2>/dev/null | grep -v "(optional)" || echo 0)

    if [ "$incomplete_count" -gt 0 ]; then
      INCOMPLETE_DIRS+=("$dir:$incomplete_count")
    fi
  done
done
shopt -u nullglob

# 결과 처리
count=${#INCOMPLETE_DIRS[@]}

if [ $count -eq 0 ]; then
  echo "" >&2
  echo "❌ 미완료 작업이 없습니다" >&2
  echo "" >&2
  echo "모든 작업이 완료되었거나 새로운 작업이 필요합니다." >&2
  echo "다음 중 하나를 실행하세요:" >&2
  echo "  - /triage - 새 작업 분석" >&2
  echo "  - /plan-major - Major 작업 계획" >&2
  echo "  - /plan-minor - Minor 작업 계획" >&2
  exit 2

elif [ $count -eq 1 ]; then
  # 1개 발견: 자동 선택
  dir_info="${INCOMPLETE_DIRS[0]}"
  dir_path="${dir_info%%:*}"
  task_count="${dir_info##*:}"

  echo "" >&2
  echo "✅ 발견: $dir_path" >&2
  echo "   - ${task_count}개 미완료 task" >&2
  echo "" >&2
  echo "📍 자동 선택되었습니다" >&2

  # Context 저장 (.claude/cache/implement-context.json)
  mkdir -p .claude/cache
  cat > .claude/cache/implement-context.json <<EOF
{
  "dir": "$dir_path",
  "task_count": $task_count,
  "selected_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

  exit 0

else
  # 여러 개 발견: stderr로 목록 출력 (명령어가 AskUserQuestion 생성)
  echo "" >&2
  echo "✅ 발견 (${count}개):" >&2

  index=1
  for dir_info in "${INCOMPLETE_DIRS[@]}"; do
    dir_path="${dir_info%%:*}"
    task_count="${dir_info##*:}"
    echo "${index}. $dir_path (${task_count}개 미완료)" >&2
    ((index++))
  done

  echo "" >&2
  echo "⚠️  여러 작업이 발견되었습니다. 명령어에서 선택해주세요." >&2

  # 목록을 JSON으로 저장 (명령어가 읽을 수 있도록)
  mkdir -p .claude/cache
  echo "[" > .claude/cache/implement-options.json

  first=true
  for dir_info in "${INCOMPLETE_DIRS[@]}"; do
    dir_path="${dir_info%%:*}"
    task_count="${dir_info##*:}"

    if [ "$first" = true ]; then
      first=false
    else
      echo "," >> .claude/cache/implement-options.json
    fi

    echo "  {\"dir\": \"$dir_path\", \"task_count\": $task_count}" >> .claude/cache/implement-options.json
  done

  echo "]" >> .claude/cache/implement-options.json

  exit 0
fi
