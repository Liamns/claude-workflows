#!/bin/bash
# quick-check-express.sh
# Express MVC Architecture Quick Check Rules
#
# Based on Express.js MVC best practices:
# - Clear separation of Routes, Controllers, Services, Models
# - Middleware organization
# - Router/Controller separation
# - Model/Service layer distinction
#
# Usage: bash quick-check-express.sh [directory]

set -euo pipefail

# ============================================================================
# Express MVC 구조 정의
# ============================================================================

# Get Express MVC component type (bash 3.2 compatible)
get_express_component() {
  local file="$1"

  # Routes
  if [[ "$file" =~ /routes?/ ]] || [[ "$file" =~ src/routes?/ ]]; then
    echo "route"
  # Controllers
  elif [[ "$file" =~ /controllers?/ ]] || [[ "$file" =~ src/controllers?/ ]]; then
    echo "controller"
  # Services
  elif [[ "$file" =~ /services?/ ]] || [[ "$file" =~ src/services?/ ]]; then
    echo "service"
  # Models
  elif [[ "$file" =~ /models?/ ]] || [[ "$file" =~ src/models?/ ]]; then
    echo "model"
  # Middleware
  elif [[ "$file" =~ /middlewares?/ ]] || [[ "$file" =~ src/middlewares?/ ]]; then
    echo "middleware"
  # Utils/Helpers
  elif [[ "$file" =~ /utils?/ ]] || [[ "$file" =~ /helpers?/ ]]; then
    echo "util"
  else
    echo ""
  fi
}

# ============================================================================
# Router/Controller 분리 규칙
# ============================================================================

# Router 순수성 검증
# Rule: Routes should only define routing, not business logic
validate_express_router_purity() {
  local file="$1"

  # route 파일이 아니면 스킵
  local component=$(get_express_component "$file")
  if [[ "$component" != "route" ]]; then
    return 0
  fi

  local has_errors=0

  # async 함수 정의 체크 (routes 내 비즈니스 로직)
  if grep -qE "async\s*\(" "$file" 2>/dev/null; then
    echo "⚠️  Express router warning: Async function definition in route"
    echo "   File: $file"
    echo "   Recommendation: Move business logic to controller"
    # Warning only
  fi

  # 복잡한 로직 체크 (if/for/while 문이 많음)
  local logic_count=$(grep -cE "^\s*(if|for|while|switch)\s*\(" "$file" 2>/dev/null || echo "0")
  if [[ $logic_count -gt 2 ]]; then
    echo "⚠️  Express router warning: Complex logic in route file ($logic_count statements)"
    echo "   File: $file"
    echo "   Recommendation: Routes should delegate to controllers"
    # Warning only
  fi

  # Database query 직접 사용 체크
  local db_patterns=(
    "\.find\("
    "\.findOne\("
    "\.create\("
    "\.update\("
    "\.delete\("
    "\.query\("
    "\.exec\("
  )

  for pattern in "${db_patterns[@]}"; do
    if grep -qE "$pattern" "$file" 2>/dev/null; then
      echo "❌ Express router violation: Database query in route"
      echo "   File: $file"
      echo "   Pattern: $pattern"
      echo "   Rule: Routes should not contain database logic"
      has_errors=1
      break
    fi
  done

  if [[ $has_errors -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Controller 규칙
# ============================================================================

# Controller 책임 검증
# Rule: Controllers handle HTTP, delegate to services
validate_express_controller_responsibility() {
  local file="$1"

  # controller 파일이 아니면 스킵
  local component=$(get_express_component "$file")
  if [[ "$component" != "controller" ]]; then
    return 0
  fi

  local has_errors=0

  # req, res 파라미터 체크 (Controller는 Express request/response 사용)
  if ! grep -qE "(req|request).*(res|response)" "$file" 2>/dev/null; then
    echo "⚠️  Express controller warning: No req/res parameters found"
    echo "   File: $file"
    echo "   Note: Controllers typically handle Express req/res objects"
    # Warning only
  fi

  # 직접 Database model import 체크
  local db_imports=(
    "from.*models/"
    "require.*models/"
    "from.*prisma"
    "from.*typeorm"
    "from.*mongoose"
  )

  for pattern in "${db_imports[@]}"; do
    if grep -qE "$pattern" "$file" 2>/dev/null; then
      echo "⚠️  Express controller warning: Direct model/ORM import"
      echo "   File: $file"
      echo "   Pattern: $pattern"
      echo "   Recommendation: Use service layer for data access"
      # Warning only (일부 경우 허용 가능)
      break
    fi
  done

  if [[ $has_errors -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Service 레이어 규칙
# ============================================================================

# Service 순수성 검증
# Rule: Services contain business logic, no HTTP concerns
validate_express_service_purity() {
  local file="$1"

  # service 파일이 아니면 스킵
  local component=$(get_express_component "$file")
  if [[ "$component" != "service" ]]; then
    return 0
  fi

  local has_warnings=0

  # Express-specific imports 체크
  local express_patterns=(
    "from.*express"
    "require.*express"
  )

  for pattern in "${express_patterns[@]}"; do
    if grep -qE "$pattern" "$file" 2>/dev/null; then
      # Request/Response type만 import하는 경우는 제외
      if ! grep -qE "import.*\{.*Request.*Response.*\}" "$file" 2>/dev/null; then
        echo "⚠️  Express service warning: Express framework import"
        echo "   File: $file"
        echo "   Rule: Services should be framework-independent"
        has_warnings=1
        break
      fi
    fi
  done

  # HTTP status code 하드코딩 체크 (Service는 HTTP 레이어와 분리되어야 함)
  if grep -qE "\b(200|201|400|401|403|404|500)\b" "$file" 2>/dev/null; then
    echo "⚠️  Express service warning: HTTP status code found"
    echo "   File: $file"
    echo "   Recommendation: Services should throw errors, controllers handle HTTP status"
    # Warning only
  fi

  # Warning only
  return 0
}

# ============================================================================
# Model 규칙
# ============================================================================

# Model 위치 검증
# Rule: Models should be in models/ directory
validate_express_model_location() {
  local file="$1"

  # .model.ts/js 파일인지 확인
  if [[ ! "$file" =~ \.(model|schema)\.(ts|js)$ ]]; then
    return 0
  fi

  # models/ 또는 model/ 디렉토리에 있는지 확인
  if [[ ! "$file" =~ /models?/ ]]; then
    echo "⚠️  Express model warning: Model not in models/ directory"
    echo "   File: $file"
    echo "   Recommendation: Place models in models/ directory"
    # Warning only
  fi

  return 0
}

# ============================================================================
# Middleware 규칙
# ============================================================================

# Middleware 위치 검증
# Rule: Middlewares should be in middlewares/ directory
validate_express_middleware_location() {
  local file="$1"

  # middleware 관련 파일인지 확인
  if [[ ! "$file" =~ middleware ]]; then
    return 0
  fi

  # middlewares/ 또는 middleware/ 디렉토리에 있는지 확인
  if [[ ! "$file" =~ /middlewares?/ ]]; then
    echo "❌ Express middleware violation: Middleware not in middlewares/ directory"
    echo "   File: $file"
    echo "   Rule: Middlewares must be in middlewares/ directory"
    return 1
  fi

  return 0
}

# Middleware 시그니처 검증
# Rule: Middlewares should have (req, res, next) signature
validate_express_middleware_signature() {
  local file="$1"

  # middleware 파일이 아니면 스킵
  local component=$(get_express_component "$file")
  if [[ "$component" != "middleware" ]]; then
    return 0
  fi

  # (req, res, next) 시그니처 체크
  if ! grep -qE "\(.*req.*res.*next.*\)" "$file" 2>/dev/null; then
    echo "⚠️  Express middleware warning: No (req, res, next) signature found"
    echo "   File: $file"
    echo "   Note: Middlewares typically use (req, res, next) signature"
    # Warning only
  fi

  return 0
}

# ============================================================================
# 의존성 규칙
# ============================================================================

# Express MVC 레이어 의존성 검증
# Rule: Route → Controller → Service → Model
validate_express_dependency_rule() {
  local source_file="$1"
  local import_path="$2"

  local source_component=$(get_express_component "$source_file")
  local target_component=$(get_express_component "$import_path")

  # Express 구조가 아니면 스킵
  if [[ -z "$source_component" || -z "$target_component" ]]; then
    return 0
  fi

  # 동일 컴포넌트 내 import는 허용
  if [[ "$source_component" == "$target_component" ]]; then
    return 0
  fi

  # 의존성 규칙 검증
  case "$source_component" in
    "route")
      # Routes는 controller, middleware만 import 가능
      if [[ "$target_component" != "controller" ]] && [[ "$target_component" != "middleware" ]]; then
        echo "❌ Express dependency violation: Route can only import controller/middleware"
        echo "   Source: $source_file"
        echo "   Import: $import_path ($target_component)"
        echo "   Rule: Route → Controller/Middleware only"
        return 1
      fi
      ;;

    "controller")
      # Controllers는 service, middleware만 import 가능 (model 직접 사용 지양)
      if [[ "$target_component" == "route" ]]; then
        echo "❌ Express dependency violation: Controller cannot import route"
        echo "   Source: $source_file"
        echo "   Import: $import_path"
        echo "   Rule: Controller → Service/Middleware (no upward dependencies)"
        return 1
      fi
      ;;

    "service")
      # Services는 model, util만 import 가능
      if [[ "$target_component" == "route" ]] || [[ "$target_component" == "controller" ]]; then
        echo "❌ Express dependency violation: Service cannot import route/controller"
        echo "   Source: $source_file"
        echo "   Import: $import_path ($target_component)"
        echo "   Rule: Service → Model/Util only (no upward dependencies)"
        return 1
      fi
      ;;

    "model")
      # Models는 다른 레이어를 import 불가 (util은 허용)
      if [[ "$target_component" == "route" ]] || [[ "$target_component" == "controller" ]] || [[ "$target_component" == "service" ]]; then
        echo "❌ Express dependency violation: Model cannot import upper layers"
        echo "   Source: $source_file"
        echo "   Import: $import_path ($target_component)"
        echo "   Rule: Model must be independent (no business/presentation layer dependencies)"
        return 1
      fi
      ;;
  esac

  return 0
}

# ============================================================================
# 메인 검증 함수
# ============================================================================

# Express MVC 파일 검증 (모든 규칙 통합)
validate_express_file() {
  local file="$1"

  # 파일 존재 확인
  if [[ ! -f "$file" ]]; then
    echo "File not found: $file"
    return 1
  fi

  # JavaScript/TypeScript 파일만 검증
  if [[ ! "$file" =~ \.(js|ts)$ ]]; then
    return 0
  fi

  # Express 구조가 아니면 스킵
  local component=$(get_express_component "$file")
  if [[ -z "$component" ]] && [[ ! "$file" =~ /src/ ]]; then
    return 0
  fi

  local has_errors=0

  # 1. Router 순수성 검증
  if ! validate_express_router_purity "$file"; then
    has_errors=1
  fi

  # 2. Controller 책임 검증
  if ! validate_express_controller_responsibility "$file"; then
    # warnings only
    :
  fi

  # 3. Service 순수성 검증
  if ! validate_express_service_purity "$file"; then
    # warnings only
    :
  fi

  # 4. Model 위치 검증
  if ! validate_express_model_location "$file"; then
    # warnings only
    :
  fi

  # 5. Middleware 위치 검증
  if ! validate_express_middleware_location "$file"; then
    has_errors=1
  fi

  # 6. Middleware 시그니처 검증
  if ! validate_express_middleware_signature "$file"; then
    # warnings only
    :
  fi

  # 7. import 문 추출 및 의존성 검증
  local import_lines=$(grep -E "^import |^from |^const.*=.*require\(" "$file" 2>/dev/null || true)

  while IFS= read -r import_line; do
    if [[ -z "$import_line" ]]; then
      continue
    fi

    # import 경로 추출
    local import_path=""
    if [[ "$import_line" =~ from[[:space:]]+[\'\"](.*)[\'\"] ]] || \
         [[ "$import_line" =~ import[[:space:]]+[\'\"](.*)[\'\"] ]] || \
         [[ "$import_line" =~ require\([\'\"](.*)[\'\"] ]]; then
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
    if ! validate_express_dependency_rule "$file" "$resolved_import"; then
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

# 디렉토리 내 모든 Express MVC 파일 검증
validate_express_directory() {
  local root_dir="${1:-src}"

  if [[ ! -d "$root_dir" ]]; then
    echo "Directory not found: $root_dir"
    return 1
  fi

  local total_files=0
  local passed_files=0
  local failed_files=0

  echo "Validating Express MVC Architecture in: $root_dir"
  echo ""

  # JavaScript/TypeScript 파일 검색
  while IFS= read -r file; do
    if [[ -f "$file" ]]; then
      total_files=$((total_files + 1))

      if validate_express_file "$file"; then
        passed_files=$((passed_files + 1))
      else
        failed_files=$((failed_files + 1))
        echo ""
      fi
    fi
  done < <(find "$root_dir" -type f \( -name "*.js" -o -name "*.ts" \) 2>/dev/null)

  echo ""
  echo "=========================================="
  echo "Express MVC Architecture Validation Summary"
  echo "=========================================="
  echo "Total files: $total_files"
  echo "Passed: $passed_files"
  echo "Failed: $failed_files"
  echo ""

  if [[ $failed_files -eq 0 ]]; then
    echo "✓ All Express MVC architecture rules validated successfully"
    return 0
  else
    echo "✗ $failed_files file(s) failed Express MVC architecture validation"
    return 1
  fi
}

# Note: This module is designed to be sourced by other scripts
# Based on Express.js MVC best practices
