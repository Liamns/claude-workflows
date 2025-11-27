#!/bin/bash
# PreHook: /implement 실행 전 미완료 작업 탐지 및 선택
# Exit codes: 0=성공(계속), 2=차단
#
# 추가 기능 (009-todo7-tdd-enhancement):
# - Major 모드 감지 및 TDD 강제
# - 테스트 파일 존재 여부 검사
# - TEST_REQUIRED 플래그 출력

set -e

echo "🔍 미완료 작업 탐색 중..." >&2

# 탐색 범위 정의
SEARCH_PATHS=(
  ".specify/features"
  ".specify/epics/*/features"
  ".specify/fixes"
)

# ============================================
# TDD 강제 메커니즘 함수들
# ============================================

# Major 모드 여부 감지
# Returns: "major" | "minor" | "micro" | "unknown"
detect_workflow_mode() {
  local dir_path="$1"

  # .specify/features/*/tasks.md 존재 → Major
  if [[ "$dir_path" == *".specify/features/"* ]] && [ -f "${dir_path}tasks.md" ]; then
    echo "major"
    return
  fi

  # .specify/epics/*/features/*/tasks.md 존재 → Major (Epic 하위)
  if [[ "$dir_path" == *".specify/epics/"*"/features/"* ]] && [ -f "${dir_path}tasks.md" ]; then
    echo "major"
    return
  fi

  # .specify/fixes/*/fix-analysis.md 존재 → Minor
  if [[ "$dir_path" == *".specify/fixes/"* ]] && [ -f "${dir_path}fix-analysis.md" ]; then
    echo "minor"
    return
  fi

  # micro-context.json 존재 → Micro
  if [ -f ".claude/cache/micro-context.json" ]; then
    echo "micro"
    return
  fi

  echo "unknown"
}

# 소스 파일에서 테스트 파일 경로 추론
# Input: 소스 파일 경로 (예: src/features/order/ui/OrderForm.tsx)
# Output: 추론된 테스트 파일 경로들 (공백 구분)
infer_test_paths() {
  local source_file="$1"
  local base_name="${source_file%.*}"
  local dir_name="$(dirname "$source_file")"
  local file_name="$(basename "$base_name")"

  # 가능한 테스트 파일 패턴들
  echo "${base_name}.spec.ts"
  echo "${base_name}.spec.tsx"
  echo "${base_name}.test.ts"
  echo "${base_name}.test.tsx"
  echo "${dir_name}/__tests__/${file_name}.test.ts"
  echo "${dir_name}/__tests__/${file_name}.test.tsx"
  echo "${dir_name}/__tests__/${file_name}.spec.ts"
  echo "${dir_name}/__tests__/${file_name}.spec.tsx"
}

# 테스트 파일 존재 여부 검사
# Input: 작업 디렉토리 경로
# Output: 테스트가 필요한 소스 파일들 (테스트 미존재)
check_test_files_exist() {
  local dir_path="$1"
  local missing_tests=()

  # plan.md 또는 tasks.md에서 대상 소스 파일 추출
  local plan_file="${dir_path}plan.md"
  local tasks_file="${dir_path}tasks.md"

  local source_files=()

  # 수정 대상 파일 추출 (영향 범위 섹션에서)
  if [ -f "$plan_file" ]; then
    # .ts, .tsx 파일 경로 패턴 추출
    while IFS= read -r line; do
      if [[ "$line" =~ \.tsx?$ ]] && [[ ! "$line" =~ \.spec\. ]] && [[ ! "$line" =~ \.test\. ]]; then
        # 경로 정제 (마크다운 형식 제거)
        local clean_path=$(echo "$line" | sed 's/^[^/]*//; s/[[:space:]]*(.*)$//' | tr -d '`')
        if [ -n "$clean_path" ]; then
          source_files+=("$clean_path")
        fi
      fi
    done < <(grep -E "\.tsx?(\s|\)|$)" "$plan_file" 2>/dev/null || true)
  fi

  # 소스 파일별 테스트 존재 여부 확인
  for source_file in "${source_files[@]}"; do
    local has_test=false

    # 테스트 파일 경로들 확인
    while IFS= read -r test_path; do
      if [ -f "$test_path" ]; then
        has_test=true
        break
      fi
    done < <(infer_test_paths "$source_file")

    if [ "$has_test" = false ]; then
      missing_tests+=("$source_file")
    fi
  done

  # 결과 출력 (공백 구분)
  echo "${missing_tests[*]}"
}

# TDD 검사 실행 및 결과 출력
# Input: 작업 디렉토리 경로, 워크플로우 모드
# Output: TEST_REQUIRED 플래그 (stderr로)
run_tdd_check() {
  local dir_path="$1"
  local mode="$2"

  # Major 모드에서만 TDD 검사
  if [ "$mode" != "major" ]; then
    return 0
  fi

  echo "" >&2
  echo "🧪 TDD 검사 실행 중..." >&2

  local missing_tests=$(check_test_files_exist "$dir_path")

  if [ -n "$missing_tests" ]; then
    echo "⚠️  테스트가 없는 소스 파일 발견:" >&2
    for file in $missing_tests; do
      echo "   - $file" >&2
    done
    echo "" >&2
    echo "TEST_REQUIRED:true" >&2

    # 캐시에 테스트 필요 정보 저장
    mkdir -p .claude/cache
    cat > .claude/cache/tdd-check-result.json <<EOF
{
  "test_required": true,
  "missing_tests": [$(echo "$missing_tests" | sed 's/ /", "/g; s/^/"/; s/$/"/')],
  "checked_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
  else
    echo "✅ TDD 검사 통과 (테스트 파일 존재 확인)" >&2
    echo "TEST_REQUIRED:false" >&2
  fi
}

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

  # 워크플로우 모드 감지
  workflow_mode=$(detect_workflow_mode "$dir_path")
  echo "📋 워크플로우 모드: $workflow_mode" >&2

  # TDD 검사 실행 (Major 모드일 때만)
  run_tdd_check "$dir_path" "$workflow_mode"

  # Context 저장 (.claude/cache/implement-context.json)
  mkdir -p .claude/cache
  cat > .claude/cache/implement-context.json <<EOF
{
  "dir": "$dir_path",
  "task_count": $task_count,
  "workflow_mode": "$workflow_mode",
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
