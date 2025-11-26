#!/bin/bash
# detect-architecture.sh
# 프로젝트 아키텍처 자동 감지
# 프론트엔드/백엔드 프레임워크, 패키지 매니저 감지
#
# Usage: detect-architecture.sh [output_format]
#        output_format: text (default) | json

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

# PROJECT_ROOT 감지 (git 저장소 루트, 없으면 현재 디렉토리)
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$PROJECT_ROOT"

# ============================================================================
# 프론트엔드 프레임워크 감지
# ============================================================================

detect_frontend_framework() {
  local package_json="package.json"

  # package.json 없으면 unknown
  if [[ ! -f "$package_json" ]]; then
    echo "unknown"
    return
  fi

  # React 감지
  if grep -q '"react"' "$package_json" 2>/dev/null; then
    echo "react"
    return
  fi

  # Vue 감지
  if grep -q '"vue"' "$package_json" 2>/dev/null; then
    echo "vue"
    return
  fi

  # Angular 감지
  if grep -q '"@angular/core"' "$package_json" 2>/dev/null; then
    echo "angular"
    return
  fi

  # Svelte 감지
  if grep -q '"svelte"' "$package_json" 2>/dev/null; then
    echo "svelte"
    return
  fi

  echo "unknown"
}

# ============================================================================
# 백엔드 프레임워크 감지
# ============================================================================

detect_backend_framework() {
  local package_json="package.json"

  # package.json 없으면 unknown
  if [[ ! -f "$package_json" ]]; then
    echo "unknown"
    return
  fi

  # NestJS 감지
  if grep -q '"@nestjs/core"' "$package_json" 2>/dev/null; then
    echo "nestjs"
    return
  fi

  # Express 감지
  if grep -q '"express"' "$package_json" 2>/dev/null; then
    echo "express"
    return
  fi

  # Fastify 감지
  if grep -q '"fastify"' "$package_json" 2>/dev/null; then
    echo "fastify"
    return
  fi

  # Koa 감지
  if grep -q '"koa"' "$package_json" 2>/dev/null; then
    echo "koa"
    return
  fi

  echo "unknown"
}

# ============================================================================
# 패키지 매니저 감지
# ============================================================================

detect_package_manager() {
  # yarn 감지
  if [[ -f "yarn.lock" ]]; then
    echo "yarn"
    return
  fi

  # pnpm 감지
  if [[ -f "pnpm-lock.yaml" ]]; then
    echo "pnpm"
    return
  fi

  # npm 감지
  if [[ -f "package-lock.json" ]]; then
    echo "npm"
    return
  fi

  echo "unknown"
}

# ============================================================================
# 프레임워크 버전 감지 (선택적)
# ============================================================================

get_framework_version() {
  local framework="$1"
  local package_json="package.json"

  if [[ ! -f "$package_json" ]]; then
    echo "unknown"
    return
  fi

  # jq가 있으면 사용 (더 정확)
  if command -v jq &> /dev/null; then
    local version=$(jq -r ".dependencies.\"$framework\" // .devDependencies.\"$framework\" // \"unknown\"" "$package_json" 2>/dev/null)
    echo "$version"
  else
    # jq 없으면 grep/sed 사용 (근사치)
    local version=$(grep "\"$framework\"" "$package_json" 2>/dev/null | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
    echo "${version:-unknown}"
  fi
}

# ============================================================================
# 메인 함수
# ============================================================================

main() {
  local output_format="${1:-text}"

  # 감지 실행
  local frontend=$(detect_frontend_framework)
  local backend=$(detect_backend_framework)
  local pkg_manager=$(detect_package_manager)

  # 출력 형식에 따라 표시
  if [[ "$output_format" == "json" ]]; then
    # JSON 출력
    cat <<EOF
{
  "frontend": {
    "framework": "$frontend"
  },
  "backend": {
    "framework": "$backend"
  },
  "packageManager": "$pkg_manager",
  "projectRoot": "$PROJECT_ROOT"
}
EOF
  else
    # 텍스트 출력
    echo "Frontend Framework: $frontend"
    echo "Backend Framework: $backend"
    echo "Package Manager: $pkg_manager"
    echo "Project Root: $PROJECT_ROOT"
  fi
}

# ============================================================================
# 스크립트 직접 실행 감지
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
