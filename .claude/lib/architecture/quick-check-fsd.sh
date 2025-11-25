#!/bin/bash
# quick-check-fsd.sh
# FSD (Feature-Sliced Design) Quick Check Rules - Team Custom v2.1
#
# Validates Team Custom FSD architecture rules:
# - Layer dependency rules (app → pages → features → entities → shared)
# - Type-only imports between features
# - Entity purity (no interactions, GET only)
# - Shared purity (no domain logic)
# - Public API (index.ts)
#
# Based on: FSD v2.1 + Team Domain-Centric Adaptations
#
# Usage:
#   source quick-check-fsd.sh
#   validate_fsd_file "src/features/auth/ui/SignInForm.tsx"

set -euo pipefail

# ============================================================================
# FSD 레이어 정의 (Team Custom)
# ============================================================================

# FSD 레이어 우선순위 (낮을수록 하위 레이어)
# 1: shared (가장 하위)
# 2: entities (optional)
# 3: features
# 4: pages
# 5: app (가장 상위)
#
# Note: widgets layer removed in team custom

# Get FSD layer priority (bash 3.2 compatible)
#
# Arguments:
#   $1 - 레이어 이름
# Returns:
#   우선순위 번호 (1-5)
#   -1 if unknown layer
get_fsd_layer_priority() {
  local layer="$1"

  case "$layer" in
    "shared")
      echo 1
      ;;
    "entities")
      echo 2
      ;;
    "features")
      echo 3
      ;;
    "pages")
      echo 4
      ;;
    "app")
      echo 5
      ;;
    *)
      echo -1
      ;;
  esac
}

# ============================================================================
# 유틸리티 함수
# ============================================================================

# 파일의 FSD 레이어 추출
#
# Arguments:
#   $1 - 파일 경로 (e.g., "src/entities/user/model.ts")
# Returns:
#   레이어 이름 (shared, entities, features, pages, app)
#   빈 문자열 if not FSD structure
get_fsd_layer() {
  local file="$1"

  if [[ "$file" =~ src/(shared|entities|features|pages|app)/ ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo ""
  fi
}

# 파일의 FSD 슬라이스 추출
#
# Arguments:
#   $1 - 파일 경로
# Returns:
#   슬라이스 이름 (e.g., "auth", "order")
#   빈 문자열 if no slice
get_fsd_slice() {
  local file="$1"
  local layer=$(get_fsd_layer "$file")

  if [[ -z "$layer" ]]; then
    echo ""
    return
  fi

  # entities, features, pages는 슬라이스 개념이 있음
  if [[ "$layer" == "entities" || "$layer" == "features" || "$layer" == "pages" ]]; then
    if [[ "$file" =~ src/$layer/([^/]+) ]]; then
      echo "${BASH_REMATCH[1]}"
    else
      echo ""
    fi
  else
    echo ""
  fi
}

# ============================================================================
# 레이어 의존성 규칙
# ============================================================================

# FSD 레이어 의존성 규칙 검증 (Team Custom)
#
# Rules:
#   app → pages, features, entities, shared
#   pages → features, entities, shared
#   features → entities, shared (+ type-only from features)
#   entities → shared
#   shared → none
#
# Arguments:
#   $1 - 소스 파일 경로
#   $2 - import된 파일 경로
#   $3 - import 문 전체 (type-only 체크용)
# Returns:
#   0 if valid dependency
#   1 if invalid dependency
validate_fsd_layer_dependency() {
  local source_file="$1"
  local import_path="$2"
  local import_statement="${3:-}"

  local source_layer=$(get_fsd_layer "$source_file")
  local target_layer=$(get_fsd_layer "$import_path")

  # FSD 구조가 아니면 스킵
  if [[ -z "$source_layer" || -z "$target_layer" ]]; then
    return 0
  fi

  # 동일 레이어 내 import는 일단 허용 (슬라이스 체크는 별도)
  if [[ "$source_layer" == "$target_layer" ]]; then
    return 0
  fi

  # 레이어 우선순위 확인
  local source_priority=$(get_fsd_layer_priority "$source_layer")
  local target_priority=$(get_fsd_layer_priority "$target_layer")

  # 하위 레이어만 import 가능 (상위 → 하위는 OK)
  if [[ $source_priority -gt $target_priority ]]; then
    return 0
  else
    echo "❌ FSD layer violation: $source_layer cannot import from $target_layer"
    echo "   Source: $source_file"
    echo "   Import: $import_path"
    echo "   Rule: Higher layers can only import from lower layers"
    return 1
  fi
}

# ============================================================================
# Feature간 Import 규칙 (Type-Only)
# ============================================================================

# Feature간 import 검증 (runtime import 금지, type-only만 허용)
#
# Team Rule: Features cannot import other features at runtime
# Exception: Type-only imports allowed with 'import type' syntax
#
# Arguments:
#   $1 - 소스 파일 경로
#   $2 - import 문 전체
# Returns:
#   0 if valid
#   1 if invalid (runtime import between features)
validate_fsd_feature_imports() {
  local source_file="$1"
  local import_statement="$2"

  local source_layer=$(get_fsd_layer "$source_file")

  # features 레이어가 아니면 스킵
  if [[ "$source_layer" != "features" ]]; then
    return 0
  fi

  # import 경로 추출
  local import_path=""
  if [[ "$import_statement" =~ from[[:space:]]+[\'\"](.*)[\'\"] ]] || [[ "$import_statement" =~ import[[:space:]]+[\'\"](.*)[\'\"] ]]; then
    import_path="${BASH_REMATCH[1]}"
  else
    return 0
  fi

  # features에서 다른 feature를 import하는지 체크
  local is_feature_import=0
  if [[ "$import_path" =~ ^@/features/ ]] || [[ "$import_path" =~ ^\.\./\.\./features/ ]] || [[ "$import_path" =~ features/ ]]; then
    is_feature_import=1
  fi

  if [[ $is_feature_import -eq 0 ]]; then
    return 0
  fi

  # Type-only import인지 체크
  if [[ "$import_statement" =~ ^import[[:space:]]+type[[:space:]]+ ]]; then
    # ✅ Type-only import는 허용
    return 0
  else
    # ❌ Runtime import는 금지
    echo "❌ FSD feature-to-feature violation: Runtime imports between features not allowed"
    echo "   Source: $source_file"
    echo "   Import: $import_path"
    echo "   Rule: Use 'import type' for type-only imports between features"
    echo "   Fix: import type { Type } from '$import_path'"
    return 1
  fi
}

# ============================================================================
# Entity 순수성 규칙
# ============================================================================

# Entity 순수성 검증
#
# Rules:
#   - NO React hooks (useState, useEffect, etc.)
#   - NO mutations (POST/PUT/DELETE)
#   - NO event handlers in component props
#
# Arguments:
#   $1 - 파일 경로
# Returns:
#   0 if valid
#   1 if purity violation
validate_fsd_entity_purity() {
  local file="$1"
  local layer=$(get_fsd_layer "$file")

  # entities 레이어가 아니면 스킵
  if [[ "$layer" != "entities" ]]; then
    return 0
  fi

  local has_errors=0

  # 1. React hooks 체크 (UI 파일에서)
  if [[ "$file" =~ \.(tsx|jsx)$ ]]; then
    if grep -qE "useState|useEffect|useReducer|useCallback|useMemo" "$file" 2>/dev/null; then
      echo "⚠️  FSD entity purity warning: Entity should not use React hooks"
      echo "   File: $file"
      echo "   Rule: Entities are pure domain models (read-only, no interactions)"
      has_errors=1
    fi
  fi

  # 2. Mutation methods 체크 (api 파일에서)
  if [[ "$file" =~ /api/ ]] && [[ "$file" =~ \.(ts|js)$ ]]; then
    if grep -qE "(POST|PUT|DELETE|PATCH)|(\.post\()|(\.put\()|(\.delete\()|(\.patch\()" "$file" 2>/dev/null; then
      echo "⚠️  FSD entity purity warning: Entity API should be GET only"
      echo "   File: $file"
      echo "   Rule: Mutations (POST/PUT/DELETE) belong in features or pages"
      has_errors=1
    fi
  fi

  # 3. Event handler props 체크 (컴포넌트에서)
  if [[ "$file" =~ \.(tsx|jsx)$ ]]; then
    if grep -qE "on[A-Z][a-zA-Z]*\s*:" "$file" 2>/dev/null; then
      echo "⚠️  FSD entity purity warning: Entity component should not have event handlers"
      echo "   File: $file"
      echo "   Rule: Entities accept only domain data props (no onClick, onChange, etc.)"
      has_errors=1
    fi
  fi

  if [[ $has_errors -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Shared 순수성 규칙
# ============================================================================

# Shared 순수성 검증 (도메인 특화 코드 금지)
#
# Rules:
#   - NO domain-specific logic
#   - Only generic utilities
#
# Arguments:
#   $1 - 파일 경로
# Returns:
#   0 if valid
#   1 if domain-specific code detected
validate_fsd_shared_purity() {
  local file="$1"
  local layer=$(get_fsd_layer "$file")

  # shared 레이어가 아니면 스킵
  if [[ "$layer" != "shared" ]]; then
    return 0
  fi

  local filename=$(basename "$file")

  # 도메인 특화 키워드 체크
  local domain_keywords=(
    "order" "Order"
    "payment" "Payment"
    "user" "User"
    "auth" "Auth"
    "product" "Product"
    "company" "Company"
    "freight" "Freight"
    "dispatch" "Dispatch"
  )

  for keyword in "${domain_keywords[@]}"; do
    if [[ "$filename" =~ $keyword ]]; then
      echo "⚠️  FSD shared purity warning: Shared should not contain domain-specific code"
      echo "   File: $file"
      echo "   Detected: '$keyword' (domain keyword)"
      echo "   Rule: Shared layer must be generic utilities only"
      echo "   Fix: Move to features/{domain}/ or entities/{domain}/"
      return 1
    fi
  done

  return 0
}

# ============================================================================
# Public API 규칙
# ============================================================================

# Public API (index.ts) 존재 확인
#
# Rule: Each slice should export through index.ts
#
# Arguments:
#   $1 - 슬라이스 디렉토리 경로
# Returns:
#   0 if valid (has index.ts or warning only)
#   1 never returned (warning only)
validate_fsd_public_api() {
  local slice_dir="$1"

  if [[ ! -d "$slice_dir" ]]; then
    return 0
  fi

  # index.ts 또는 index.tsx 존재 확인
  if [[ ! -f "${slice_dir}/index.ts" ]] && [[ ! -f "${slice_dir}/index.tsx" ]]; then
    echo "⚠️  FSD public API warning: Missing index.ts"
    echo "   Slice: $slice_dir"
    echo "   Rule: Each slice should export through index.ts (Public API)"
    # Warning only
  fi

  return 0
}

# ============================================================================
# Cross-Slice Import 규칙
# ============================================================================

# 동일 레이어 내 크로스 슬라이스 import 검증
#
# Rule: Imports between slices should use Public API (index.ts)
#
# Arguments:
#   $1 - 소스 파일 경로
#   $2 - import 문
# Returns:
#   0 always (warning only)
validate_fsd_cross_slice_import() {
  local source_file="$1"
  local import_statement="$2"

  # import 경로 추출
  local import_path=""
  if [[ "$import_statement" =~ from[[:space:]]+[\'\"](.*)[\'\"] ]] || [[ "$import_statement" =~ import[[:space:]]+[\'\"](.*)[\'\"] ]]; then
    import_path="${BASH_REMATCH[1]}"
  else
    return 0
  fi

  local source_layer=$(get_fsd_layer "$source_file")
  local source_slice=$(get_fsd_slice "$source_file")

  # 외부 패키지는 스킵
  if [[ ! "$import_path" =~ ^\.\.?/ ]] && [[ ! "$import_path" =~ ^src/ ]] && [[ ! "$import_path" =~ ^@/ ]]; then
    return 0
  fi

  # 슬라이스가 없는 레이어는 스킵
  if [[ -z "$source_slice" ]]; then
    return 0
  fi

  # import path에서 레이어와 슬라이스 추출
  local target_layer=""
  local target_slice=""

  if [[ "$import_path" =~ (shared|entities|features|pages|app)/([^/]+) ]]; then
    target_layer="${BASH_REMATCH[1]}"
    target_slice="${BASH_REMATCH[2]}"
  else
    return 0
  fi

  # 동일 레이어, 다른 슬라이스인 경우
  if [[ "$source_layer" == "$target_layer" ]] && [[ "$source_slice" != "$target_slice" ]]; then
    # Public API (index)를 통하는지 체크
    if [[ ! "$import_path" =~ /index$ ]] && [[ ! "$import_path" =~ /$target_slice$ ]]; then
      echo "⚠️  FSD cross-slice warning: Should use Public API (index.ts)"
      echo "   Source: $source_file ($source_layer/$source_slice)"
      echo "   Import: $import_path"
      echo "   Suggestion: import from '@/$target_layer/$target_slice' (uses index.ts)"
      # Warning only
    fi
  fi

  return 0
}

# ============================================================================
# 메인 검증 함수
# ============================================================================

# FSD 파일 검증 (모든 규칙 통합)
#
# Arguments:
#   $1 - 파일 경로
# Returns:
#   0 if all validations pass
#   1 if any validation fails
validate_fsd_file() {
  local file="$1"

  # 파일 존재 확인
  if [[ ! -f "$file" ]]; then
    echo "File not found: $file"
    return 1
  fi

  # FSD 구조가 아니면 스킵
  local layer=$(get_fsd_layer "$file")
  if [[ -z "$layer" ]]; then
    return 0
  fi

  local has_errors=0

  # 1. Entity 순수성 검증
  if ! validate_fsd_entity_purity "$file"; then
    has_errors=1
  fi

  # 2. Shared 순수성 검증
  if ! validate_fsd_shared_purity "$file"; then
    has_errors=1
  fi

  # 3. import 문 추출 및 검증
  local import_lines=$(grep -E "^import " "$file" 2>/dev/null || true)

  while IFS= read -r import_line; do
    if [[ -z "$import_line" ]]; then
      continue
    fi

    # import 경로 추출
    local import_path=""
    if [[ "$import_line" =~ from[[:space:]]+[\'\"](.*)[\'\"] ]] || [[ "$import_line" =~ import[[:space:]]+[\'\"](.*)[\'\"] ]]; then
      import_path="${BASH_REMATCH[1]}"
    else
      continue
    fi

    # 외부 패키지는 스킵
    if [[ ! "$import_path" =~ ^\.\.?/ ]] && [[ ! "$import_path" =~ ^src/ ]] && [[ ! "$import_path" =~ ^@/ ]]; then
      continue
    fi

    # 상대 경로를 프로젝트 경로로 변환
    local resolved_import=""
    if [[ "$import_path" =~ ^@/ ]]; then
      # Alias import (@/...)
      resolved_import="${import_path#@/}"
      resolved_import="src/$resolved_import"
    elif [[ "$import_path" =~ ^\.\.?/ ]]; then
      # 상대 경로
      local source_dir=$(dirname "$file")
      resolved_import="${source_dir}/${import_path}"
      resolved_import=$(realpath -m "$resolved_import" 2>/dev/null || echo "$resolved_import")
    else
      # 절대 경로
      resolved_import="$import_path"
    fi

    # 레이어 의존성 검증
    if ! validate_fsd_layer_dependency "$file" "$resolved_import" "$import_line"; then
      has_errors=1
    fi

    # Feature간 import 검증 (type-only)
    if ! validate_fsd_feature_imports "$file" "$import_line"; then
      has_errors=1
    fi

    # 크로스 슬라이스 import 검증 (warning only)
    validate_fsd_cross_slice_import "$file" "$import_line"

  done <<< "$import_lines"

  # 4. Public API 검증 (warning only)
  local slice=$(get_fsd_slice "$file")
  if [[ -n "$slice" ]]; then
    local slice_dir=$(dirname "$file")
    # 슬라이스 루트 디렉토리까지 올라감
    while [[ "$slice_dir" != "." ]] && [[ ! "$slice_dir" =~ /$layer/$slice$ ]]; do
      slice_dir=$(dirname "$slice_dir")
    done
    if [[ "$slice_dir" =~ /$layer/$slice$ ]]; then
      validate_fsd_public_api "$slice_dir"
    fi
  fi

  if [[ $has_errors -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# 배치 검증
# ============================================================================

# 디렉토리 내 모든 FSD 파일 검증
#
# Arguments:
#   $1 - 루트 디렉토리 (기본값: src)
# Returns:
#   0 if all files pass
#   1 if any file fails
validate_fsd_directory() {
  local root_dir="${1:-src}"

  if [[ ! -d "$root_dir" ]]; then
    echo "Directory not found: $root_dir"
    return 1
  fi

  local total_files=0
  local passed_files=0
  local failed_files=0

  echo "Validating FSD architecture in: $root_dir"
  echo ""

  # FSD 레이어별로 파일 검색 (Team Custom: app, pages, features, entities, shared)
  for layer in app pages features entities shared; do
    local layer_dir="${root_dir}/${layer}"
    if [[ ! -d "$layer_dir" ]]; then
      continue
    fi

    while IFS= read -r file; do
      if [[ -f "$file" ]]; then
        total_files=$((total_files + 1))

        if validate_fsd_file "$file"; then
          passed_files=$((passed_files + 1))
        else
          failed_files=$((failed_files + 1))
          echo ""
        fi
      fi
    done < <(find "$layer_dir" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) 2>/dev/null)
  done

  echo ""
  echo "=========================================="
  echo "FSD Validation Summary (Team Custom)"
  echo "=========================================="
  echo "Total files: $total_files"
  echo "Passed: $passed_files"
  echo "Failed: $failed_files"
  echo ""

  if [[ $failed_files -eq 0 ]]; then
    echo "✓ All FSD rules validated successfully"
    return 0
  else
    echo "✗ $failed_files file(s) failed FSD validation"
    return 1
  fi
}

# Note: This module is designed to be sourced by other scripts
# Functions can be called individually or use validate_fsd_directory for batch validation
# Based on FSD v2.1 + Team Domain-Centric Adaptations
