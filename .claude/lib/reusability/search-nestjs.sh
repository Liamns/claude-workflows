#!/bin/bash
# search-nestjs.sh
# NestJS 패턴 검색 스크립트
# Service, Controller, Prisma 모델 등 백엔드 패턴 검색
#
# Usage: search-nestjs.sh <query> [type]
#        type: all (default) | service | controller | prisma

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
# NestJS Service 검색
# ============================================================================

search_nestjs_service() {
  local query="$1"

  # 패턴: @Injectable() 데코레이터와 Service 클래스
  local pattern="(@Injectable|class.*${query}.*Service|export.*${query}.*Service)"

  # .ts 파일에서 검색
  grep -rn \
    --include="*.service.ts" \
    --include="*.ts" \
    --exclude-dir={node_modules,.git,dist,build} \
    -E "$pattern" \
    src/ 2>/dev/null || true
}

# ============================================================================
# NestJS Controller 검색
# ============================================================================

search_nestjs_controller() {
  local query="$1"

  # 패턴: @Controller() 데코레이터와 Controller 클래스
  local pattern="(@Controller|class.*${query}.*Controller|export.*${query}.*Controller)"

  # .ts 파일에서 검색
  grep -rn \
    --include="*.controller.ts" \
    --include="*.ts" \
    --exclude-dir={node_modules,.git,dist,build} \
    -E "$pattern" \
    src/ 2>/dev/null || true
}

# ============================================================================
# NestJS Module 검색
# ============================================================================

search_nestjs_module() {
  local query="$1"

  # 패턴: @Module() 데코레이터와 Module 클래스
  local pattern="(@Module|class.*${query}.*Module|export.*${query}.*Module)"

  # .ts 파일에서 검색
  grep -rn \
    --include="*.module.ts" \
    --include="*.ts" \
    --exclude-dir={node_modules,.git,dist,build} \
    -E "$pattern" \
    src/ 2>/dev/null || true
}

# ============================================================================
# NestJS Guard 검색
# ============================================================================

search_nestjs_guard() {
  local query="$1"

  # 패턴: @Injectable() + CanActivate 구현
  local pattern="(class.*${query}.*Guard|implements.*CanActivate|@UseGuards.*${query})"

  grep -rn \
    --include="*.guard.ts" \
    --include="*.ts" \
    --exclude-dir={node_modules,.git,dist,build} \
    -E "$pattern" \
    src/ 2>/dev/null || true
}

# ============================================================================
# NestJS Interceptor 검색
# ============================================================================

search_nestjs_interceptor() {
  local query="$1"

  # 패턴: NestInterceptor 구현
  local pattern="(class.*${query}.*Interceptor|implements.*NestInterceptor|@UseInterceptors.*${query})"

  grep -rn \
    --include="*.interceptor.ts" \
    --include="*.ts" \
    --exclude-dir={node_modules,.git,dist,build} \
    -E "$pattern" \
    src/ 2>/dev/null || true
}

# ============================================================================
# NestJS Decorator 검색
# ============================================================================

search_nestjs_decorator() {
  local query="$1"

  # 패턴: 커스텀 데코레이터
  local pattern="(export.*${query}|SetMetadata.*${query}|createParamDecorator.*${query})"

  grep -rn \
    --include="*.decorator.ts" \
    --include="*.ts" \
    --exclude-dir={node_modules,.git,dist,build} \
    -E "$pattern" \
    src/ 2>/dev/null || true
}

# ============================================================================
# Prisma Model 검색
# ============================================================================

search_prisma_model() {
  local query="$1"

  # schema.prisma 파일에서 모델 검색
  if [[ -f "prisma/schema.prisma" ]]; then
    # 패턴: model 선언
    grep -n -E "(model\s+${query}|model.*${query})" prisma/schema.prisma 2>/dev/null || true
  else
    log_warning "prisma/schema.prisma not found"
  fi
}

# ============================================================================
# Prisma Service 검색 (PrismaClient 사용)
# ============================================================================

search_prisma_service() {
  local query="$1"

  # 패턴: PrismaClient 사용 또는 prisma.${model} 접근
  local pattern="(prisma\.${query}|PrismaClient.*${query})"

  grep -rn \
    --include="*.ts" \
    --exclude-dir={node_modules,.git,dist,build} \
    -E "$pattern" \
    src/ 2>/dev/null || true
}

# ============================================================================
# DTO (Data Transfer Object) 검색
# ============================================================================

search_dto() {
  local query="$1"

  # 패턴: DTO 클래스 및 Validation 데코레이터
  local pattern="(class.*${query}.*Dto|@Is.*${query}|@ValidateNested.*${query})"

  grep -rn \
    --include="*.dto.ts" \
    --include="*.ts" \
    --exclude-dir={node_modules,.git,dist,build} \
    -E "$pattern" \
    src/ 2>/dev/null || true
}

# ============================================================================
# Entity 검색
# ============================================================================

search_entity() {
  local query="$1"

  # 패턴: TypeORM Entity
  local pattern="(@Entity|class.*${query}.*Entity|@Column.*${query})"

  grep -rn \
    --include="*.entity.ts" \
    --include="*.ts" \
    --exclude-dir={node_modules,.git,dist,build} \
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
    echo "Types: all, service, controller, module, guard, interceptor, decorator, prisma, dto, entity"
    exit 1
  fi

  # 타입별 검색
  case "$type" in
    service|services)
      search_nestjs_service "$query"
      ;;
    controller|controllers)
      search_nestjs_controller "$query"
      ;;
    module|modules)
      search_nestjs_module "$query"
      ;;
    guard|guards)
      search_nestjs_guard "$query"
      ;;
    interceptor|interceptors)
      search_nestjs_interceptor "$query"
      ;;
    decorator|decorators)
      search_nestjs_decorator "$query"
      ;;
    prisma|model|models)
      search_prisma_model "$query"
      ;;
    dto|dtos)
      search_dto "$query"
      ;;
    entity|entities)
      search_entity "$query"
      ;;
    all)
      echo "# NestJS Services:"
      search_nestjs_service "$query"
      echo ""

      echo "# NestJS Controllers:"
      search_nestjs_controller "$query"
      echo ""

      echo "# NestJS Modules:"
      search_nestjs_module "$query"
      echo ""

      echo "# NestJS Guards:"
      search_nestjs_guard "$query"
      echo ""

      echo "# NestJS Interceptors:"
      search_nestjs_interceptor "$query"
      echo ""

      echo "# NestJS Decorators:"
      search_nestjs_decorator "$query"
      echo ""

      echo "# Prisma Models:"
      search_prisma_model "$query"
      echo ""

      echo "# Prisma Service Usage:"
      search_prisma_service "$query"
      echo ""

      echo "# DTOs:"
      search_dto "$query"
      echo ""

      echo "# Entities:"
      search_entity "$query"
      ;;
    *)
      log_error "Unknown type: $type"
      echo "Valid types: all, service, controller, module, guard, interceptor, decorator, prisma, dto, entity"
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
