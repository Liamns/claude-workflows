#!/bin/bash
# React 컴포넌트, 훅, 유틸리티 검색

search_react_components() {
    local pattern="$1"
    echo "🔍 Searching React Components..."

    # React 함수 컴포넌트
    grep -r "export.*function.*${pattern}" src/ \
        --include="*.tsx" \
        --include="*.jsx" \
        -n 2>/dev/null | head -20

    # React 클래스 컴포넌트
    grep -r "class.*${pattern}.*extends.*Component" src/ \
        --include="*.tsx" \
        --include="*.jsx" \
        -n 2>/dev/null | head -20
}

search_react_hooks() {
    local pattern="$1"
    echo "🔍 Searching React Hooks..."

    # 커스텀 훅 (use* 패턴)
    grep -r "export.*function use${pattern}" src/ \
        --include="*.ts" \
        --include="*.tsx" \
        -n 2>/dev/null | head -20
}

search_react_types() {
    local pattern="$1"
    echo "🔍 Searching TypeScript Types..."

    # interface
    grep -r "export interface ${pattern}" src/ \
        --include="*.ts" \
        --include="*.tsx" \
        -n 2>/dev/null | head -20

    # type alias
    grep -r "export type ${pattern}" src/ \
        --include="*.ts" \
        --include="*.tsx" \
        -n 2>/dev/null | head -20

    # enum
    grep -r "export enum ${pattern}" src/ \
        --include="*.ts" \
        --include="*.tsx" \
        -n 2>/dev/null | head -20
}

search_react_utils() {
    local pattern="$1"
    echo "🔍 Searching Utility Functions..."

    # shared/lib 유틸리티
    grep -r "export.*function.*${pattern}" src/shared/lib \
        --include="*.ts" \
        -n 2>/dev/null | head -20

    # entities 레이어 유틸리티
    grep -r "export.*function.*${pattern}" src/entities/*/lib \
        --include="*.ts" \
        -n 2>/dev/null | head -20
}
