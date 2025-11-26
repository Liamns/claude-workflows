#!/bin/bash
# quick-check.sh
# Unified Architecture Quick Check Orchestrator
#
# Integrates all architecture-specific quick checks:
# - FSD (Feature-Sliced Design)
# - Clean Architecture
# - Hexagonal Architecture
# - DDD (Domain-Driven Design)
# - Layered (N-Tier)
# - NestJS Layered
# - Express MVC
# - Serverless
#
# Usage: bash quick-check.sh [options]

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

# 기본값
ARCH_TYPE="auto"
ROOT_PATH="src"
OUTPUT_FORMAT="text"
AUTO_FIX=false
VERBOSE=false

# ============================================================================
# 사용법
# ============================================================================

show_usage() {
  cat <<EOF
Usage: bash quick-check.sh [options]

Architecture Quick Check - Fast validation using Bash

Options:
  --arch <TYPE>     Architecture type (default: auto)
                    Available: fsd, clean, hexagonal, ddd, layered, nestjs, express, serverless, auto
  --path <PATH>     Root path to check (default: src/)
  --fix             Auto-fix violations if possible
  --json            Output as JSON format
  -v, --verbose     Verbose output
  -h, --help        Show this help message

Examples:
  # Auto-detect architecture and validate
  bash quick-check.sh

  # Validate specific architecture
  bash quick-check.sh --arch fsd --path src/

  # Output as JSON for CI/CD
  bash quick-check.sh --json

  # Auto-fix violations
  bash quick-check.sh --fix

Exit codes:
  0 - All checks passed
  1 - Validation errors found
  2 - Invalid arguments or configuration error

EOF
}

# ============================================================================
# 옵션 파싱
# ============================================================================

parse_options() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
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
# 아키텍처 자동 감지
# ============================================================================

# 프로젝트의 아키텍처 타입 자동 감지
detect_architecture() {
  local root_path="$1"

  # 존재하지 않는 경로
  if [[ ! -d "$root_path" ]]; then
    echo "unknown"
    return
  fi

  # FSD: app, pages, widgets, features, entities, shared 디렉토리
  if [[ -d "$root_path/app" ]] && [[ -d "$root_path/entities" ]] && [[ -d "$root_path/shared" ]]; then
    echo "fsd"
    return
  fi

  # Clean Architecture: domain, application, infrastructure, presentation
  if [[ -d "$root_path/domain" ]] && [[ -d "$root_path/application" ]]; then
    echo "clean"
    return
  fi

  # Hexagonal: core, adapters
  if [[ -d "$root_path/core" ]] && [[ -d "$root_path/adapters" ]]; then
    echo "hexagonal"
    return
  fi

  # DDD: domain, infrastructure, interfaces 또는 boundedContexts
  if [[ -d "$root_path/boundedContexts" ]]; then
    echo "ddd"
    return
  fi

  # NestJS: .module.ts 파일들이 많음
  local module_count=$(find "$root_path" -name "*.module.ts" 2>/dev/null | wc -l)
  if [[ $module_count -gt 2 ]]; then
    echo "nestjs"
    return
  fi

  # Express MVC: routes, controllers, models, services 디렉토리
  if [[ -d "$root_path/routes" ]] || [[ -d "$root_path/controllers" ]]; then
    if [[ -d "$root_path/models" ]] || [[ -d "$root_path/services" ]]; then
      echo "express"
      return
    fi
  fi

  # Serverless: functions, layers 디렉토리
  if [[ -d "$root_path/functions" ]] && [[ -d "$root_path/layers" ]]; then
    echo "serverless"
    return
  fi

  # Layered: presentation, business, data 디렉토리
  if [[ -d "$root_path/presentation" ]] && [[ -d "$root_path/business" ]] && [[ -d "$root_path/data" ]]; then
    echo "layered"
    return
  fi

  # 감지 실패
  echo "unknown"
}

# ============================================================================
# Quick Check 실행
# ============================================================================

# 특정 아키텍처에 대한 quick check 실행
run_quick_check() {
  local arch="$1"
  local path="$2"

  local check_script="${SCRIPT_DIR}/quick-check-${arch}.sh"

  # 스크립트 존재 확인
  if [[ ! -f "$check_script" ]]; then
    log_error "Quick check script not found for architecture: $arch"
    log_error "Expected: $check_script"
    return 2
  fi

  # 스크립트 source
  source "$check_script"

  # 아키텍처별 validate 함수 호출
  local validate_func="validate_${arch}_directory"

  if ! declare -f "$validate_func" &> /dev/null; then
    log_error "Validation function not found: $validate_func"
    return 2
  fi

  # 검증 실행
  if $VERBOSE; then
    log_info "Running quick check for: $arch"
    log_info "Using script: $check_script"
    log_info "Validating path: $path"
  fi

  # JSON 모드일 때는 출력 억제
  if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    if "$validate_func" "$path" > /dev/null 2>&1; then
      return 0
    else
      return 1
    fi
  else
    if "$validate_func" "$path"; then
      return 0
    else
      return 1
    fi
  fi
}

# ============================================================================
# JSON 출력
# ============================================================================

# JSON 형식으로 결과 출력
output_json() {
  local arch="$1"
  local path="$2"
  local result="$3"
  local message="$4"

  local status="pass"
  if [[ "$result" != "0" ]]; then
    status="fail"
  fi

  cat <<EOF
{
  "architecture": "$arch",
  "path": "$path",
  "status": "$status",
  "message": "$message",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "tool": "quick-check.sh",
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
      output_json "unknown" "$ROOT_PATH" "2" "Root path not found"
    else
      log_error "Root path not found: $ROOT_PATH"
    fi
    exit 2
  fi

  # 아키텍처 자동 감지
  if [[ "$ARCH_TYPE" == "auto" ]]; then
    ARCH_TYPE=$(detect_architecture "$ROOT_PATH")

    if [[ "$ARCH_TYPE" == "unknown" ]]; then
      if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        output_json "unknown" "$ROOT_PATH" "2" "Could not detect architecture type"
      else
        log_error "Could not detect architecture type in: $ROOT_PATH"
        log_info "Please specify architecture with --arch option"
        echo ""
        echo "Available architectures:"
        echo "  - fsd (Feature-Sliced Design)"
        echo "  - clean (Clean Architecture)"
        echo "  - hexagonal (Hexagonal/Ports & Adapters)"
        echo "  - ddd (Domain-Driven Design)"
        echo "  - layered (N-Tier Layered)"
        echo "  - nestjs (NestJS Layered)"
        echo "  - express (Express MVC)"
        echo "  - serverless (Serverless/FaaS)"
      fi
      exit 2
    fi

    if $VERBOSE; then
      log_success "Detected architecture: $ARCH_TYPE"
    fi
  fi

  # 아키텍처 유효성 확인
  local valid_archs=("fsd" "clean" "hexagonal" "ddd" "layered" "nestjs" "express" "serverless")
  local is_valid=false
  for valid_arch in "${valid_archs[@]}"; do
    if [[ "$ARCH_TYPE" == "$valid_arch" ]]; then
      is_valid=true
      break
    fi
  done

  if ! $is_valid; then
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
      output_json "$ARCH_TYPE" "$ROOT_PATH" "2" "Invalid architecture type"
    else
      log_error "Invalid architecture type: $ARCH_TYPE"
      log_info "Valid types: ${valid_archs[*]}"
    fi
    exit 2
  fi

  # Quick check 실행
  local result=0
  local message="All checks passed"

  if ! run_quick_check "$ARCH_TYPE" "$ROOT_PATH"; then
    result=1
    message="Validation errors found"
  fi

  # 결과 출력
  if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    output_json "$ARCH_TYPE" "$ROOT_PATH" "$result" "$message"
  else
    echo ""
    if [[ $result -eq 0 ]]; then
      log_success "✓ Quick check passed for $ARCH_TYPE architecture"
    else
      log_error "✗ Quick check failed for $ARCH_TYPE architecture"
    fi
  fi

  exit $result
}

# ============================================================================
# 실행
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
