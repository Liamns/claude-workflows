#!/bin/bash
# search-react.sh
# React 패턴 검색 스크립트
# 컴포넌트, Hooks, Context, State 관리 등 React 관련 패턴 검색
#
# Usage: search-react.sh <query> [type]
#        type: all (default) | component | hook | context | state

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

# PROJECT_ROOT 감지
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$PROJECT_ROOT"

# ============================================================================
# React 컴포넌트 검색
# ============================================================================

search_react_components() {
  local query="$1"

  # 패턴: export function 또는 export const 컴포넌트
  local pattern="export.*(function|const).*${query}"

  # .tsx, .jsx 파일에서 검색
  grep -rn \
    --include="*.tsx" \
    --include="*.jsx" \
    --exclude-dir={node_modules,.git,dist,build,.next,out} \
    -E "$pattern" \
    src/ 2>/dev/null || true
}

# ============================================================================
# React Hooks 검색
# ============================================================================

search_react_hooks() {
  local query="$1"

  # 패턴: use로 시작하는 Hook
  local pattern="(use${query}|const.*use.*=|export.*use)"

  # .ts, .tsx 파일에서 검색
  grep -rn \
    --include="*.ts" \
    --include="*.tsx" \
    --exclude-dir={node_modules,.git,dist,build,.next,out} \
    -E "$pattern" \
    src/ 2>/dev/null || true
}

# ============================================================================
# React Context 검색
# ============================================================================

search_react_context() {
  local query="$1"

  # 패턴: createContext 또는 Context 변수
  local pattern="(createContext.*${query}|${query}Context|${query}Provider)"

  # .ts, .tsx 파일에서 검색
  grep -rn \
    --include="*.ts" \
    --include="*.tsx" \
    --exclude-dir={node_modules,.git,dist,build,.next,out} \
    -E "$pattern" \
    src/ 2>/dev/null || true
}

# ============================================================================
# React State 관리 검색 (Zustand, Redux, etc.)
# ============================================================================

search_react_state() {
  local query="$1"

  # Zustand store 검색
  local zustand_pattern="(create.*${query}|${query}Store|use${query}Store)"

  # Redux slice 검색
  local redux_pattern="(createSlice.*${query}|${query}Slice|${query}Reducer)"

  echo "# Zustand Stores:"
  grep -rn \
    --include="*.ts" \
    --include="*.tsx" \
    --exclude-dir={node_modules,.git,dist,build,.next,out} \
    -E "$zustand_pattern" \
    src/ 2>/dev/null || true

  echo ""
  echo "# Redux Slices:"
  grep -rn \
    --include="*.ts" \
    --include="*.tsx" \
    --exclude-dir={node_modules,.git,dist,build,.next,out} \
    -E "$redux_pattern" \
    src/ 2>/dev/null || true
}

# ============================================================================
# React Query Hooks 검색
# ============================================================================

search_react_query() {
  local query="$1"

  # 패턴: useQuery, useMutation 등
  local pattern="(useQuery.*${query}|useMutation.*${query}|use.*${query}.*Query)"

  grep -rn \
    --include="*.ts" \
    --include="*.tsx" \
    --exclude-dir={node_modules,.git,dist,build,.next,out} \
    -E "$pattern" \
    src/ 2>/dev/null || true
}

# ============================================================================
# React Form 관련 검색
# ============================================================================

search_react_form() {
  local query="$1"

  # React Hook Form, Formik 등
  local pattern="(useForm.*${query}|${query}Schema|${query}Validation)"

  grep -rn \
    --include="*.ts" \
    --include="*.tsx" \
    --exclude-dir={node_modules,.git,dist,build,.next,out} \
    -E "$pattern" \
    src/ 2>/dev/null || true
}

# ============================================================================
# 메인 함수
# ============================================================================

main() {
  local query="${1:-}"
  local type="${2:-all}"

  # 검색어 필수
  if [[ -z "$query" ]]; then
    log_error "Query is required"
    echo "Usage: $0 <query> [type]"
    echo "Types: all, component, hook, context, state, query, form"
    exit 1
  fi

  # 타입별 검색
  case "$type" in
    component|components)
      search_react_components "$query"
      ;;
    hook|hooks)
      search_react_hooks "$query"
      ;;
    context)
      search_react_context "$query"
      ;;
    state)
      search_react_state "$query"
      ;;
    query)
      search_react_query "$query"
      ;;
    form)
      search_react_form "$query"
      ;;
    all)
      echo "# React Components:"
      search_react_components "$query"
      echo ""

      echo "# React Hooks:"
      search_react_hooks "$query"
      echo ""

      echo "# React Context:"
      search_react_context "$query"
      echo ""

      echo "# State Management:"
      search_react_state "$query"
      echo ""

      echo "# React Query:"
      search_react_query "$query"
      echo ""

      echo "# Forms:"
      search_react_form "$query"
      ;;
    *)
      log_error "Unknown type: $type"
      echo "Valid types: all, component, hook, context, state, query, form"
      exit 1
      ;;
  esac
}

# ============================================================================
# 스크립트 직접 실행 감지
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
