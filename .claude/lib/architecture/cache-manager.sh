#!/bin/bash
# cache-manager.sh
# 아키텍처 검증 캐시 관리 시스템
#
# Usage: source .claude/lib/architecture/cache-manager.sh
#
# Provides:
# - init_cache()          캐시 초기화
# - is_cache_valid()      캐시 검증
# - update_cache()        캐시 업데이트
# - invalidate_cache()    캐시 무효화
# - get_cached_result()   캐시 결과 조회

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"
source "${SCRIPT_DIR}/../checksum-helper.sh"

# 캐시 디렉토리 및 파일
readonly CACHE_DIR=".claude/cache/architecture"
readonly CACHE_FILE="${CACHE_DIR}/validation-cache.json"
readonly CACHE_TTL_HOURS=24

# ============================================================================
# 캐시 초기화
# ============================================================================

# 캐시 디렉토리 및 초기 파일 생성
#
# Arguments: None
# Returns:
#   0 on success
#   1 on failure
# Output:
#   Success/error messages
#
# Example:
#   init_cache
init_cache() {
  # 캐시 디렉토리 생성
  if ! mkdir -p "$CACHE_DIR" 2>/dev/null; then
    log_error "Failed to create cache directory: $CACHE_DIR"
    return 1
  fi

  # 캐시 파일이 이미 존재하면 스킵
  if [[ -f "$CACHE_FILE" ]]; then
    log_info "Cache file already exists: $CACHE_FILE"
    return 0
  fi

  # 초기 캐시 JSON 생성
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  cat > "$CACHE_FILE" <<EOF
{
  "timestamp": "$timestamp",
  "architecture": "",
  "config_checksum": "",
  "files": {}
}
EOF

  if [[ $? -eq 0 ]]; then
    log_success "Cache initialized: $CACHE_FILE"
    return 0
  else
    log_error "Failed to initialize cache file"
    return 1
  fi
}

# ============================================================================
# 캐시 검증
# ============================================================================

# 특정 파일의 캐시가 유효한지 확인
#
# Arguments:
#   $1 - 파일 경로 (상대 또는 절대 경로)
# Returns:
#   0 if cache is valid
#   1 if cache is invalid or doesn't exist
# Output:
#   None (silent)
#
# Example:
#   if is_cache_valid "src/entities/user/model.ts"; then
#     echo "Cache hit"
#   fi
is_cache_valid() {
  local file="$1"

  # 인자 검증
  if [[ -z "$file" ]]; then
    return 1
  fi

  # 파일 존재 확인
  if [[ ! -f "$file" ]]; then
    return 1
  fi

  # 캐시 파일 존재 확인
  if [[ ! -f "$CACHE_FILE" ]]; then
    return 1
  fi

  # jq 확인
  if ! command -v jq &> /dev/null; then
    log_warning "jq not found - cannot validate cache"
    return 1
  fi

  # 캐시에서 파일 정보 조회
  local cached_checksum=$(jq -r ".files[\"$file\"].checksum // \"\"" "$CACHE_FILE" 2>/dev/null)

  # 캐시에 파일이 없으면 invalid
  if [[ -z "$cached_checksum" || "$cached_checksum" == "null" ]]; then
    return 1
  fi

  # 현재 파일 체크섬 계산
  local current_checksum
  if ! current_checksum=$(calculate_sha256 "$file" 2>/dev/null); then
    return 1
  fi

  # 체크섬 비교
  if [[ "$cached_checksum" == "$current_checksum" ]]; then
    # TTL 검증
    local last_checked=$(jq -r ".files[\"$file\"].last_checked // \"\"" "$CACHE_FILE" 2>/dev/null)
    if [[ -n "$last_checked" && "$last_checked" != "null" ]]; then
      if is_cache_expired "$last_checked"; then
        return 1
      fi
    fi
    return 0
  else
    return 1
  fi
}

# 캐시 TTL 만료 확인 (내부 함수)
#
# Arguments:
#   $1 - ISO 8601 timestamp (e.g., "2024-11-24T10:30:00Z")
# Returns:
#   0 if expired
#   1 if not expired
is_cache_expired() {
  local last_checked="$1"

  # date 명령어로 시간 비교 (macOS/Linux 호환)
  local last_epoch
  local now_epoch
  local diff_hours

  # macOS (BSD date)
  if date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_checked" "+%s" &> /dev/null; then
    last_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_checked" "+%s")
    now_epoch=$(date -u "+%s")
  # Linux (GNU date)
  elif date -d "$last_checked" "+%s" &> /dev/null; then
    last_epoch=$(date -d "$last_checked" "+%s")
    now_epoch=$(date -u "+%s")
  else
    # date 파싱 실패 시 만료로 간주
    return 0
  fi

  diff_hours=$(( (now_epoch - last_epoch) / 3600 ))

  if [[ $diff_hours -ge $CACHE_TTL_HOURS ]]; then
    return 0  # expired
  else
    return 1  # not expired
  fi
}

# ============================================================================
# 캐시 업데이트
# ============================================================================

# 특정 파일의 검증 결과를 캐시에 저장
#
# Arguments:
#   $1 - 파일 경로
#   $2 - 검증 결과 ("valid" or "invalid")
#   $3 - 위반 사항 JSON 배열 (선택적, 기본값: "[]")
# Returns:
#   0 on success
#   1 on failure
# Output:
#   Success/error messages
#
# Example:
#   update_cache "src/entities/user/model.ts" "valid"
#   update_cache "src/features/bad.ts" "invalid" '[{"rule":"fsd-layer","message":"..."}]'
update_cache() {
  local file="$1"
  local result="$2"
  local violations="${3:-[]}"

  # 인자 검증
  if [[ -z "$file" || -z "$result" ]]; then
    log_error "update_cache: Missing required arguments"
    return 1
  fi

  # 결과 검증
  if [[ "$result" != "valid" && "$result" != "invalid" ]]; then
    log_error "update_cache: Invalid result value: $result (must be 'valid' or 'invalid')"
    return 1
  fi

  # 캐시 파일 없으면 초기화
  if [[ ! -f "$CACHE_FILE" ]]; then
    init_cache
  fi

  # jq 확인
  if ! command -v jq &> /dev/null; then
    log_warning "jq not found - cannot update cache"
    return 1
  fi

  # 파일 체크섬 계산
  local checksum
  if [[ -f "$file" ]]; then
    if ! checksum=$(calculate_sha256 "$file" 2>/dev/null); then
      checksum=""
    fi
  else
    checksum=""
  fi

  # 타임스탬프
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # 캐시 업데이트 (jq 사용)
  local temp_file="${CACHE_FILE}.tmp"
  local valid_bool
  if [[ "$result" == "valid" ]]; then
    valid_bool="true"
  else
    valid_bool="false"
  fi

  jq --arg file "$file" \
     --arg checksum "$checksum" \
     --arg timestamp "$timestamp" \
     --argjson valid "$valid_bool" \
     --argjson violations "$violations" \
     '.files[$file] = {
       "checksum": $checksum,
       "valid": $valid,
       "last_checked": $timestamp,
       "violations": $violations
     }' "$CACHE_FILE" > "$temp_file"

  if [[ $? -eq 0 ]]; then
    mv "$temp_file" "$CACHE_FILE"
    return 0
  else
    log_error "Failed to update cache for: $file"
    rm -f "$temp_file"
    return 1
  fi
}

# ============================================================================
# 캐시 무효화
# ============================================================================

# 캐시 무효화 (전체 또는 특정 파일)
#
# Arguments:
#   $1 - 무효화 대상 (선택적)
#        - "all": 전체 캐시 삭제
#        - file path: 특정 파일만 무효화
#        - 생략 시: 전체 캐시 삭제
# Returns:
#   0 on success
#   1 on failure
# Output:
#   Success/error messages
#
# Example:
#   invalidate_cache "all"
#   invalidate_cache "src/entities/user/model.ts"
invalidate_cache() {
  local target="${1:-all}"

  if [[ "$target" == "all" ]]; then
    # 전체 캐시 삭제
    if [[ -f "$CACHE_FILE" ]]; then
      rm -f "$CACHE_FILE"
      log_success "Cache invalidated (all)"
      return 0
    else
      log_info "Cache file does not exist"
      return 0
    fi
  else
    # 특정 파일만 무효화
    local file="$target"

    if [[ ! -f "$CACHE_FILE" ]]; then
      log_info "Cache file does not exist"
      return 0
    fi

    # jq 확인
    if ! command -v jq &> /dev/null; then
      log_warning "jq not found - cannot invalidate specific file"
      return 1
    fi

    # 캐시에서 파일 제거
    local temp_file="${CACHE_FILE}.tmp"
    jq --arg file "$file" 'del(.files[$file])' "$CACHE_FILE" > "$temp_file"

    if [[ $? -eq 0 ]]; then
      mv "$temp_file" "$CACHE_FILE"
      log_success "Cache invalidated: $file"
      return 0
    else
      log_error "Failed to invalidate cache for: $file"
      rm -f "$temp_file"
      return 1
    fi
  fi
}

# ============================================================================
# 캐시 결과 조회
# ============================================================================

# 특정 파일의 캐시된 검증 결과 조회
#
# Arguments:
#   $1 - 파일 경로
# Returns:
#   0 on success
#   1 on failure
# Output:
#   JSON object with cached result, or empty if not found
#
# Example:
#   result=$(get_cached_result "src/entities/user/model.ts")
get_cached_result() {
  local file="$1"

  # 인자 검증
  if [[ -z "$file" ]]; then
    echo "{}"
    return 1
  fi

  # 캐시 파일 존재 확인
  if [[ ! -f "$CACHE_FILE" ]]; then
    echo "{}"
    return 1
  fi

  # jq 확인
  if ! command -v jq &> /dev/null; then
    echo "{}"
    return 1
  fi

  # 캐시 조회
  local result=$(jq -r ".files[\"$file\"] // {}" "$CACHE_FILE" 2>/dev/null)

  echo "$result"

  if [[ -n "$result" && "$result" != "{}" ]]; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# 모듈 초기화
# ============================================================================

# Note: This module is designed to be sourced, not executed directly.
# For testing, use .claude/lib/architecture/__tests__/test-cache-manager.sh
