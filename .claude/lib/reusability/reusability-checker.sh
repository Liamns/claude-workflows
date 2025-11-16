#!/bin/bash
# 메인 재사용성 검사 스크립트

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 아키텍처 감지 먼저 로드 (다른 스크립트에서 사용)
source "${SCRIPT_DIR}/detect-architecture.sh"

# 하위 스크립트 로드
source "${SCRIPT_DIR}/search-react.sh"
source "${SCRIPT_DIR}/search-nestjs.sh"
source "${SCRIPT_DIR}/search-capacitor.sh"
source "${SCRIPT_DIR}/analyze-similarity.sh"

# 사용법
usage() {
    cat <<EOF
Usage: reusability-checker.sh [OPTIONS] <PATTERN>

재사용 가능한 모듈을 검색합니다.

OPTIONS:
  -e, --environment ENV    검색 환경 (frontend|backend|mobile|all)
  -t, --type TYPE          검색 타입 (component|function|type|service|dto|prisma|controller|module|all)
  -v, --verbose            상세 출력
  -h, --help               도움말 표시

EXAMPLES:
  # React 컴포넌트 검색
  reusability-checker.sh -e frontend -t component Button

  # NestJS 서비스 검색
  reusability-checker.sh -e backend -t service Auth

  # Prisma Model 검색
  reusability-checker.sh -e backend -t prisma User

  # 전체 환경에서 타입 검색
  reusability-checker.sh -e all -t type OrderStatus

  # Capacitor 플러그인 검색
  reusability-checker.sh -e mobile -t function Camera
EOF
}

# 메인 로직
main() {
    local environment="all"
    local type="all"
    local pattern=""
    local verbose=false

    # 옵션 파싱
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                environment="$2"
                shift 2
                ;;
            -t|--type)
                type="$2"
                shift 2
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                pattern="$1"
                shift
                ;;
        esac
    done

    if [ -z "$pattern" ]; then
        echo "❌ Error: 검색 패턴이 필요합니다"
        usage
        exit 1
    fi

    echo "🔍 Reusability Check: ${pattern}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Frontend 검색
    if [[ "$environment" == "all" || "$environment" == "frontend" ]]; then
        echo ""
        echo "📱 Frontend (React)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        if [[ "$type" == "all" || "$type" == "component" ]]; then
            search_react_components "$pattern"
        fi

        if [[ "$type" == "all" || "$type" == "type" ]]; then
            search_react_types "$pattern"
        fi

        if [[ "$type" == "all" || "$type" == "function" ]]; then
            search_react_utils "$pattern"
        fi

        if [[ "$type" == "all" || "$type" == "hook" ]]; then
            search_react_hooks "$pattern"
        fi
    fi

    # Backend 검색
    if [[ "$environment" == "all" || "$environment" == "backend" ]]; then
        echo ""
        echo "⚙️  Backend (NestJS)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        if [[ "$type" == "all" || "$type" == "service" ]]; then
            search_nestjs_services "$pattern"
        fi

        if [[ "$type" == "all" || "$type" == "dto" ]]; then
            search_nestjs_dtos "$pattern"
        fi

        if [[ "$type" == "all" || "$type" == "prisma" || "$type" == "model" ]]; then
            search_nestjs_prisma "$pattern"
        fi

        if [[ "$type" == "all" || "$type" == "controller" ]]; then
            search_nestjs_controllers "$pattern"
        fi

        if [[ "$type" == "all" || "$type" == "module" ]]; then
            search_nestjs_modules "$pattern"
        fi
    fi

    # Mobile 검색
    if [[ "$environment" == "all" || "$environment" == "mobile" ]]; then
        echo ""
        echo "📱 Mobile (Capacitor)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        search_capacitor_plugins "$pattern"
        search_capacitor_wrappers "$pattern"
    fi

    echo ""
    echo "✅ 검색 완료"
}

main "$@"
