#!/bin/bash
# verify.sh
# Architecture Verification Orchestrator
#
# 통합 검증 시스템: Quick Check → Deep Check (조건부)
# Hybrid 접근: Bash Quick Check (0 tokens, <1s) → TypeScript Deep Check (필요시)
#
# Usage: bash verify.sh [OPTIONS]
#
# Options:
#   --quick            Run only quick check (default)
#   --deep             Run only deep check (TypeScript AST)
#   --both             Run both quick and deep checks
#   --incremental      Run incremental validation (changed files only)
#   --fix              Auto-fix simple violations
#   --cache-clear      Clear validation cache
#   --json             Output as JSON format
#   -v, --verbose      Verbose output
#   -h, --help         Show this help message
#
# Examples:
#   bash verify.sh                          # Quick check only
#   bash verify.sh --deep                   # Deep check only
#   bash verify.sh --both                   # Both checks
#   bash verify.sh --incremental            # Changed files only
#   bash verify.sh --quick --json           # Quick check with JSON output

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

VERIFY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$VERIFY_DIR")"

# Dependencies
source "${LIB_DIR}/common.sh"
# cache-manager.sh는 incremental.sh에서 source됨
source "${VERIFY_DIR}/incremental.sh"

# 기본 설정
MODE="quick"  # quick, deep, both
INCREMENTAL=false
AUTO_FIX=false
CACHE_CLEAR=false
OUTPUT_FORMAT="text"  # text, json
VERBOSE=false
ROOT_PATH="src"
ARCH_TYPE="auto"

# ============================================================================
# Usage
# ============================================================================

show_usage() {
  cat << EOF
Usage: bash verify.sh [OPTIONS]

Architecture Verification Orchestrator
Hybrid approach: Quick Check (Bash) → Deep Check (TypeScript, if needed)

Options:
  --quick            Run only quick check (default)
  --deep             Run only deep check (TypeScript AST)
  --both             Run both quick and deep checks
  --incremental      Run incremental validation (changed files only)
  --arch TYPE        Specify architecture type (auto-detect if not provided)
  --path PATH        Root path to validate (default: src)
  --fix              Auto-fix simple violations (experimental)
  --cache-clear      Clear validation cache
  --json             Output as JSON format
  -v, --verbose      Verbose output
  -h, --help         Show this help message

Supported Architectures:
  - fsd (Feature-Sliced Design)
  - clean (Clean Architecture)
  - hexagonal (Hexagonal/Ports & Adapters)
  - ddd (Domain-Driven Design)
  - layered (N-Tier Layered)
  - nestjs (NestJS Layered)
  - express (Express MVC)
  - serverless (Serverless/FaaS)

Examples:
  bash verify.sh                          # Quick check only
  bash verify.sh --deep                   # Deep check only
  bash verify.sh --both                   # Both checks
  bash verify.sh --incremental            # Changed files only
  bash verify.sh --quick --json           # Quick check with JSON output
  bash verify.sh --arch fsd --path src    # FSD quick check

Performance:
  Quick Check:  <1s, 0 tokens
  Deep Check:   5-30s, 10,000+ tokens
  Incremental:  <2s, <1,000 tokens

EOF
}

# ============================================================================
# 옵션 파싱
# ============================================================================

parse_options() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --quick)
        MODE="quick"
        shift
        ;;
      --deep)
        MODE="deep"
        shift
        ;;
      --both)
        MODE="both"
        shift
        ;;
      --incremental)
        INCREMENTAL=true
        shift
        ;;
      --arch)
        ARCH_TYPE="$2"
        shift 2
        ;;
      --path)
        ROOT_PATH="$2"
        shift 2
        ;;
      --fix)
        AUTO_FIX=true
        shift
        ;;
      --cache-clear)
        CACHE_CLEAR=true
        shift
        ;;
      --json)
        OUTPUT_FORMAT="json"
        shift
        ;;
      -v|--verbose)
        VERBOSE=true
        shift
        ;;
      -h|--help)
        show_usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        show_usage
        exit 2
        ;;
    esac
  done
}

# ============================================================================
# Quick Check 실행
# ============================================================================

run_quick_validation() {
  local path="$1"

  if $VERBOSE; then
    log_info "Running Quick Check..."
    log_info "Path: $path"
    log_info "Architecture: $ARCH_TYPE"
  fi

  # quick-check.sh 실행
  local quick_check_script="${VERIFY_DIR}/quick-check.sh"

  if [[ ! -f "$quick_check_script" ]]; then
    log_error "Quick check script not found: $quick_check_script"
    return 2
  fi

  # 옵션 구성
  local quick_opts="--path $path"

  if [[ "$ARCH_TYPE" != "auto" ]]; then
    quick_opts="$quick_opts --arch $ARCH_TYPE"
  fi

  # JSON 모드일 때는 quick-check.sh를 text 모드로 실행 (출력 억제)
  # verify.sh가 최종 JSON을 출력
  if $VERBOSE && [[ "$OUTPUT_FORMAT" != "json" ]]; then
    quick_opts="$quick_opts --verbose"
  fi

  # Quick check 실행
  if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    # JSON 모드: quick-check의 출력 억제, exit code만 사용
    bash "$quick_check_script" $quick_opts > /dev/null 2>&1
    return $?
  else
    # Text 모드: 정상 출력
    bash "$quick_check_script" $quick_opts
    return $?
  fi
}

# ============================================================================
# Deep Check 실행
# ============================================================================

run_deep_validation() {
  local path="$1"

  if $VERBOSE; then
    log_info "Running Deep Check..."
    log_info "Path: $path"
  fi

  # TypeScript validate.ts 실행
  local validate_script="${VERIFY_DIR}/../../architectures/tools/validate.ts"

  if [[ ! -f "$validate_script" ]]; then
    log_warning "Deep check script not found: $validate_script"
    log_warning "Skipping deep check"
    return 0
  fi

  # Deep check 실행 (tsx 또는 ts-node 필요)
  if command -v tsx &> /dev/null; then
    tsx "$validate_script" "$path"
    return $?
  elif command -v ts-node &> /dev/null; then
    ts-node "$validate_script" "$path"
    return $?
  else
    log_warning "tsx or ts-node not found - skipping deep check"
    log_info "Install: npm install -g tsx"
    return 0
  fi
}

# ============================================================================
# JSON 출력
# ============================================================================

output_json_result() {
  local status="$1"
  local message="$2"
  local mode="$3"

  cat <<EOF
{
  "status": "$status",
  "message": "$message",
  "mode": "$mode",
  "path": "$ROOT_PATH",
  "architecture": "$ARCH_TYPE",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "tool": "verify.sh",
  "version": "1.0.0"
}
EOF
}

# ============================================================================
# 메인 함수
# ============================================================================

main() {
  # 옵션 파싱
  parse_options "$@"

  # 경로 존재 확인
  if [[ ! -d "$ROOT_PATH" ]]; then
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
      output_json_result "error" "Root path not found: $ROOT_PATH" "$MODE"
    else
      log_error "Root path not found: $ROOT_PATH"
    fi
    exit 2
  fi

  # 캐시 초기화 (JSON 모드에서는 출력 억제)
  if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    init_cache > /dev/null 2>&1
  else
    init_cache
  fi

  # 캐시 삭제 (요청 시)
  if [[ "$CACHE_CLEAR" == "true" ]]; then
    if $VERBOSE; then
      log_info "Clearing cache..."
    fi
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
      invalidate_cache > /dev/null 2>&1
    else
      invalidate_cache
    fi
  fi

  # 증분 검증 모드
  if [[ "$INCREMENTAL" == "true" ]]; then
    if $VERBOSE; then
      log_info "Running incremental validation..."
    fi

    run_incremental_validation "$ROOT_PATH"
    local result=$?

    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
      if [[ $result -eq 0 ]]; then
        output_json_result "pass" "Incremental validation passed" "incremental"
      else
        output_json_result "fail" "Incremental validation failed" "incremental"
      fi
    fi

    exit $result
  fi

  # Quick Check 실행
  if [[ "$MODE" == "quick" ]] || [[ "$MODE" == "both" ]]; then
    run_quick_validation "$ROOT_PATH"
    local quick_result=$?

    if [[ $quick_result -ne 0 ]]; then
      if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        output_json_result "fail" "Quick check failed" "quick"
      else
        log_error "Quick check failed"
      fi
      exit 1
    fi

    if [[ "$MODE" == "quick" ]]; then
      if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        output_json_result "pass" "Quick check passed" "quick"
      else
        log_success "Quick check passed!"
      fi
      exit 0
    fi
  fi

  # Deep Check 실행 (조건부)
  if [[ "$MODE" == "deep" ]] || [[ "$MODE" == "both" ]]; then
    run_deep_validation "$ROOT_PATH"
    local deep_result=$?

    if [[ $deep_result -ne 0 ]]; then
      if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        output_json_result "fail" "Deep check failed" "deep"
      else
        log_error "Deep check failed"
      fi
      exit 1
    fi

    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
      output_json_result "pass" "All checks passed" "$MODE"
    else
      log_success "All checks passed!"
    fi
    exit 0
  fi

  # 기본 성공
  exit 0
}

# ============================================================================
# 실행
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
