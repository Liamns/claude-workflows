#!/bin/bash
# incremental.sh
# 증분 검증 시스템 (Incremental Validation System)
#
# Usage: source .claude/lib/architecture/incremental.sh
#
# Provides:
# - get_changed_files()              Git 기반 변경 파일 목록
# - get_affected_files()             Import 영향 파일 계산
# - is_file_in_cache()               캐시 존재 확인
# - run_incremental_validation()     증분 검증 실행

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"
source "${SCRIPT_DIR}/cache-manager.sh"

# Debug logging (only if DEBUG=1)
log_debug() {
  if [[ "${DEBUG:-0}" == "1" ]]; then
    local message="$1"
    echo -e "\033[0;90m[DEBUG]\033[0m $message" >&2
  fi
}

# ============================================================================
# Git 기반 변경 파일 감지
# ============================================================================

# Git diff 기반 변경 파일 목록 조회
#
# Arguments:
#   $1 - base commit/branch (선택적, 기본값: HEAD)
# Returns:
#   0 on success
#   1 on failure
# Output:
#   List of changed file paths (one per line)
#
# Example:
#   changed_files=$(get_changed_files)
#   changed_files=$(get_changed_files "origin/main")
get_changed_files() {
  local base="${1:-HEAD}"

  # Git 저장소 확인
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_warning "Not a git repository - cannot detect changed files"
    return 1
  fi

  local changed_files=""

  # 1. Staged changes (git add된 파일)
  local staged
  staged=$(git diff --name-only --cached "$base" 2>/dev/null || true)
  if [[ -n "$staged" ]]; then
    changed_files+="$staged"$'\n'
  fi

  # 2. Unstaged changes (수정되었지만 add되지 않은 파일)
  local unstaged
  unstaged=$(git diff --name-only "$base" 2>/dev/null || true)
  if [[ -n "$unstaged" ]]; then
    changed_files+="$unstaged"$'\n'
  fi

  # 3. Untracked files (새로 생성된 파일)
  local untracked
  untracked=$(git status --porcelain 2>/dev/null | grep "^??" | cut -d' ' -f2 || true)
  if [[ -n "$untracked" ]]; then
    changed_files+="$untracked"$'\n'
  fi

  # 중복 제거 및 정렬
  if [[ -n "$changed_files" ]]; then
    echo "$changed_files" | grep -v "^$" | sort -u
    return 0
  else
    return 0
  fi
}

# ============================================================================
# Import 영향 파일 계산
# ============================================================================

# Import 영향을 받는 파일 목록 조회 (간소화된 grep 기반)
#
# Arguments:
#   $1 - changed file path
#   $2 - search directory (선택적, 기본값: src)
# Returns:
#   0 on success
#   1 on failure
# Output:
#   List of affected file paths (one per line)
#
# Example:
#   affected_files=$(get_affected_files "src/entities/user/model.ts")
#   affected_files=$(get_affected_files "src/shared/lib/utils.ts" "src")
#
# Note:
#   TypeScript/JavaScript import 패턴만 지원
#   - import ... from './path'
#   - import ... from '@/path'
#   - import ... from 'module'
get_affected_files() {
  local changed_file="$1"
  local search_dir="${2:-src}"

  # 인자 검증
  if [[ -z "$changed_file" ]]; then
    return 1
  fi

  # 검색 디렉토리 존재 확인
  if [[ ! -d "$search_dir" ]]; then
    log_debug "Search directory does not exist: $search_dir"
    return 0
  fi

  # 파일명 추출 (확장자 제거)
  local basename
  basename=$(basename "$changed_file" | sed 's/\.[^.]*$//')

  # 파일 경로에서 상대 경로 추출
  # 예: src/entities/user/model.ts -> entities/user/model
  local relative_path
  if [[ "$changed_file" == "$search_dir"/* ]]; then
    relative_path="${changed_file#$search_dir/}"
    relative_path="${relative_path%.*}"
  else
    relative_path="$basename"
  fi

  # Import 패턴 검색
  # 1. 파일명 기반: from './user' or from './model'
  # 2. 경로 기반: from 'entities/user/model' or from '@/entities/user'
  local pattern="(from ['\"].*${basename}['\"]|import.*['\"].*${basename}['\"]"
  pattern+="|from ['\"].*${relative_path}['\"]|import.*['\"].*${relative_path}['\"])"

  # grep으로 import 검색
  grep -r \
    --include="*.ts" \
    --include="*.tsx" \
    --include="*.js" \
    --include="*.jsx" \
    -l \
    -E "$pattern" \
    "$search_dir" 2>/dev/null || true
}

# ============================================================================
# 캐시 확인
# ============================================================================

# 파일이 캐시에 존재하고 유효한지 확인
#
# Arguments:
#   $1 - file path
# Returns:
#   0 if file is in cache and valid
#   1 otherwise
# Output:
#   None (silent)
#
# Example:
#   if is_file_in_cache "src/entities/user/model.ts"; then
#     echo "Cache hit"
#   fi
is_file_in_cache() {
  local file="$1"

  # 인자 검증
  if [[ -z "$file" ]]; then
    return 1
  fi

  # cache-manager의 is_cache_valid 사용
  if is_cache_valid "$file"; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# 증분 검증 실행
# ============================================================================

# 증분 검증 실행 (변경된 파일 + 영향 받는 파일만 검증)
#
# Arguments:
#   $1 - base commit/branch (선택적, 기본값: HEAD)
#   $2 - validation function name (필수)
#        - 함수는 파일 경로를 인자로 받고 0(성공)/1(실패) 반환
# Returns:
#   0 if all files pass validation
#   1 if any files fail
# Output:
#   Validation progress and results
#
# Example:
#   # 검증 함수 정의
#   validate_file() {
#     local file="$1"
#     # validation logic here
#     return 0
#   }
#
#   # 증분 검증 실행
#   run_incremental_validation "HEAD" "validate_file"
#
# Note:
#   - 캐시에 있는 파일은 스킵
#   - 검증 통과 시 캐시에 저장
#   - Import 영향 파일도 자동으로 검증
run_incremental_validation() {
  local base="${1:-HEAD}"
  local validate_func="${2:-}"

  # 인자 검증
  if [[ -z "$validate_func" ]]; then
    log_error "run_incremental_validation: validation function required"
    return 1
  fi

  # 검증 함수 존재 확인
  if ! declare -f "$validate_func" > /dev/null; then
    log_error "run_incremental_validation: function '$validate_func' not found"
    return 1
  fi

  log_info "Running incremental validation..."

  # 캐시 초기화
  if [[ ! -f "$CACHE_FILE" ]]; then
    init_cache
  fi

  # 변경 파일 조회
  local changed_files
  changed_files=$(get_changed_files "$base" 2>/dev/null || echo "")

  if [[ -z "$changed_files" ]]; then
    log_success "No files changed - validation skipped"
    return 0
  fi

  # 통계 변수
  local total_files=0
  local validated_files=0
  local cached_files=0
  local failed_files=0

  # 검증할 파일 목록 (중복 제거용) - bash 3.2 호환
  local files_to_validate=()

  # 중복 체크 헬퍼 함수
  is_in_files_list() {
    local item="$1"
    shift
    for i in "$@"; do
      if [[ "$i" == "$item" ]]; then
        return 0
      fi
    done
    return 1
  }

  # 변경 파일 처리
  while IFS= read -r file; do
    # 빈 줄 스킵
    if [[ -z "$file" ]]; then
      continue
    fi

    # 삭제된 파일 스킵
    if [[ ! -f "$file" ]]; then
      continue
    fi

    # TypeScript/JavaScript 파일만 검증
    if [[ ! "$file" =~ \.(ts|tsx|js|jsx)$ ]]; then
      continue
    fi

    total_files=$((total_files + 1))

    # 검증 대상 추가 (중복 제거)
    if ! is_in_files_list "$file" "${files_to_validate[@]+"${files_to_validate[@]}"}"; then
      files_to_validate+=("$file")
    fi

    # 영향 받는 파일도 추가
    local affected_files
    affected_files=$(get_affected_files "$file" 2>/dev/null || echo "")

    if [[ -n "$affected_files" ]]; then
      while IFS= read -r affected_file; do
        if [[ -n "$affected_file" && -f "$affected_file" ]]; then
          if [[ "$affected_file" =~ \.(ts|tsx|js|jsx)$ ]]; then
            if ! is_in_files_list "$affected_file" "${files_to_validate[@]+"${files_to_validate[@]}"}"; then
              files_to_validate+=("$affected_file")
            fi
          fi
        fi
      done <<< "$affected_files"
    fi
  done <<< "$changed_files"

  # 실제 검증 실행
  log_info "Validating ${#files_to_validate[@]} file(s)..."

  for file in "${files_to_validate[@]+"${files_to_validate[@]}"}"; do
    # 캐시 확인
    if is_file_in_cache "$file"; then
      cached_files=$((cached_files + 1))
      log_debug "Cache hit: $file"
      continue
    fi

    # 검증 실행
    log_debug "Validating: $file"

    local validation_result
    set +e
    $validate_func "$file"
    validation_result=$?
    set -e

    if [[ $validation_result -eq 0 ]]; then
      validated_files=$((validated_files + 1))
      # 캐시 업데이트 (성공)
      update_cache "$file" "valid" "[]"
      log_debug "✓ Valid: $file"
    else
      failed_files=$((failed_files + 1))
      # 캐시 업데이트 (실패)
      update_cache "$file" "invalid" '[{"rule":"incremental","message":"Validation failed"}]'
      log_error "✗ Invalid: $file"
    fi
  done

  # 검증 결과 요약
  echo ""
  log_info "========================================="
  log_info "Incremental Validation Summary"
  log_info "========================================="
  log_info "Total changed files:    $total_files"
  log_info "Files to validate:      ${#files_to_validate[@]}"
  log_info "Cached (skipped):       $cached_files"
  log_info "Newly validated:        $validated_files"
  log_info "Failed:                 $failed_files"
  echo ""

  if [[ $failed_files -eq 0 ]]; then
    log_success "All files passed validation ✓"
    return 0
  else
    log_error "$failed_files file(s) failed validation ✗"
    return 1
  fi
}

# ============================================================================
# 모듈 초기화
# ============================================================================

# Note: This module is designed to be sourced, not executed directly.
# For testing, use .claude/lib/architecture/__tests__/test-incremental.sh
