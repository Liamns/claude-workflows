#!/bin/bash
# quick-check-nestjs.sh
# NestJS Layered Architecture Quick Check Rules
#
# Based on NestJS best practices:
# - Module-based organization
# - Controller → Service → Repository pattern
# - Dependency injection through providers
# - Clear separation of concerns
#
# Usage: bash quick-check-nestjs.sh [directory]

set -euo pipefail

# ============================================================================
# NestJS 구조 정의
# ============================================================================

# Get NestJS component type (bash 3.2 compatible)
get_nestjs_component() {
  local file="$1"

  # Module files
  if [[ "$file" =~ \.module\.ts$ ]]; then
    echo "module"
  # Controller files
  elif [[ "$file" =~ \.controller\.ts$ ]]; then
    echo "controller"
  # Service files
  elif [[ "$file" =~ \.service\.ts$ ]]; then
    echo "service"
  # Repository files (TypeORM/Prisma)
  elif [[ "$file" =~ \.repository\.ts$ ]] || [[ "$file" =~ \.entity\.ts$ ]]; then
    echo "repository"
  # DTO files
  elif [[ "$file" =~ \.dto\.ts$ ]]; then
    echo "dto"
  # Guard/Middleware/Interceptor
  elif [[ "$file" =~ \.(guard|middleware|interceptor)\.ts$ ]]; then
    echo "infrastructure"
  else
    echo ""
  fi
}

# ============================================================================
# Module 구조 검증
# ============================================================================

# NestJS Module 구조 검증
# Rule: Each module should have module.ts, and typically controller.ts and service.ts
validate_nestjs_module_structure() {
  local file="$1"

  # .module.ts 파일이 아니면 스킵
  if [[ ! "$file" =~ \.module\.ts$ ]]; then
    return 0
  fi

  local dir=$(dirname "$file")
  local module_name=$(basename "$file" .module.ts)

  # Service 파일 확인 (권장사항, 경고만)
  if ! ls "$dir"/*.service.ts &> /dev/null; then
    echo "⚠️  NestJS module warning: Module without service"
    echo "   Module: $file"
    echo "   Recommendation: Modules should typically have a service"
    # Warning only
  fi

  return 0
}

# ============================================================================
# Controller 규칙
# ============================================================================

# Controller 의존성 검증
# Rule: Controllers should only inject Services, not Repositories directly
validate_nestjs_controller_deps() {
  local file="$1"

  # .controller.ts 파일이 아니면 스킵
  if [[ ! "$file" =~ \.controller\.ts$ ]]; then
    return 0
  fi

  local has_errors=0

  # @InjectRepository 직접 사용 체크
  if grep -q "@InjectRepository" "$file" 2>/dev/null; then
    echo "❌ NestJS controller violation: Direct repository injection"
    echo "   File: $file"
    echo "   Rule: Controllers should inject Services, not Repositories"
    echo "   Fix: Create a Service layer to handle data access"
    has_errors=1
  fi

  # TypeORM Repository 직접 import 체크
  if grep -qE "import.*Repository.*from.*typeorm" "$file" 2>/dev/null; then
    echo "⚠️  NestJS controller warning: TypeORM Repository import"
    echo "   File: $file"
    echo "   Recommendation: Use Service layer for data access"
    # Warning only
  fi

  # 비즈니스 로직 체크 (간단한 휴리스틱: 너무 많은 로직)
  local method_count=$(grep -c "async.*{" "$file" 2>/dev/null || echo "0")
  if [[ $method_count -gt 10 ]]; then
    echo "⚠️  NestJS controller warning: Too many methods ($method_count)"
    echo "   File: $file"
    echo "   Recommendation: Consider splitting into multiple controllers"
    # Warning only
  fi

  if [[ $has_errors -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Service 규칙
# ============================================================================

# Service 위치 검증
# Rule: Services should be in the same module directory
validate_nestjs_service_location() {
  local file="$1"

  # .service.ts 파일이 아니면 스킵
  if [[ ! "$file" =~ \.service\.ts$ ]]; then
    return 0
  fi

  local dir=$(dirname "$file")

  # 같은 디렉토리에 .module.ts 파일이 있는지 확인
  if ! ls "$dir"/*.module.ts &> /dev/null; then
    echo "⚠️  NestJS service warning: Orphan service (no module in same directory)"
    echo "   File: $file"
    echo "   Recommendation: Services should be co-located with their module"
    # Warning only
  fi

  return 0
}

# ============================================================================
# Provider 규칙
# ============================================================================

# Provider 등록 검증 (간단한 체크)
# Rule: Services should be decorated with @Injectable()
validate_nestjs_provider_decoration() {
  local file="$1"

  # .service.ts 파일이 아니면 스킵
  if [[ ! "$file" =~ \.service\.ts$ ]]; then
    return 0
  fi

  # @Injectable() 데코레이터 확인
  if ! grep -q "@Injectable()" "$file" 2>/dev/null; then
    echo "❌ NestJS provider violation: Missing @Injectable() decorator"
    echo "   File: $file"
    echo "   Rule: Services must be decorated with @Injectable()"
    return 1
  fi

  return 0
}

# ============================================================================
# DTO 규칙
# ============================================================================

# DTO 위치 검증
# Rule: DTOs should be in dto/ subdirectory or co-located with module
validate_nestjs_dto_location() {
  local file="$1"

  # .dto.ts 파일이 아니면 스킵
  if [[ ! "$file" =~ \.dto\.ts$ ]]; then
    return 0
  fi

  # dto/ 디렉토리 또는 dtos/ 디렉토리에 있는지 확인
  if [[ ! "$file" =~ /dto/ ]] && [[ ! "$file" =~ /dtos/ ]]; then
    # 모듈과 같은 디렉토리인지 확인
    local dir=$(dirname "$file")
    if ! ls "$dir"/*.module.ts &> /dev/null; then
      echo "⚠️  NestJS DTO warning: DTO not in dto/ directory or module directory"
      echo "   File: $file"
      echo "   Recommendation: Place DTOs in dto/ subdirectory or with module"
      # Warning only
    fi
  fi

  return 0
}

# ============================================================================
# 의존성 규칙
# ============================================================================

# NestJS 레이어 의존성 검증
# Rule: Controller → Service → Repository
validate_nestjs_dependency_rule() {
  local source_file="$1"
  local import_path="$2"

  local source_component=$(get_nestjs_component "$source_file")

  # NestJS 컴포넌트가 아니면 스킵
  if [[ -z "$source_component" ]]; then
    return 0
  fi

  # DTO는 어디서든 import 가능
  if [[ "$import_path" =~ \.dto\.ts$ ]]; then
    return 0
  fi

  # Controller에서 Repository 직접 import 금지
  if [[ "$source_component" == "controller" ]] && [[ "$import_path" =~ \.(repository|entity)\.ts$ ]]; then
    echo "❌ NestJS dependency violation: Controller importing Repository"
    echo "   Source: $source_file"
    echo "   Import: $import_path"
    echo "   Rule: Controller → Service → Repository (no direct repository access)"
    return 1
  fi

  return 0
}

# ============================================================================
# 메인 검증 함수
# ============================================================================

# NestJS 파일 검증 (모든 규칙 통합)
validate_nestjs_file() {
  local file="$1"

  # 파일 존재 확인
  if [[ ! -f "$file" ]]; then
    echo "File not found: $file"
    return 1
  fi

  # TypeScript 파일만 검증
  if [[ ! "$file" =~ \.ts$ ]]; then
    return 0
  fi

  # NestJS 구조가 아니면 스킵
  local component=$(get_nestjs_component "$file")
  if [[ -z "$component" ]] && [[ ! "$file" =~ /src/ ]]; then
    return 0
  fi

  local has_errors=0

  # 1. Module 구조 검증
  if ! validate_nestjs_module_structure "$file"; then
    # warnings only
    :
  fi

  # 2. Controller 규칙 검증
  if ! validate_nestjs_controller_deps "$file"; then
    has_errors=1
  fi

  # 3. Service 위치 검증
  if ! validate_nestjs_service_location "$file"; then
    # warnings only
    :
  fi

  # 4. Provider 데코레이터 검증
  if ! validate_nestjs_provider_decoration "$file"; then
    has_errors=1
  fi

  # 5. DTO 위치 검증
  if ! validate_nestjs_dto_location "$file"; then
    # warnings only
    :
  fi

  # 6. import 문 추출 및 의존성 검증
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

    # 외부 패키지는 스킵
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
    if ! validate_nestjs_dependency_rule "$file" "$resolved_import"; then
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

# 디렉토리 내 모든 NestJS 파일 검증
validate_nestjs_directory() {
  local root_dir="${1:-src}"

  if [[ ! -d "$root_dir" ]]; then
    echo "Directory not found: $root_dir"
    return 1
  fi

  local total_files=0
  local passed_files=0
  local failed_files=0

  echo "Validating NestJS Layered Architecture in: $root_dir"
  echo ""

  # TypeScript 파일 검색
  while IFS= read -r file; do
    if [[ -f "$file" ]]; then
      total_files=$((total_files + 1))

      if validate_nestjs_file "$file"; then
        passed_files=$((passed_files + 1))
      else
        failed_files=$((failed_files + 1))
        echo ""
      fi
    fi
  done < <(find "$root_dir" -type f -name "*.ts" 2>/dev/null)

  echo ""
  echo "=========================================="
  echo "NestJS Architecture Validation Summary"
  echo "=========================================="
  echo "Total files: $total_files"
  echo "Passed: $passed_files"
  echo "Failed: $failed_files"
  echo ""

  if [[ $failed_files -eq 0 ]]; then
    echo "✓ All NestJS architecture rules validated successfully"
    return 0
  else
    echo "✗ $failed_files file(s) failed NestJS architecture validation"
    return 1
  fi
}

# Note: This module is designed to be sourced by other scripts
# Based on NestJS best practices and layered architecture principles
