#!/bin/bash
# consent-manager.sh
# 파일 생성 전 사용자 동의 관리
#
# 사용법:
#   source consent-manager.sh
#   response=$(request_consent "/path/to/file.md" "$preview_content")

# Note: set -e 제거 (source될 때 테스트 스크립트에 영향을 주지 않도록)

# 동의 응답 상수 정의 (이미 선언되어 있으면 건너뛰기)
if [ -z "${CONSENT_APPROVE:-}" ]; then
  readonly CONSENT_APPROVE="approve"
  readonly CONSENT_MODIFY="modify"
  readonly CONSENT_REJECT="reject"
  readonly AUTO_APPROVE="AUTO_APPROVE"
fi

# 에러 코드 정의
if [ -z "${ERR_CONSENT_FAILED:-}" ]; then
  readonly ERR_CONSENT_FAILED=20
  readonly ERR_CONSENT_TIMEOUT=21
  readonly ERR_INVALID_INPUT=22
  readonly ERR_MAX_RETRIES=23
fi

# 환경 변수 검증
validate_consent_environment() {
  local env="${CLAUDE_ENV:-production}"

  case "$env" in
    development|production)
      echo "$env"
      ;;
    *)
      log_consent_error "INVALID_ENVIRONMENT" "Invalid CLAUDE_ENV: $env (expected: development or production)"
      echo "production"  # Safe default
      ;;
  esac
}

# development 모드 체크
is_consent_development_mode() {
  local env=$(validate_consent_environment)
  [ "$env" = "development" ]
}

# 로깅 함수
log_consent_error() {
  local error_type="$1"
  local message="$2"
  echo "[CONSENT ERROR] $error_type: $message" >&2
}

log_consent_info() {
  local message="$1"
  echo "[CONSENT INFO] $message" >&2
}

# 동의 응답 검증
validate_consent_response() {
  local response="$1"

  case "$response" in
    approve|modify|reject)
      return 0
      ;;
    *)
      log_consent_error "INVALID_RESPONSE" "Invalid consent response: $response (expected: approve, modify, or reject)"
      return 1
      ;;
  esac
}

# 동의 질문 포맷팅
format_consent_question() {
  local file_path="$1"
  local preview_content="$2"

  cat <<EOF
다음 파일을 생성하려고 합니다:

**파일 경로:** \`$file_path\`

**미리보기:**
$preview_content

파일을 생성하시겠습니까?
EOF
}

# 사용자 동의 요청 (메인 함수)
request_consent() {
  local file_path="$1"
  local preview_content="$2"
  local max_retries="${3:-3}"

  # 환경 정보 로깅
  local env_mode=$(validate_consent_environment)
  log_consent_info "Running in $env_mode mode"

  # 입력 검증
  if [ -z "$file_path" ]; then
    log_consent_error "INVALID_INPUT" "File path is required"
    return $ERR_INVALID_INPUT
  fi

  if [ -z "$preview_content" ]; then
    log_consent_error "INVALID_INPUT" "Preview content is required"
    return $ERR_INVALID_INPUT
  fi

  # Development 모드: 자동 승인
  if is_consent_development_mode; then
    log_consent_info "Development mode: AUTO_APPROVE for $file_path"
    echo "$AUTO_APPROVE"
    return 0
  fi

  # Production 모드: 사용자에게 질문
  log_consent_info "Production mode: Requesting user consent for $file_path"

  # 질문 포맷팅
  local question=$(format_consent_question "$file_path" "$preview_content")

  # AskUserQuestion 호출 (Claude Code CLI 컨텍스트에서 사용 가능)
  # NOTE: 실제 구현에서는 AskUserQuestion 도구를 사용합니다.
  # 현재는 폴백 로직 (에러 반환)을 사용합니다.

  # TODO: 실제 환경에서는 Claude가 AskUserQuestion을 호출하여 사용자 응답 수집
  # 개발 중에는 단순히 에러를 반환하거나 환경에 따라 처리

  log_consent_error "NOT_IMPLEMENTED" "AskUserQuestion integration not yet implemented in production mode"
  log_consent_info "Question that would be asked:"
  echo "$question" >&2

  # 폴백: 프로덕션 모드에서는 기본적으로 거부
  # 실제 구현 시 AskUserQuestion으로 대체될 예정
  echo "$CONSENT_REJECT"
  return $ERR_CONSENT_FAILED
}

# 동의 재시도 관리 (고급 버전)
request_consent_with_retry() {
  local file_path="$1"
  local preview_content="$2"
  local max_retries="${3:-3}"
  local retry_count=0

  log_consent_info "Starting consent request with max $max_retries retries"

  while [ $retry_count -lt $max_retries ]; do
    log_consent_info "Attempt $((retry_count + 1)) of $max_retries"

    local response
    response=$(request_consent "$file_path" "$preview_content" 2>&1)
    local exit_code=$?

    # AUTO_APPROVE 또는 성공적인 응답
    if [ "$response" = "$AUTO_APPROVE" ] || [ "$response" = "$CONSENT_APPROVE" ]; then
      log_consent_info "Consent granted"
      echo "$response"
      return 0
    fi

    # 거부
    if [ "$response" = "$CONSENT_REJECT" ]; then
      log_consent_info "Consent rejected by user"
      echo "$response"
      return 0
    fi

    # 수정 요청
    if [ "$response" = "$CONSENT_MODIFY" ]; then
      log_consent_info "User requested modification (retry $((retry_count + 1)))"
      ((retry_count++))
      continue
    fi

    # 에러 또는 알 수 없는 응답
    log_consent_error "RETRY_FAILED" "Attempt $((retry_count + 1)) failed with exit code $exit_code"
    ((retry_count++))
  done

  # 최대 재시도 횟수 초과
  log_consent_error "MAX_RETRIES_EXCEEDED" "Maximum retries ($max_retries) exceeded"
  echo "$CONSENT_REJECT"
  return $ERR_MAX_RETRIES
}

# 동의 응답 처리
handle_consent_response() {
  local response="$1"
  local file_path="$2"

  case "$response" in
    "$AUTO_APPROVE"|"$CONSENT_APPROVE")
      log_consent_info "File creation approved: $file_path"
      return 0
      ;;
    "$CONSENT_MODIFY")
      log_consent_info "Modification requested for: $file_path"
      return 1
      ;;
    "$CONSENT_REJECT")
      log_consent_info "File creation rejected: $file_path"
      return 2
      ;;
    *)
      log_consent_error "UNKNOWN_RESPONSE" "Unknown consent response: $response"
      return $ERR_CONSENT_FAILED
      ;;
  esac
}

# 타임아웃 처리 (옵션)
request_consent_with_timeout() {
  local file_path="$1"
  local preview_content="$2"
  local timeout_seconds="${3:-300}"  # Default: 5 minutes

  log_consent_info "Requesting consent with ${timeout_seconds}s timeout"

  # timeout 명령어 사용 (GNU coreutils)
  local response
  if command -v timeout >/dev/null 2>&1; then
    response=$(timeout "$timeout_seconds" bash -c "request_consent '$file_path' '$preview_content'" 2>&1)
    local exit_code=$?

    if [ $exit_code -eq 124 ]; then
      log_consent_error "TIMEOUT" "Consent request timed out after ${timeout_seconds}s"
      echo "$CONSENT_REJECT"
      return $ERR_CONSENT_TIMEOUT
    fi

    echo "$response"
    return $exit_code
  else
    # timeout 명령어가 없으면 일반 request_consent 호출
    log_consent_info "timeout command not available, using standard request_consent"
    request_consent "$file_path" "$preview_content"
  fi
}

# 스크립트가 직접 실행된 경우 (테스트용)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [ $# -lt 2 ]; then
    echo "Usage: $0 <file_path> <preview_content> [max_retries]"
    echo "Example: $0 'spec.md' 'Preview content here' 3"
    exit 1
  fi

  file_path="$1"
  preview_content="$2"
  max_retries="${3:-3}"

  echo "Requesting consent for: $file_path"
  echo "---"

  response=$(request_consent_with_retry "$file_path" "$preview_content" "$max_retries")
  exit_code=$?

  echo "Response: $response"
  echo "Exit code: $exit_code"

  handle_consent_response "$response" "$file_path"
  exit $?
fi
