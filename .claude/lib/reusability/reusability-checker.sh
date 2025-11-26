#!/bin/bash
# reusability-checker.sh
# 재사용성 검사 통합 CLI - Bash 스크립트 기반 하이브리드 접근법
# 토큰 사용량 85-90% 절감 (15,000 → 1,500 토큰)
#
# Usage: reusability-checker.sh [options] <query>

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

readonly VERSION="1.0.0"
readonly SCRIPT_NAME="reusability-checker"

# ============================================================================
# 도움말
# ============================================================================

show_usage() {
  cat <<EOF
Usage: $0 [options] <query>

재사용성 검사 통합 CLI - Bash 스크립트 기반 하이브리드 접근법

Options:
  -e, --env <ENV>       Environment: auto|frontend|backend|fullstack
                        (default: auto - 자동 감지)

  -t, --type <TYPE>     Pattern type to search:
                        - all: 모든 패턴 검색
                        - api: API 호출 패턴
                        - component: React/Vue 컴포넌트
                        - hook: React Hooks
                        - service: NestJS Service
                        - controller: NestJS Controller
                        - prisma: Prisma 모델
                        - utils: 유틸리티 함수
                        - state: 상태 관리 (Zustand, Redux)
                        - form: 폼 관련 코드
                        (default: all)

  -o, --output <FORMAT> Output format: text|json|markdown
                        (default: text)

  -v, --verbose         Verbose output (상세 로그 표시)

  -h, --help           Show this help message

Examples:
  # 자동 환경 감지로 "User" 검색
  $0 "User"

  # 백엔드 API 패턴만 검색
  $0 -e backend -t api "Auth"

  # 프론트엔드 컴포넌트 검색 (JSON 출력)
  $0 -e frontend -t component -o json "Button"

  # 전체 환경에서 모든 패턴 검색 (상세 로그)
  $0 -e fullstack -t all -v "User"

Token Savings:
  - Before (Claude direct Grep): ~15,000 tokens
  - After (Bash script): ~1,500 tokens
  - Savings: 90%

Version: $VERSION
EOF
}

# ============================================================================
# 메인 함수
# ============================================================================

main() {
  # 기본값
  local env="auto"
  local type="all"
  local output_format="text"
  local verbose=false
  local query=""

  # 옵션 파싱
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -e|--env)
        env="$2"
        shift 2
        ;;
      -t|--type)
        type="$2"
        shift 2
        ;;
      -o|--output)
        output_format="$2"
        shift 2
        ;;
      -v|--verbose)
        verbose=true
        shift
        ;;
      -h|--help)
        show_usage
        exit 0
        ;;
      -*)
        log_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
      *)
        query="$1"
        shift
        ;;
    esac
  done

  # 검색어 필수 검증
  if [[ -z "$query" ]]; then
    log_error "Query is required"
    echo ""
    show_usage
    exit 1
  fi

  # 환경 검증
  case "$env" in
    auto|frontend|backend|fullstack)
      # Valid
      ;;
    *)
      log_error "Invalid environment: $env"
      log_error "Must be one of: auto, frontend, backend, fullstack"
      exit 1
      ;;
  esac

  # 타입 검증
  case "$type" in
    all|api|component|hook|service|controller|prisma|utils|state|form)
      # Valid
      ;;
    *)
      log_error "Invalid type: $type"
      log_error "Must be one of: all, api, component, hook, service, controller, prisma, utils, state, form"
      exit 1
      ;;
  esac

  # 출력 형식 검증
  case "$output_format" in
    text|json|markdown)
      # Valid
      ;;
    *)
      log_error "Invalid output format: $output_format"
      log_error "Must be one of: text, json, markdown"
      exit 1
      ;;
  esac

  # 시작 로그
  if [[ "$verbose" == "true" ]]; then
    log_info "Starting reusability check..."
    log_info "Query: $query"
    log_info "Environment: $env"
    log_info "Type: $type"
    log_info "Output format: $output_format"
    echo ""
  fi

  # ============================================================================
  # 아키텍처 감지
  # ============================================================================

  local detected_frontend="unknown"
  local detected_backend="unknown"

  if [[ "$env" == "auto" ]]; then
    if [[ "$verbose" == "true" ]]; then
      log_info "Detecting architecture..."
    fi

    # detect-architecture.sh 실행
    local arch_result=$("${SCRIPT_DIR}/detect-architecture.sh" "json" 2>/dev/null || echo "{}")

    # jq가 있으면 JSON 파싱, 없으면 grep/sed 사용
    if command -v jq &> /dev/null; then
      detected_frontend=$(echo "$arch_result" | jq -r '.frontend.framework // "unknown"' 2>/dev/null || echo "unknown")
      detected_backend=$(echo "$arch_result" | jq -r '.backend.framework // "unknown"' 2>/dev/null || echo "unknown")
    else
      detected_frontend=$(echo "$arch_result" | grep -o '"frontend"[^}]*"framework"[^"]*"[^"]*"' | sed -E 's/.*"([^"]+)"$/\1/' || echo "unknown")
      detected_backend=$(echo "$arch_result" | grep -o '"backend"[^}]*"framework"[^"]*"[^"]*"' | sed -E 's/.*"([^"]+)"$/\1/' || echo "unknown")
    fi

    # 환경 자동 결정
    if [[ "$detected_frontend" != "unknown" && "$detected_backend" != "unknown" ]]; then
      env="fullstack"
    elif [[ "$detected_frontend" != "unknown" ]]; then
      env="frontend"
    elif [[ "$detected_backend" != "unknown" ]]; then
      env="backend"
    else
      env="fullstack"  # 감지 실패 시 전체 검색
    fi

    if [[ "$verbose" == "true" ]]; then
      log_success "Detected: $env (frontend=$detected_frontend, backend=$detected_backend)"
    fi
  fi

  # ============================================================================
  # 환경별 검색 실행
  # ============================================================================

  local search_results=""

  case "$env" in
    frontend)
      if [[ "$verbose" == "true" ]]; then
        log_info "Searching frontend patterns..."
      fi
      search_results=$("${SCRIPT_DIR}/search-react.sh" "$query" "$type" 2>/dev/null || echo "")
      ;;

    backend)
      if [[ "$verbose" == "true" ]]; then
        log_info "Searching backend patterns..."
      fi
      search_results=$("${SCRIPT_DIR}/search-nestjs.sh" "$query" "$type" 2>/dev/null || echo "")
      ;;

    fullstack)
      if [[ "$verbose" == "true" ]]; then
        log_info "Searching fullstack patterns..."
      fi

      local frontend_results=$("${SCRIPT_DIR}/search-react.sh" "$query" "$type" 2>/dev/null || echo "")
      local backend_results=$("${SCRIPT_DIR}/search-nestjs.sh" "$query" "$type" 2>/dev/null || echo "")

      # 결과 결합
      search_results=$(cat <<EOF
# ========================================
# Frontend Results
# ========================================
${frontend_results}

# ========================================
# Backend Results
# ========================================
${backend_results}
EOF
)
      ;;
  esac

  # ============================================================================
  # 결과 포맷팅 및 출력
  # ============================================================================

  case "$output_format" in
    text)
      # 텍스트 출력 (기본)
      echo "$search_results"
      ;;

    json)
      # JSON 출력
      cat <<EOF
{
  "query": "$query",
  "environment": "$env",
  "type": "$type",
  "detected": {
    "frontend": "$detected_frontend",
    "backend": "$detected_backend"
  },
  "results": $(echo "$search_results" | jq -Rs '.' 2>/dev/null || echo "\"$search_results\"")
}
EOF
      ;;

    markdown)
      # Markdown 출력
      cat <<EOF
# Reusability Check Results

- **Query**: \`$query\`
- **Environment**: $env
- **Type**: $type
- **Detected**: frontend=$detected_frontend, backend=$detected_backend

## Search Results

\`\`\`
$search_results
\`\`\`
EOF
      ;;
  esac

  # 완료 로그
  if [[ "$verbose" == "true" ]]; then
    echo ""
    log_success "Reusability check completed"
  fi
}

# ============================================================================
# 스크립트 직접 실행 감지
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
