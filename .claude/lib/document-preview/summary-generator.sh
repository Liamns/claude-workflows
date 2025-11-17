#!/bin/bash
# summary-generator.sh
# AI 기반 문서 요약 생성 스크립트
#
# 사용법:
#   source summary-generator.sh
#   summary=$(generate_summary "/path/to/file.md" 300)

# Note: set -e 제거 (source될 때 테스트 스크립트에 영향을 주지 않도록)

# 에러 코드 정의 (이미 선언되어 있으면 건너뛰기)
if [ -z "${ERR_SUMMARY_GENERATION:-}" ]; then
  readonly ERR_SUMMARY_GENERATION=10
  readonly ERR_EMPTY_CONTENT=11
  readonly ERR_INVALID_LENGTH=12
fi

# 스크립트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_TEMPLATE="$SCRIPT_DIR/prompts/summarize.md"

# 환경 변수 검증
validate_environment() {
  local env="${CLAUDE_ENV:-production}"

  case "$env" in
    development|production)
      echo "$env"
      ;;
    *)
      log_error "INVALID_ENVIRONMENT" "Invalid CLAUDE_ENV: $env (expected: development or production)"
      echo "production"  # Safe default
      ;;
  esac
}

# development 모드 체크
is_development_mode() {
  local env=$(validate_environment)
  [ "$env" = "development" ]
}

# 로깅 함수
log_error() {
  local error_type="$1"
  local message="$2"
  echo "[ERROR] $error_type: $message" >&2
}

log_info() {
  local message="$1"
  echo "[INFO] $message" >&2
}

# 프롬프트 템플릿 로드
load_prompt_template() {
  if [ ! -f "$PROMPT_TEMPLATE" ]; then
    log_error "TEMPLATE_NOT_FOUND" "Prompt template not found: $PROMPT_TEMPLATE"
    return 1
  fi

  cat "$PROMPT_TEMPLATE"
}

# Overview 섹션 추출
extract_overview() {
  local content="$1"

  # Overview 섹션 찾기 (## Overview 부터 다음 ## 까지)
  echo "$content" | sed -n '/^## Overview/,/^##/p' | sed '$d' | sed '1d'
}

# Functional Requirements 추출 (상위 3개)
extract_top_requirements() {
  local content="$1"

  # FR-001, FR-002, FR-003 찾기
  echo "$content" | grep -E '^- FR-00[1-3]:' | head -3
}

# 핵심 정보 추출 (Overview + 상위 3개 FR)
# 한 문장으로 결합하여 반환
extract_key_info() {
  local content="$1"

  # Overview 추출 및 한 줄로 변환
  local overview=$(extract_overview "$content" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')

  # Requirements 추출
  local req1=$(echo "$content" | grep -E '^- FR-001:' | head -1 | sed 's/^- FR-001: //' | sed 's/^ *//;s/ *$//')
  local req2=$(echo "$content" | grep -E '^- FR-002:' | head -1 | sed 's/^- FR-002: //' | sed 's/^ *//;s/ *$//')
  local req3=$(echo "$content" | grep -E '^- FR-003:' | head -1 | sed 's/^- FR-003: //' | sed 's/^ *//;s/ *$//')

  # 한 문장으로 결합
  if [ -n "$req1" ] && [ -n "$req2" ] && [ -n "$req3" ]; then
    echo "$overview 주요 기능: (1) $req1, (2) $req2, (3) $req3."
  elif [ -n "$overview" ]; then
    echo "$overview"
  else
    # Overview도 없으면 전체 내용의 첫 부분 반환
    echo "$content" | head -5 | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//'
  fi
}

# 문장 경계에서 자르기
truncate_to_sentence() {
  local text="$1"
  local max_length="$2"

  # 이미 길이 이내면 그대로 반환
  if [ ${#text} -le "$max_length" ]; then
    echo "$text"
    return 0
  fi

  # max_length까지 자르기
  local truncated="${text:0:$max_length}"

  # 마지막 완전한 문장 찾기 (. ! ? 또는 한글 . ! ?)
  # grep -ob: byte offset 출력
  local last_sentence_end=$(echo "$truncated" | grep -ob '[.!?]' | tail -1 | cut -d: -f1)

  if [ -n "$last_sentence_end" ] && [ "$last_sentence_end" -gt 0 ]; then
    # 문장 끝 위치 + 1 (마침표 포함)
    echo "${text:0:$((last_sentence_end + 1))}"
  else
    # 문장 끝을 못 찾으면 단어 경계에서 자르고 ... 추가
    echo "$truncated" | sed 's/ [^ ]*$/.../'
  fi
}

# AI 기반 요약 생성 (메인 함수)
generate_summary() {
  local file_path="$1"
  local max_length="${2:-300}"

  # 환경 정보 로깅
  local env_mode=$(validate_environment)
  if is_development_mode; then
    log_info "Running in development mode (CLAUDE_ENV=$env_mode)"
  fi

  # 파일 존재 확인
  if [ ! -f "$file_path" ]; then
    log_error "FILE_NOT_FOUND" "File not found: $file_path"
    return $ERR_SUMMARY_GENERATION
  fi

  # 파일 읽기 권한 확인
  if [ ! -r "$file_path" ]; then
    log_error "FILE_NOT_READABLE" "File is not readable: $file_path"
    return $ERR_SUMMARY_GENERATION
  fi

  # 파일 내용 읽기
  local content
  content=$(cat "$file_path" 2>/dev/null)
  if [ $? -ne 0 ]; then
    log_error "FILE_READ_ERROR" "Failed to read file: $file_path"
    return $ERR_SUMMARY_GENERATION
  fi

  # 빈 파일 체크
  if [ -z "$content" ]; then
    log_error "EMPTY_CONTENT" "File is empty: $file_path"
    return $ERR_EMPTY_CONTENT
  fi

  # 길이 검증
  if [ "$max_length" -lt 50 ]; then
    log_error "INVALID_LENGTH" "max_length too short: $max_length (minimum: 50)"
    return $ERR_INVALID_LENGTH
  fi

  # 내용이 max_length보다 짧아도 요약 형식으로 변환
  # (마크다운 원본이 아닌 한 문장 요약으로 반환)

  # 프롬프트 템플릿 로드
  local prompt_template=$(load_prompt_template)
  if [ $? -ne 0 ]; then
    log_error "TEMPLATE_LOAD_FAILED" "Failed to load prompt template"
    return $ERR_SUMMARY_GENERATION
  fi

  # 프롬프트 구성 (템플릿의 실제 프롬프트 부분만 추출)
  local prompt=$(echo "$prompt_template" | sed -n '/^---$/,/^---$/p' | sed '1d;$d')

  # ${content} 플레이스홀더를 실제 내용으로 치환
  prompt="${prompt//\$\{content\}/$content}"

  # AI 요약 생성
  # NOTE: 실제 AI 처리는 Claude Code CLI 컨텍스트에서 이루어집니다.
  # 이 스크립트가 major.md/epic.md에서 호출될 때,
  # Claude가 이 프롬프트를 읽고 자체적으로 요약을 생성합니다.
  #
  # 현재는 폴백 로직 (첫 300자 추출)을 사용합니다.
  local summary

  # TODO: 실제 환경에서는 Claude가 이 프롬프트를 처리하여 요약 생성
  # 개발 중에는 단순 추출 방식 사용
  log_info "Generating summary using fallback method (first $max_length chars)"
  summary=$(extract_key_info "$content")

  # 길이 검증 및 문장 경계 처리
  summary=$(truncate_to_sentence "$summary" "$max_length")

  echo "$summary"
  return 0
}

# 폴백 포함 요약 생성 (에러 처리 강화 버전)
generate_summary_with_fallback() {
  local file_path="$1"
  local max_length="${2:-300}"

  log_info "Attempting AI-based summary generation for: $file_path"

  # AI 기반 요약 시도
  local summary
  local stderr_output
  stderr_output=$(mktemp)

  summary=$(generate_summary "$file_path" "$max_length" 2>"$stderr_output")
  local exit_code=$?

  # 에러 로그가 있으면 출력
  if [ -s "$stderr_output" ]; then
    cat "$stderr_output" >&2
  fi
  rm -f "$stderr_output"

  # 성공 시 검증 후 반환
  if [ $exit_code -eq 0 ] && [ -n "$summary" ]; then
    if validate_summary "$summary" "$max_length" 2>/dev/null; then
      log_info "Summary generation successful (length: ${#summary})"
      echo "$summary"
      return 0
    else
      log_error "VALIDATION_FAILED" "Generated summary failed validation"
    fi
  fi

  # 실패 시 폴백: extract_key_info 사용
  log_error "AI_GENERATION_FAILED" "AI summary generation failed (exit code: $exit_code), using fallback"

  if [ ! -f "$file_path" ]; then
    log_error "FALLBACK_FAILED" "File not found, cannot fallback"
    return $ERR_SUMMARY_GENERATION
  fi

  local content
  content=$(cat "$file_path" 2>/dev/null)
  if [ -z "$content" ]; then
    log_error "FALLBACK_FAILED" "Empty content, cannot fallback"
    return $ERR_EMPTY_CONTENT
  fi

  # Fallback: extract_key_info로 요약 생성
  summary=$(extract_key_info "$content")
  summary=$(truncate_to_sentence "$summary" "$max_length")

  if validate_summary "$summary" "$max_length" 2>/dev/null; then
    log_info "Fallback summary generated successfully (length: ${#summary})"
    echo "$summary"
    return 0
  else
    log_error "FALLBACK_VALIDATION_FAILED" "Fallback summary validation failed"
    return $ERR_SUMMARY_GENERATION
  fi
}

# 요약 품질 검증
validate_summary() {
  local summary="$1"
  local max_length="$2"

  # 길이 체크
  if [ ${#summary} -gt "$max_length" ]; then
    log_error "VALIDATION_FAILED" "Summary exceeds max_length: ${#summary} > $max_length"
    return 1
  fi

  # 빈 출력 체크
  if [ -z "$summary" ]; then
    log_error "VALIDATION_FAILED" "Summary is empty"
    return 1
  fi

  # 문장 완성도 체크 (마지막 문자가 . ! ? 또는 ... 로 끝나는지)
  local last_char="${summary: -1}"
  local last_three="${summary: -3}"

  if [[ ! "$last_char" =~ [.!?] ]] && [[ "$last_three" != "..." ]]; then
    log_error "VALIDATION_WARNING" "Summary may not end with complete sentence"
    # Warning만 출력하고 계속 진행
  fi

  log_info "Summary validation passed: ${#summary} chars"
  return 0
}

# 스크립트가 직접 실행된 경우 (테스트용)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [ $# -lt 1 ]; then
    echo "Usage: $0 <file_path> [max_length]"
    echo "Example: $0 /path/to/spec.md 300"
    exit 1
  fi

  file_path="$1"
  max_length="${2:-300}"

  echo "Generating summary for: $file_path (max: $max_length chars)"
  echo "---"

  summary=$(generate_summary_with_fallback "$file_path" "$max_length")
  exit_code=$?

  if [ $exit_code -eq 0 ]; then
    echo "$summary"
    echo "---"
    echo "Length: ${#summary} characters"

    # 검증
    validate_summary "$summary" "$max_length"
  else
    echo "Failed to generate summary (exit code: $exit_code)"
    exit $exit_code
  fi
fi
