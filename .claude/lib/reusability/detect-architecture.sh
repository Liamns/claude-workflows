#!/bin/bash
# 프로젝트 아키텍처 자동 감지

detect_backend_path() {
    echo "🔍 Detecting backend path..." >&2

    local BACKEND_PATHS=(
        "apps/api/src"
        "apps/backend/src"
        "apps/server/src"
        "backend/src"
        "server/src"
        "api/src"
        "packages/api/src"
        "packages/backend/src"
    )

    for path in "${BACKEND_PATHS[@]}"; do
        if [ -d "$path" ]; then
            echo "✅ Found backend: $path" >&2
            echo "$path"
            return 0
        fi
    done

    echo "⚠️  Backend path not found, using root" >&2
    echo "."
}

detect_project_size() {
    echo "📊 Analyzing project size..." >&2
    local total_files=$(find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) | wc -l)

    if [ "$total_files" -lt 100 ]; then
        echo "small"
    elif [ "$total_files" -lt 500 ]; then
        echo "medium"
    else
        echo "large"
    fi
}

detect_monorepo() {
    if [ -f "lerna.json" ] || [ -f "nx.json" ] || [ -f "turbo.json" ] || [ -f "pnpm-workspace.yaml" ]; then
        echo "yes"
    else
        echo "no"
    fi
}

# 메인 감지 함수
main() {
    local backend_path=$(detect_backend_path)
    local project_size=$(detect_project_size)
    local is_monorepo=$(detect_monorepo)

    export BACKEND_PATH="$backend_path"
    export PROJECT_SIZE="$project_size"
    export IS_MONOREPO="$is_monorepo"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Project Architecture"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Backend Path: $backend_path"
    echo "Project Size: $project_size"
    echo "Monorepo: $is_monorepo"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# 직접 실행할 때만 main 함수 호출 (source될 때는 호출 안 함)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
