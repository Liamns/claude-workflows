#!/bin/bash
# NestJS 서비스, 컨트롤러, DTO, Prisma Client 검색

# Architecture detection 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/detect-architecture.sh"

# 백엔드 경로 자동 감지 (환경 변수가 없을 때만)
if [ -z "${BACKEND_PATH:-}" ]; then
    BACKEND_PATH=$(detect_backend_path 2>/dev/null)
    export BACKEND_PATH
fi

search_nestjs_services() {
    local pattern="$1"
    echo "🔍 Searching NestJS Services in $BACKEND_PATH..."

    # Find service files once and cache
    local service_files
    service_files=$(find "$BACKEND_PATH" -name "*.service.ts" -type f)

    # @Injectable 데코레이터가 있는 서비스
    echo "$service_files" | xargs grep -l "@Injectable()" 2>/dev/null \
        | xargs grep -l "${pattern}" 2>/dev/null | head -20

    # 서비스 메서드
    grep -r "async.*${pattern}" "$BACKEND_PATH" \
        --include="*.service.ts" \
        -n 2>/dev/null | head -20
}

search_nestjs_controllers() {
    local pattern="$1"
    echo "🔍 Searching NestJS Controllers in $BACKEND_PATH..."

    # Find controller files once and cache
    local controller_files
    controller_files=$(find "$BACKEND_PATH" -name "*.controller.ts" -type f)

    # @Controller 데코레이터
    echo "$controller_files" | xargs grep -l "@Controller(" 2>/dev/null \
        | xargs grep -l "${pattern}" 2>/dev/null | head -20

    # 엔드포인트 메서드
    grep -r "@(Get|Post|Put|Delete|Patch)(" "$BACKEND_PATH" \
        --include="*.controller.ts" \
        -A 2 | grep "${pattern}" 2>/dev/null | head -20
}

search_nestjs_dtos() {
    local pattern="$1"
    echo "🔍 Searching NestJS DTOs in $BACKEND_PATH..."

    # DTO 파일
    find "$BACKEND_PATH" -name "*${pattern}*.dto.ts" -type f 2>/dev/null

    # class-validator 데코레이터가 있는 DTO
    grep -r "@Is(String|Number|Email|Optional|Array)" "$BACKEND_PATH" \
        --include="*.dto.ts" \
        -B 3 | grep "class.*${pattern}" 2>/dev/null | head -20
}

search_nestjs_prisma() {
    local pattern="$1"
    echo "🔍 Searching Prisma Models and Client Usage..."

    # Prisma Schema (model definitions)
    local prisma_schema=$(find . -name "schema.prisma" -type f | head -1)
    if [ -n "$prisma_schema" ]; then
        echo "📄 Prisma Schema: $prisma_schema"
        grep "^model " "$prisma_schema" | grep -i "${pattern}" 2>/dev/null
    fi

    # Prisma Client usage (Service internal)
    echo "🔍 Prisma Client Usage in Services:"
    grep -r "prisma\.${pattern,,}" "$BACKEND_PATH" \
        --include="*.service.ts" \
        | grep -E "(findMany|findUnique|findFirst|create|update|delete|upsert)" | head -20

    # PrismaService injection
    echo "🔍 PrismaService Injection:"
    grep -r "constructor.*PrismaService" "$BACKEND_PATH" \
        --include="*.service.ts" \
        -A 1 | grep -i "${pattern}" | head -10
}

search_nestjs_modules() {
    local pattern="$1"
    echo "🔍 Searching NestJS Modules in $BACKEND_PATH..."

    # @Module 데코레이터
    grep -r "@Module({" "$BACKEND_PATH" \
        --include="*.module.ts" \
        -B 1 | grep -i "${pattern}" 2>/dev/null | head -20
}
