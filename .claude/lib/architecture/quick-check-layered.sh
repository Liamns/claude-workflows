#!/bin/bash
# quick-check-layered.sh
# Layered Architecture (N-Tier) Quick Check Rules
#
# Based on traditional Layered Architecture principles:
# - Clear layer separation
# - Unidirectional dependencies (top to bottom)
# - Each layer has specific responsibility
#
# Usage: bash quick-check-layered.sh [directory]

set -euo pipefail

# ============================================================================
# Layered Architecture 레이어 정의
# ============================================================================

# Get Layered Architecture layer (bash 3.2 compatible)
get_layered_layer() {
  local file="$1"

  # 레이어 패턴 매칭
  if [[ "$file" =~ presentation/ ]] || [[ "$file" =~ src/presentation/ ]]; then
    echo "presentation"
  elif [[ "$file" =~ business/ ]] || [[ "$file" =~ src/business/ ]]; then
    echo "business"
  elif [[ "$file" =~ data/ ]] || [[ "$file" =~ src/data/ ]]; then
    echo "data"
  elif [[ "$file" =~ common/ ]] || [[ "$file" =~ src/common/ ]]; then
    echo "common"
  else
    echo ""
  fi
}

# Get layer priority (lower number = lower layer, more stable)
get_layered_layer_priority() {
  local layer="$1"
  case "$layer" in
    "common") echo 1 ;;
    "data") echo 2 ;;
    "business") echo 3 ;;
    "presentation") echo 4 ;;
    *) echo -1 ;;
  esac
}

# ============================================================================
# 레이어 의존성 규칙
# ============================================================================

# Layered 의존성 규칙 검증
# Rule: Dependencies flow downward only
#   - presentation → business, common
#   - business → data, common
#   - data → common
#   - common → (none)
validate_layered_dependency_rule() {
  local source_file="$1"
  local import_path="$2"

  local source_layer=$(get_layered_layer "$source_file")
  local target_layer=$(get_layered_layer "$import_path")

  # Layered 구조가 아니면 스킵
  if [[ -z "$source_layer" || -z "$target_layer" ]]; then
    return 0
  fi

  # 동일 레이어 내 import는 허용
  if [[ "$source_layer" == "$target_layer" ]]; then
    return 0
  fi

  # common은 어디서든 import 가능 (cross-cutting concerns)
  if [[ "$target_layer" == "common" ]]; then
    return 0
  fi

  # 의존성 규칙 검증
  case "$source_layer" in
    "presentation")
      # Presentation은 business, common만 import 가능
      if [[ "$target_layer" != "business" ]]; then
        echo "❌ Layered dependency violation: presentation can only import business (or common)"
        echo "   Source: $source_file"
        echo "   Import: $import_path ($target_layer)"
        echo "   Rule: presentation → business, common only"
        return 1
      fi
      ;;

    "business")
      # Business는 data, common만 import 가능
      if [[ "$target_layer" != "data" ]]; then
        echo "❌ Layered dependency violation: business can only import data (or common)"
        echo "   Source: $source_file"
        echo "   Import: $import_path ($target_layer)"
        echo "   Rule: business → data, common only"
        return 1
      fi
      ;;

    "data")
      # Data는 common만 import 가능 (이미 위에서 체크)
      # data → business, presentation은 금지
      if [[ "$target_layer" == "business" ]] || [[ "$target_layer" == "presentation" ]]; then
        echo "❌ Layered dependency violation: data cannot import upper layers"
        echo "   Source: $source_file"
        echo "   Import: $import_path ($target_layer)"
        echo "   Rule: data → common only (no upward dependencies)"
        return 1
      fi
      ;;

    "common")
      # Common은 다른 레이어를 import 불가
      if [[ "$target_layer" != "common" ]]; then
        echo "❌ Layered dependency violation: common cannot import other layers"
        echo "   Source: $source_file"
        echo "   Import: $import_path ($target_layer)"
        echo "   Rule: common must be independent (cross-cutting concerns)"
        return 1
      fi
      ;;
  esac

  return 0
}

# ============================================================================
# Data Access Abstraction 규칙
# ============================================================================

# Data Access Abstraction 검증
# Rule: Business layer should not know about database details
validate_layered_data_abstraction() {
  local file="$1"
  local layer=$(get_layered_layer "$file")

  # business 레이어가 아니면 스킵
  if [[ "$layer" != "business" ]]; then
    return 0
  fi

  local has_errors=0

  # import 문 추출
  local import_lines=$(grep -E "^import |^from " "$file" 2>/dev/null || true)

  # Database-specific imports 체크
  local db_patterns=(
    "typeorm"
    "mongoose"
    "prisma"
    "sequelize"
    "mysql"
    "pg"
    "mongodb"
    "redis"
  )

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

    # Database library import 체크
    for db_pattern in "${db_patterns[@]}"; do
      if [[ "$import_path" =~ $db_pattern ]]; then
        echo "❌ Layered data abstraction violation: Business layer importing database library"
        echo "   File: $file"
        echo "   Import: $import_path"
        echo "   Rule: Business layer should use repository abstractions"
        has_errors=1
        break
      fi
    done

  done <<< "$import_lines"

  if [[ $has_errors -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Layer Responsibility 규칙
# ============================================================================

# Presentation 레이어 책임 검증
# Rule: Presentation handles HTTP only, no business logic
validate_layered_presentation_responsibility() {
  local file="$1"
  local layer=$(get_layered_layer "$file")

  # presentation 레이어가 아니면 스킵
  if [[ "$layer" != "presentation" ]]; then
    return 0
  fi

  # Controller/DTO가 아닌 파일에서 복잡한 로직 감지 (간단한 휴리스틱)
  # 너무 많은 if문 = 비즈니스 로직
  local if_count=$(grep -c "if (" "$file" 2>/dev/null || echo "0")
  if [[ $if_count -gt 3 ]]; then
    echo "⚠️  Layered presentation warning: Complex logic detected"
    echo "   File: $file"
    echo "   Count: $if_count if statements"
    echo "   Rule: Presentation should delegate to business layer"
    # Warning only
  fi

  # Direct database/ORM imports (이미 dependency rule에서 체크)
  return 0
}

# Business 레이어 책임 검증
# Rule: Business contains business logic, no HTTP/DB details
validate_layered_business_responsibility() {
  local file="$1"
  local layer=$(get_layered_layer "$file")

  # business 레이어가 아니면 스킵
  if [[ "$layer" != "business" ]]; then
    return 0
  fi

  # HTTP-specific imports (express, fastify 등)
  local http_patterns=(
    "express"
    "fastify"
    "koa"
    "@nestjs/common"
  )

  local import_lines=$(grep -E "^import |^from " "$file" 2>/dev/null || true)

  while IFS= read -r import_line; do
    if [[ -z "$import_line" ]]; then
      continue
    fi

    local import_path=""
    if [[ "$import_line" =~ from[[:space:]]+[\'\"](.*)[\'\"] ]] || [[ "$import_line" =~ import[[:space:]]+[\'\"](.*)[\'\"] ]]; then
      import_path="${BASH_REMATCH[1]}"
    else
      continue
    fi

    for http_pattern in "${http_patterns[@]}"; do
      if [[ "$import_path" =~ $http_pattern ]]; then
        echo "⚠️  Layered business warning: HTTP framework import detected"
        echo "   File: $file"
        echo "   Import: $import_path"
        echo "   Rule: Business layer should be framework-independent"
        # Warning only
        break
      fi
    done

  done <<< "$import_lines"

  return 0
}

# Data 레이어 책임 검증
# Rule: Data handles persistence only, no business logic
validate_layered_data_responsibility() {
  local file="$1"
  local layer=$(get_layered_layer "$file")

  # data 레이어가 아니면 스킵
  if [[ "$layer" != "data" ]]; then
    return 0
  fi

  # Repository/Entity가 아닌 곳에서 복잡한 비즈니스 로직 감지
  # Business rule patterns (간단한 휴리스틱)
  if grep -qE "business|workflow|orchestrat|validat.*business" "$file" 2>/dev/null; then
    echo "⚠️  Layered data warning: Business logic keywords detected"
    echo "   File: $file"
    echo "   Rule: Data layer should focus on persistence"
    # Warning only
  fi

  return 0
}

# ============================================================================
# 메인 검증 함수
# ============================================================================

# Layered Architecture 파일 검증 (모든 규칙 통합)
validate_layered_file() {
  local file="$1"

  # 파일 존재 확인
  if [[ ! -f "$file" ]]; then
    echo "File not found: $file"
    return 1
  fi

  # Layered 구조가 아니면 스킵
  local layer=$(get_layered_layer "$file")
  if [[ -z "$layer" ]]; then
    return 0
  fi

  local has_errors=0

  # 1. Data Access Abstraction 검증
  if ! validate_layered_data_abstraction "$file"; then
    has_errors=1
  fi

  # 2. Layer Responsibility 검증
  if ! validate_layered_presentation_responsibility "$file"; then
    # warnings only
    :
  fi

  if ! validate_layered_business_responsibility "$file"; then
    # warnings only
    :
  fi

  if ! validate_layered_data_responsibility "$file"; then
    # warnings only
    :
  fi

  # 3. import 문 추출 및 의존성 검증
  local import_lines=$(grep -E "^import |^from " "$file" 2>/dev/null || true)

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

    # 외부 패키지는 data abstraction에서 체크했으므로 스킵
    if [[ ! "$import_path" =~ ^\.\.?/ ]] && [[ ! "$import_path" =~ ^src/ ]] && [[ ! "$import_path" =~ ^@/ ]]; then
      continue
    fi

    # 상대 경로를 프로젝트 경로로 변환
    local resolved_import=""
    if [[ "$import_path" =~ ^@/ ]]; then
      resolved_import="${import_path#@/}"
      resolved_import="src/$resolved_import"
    elif [[ "$import_path" =~ ^\.\.?/ ]]; then
      local source_dir=$(dirname "$file")
      resolved_import="${source_dir}/${import_path}"
      if command -v realpath &> /dev/null; then
        resolved_import=$(realpath -m "$resolved_import" 2>/dev/null || echo "$resolved_import")
      fi
    else
      resolved_import="$import_path"
    fi

    # 의존성 규칙 검증
    if ! validate_layered_dependency_rule "$file" "$resolved_import"; then
      has_errors=1
    fi

  done <<< "$import_lines"

  if [[ $has_errors -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# 배치 검증
# ============================================================================

# 디렉토리 내 모든 Layered Architecture 파일 검증
validate_layered_directory() {
  local root_dir="${1:-src}"

  if [[ ! -d "$root_dir" ]]; then
    echo "Directory not found: $root_dir"
    return 1
  fi

  local total_files=0
  local passed_files=0
  local failed_files=0

  echo "Validating Layered Architecture (N-Tier) in: $root_dir"
  echo ""

  # Layered 구조별로 파일 검색
  for layer in presentation business data common; do
    local layer_dir="${root_dir}/${layer}"
    if [[ ! -d "$layer_dir" ]]; then
      continue
    fi

    while IFS= read -r file; do
      if [[ -f "$file" ]]; then
        total_files=$((total_files + 1))

        if validate_layered_file "$file"; then
          passed_files=$((passed_files + 1))
        else
          failed_files=$((failed_files + 1))
          echo ""
        fi
      fi
    done < <(find "$layer_dir" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.java" -o -name "*.cs" \) 2>/dev/null)
  done

  echo ""
  echo "=========================================="
  echo "Layered Architecture Validation Summary"
  echo "=========================================="
  echo "Total files: $total_files"
  echo "Passed: $passed_files"
  echo "Failed: $failed_files"
  echo ""

  if [[ $failed_files -eq 0 ]]; then
    echo "✓ All Layered Architecture rules validated successfully"
    return 0
  else
    echo "✗ $failed_files file(s) failed Layered Architecture validation"
    return 1
  fi
}

# Note: This module is designed to be sourced by other scripts
# Based on traditional Layered (N-Tier) Architecture principles
