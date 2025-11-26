#!/bin/bash
# quick-check-clean.sh
# Clean Architecture Quick Check Rules
#
# Based on Clean Architecture principles:
# - Dependency Rule: Dependencies point inward
# - Domain independence: Domain layer has no dependencies
# - Framework independence: Business logic doesn't depend on frameworks
#
# Usage: bash quick-check-clean.sh [directory]

set -euo pipefail

# ============================================================================
# Clean Architecture 레이어 정의
# ============================================================================

# Get Clean Architecture layer priority (bash 3.2 compatible)
# Lower number = inner layer (more stable)
get_clean_layer_priority() {
  local layer="$1"
  case "$layer" in
    "domain") echo 1 ;;
    "application") echo 2 ;;
    "infrastructure") echo 3 ;;
    "presentation") echo 3 ;;
    *) echo -1 ;;
  esac
}

# ============================================================================
# 유틸리티 함수
# ============================================================================

# 파일의 Clean Architecture 레이어 추출
get_clean_layer() {
  local file="$1"

  # src/ 또는 domain/, application/ 등으로 시작하는 경로 처리
  if [[ "$file" =~ (domain|application|infrastructure|presentation)/ ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ "$file" =~ src/(domain|application|infrastructure|presentation)/ ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo ""
  fi
}

# ============================================================================
# 레이어 의존성 규칙 (Dependency Rule)
# ============================================================================

# Clean Architecture 의존성 규칙 검증
# Rule: Dependencies point inward only
#   - domain: no dependencies
#   - application: domain only
#   - presentation: application only
#   - infrastructure: domain, application only
validate_clean_dependency_rule() {
  local source_file="$1"
  local import_path="$2"

  local source_layer=$(get_clean_layer "$source_file")
  local target_layer=$(get_clean_layer "$import_path")

  # Clean Architecture 구조가 아니면 스킵
  if [[ -z "$source_layer" || -z "$target_layer" ]]; then
    return 0
  fi

  # 동일 레이어 내 import는 허용
  if [[ "$source_layer" == "$target_layer" ]]; then
    return 0
  fi

  # 의존성 규칙 검증
  case "$source_layer" in
    "domain")
      # Domain은 어떤 레이어도 import 불가
      echo "❌ Clean dependency violation: domain cannot import from any layer"
      echo "   Source: $source_file"
      echo "   Import: $import_path"
      echo "   Rule: Domain layer must be independent (no external dependencies)"
      return 1
      ;;

    "application")
      # Application은 domain만 import 가능
      if [[ "$target_layer" != "domain" ]]; then
        echo "❌ Clean dependency violation: application can only import from domain"
        echo "   Source: $source_file"
        echo "   Import: $import_path ($target_layer)"
        echo "   Rule: Application → Domain only"
        return 1
      fi
      ;;

    "presentation")
      # Presentation은 application만 import 가능
      if [[ "$target_layer" != "application" ]]; then
        echo "❌ Clean dependency violation: presentation can only import from application"
        echo "   Source: $source_file"
        echo "   Import: $import_path ($target_layer)"
        echo "   Rule: Presentation → Application only"
        return 1
      fi
      ;;

    "infrastructure")
      # Infrastructure는 domain, application만 import 가능
      if [[ "$target_layer" != "domain" ]] && [[ "$target_layer" != "application" ]]; then
        echo "❌ Clean dependency violation: infrastructure can only import from domain/application"
        echo "   Source: $source_file"
        echo "   Import: $import_path ($target_layer)"
        echo "   Rule: Infrastructure → Domain/Application only"
        return 1
      fi
      ;;
  esac

  return 0
}

# ============================================================================
# Domain 순수성 규칙
# ============================================================================

# Framework/library blacklist for domain layer
is_framework_import() {
  local import_path="$1"

  # 프레임워크/라이브러리 패턴
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
    "redis"
    "mysql"
    "pg"
    "mongodb"
  )

  for pattern in "${framework_patterns[@]}"; do
    if [[ "$import_path" =~ $pattern ]]; then
      return 0
    fi
  done

  return 1
}

# Domain 순수성 검증
# Rules:
#   - NO framework dependencies
#   - NO external library dependencies
#   - Pure business logic only
validate_clean_domain_purity() {
  local file="$1"
  local layer=$(get_clean_layer "$file")

  # domain 레이어가 아니면 스킵
  if [[ "$layer" != "domain" ]]; then
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

    # 내부 import는 스킵 (상대 경로, @/ 경로)
    if [[ "$import_path" =~ ^\.\.?/ ]] || [[ "$import_path" =~ ^@/ ]] || [[ "$import_path" =~ ^src/ ]]; then
      continue
    fi

    # 프레임워크/라이브러리 import 체크
    if is_framework_import "$import_path"; then
      echo "❌ Clean domain purity violation: Framework dependency detected"
      echo "   File: $file"
      echo "   Import: $import_path"
      echo "   Rule: Domain layer must not depend on frameworks"
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
# Application 순수성 규칙
# ============================================================================

# Application 순수성 검증
# Rules:
#   - NO framework dependencies
#   - Orchestration logic only (UseCases)
validate_clean_application_purity() {
  local file="$1"
  local layer=$(get_clean_layer "$file")

  # application 레이어가 아니면 스킵
  if [[ "$layer" != "application" ]]; then
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

    # 내부 import는 스킵
    if [[ "$import_path" =~ ^\.\.?/ ]] || [[ "$import_path" =~ ^@/ ]] || [[ "$import_path" =~ ^src/ ]]; then
      continue
    fi

    # 프레임워크 import 체크
    if is_framework_import "$import_path"; then
      echo "❌ Clean application purity violation: Framework dependency detected"
      echo "   File: $file"
      echo "   Import: $import_path"
      echo "   Rule: Application layer must not depend on frameworks"
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
# Presentation 규칙
# ============================================================================

# Presentation 레이어 규칙 검증
# Rules:
#   - NO business logic
#   - HTTP handling only
#   - Must use DTOs/Mappers
validate_clean_presentation_rules() {
  local file="$1"
  local layer=$(get_clean_layer "$file")

  # presentation 레이어가 아니면 스킵
  if [[ "$layer" != "presentation" ]]; then
    return 0
  fi

  # Controllers/Presenters는 비즈니스 로직이 있으면 안됨
  # Warning: 복잡한 비즈니스 로직 패턴 감지 (간단한 휴리스틱)

  # 1. 큰 if-else 체인 감지 (5개 이상 if)
  local if_count=$(grep -c "if (" "$file" 2>/dev/null || echo "0")
  if [[ $if_count -gt 5 ]]; then
    echo "⚠️  Clean presentation warning: Too many conditionals detected"
    echo "   File: $file"
    echo "   Count: $if_count if statements"
    echo "   Rule: Presentation should delegate to application layer"
    # Warning only
  fi

  # 2. 직접 DB/API 호출 감지 (presentation은 application을 통해야 함)
  if grep -qE "SELECT |INSERT |UPDATE |DELETE |fetch\(|axios\." "$file" 2>/dev/null; then
    echo "⚠️  Clean presentation warning: Direct data access detected"
    echo "   File: $file"
    echo "   Rule: Presentation should use application layer use cases"
    # Warning only
  fi

  return 0
}

# ============================================================================
# Infrastructure 규칙
# ============================================================================

# Infrastructure 레이어 규칙 검증
# Rules:
#   - Must implement ports (interfaces from domain/application)
#   - Can have external dependencies
validate_clean_infrastructure_rules() {
  local file="$1"
  local layer=$(get_clean_layer "$file")

  # infrastructure 레이어가 아니면 스킵
  if [[ "$layer" != "infrastructure" ]]; then
    return 0
  fi

  # Repository 구현체는 domain의 repository interface를 구현해야 함
  # (TypeScript: implements, Python: class X(Interface), Java: implements)

  if [[ "$file" =~ repositories/ ]]; then
    # interface 구현 여부 체크 (간단한 패턴 매칭)
    if ! grep -qE "implements |extends |class.*\(" "$file" 2>/dev/null; then
      echo "⚠️  Clean infrastructure warning: Repository should implement interface"
      echo "   File: $file"
      echo "   Rule: Infrastructure implements ports from domain/application"
      # Warning only
    fi
  fi

  return 0
}

# ============================================================================
# Circular Dependency 감지
# ============================================================================

# 순환 의존성 감지 (간단한 버전)
detect_circular_dependencies() {
  local root_dir="${1:-src}"

  if [[ ! -d "$root_dir" ]]; then
    return 0
  fi

  # 간단한 휴리스틱: 같은 모듈 내에서 양방향 import 감지
  # 완전한 순환 감지는 복잡하므로 기본적인 패턴만 체크

  local has_circular=0

  # domain → application/infrastructure/presentation 체크
  if [[ -d "${root_dir}/domain" ]]; then
    while IFS= read -r file; do
      if [[ -f "$file" ]]; then
        if grep -qE "from .*(application|infrastructure|presentation)" "$file" 2>/dev/null; then
          echo "⚠️  Potential circular dependency: domain importing outer layer"
          echo "   File: $file"
          has_circular=1
        fi
      fi
    done < <(find "${root_dir}/domain" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.java" -o -name "*.go" \) 2>/dev/null)
  fi

  # application → infrastructure/presentation 체크
  if [[ -d "${root_dir}/application" ]]; then
    while IFS= read -r file; do
      if [[ -f "$file" ]]; then
        if grep -qE "from .*(infrastructure|presentation)" "$file" 2>/dev/null; then
          echo "⚠️  Potential circular dependency: application importing outer layer"
          echo "   File: $file"
          has_circular=1
        fi
      fi
    done < <(find "${root_dir}/application" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.java" -o -name "*.go" \) 2>/dev/null)
  fi

  if [[ $has_circular -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# 메인 검증 함수
# ============================================================================

# Clean Architecture 파일 검증 (모든 규칙 통합)
validate_clean_file() {
  local file="$1"

  # 파일 존재 확인
  if [[ ! -f "$file" ]]; then
    echo "File not found: $file"
    return 1
  fi

  # Clean Architecture 구조가 아니면 스킵
  local layer=$(get_clean_layer "$file")
  if [[ -z "$layer" ]]; then
    return 0
  fi

  local has_errors=0

  # 1. Domain 순수성 검증
  if ! validate_clean_domain_purity "$file"; then
    has_errors=1
  fi

  # 2. Application 순수성 검증
  if ! validate_clean_application_purity "$file"; then
    has_errors=1
  fi

  # 3. Presentation 규칙 검증
  if ! validate_clean_presentation_rules "$file"; then
    # warnings only
    :
  fi

  # 4. Infrastructure 규칙 검증
  if ! validate_clean_infrastructure_rules "$file"; then
    # warnings only
    :
  fi

  # 5. import 문 추출 및 의존성 검증
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

    # 외부 패키지는 domain/application purity에서 체크했으므로 스킵
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
      # realpath가 없으면 간단히 경로만 사용
      if command -v realpath &> /dev/null; then
        resolved_import=$(realpath -m "$resolved_import" 2>/dev/null || echo "$resolved_import")
      fi
    else
      # 절대 경로
      resolved_import="$import_path"
    fi

    # 의존성 규칙 검증
    if ! validate_clean_dependency_rule "$file" "$resolved_import"; then
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

# 디렉토리 내 모든 Clean Architecture 파일 검증
validate_clean_directory() {
  local root_dir="${1:-src}"

  if [[ ! -d "$root_dir" ]]; then
    echo "Directory not found: $root_dir"
    return 1
  fi

  local total_files=0
  local passed_files=0
  local failed_files=0

  echo "Validating Clean Architecture in: $root_dir"
  echo ""

  # Clean Architecture 레이어별로 파일 검색
  for layer in domain application infrastructure presentation; do
    local layer_dir="${root_dir}/${layer}"
    if [[ ! -d "$layer_dir" ]]; then
      continue
    fi

    while IFS= read -r file; do
      if [[ -f "$file" ]]; then
        total_files=$((total_files + 1))

        if validate_clean_file "$file"; then
          passed_files=$((passed_files + 1))
        else
          failed_files=$((failed_files + 1))
          echo ""
        fi
      fi
    done < <(find "$layer_dir" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.java" -o -name "*.go" \) 2>/dev/null)
  done

  echo ""
  echo "=========================================="
  echo "Clean Architecture Validation Summary"
  echo "=========================================="
  echo "Total files: $total_files"
  echo "Passed: $passed_files"
  echo "Failed: $failed_files"
  echo ""

  # 순환 의존성 체크
  echo "Checking for circular dependencies..."
  if detect_circular_dependencies "$root_dir"; then
    echo "✓ No circular dependencies detected"
  else
    echo "⚠️  Potential circular dependencies found"
  fi
  echo ""

  if [[ $failed_files -eq 0 ]]; then
    echo "✓ All Clean Architecture rules validated successfully"
    return 0
  else
    echo "✗ $failed_files file(s) failed Clean Architecture validation"
    return 1
  fi
}

# Note: This module is designed to be sourced by other scripts
# Based on Clean Architecture by Robert C. Martin (Uncle Bob)
