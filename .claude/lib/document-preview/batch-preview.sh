#!/bin/bash
# batch-preview.sh
# 복수 문서 일괄 미리보기 생성
#
# 사용법:
#   source batch-preview.sh
#   result=$(generate_batch_preview "$collection_id" 300)

# Note: set -e 제거 (source될 때 테스트 스크립트에 영향을 주지 않도록)

# 스크립트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 의존성 로드
source "$SCRIPT_DIR/document-collection.sh" 2>/dev/null || true
source "$SCRIPT_DIR/summary-generator.sh" 2>/dev/null || true
source "$SCRIPT_DIR/preview-formatter.sh" 2>/dev/null || true

# 에러 코드 정의
if [ -z "${ERR_BATCH_FAILED:-}" ]; then
  readonly ERR_BATCH_FAILED=40
  readonly ERR_BATCH_EMPTY=41
  readonly ERR_BATCH_PARTIAL=42
fi

# 배치 결과 저장 디렉토리
BATCH_RESULTS_DIR="${BATCH_RESULTS_DIR:-/tmp/batch-preview-results}"

# 로깅 함수
log_batch_error() {
  local error_type="$1"
  local message="$2"
  echo "[BATCH ERROR] $error_type: $message" >&2
}

log_batch_info() {
  local message="$1"
  echo "[BATCH INFO] $message" >&2
}

# 배치 결과 디렉토리 초기화
init_batch_results_dir() {
  if [ ! -d "$BATCH_RESULTS_DIR" ]; then
    mkdir -p "$BATCH_RESULTS_DIR" 2>/dev/null
    if [ $? -ne 0 ]; then
      log_batch_error "INIT_FAILED" "Failed to create batch results directory: $BATCH_RESULTS_DIR"
      return $ERR_BATCH_FAILED
    fi
  fi
  return 0
}

# 단일 문서 미리보기 생성
generate_document_preview() {
  local document_path="$1"
  local max_length="${2:-300}"

  log_batch_info "Generating preview for: $document_path"

  # 파일 존재 확인
  if [ ! -f "$document_path" ]; then
    log_batch_error "FILE_NOT_FOUND" "Document not found: $document_path"
    return 1
  fi

  # 요약 생성
  local summary
  summary=$(generate_summary "$document_path" "$max_length" 2>&1)
  local summary_exit=$?

  if [ $summary_exit -ne 0 ]; then
    log_batch_error "SUMMARY_FAILED" "Failed to generate summary for: $document_path"
    # 요약 실패 시 전체 내용의 첫 부분 사용
    summary=$(head -5 "$document_path" | tr '\n' ' ' | cut -c 1-"$max_length")
  fi

  # 전체 내용 읽기
  local full_content
  full_content=$(cat "$document_path" 2>/dev/null)
  if [ $? -ne 0 ]; then
    log_batch_error "CONTENT_READ_FAILED" "Failed to read document: $document_path"
    return 1
  fi

  # 미리보기 포맷팅
  local preview
  preview=$(format_preview "$summary" "$full_content" 2>&1)
  local preview_exit=$?

  if [ $preview_exit -ne 0 ]; then
    log_batch_error "FORMAT_FAILED" "Failed to format preview for: $document_path"
    # 포맷 실패 시 단순 결합
    preview="Summary: $summary\n\nContent: $full_content"
  fi

  # 결과 반환
  echo "$preview"
  return 0
}

# 배치 미리보기 생성 (메인 함수)
generate_batch_preview() {
  local collection_id="$1"
  local max_length="${2:-300}"

  log_batch_info "Starting batch preview generation for collection: $collection_id"

  # 컬렉션 검증
  validate_collection "$collection_id" 2>&1 >/dev/null
  if [ $? -ne 0 ]; then
    log_batch_error "INVALID_COLLECTION" "Collection validation failed: $collection_id"
    return $ERR_BATCH_FAILED
  fi

  # 문서 개수 확인
  local doc_count
  doc_count=$(get_document_count "$collection_id" 2>/dev/null)

  if [ "$doc_count" = "0" ]; then
    log_batch_error "EMPTY_COLLECTION" "Collection is empty: $collection_id"
    return $ERR_BATCH_EMPTY
  fi

  log_batch_info "Processing $doc_count documents"

  # 배치 결과 저장소 초기화
  init_batch_results_dir || return $?

  # 결과 파일 생성
  local batch_id="batch_$(date +%s)_$$"
  local result_file="$BATCH_RESULTS_DIR/$batch_id.results"
  > "$result_file"

  # 각 문서 처리
  local success_count=0
  local failure_count=0
  local current=0

  while IFS= read -r document_path; do
    # 빈 줄 건너뛰기
    [ -z "$document_path" ] && continue

    ((current++))
    log_batch_info "Processing $current/$doc_count: $document_path"

    # 문서 미리보기 생성
    local preview
    preview=$(generate_document_preview "$document_path" "$max_length" 2>&1)
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
      # 성공: 결과 파일에 저장
      # 형식: FILEPATH|PREVIEW_BASE64
      local preview_base64=$(echo "$preview" | base64)
      echo "$document_path|$preview_base64" >> "$result_file"
      ((success_count++))
      log_batch_info "✓ Success ($current/$doc_count)"
    else
      # 실패: 에러 기록
      echo "$document_path|ERROR" >> "$result_file"
      ((failure_count++))
      log_batch_error "PREVIEW_FAILED" "Failed to generate preview ($current/$doc_count): $document_path"
    fi
  done < <(get_document_list "$collection_id" 2>/dev/null)

  # 결과 요약
  log_batch_info "Batch preview completed: $success_count succeeded, $failure_count failed"

  # 결과 파일 경로 반환
  echo "$result_file"

  # 부분 실패 처리
  if [ $failure_count -gt 0 ] && [ $success_count -gt 0 ]; then
    return $ERR_BATCH_PARTIAL
  elif [ $failure_count -gt 0 ]; then
    return $ERR_BATCH_FAILED
  fi

  return 0
}

# 배치 결과에서 특정 문서 미리보기 추출
get_document_preview_from_batch() {
  local batch_result_file="$1"
  local document_path="$2"

  if [ ! -f "$batch_result_file" ]; then
    log_batch_error "RESULT_NOT_FOUND" "Batch result file not found: $batch_result_file"
    return 1
  fi

  # 절대 경로로 변환
  document_path=$(realpath "$document_path" 2>/dev/null || echo "$document_path")

  # 결과 파일에서 문서 찾기
  local result_line
  result_line=$(grep "^$document_path|" "$batch_result_file" 2>/dev/null)

  if [ -z "$result_line" ]; then
    log_batch_error "PREVIEW_NOT_FOUND" "Preview not found for: $document_path"
    return 1
  fi

  # 미리보기 추출 (base64 디코드)
  local preview_base64=$(echo "$result_line" | cut -d'|' -f2)

  if [ "$preview_base64" = "ERROR" ]; then
    log_batch_error "PREVIEW_ERROR" "Preview generation failed for: $document_path"
    return 1
  fi

  # base64 디코드
  echo "$preview_base64" | base64 -d

  return 0
}

# 배치 미리보기 통계
get_batch_preview_stats() {
  local batch_result_file="$1"

  if [ ! -f "$batch_result_file" ]; then
    log_batch_error "RESULT_NOT_FOUND" "Batch result file not found: $batch_result_file"
    return 1
  fi

  local total=$(wc -l < "$batch_result_file")
  local success=$(grep -cv '|ERROR$' "$batch_result_file" 2>/dev/null)
  local failure=$(grep -c '|ERROR$' "$batch_result_file" 2>/dev/null)

  cat <<EOF
Total: $total
Success: $success
Failure: $failure
EOF

  return 0
}

# 배치 결과를 JSON 형식으로 변환 (옵션)
batch_result_to_json() {
  local batch_result_file="$1"

  if [ ! -f "$batch_result_file" ]; then
    log_batch_error "RESULT_NOT_FOUND" "Batch result file not found: $batch_result_file"
    return 1
  fi

  echo "{"
  echo "  \"results\": ["

  local first=true
  while IFS='|' read -r filepath preview_base64; do
    if [ "$first" = true ]; then
      first=false
    else
      echo ","
    fi

    local status="success"
    if [ "$preview_base64" = "ERROR" ]; then
      status="error"
      preview_base64=""
    fi

    echo -n "    {\"path\": \"$filepath\", \"status\": \"$status\""
    if [ "$status" = "success" ]; then
      local preview=$(echo "$preview_base64" | base64 -d | sed 's/"/\\"/g' | tr '\n' ' ')
      echo -n ", \"preview\": \"$preview\""
    fi
    echo -n "}"
  done < "$batch_result_file"

  echo ""
  echo "  ]"
  echo "}"

  return 0
}

# 배치 결과 정리
cleanup_batch_result() {
  local batch_result_file="$1"

  if [ -f "$batch_result_file" ]; then
    rm -f "$batch_result_file"
    log_batch_info "Cleaned up batch result: $batch_result_file"
  fi

  return 0
}

# 오래된 배치 결과 정리 (24시간 이상)
cleanup_old_batch_results() {
  local max_age_hours="${1:-24}"

  if [ ! -d "$BATCH_RESULTS_DIR" ]; then
    return 0
  fi

  log_batch_info "Cleaning up batch results older than $max_age_hours hours"

  # find로 오래된 파일 삭제
  find "$BATCH_RESULTS_DIR" -name "*.results" -type f -mtime +$((max_age_hours / 24)) -delete 2>/dev/null

  return 0
}

# 스크립트가 직접 실행된 경우 (테스트용)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Batch Preview Generator"
  echo "---"

  if [ $# -lt 1 ]; then
    echo "Usage: $0 <collection_id> [max_length]"
    echo ""
    echo "Example:"
    echo "  collection=\$(create_document_collection)"
    echo "  add_document_to_collection \"\$collection\" \"spec.md\""
    echo "  add_document_to_collection \"\$collection\" \"tasks.md\""
    echo "  $0 \"\$collection\" 300"
    exit 1
  fi

  collection_id="$1"
  max_length="${2:-300}"

  echo "Generating batch preview for collection: $collection_id"
  echo "Max summary length: $max_length"
  echo "---"

  result_file=$(generate_batch_preview "$collection_id" "$max_length")
  exit_code=$?

  echo "Result file: $result_file"
  echo "Exit code: $exit_code"
  echo "---"

  if [ -f "$result_file" ]; then
    echo "Statistics:"
    get_batch_preview_stats "$result_file"
  fi
fi
