#!/bin/bash
# quick-check-ddd.sh
# Domain-Driven Design (DDD) Quick Check Rules
#
# Based on DDD principles by Eric Evans:
# - Strategic: Bounded Contexts, Ubiquitous Language, Context Maps
# - Tactical: Aggregates, Entities, Value Objects, Domain Events, etc.
#
# Usage: bash quick-check-ddd.sh [directory]

set -euo pipefail

# ============================================================================
# DDD 구조 정의
# ============================================================================

# Get DDD component type (bash 3.2 compatible)
get_ddd_component() {
  local file="$1"

  # Bounded Contexts
  if [[ "$file" =~ boundedContexts/([^/]+)/ ]]; then
    echo "boundedContext:${BASH_REMATCH[1]}"
    return
  fi

  # Domain layer
  if [[ "$file" =~ domain/aggregates/ ]]; then
    echo "domain/aggregates"
  elif [[ "$file" =~ domain/valueObjects/ ]]; then
    echo "domain/valueObjects"
  elif [[ "$file" =~ domain/events/ ]]; then
    echo "domain/events"
  elif [[ "$file" =~ domain/services/ ]]; then
    echo "domain/services"
  elif [[ "$file" =~ domain/ ]]; then
    echo "domain"
  # Application layer
  elif [[ "$file" =~ application/ ]]; then
    echo "application"
  # Infrastructure layer
  elif [[ "$file" =~ infrastructure/ ]]; then
    echo "infrastructure"
  # Interfaces layer
  elif [[ "$file" =~ interfaces/ ]]; then
    echo "interfaces"
  else
    echo ""
  fi
}

# Get bounded context name
get_bounded_context() {
  local file="$1"

  if [[ "$file" =~ boundedContexts/([^/]+)/ ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo ""
  fi
}

# ============================================================================
# Domain 순수성 규칙
# ============================================================================

# Framework/library blacklist for domain
is_framework_import() {
  local import_path="$1"

  local framework_patterns=(
    "express"
    "fastify"
    "koa"
    "axios"
    "node-fetch"
    "typeorm"
    "mongoose"
    "prisma"
    "sequelize"
  )

  for pattern in "${framework_patterns[@]}"; do
    if [[ "$import_path" =~ $pattern ]]; then
      return 0
    fi
  done

  return 1
}

# Domain 순수성 검증
# Rule: Domain must not depend on application, infrastructure, or interfaces
validate_ddd_domain_purity() {
  local file="$1"
  local component=$(get_ddd_component "$file")

  # domain이 아니면 스킵
  if [[ ! "$component" =~ ^domain ]]; then
    return 0
  fi

  local has_errors=0

  # import 문 추출
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

    # application, infrastructure, interfaces import 금지
    if [[ "$import_path" =~ (application|infrastructure|interfaces)/ ]]; then
      echo "❌ DDD domain purity violation: Domain importing outer layer"
      echo "   File: $file"
      echo "   Import: $import_path"
      echo "   Rule: Domain must be independent (no application/infrastructure/interfaces)"
      has_errors=1
      continue
    fi

    # 프레임워크 import 금지
    if [[ ! "$import_path" =~ ^\.\.?/ ]] && [[ ! "$import_path" =~ ^src/ ]] && [[ ! "$import_path" =~ ^@/ ]]; then
      if is_framework_import "$import_path"; then
        echo "❌ DDD domain purity violation: Framework dependency"
        echo "   File: $file"
        echo "   Import: $import_path"
        echo "   Rule: Domain must not depend on frameworks"
        has_errors=1
      fi
    fi

  done <<< "$import_lines"

  if [[ $has_errors -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Bounded Context 자율성 규칙
# ============================================================================

# Bounded Context 자율성 검증
# Rule: Bounded contexts must not directly depend on each other
validate_ddd_bounded_context_autonomy() {
  local file="$1"
  local source_context=$(get_bounded_context "$file")

  # Bounded Context가 아니면 스킵
  if [[ -z "$source_context" ]]; then
    return 0
  fi

  local has_errors=0

  # import 문 추출
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

    # 다른 Bounded Context import 체크
    if [[ "$import_path" =~ boundedContexts/([^/]+)/ ]]; then
      local target_context="${BASH_REMATCH[1]}"

      if [[ "$source_context" != "$target_context" ]]; then
        echo "⚠️  DDD bounded context coupling: Direct dependency between contexts"
        echo "   Source: $file ($source_context)"
        echo "   Import: $import_path ($target_context)"
        echo "   Rule: Use Anticorruption Layer or Shared Kernel pattern"
        echo "   Suggestion: Communicate via events, APIs, or shared interfaces"
        has_errors=1
      fi
    fi

  done <<< "$import_lines"

  if [[ $has_errors -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Value Object 불변성 규칙
# ============================================================================

# Value Object 불변성 검증
# Rule: Value Objects must be immutable
validate_ddd_value_object_immutability() {
  local file="$1"
  local component=$(get_ddd_component "$file")

  # value object가 아니면 스킵
  if [[ "$component" != "domain/valueObjects" ]]; then
    return 0
  fi

  local has_warnings=0

  # Setter 메서드 체크 (간단한 패턴)
  if grep -qE "set[A-Z][a-zA-Z]*\s*\(" "$file" 2>/dev/null; then
    echo "⚠️  DDD value object warning: Setter method detected"
    echo "   File: $file"
    echo "   Rule: Value Objects should be immutable (no setters)"
    has_warnings=1
  fi

  # 비 private 필드 변경 체크 (this.field = 패턴)
  if grep -qE "this\.[a-zA-Z_][a-zA-Z0-9_]*\s*=" "$file" 2>/dev/null; then
    echo "⚠️  DDD value object warning: Field mutation detected"
    echo "   File: $file"
    echo "   Rule: Value Objects should be immutable (no field mutations)"
    echo "   Suggestion: Use readonly properties or private fields"
    has_warnings=1
  fi

  # Warning only (false positives 가능)
  return 0
}

# ============================================================================
# Domain Event 명명 규칙
# ============================================================================

# Domain Event 명명 규칙 검증
# Rule: Domain Events should be named in past tense
validate_ddd_domain_event_naming() {
  local file="$1"
  local component=$(get_ddd_component "$file")

  # domain event가 아니면 스킵
  if [[ "$component" != "domain/events" ]]; then
    return 0
  fi

  local filename=$(basename "$file")

  # Event 파일명은 과거형으로 끝나야 함
  # Common past tense endings: -ed, -Created, -Updated, -Deleted, -Sent, -Received, etc.
  if [[ ! "$filename" =~ (ed|Created|Updated|Deleted|Placed|Sent|Received|Cancelled|Completed|Started|Finished)Event\. ]]; then
    echo "⚠️  DDD domain event naming warning: Event should be in past tense"
    echo "   File: $file"
    echo "   Rule: Domain Events represent something that happened"
    echo "   Examples: OrderPlacedEvent, PaymentReceivedEvent, ShipmentCompletedEvent"
    # Warning only
  fi

  return 0
}

# ============================================================================
# Aggregate 규칙
# ============================================================================

# Aggregate 규칙 검증
# Rule: Access entities only through aggregate root
validate_ddd_aggregate_rules() {
  local file="$1"
  local component=$(get_ddd_component "$file")

  # aggregate가 아니면 스킵
  if [[ "$component" != "domain/aggregates" ]]; then
    return 0
  fi

  # Aggregate Root는 identifier를 가져야 함
  if ! grep -qE "(id|getId|identifier)" "$file" 2>/dev/null; then
    echo "⚠️  DDD aggregate warning: Aggregate root should have identifier"
    echo "   File: $file"
    echo "   Rule: Aggregates must have unique identity"
    # Warning only
  fi

  return 0
}

# ============================================================================
# Repository 규칙
# ============================================================================

# Repository 규칙 검증
# Rule: One repository per aggregate
validate_ddd_repository_rules() {
  local file="$1"

  # Repository 파일이 아니면 스킵
  if [[ ! "$file" =~ [Rr]epository ]]; then
    return 0
  fi

  local component=$(get_ddd_component "$file")

  # Repository는 infrastructure 또는 domain에 있어야 함
  if [[ "$component" != "infrastructure" ]] && [[ "$component" != "domain" ]]; then
    echo "⚠️  DDD repository warning: Repository in unexpected location"
    echo "   File: $file"
    echo "   Rule: Repositories should be in domain (interface) or infrastructure (implementation)"
    # Warning only
  fi

  # Repository 인터페이스는 domain에, 구현은 infrastructure에
  if [[ "$component" == "domain" ]]; then
    # 인터페이스 체크 (interface, abstract 키워드)
    if ! grep -qE "interface |abstract class" "$file" 2>/dev/null; then
      echo "⚠️  DDD repository warning: Domain repository should be interface/abstract"
      echo "   File: $file"
      echo "   Rule: Repository interfaces in domain, implementations in infrastructure"
      # Warning only
    fi
  fi

  return 0
}

# ============================================================================
# 의존성 규칙
# ============================================================================

# DDD 의존성 규칙 검증
validate_ddd_dependency_rule() {
  local source_file="$1"
  local import_path="$2"

  local source_component=$(get_ddd_component "$source_file")
  local target_component=$(get_ddd_component "$import_path")

  # DDD 구조가 아니면 스킵
  if [[ -z "$source_component" || -z "$target_component" ]]; then
    return 0
  fi

  # 동일 컴포넌트 내 import는 허용
  if [[ "$source_component" == "$target_component" ]]; then
    return 0
  fi

  # 의존성 규칙 검증
  case "$source_component" in
    domain*)
      # Domain은 외부 의존 금지 (이미 domain_purity에서 체크)
      return 0
      ;;

    "application")
      # Application은 domain, infrastructure만 import 가능
      if [[ ! "$target_component" =~ ^domain ]] && [[ "$target_component" != "infrastructure" ]]; then
        echo "❌ DDD dependency violation: application can only import domain/infrastructure"
        echo "   Source: $source_file"
        echo "   Import: $import_path ($target_component)"
        echo "   Rule: application → domain, infrastructure only"
        return 1
      fi
      ;;

    "infrastructure")
      # Infrastructure는 domain만 import 가능
      if [[ ! "$target_component" =~ ^domain ]]; then
        echo "❌ DDD dependency violation: infrastructure can only import domain"
        echo "   Source: $source_file"
        echo "   Import: $import_path ($target_component)"
        echo "   Rule: infrastructure → domain only"
        return 1
      fi
      ;;

    "interfaces")
      # Interfaces는 application, domain import 가능
      if [[ ! "$target_component" =~ ^domain ]] && [[ "$target_component" != "application" ]]; then
        echo "❌ DDD dependency violation: interfaces can only import application/domain"
        echo "   Source: $source_file"
        echo "   Import: $import_path ($target_component)"
        echo "   Rule: interfaces → application, domain only"
        return 1
      fi
      ;;
  esac

  return 0
}

# ============================================================================
# 메인 검증 함수
# ============================================================================

# DDD 파일 검증 (모든 규칙 통합)
validate_ddd_file() {
  local file="$1"

  # 파일 존재 확인
  if [[ ! -f "$file" ]]; then
    echo "File not found: $file"
    return 1
  fi

  # DDD 구조가 아니면 스킵
  local component=$(get_ddd_component "$file")
  if [[ -z "$component" ]]; then
    return 0
  fi

  local has_errors=0

  # 1. Domain 순수성 검증
  if ! validate_ddd_domain_purity "$file"; then
    has_errors=1
  fi

  # 2. Bounded Context 자율성 검증
  if ! validate_ddd_bounded_context_autonomy "$file"; then
    has_errors=1
  fi

  # 3. Value Object 불변성 검증
  if ! validate_ddd_value_object_immutability "$file"; then
    # warnings only
    :
  fi

  # 4. Domain Event 명명 규칙 검증
  if ! validate_ddd_domain_event_naming "$file"; then
    # warnings only
    :
  fi

  # 5. Aggregate 규칙 검증
  if ! validate_ddd_aggregate_rules "$file"; then
    # warnings only
    :
  fi

  # 6. Repository 규칙 검증
  if ! validate_ddd_repository_rules "$file"; then
    # warnings only
    :
  fi

  # 7. import 문 추출 및 의존성 검증
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

    # 외부 패키지는 domain purity에서 체크했으므로 스킵
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
    if ! validate_ddd_dependency_rule "$file" "$resolved_import"; then
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

# 디렉토리 내 모든 DDD 파일 검증
validate_ddd_directory() {
  local root_dir="${1:-src}"

  if [[ ! -d "$root_dir" ]]; then
    echo "Directory not found: $root_dir"
    return 1
  fi

  local total_files=0
  local passed_files=0
  local failed_files=0

  echo "Validating Domain-Driven Design (DDD) in: $root_dir"
  echo ""

  # DDD 구조별로 파일 검색
  for component in boundedContexts domain/aggregates domain/valueObjects domain/events domain/services domain application infrastructure interfaces; do
    local component_dir="${root_dir}/${component}"

    # Bounded Contexts는 하위 디렉토리 탐색
    if [[ "$component" == "boundedContexts" ]] && [[ -d "$component_dir" ]]; then
      for context_dir in "$component_dir"/*; do
        if [[ -d "$context_dir" ]]; then
          while IFS= read -r file; do
            if [[ -f "$file" ]]; then
              total_files=$((total_files + 1))

              if validate_ddd_file "$file"; then
                passed_files=$((passed_files + 1))
              else
                failed_files=$((failed_files + 1))
                echo ""
              fi
            fi
          done < <(find "$context_dir" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.java" -o -name "*.cs" \) 2>/dev/null)
        fi
      done
    elif [[ -d "$component_dir" ]]; then
      while IFS= read -r file; do
        if [[ -f "$file" ]]; then
          total_files=$((total_files + 1))

          if validate_ddd_file "$file"; then
            passed_files=$((passed_files + 1))
          else
            failed_files=$((failed_files + 1))
            echo ""
          fi
        fi
      done < <(find "$component_dir" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.java" -o -name "*.cs" \) 2>/dev/null)
    fi
  done

  echo ""
  echo "=========================================="
  echo "DDD Validation Summary"
  echo "=========================================="
  echo "Total files: $total_files"
  echo "Passed: $passed_files"
  echo "Failed: $failed_files"
  echo ""

  if [[ $failed_files -eq 0 ]]; then
    echo "✓ All DDD rules validated successfully"
    return 0
  else
    echo "✗ $failed_files file(s) failed DDD validation"
    return 1
  fi
}

# Note: This module is designed to be sourced by other scripts
# Based on Domain-Driven Design by Eric Evans
