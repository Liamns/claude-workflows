#!/bin/bash
# Capacitor 플러그인 래퍼 검색

search_capacitor_plugins() {
    local pattern="$1"
    echo "🔍 Searching Capacitor Plugins..."

    # Capacitor 플러그인 import
    grep -r "from '@capacitor" src/ \
        --include="*.ts" \
        --include="*.tsx" \
        -n 2>/dev/null | head -20

    # Capacitor API 사용
    grep -r "Capacitor\.${pattern}\|Plugins\.${pattern}" src/ \
        --include="*.ts" \
        --include="*.tsx" \
        -n 2>/dev/null | head -20
}

search_capacitor_wrappers() {
    local pattern="$1"
    echo "🔍 Searching Capacitor Wrapper Functions..."

    # 커스텀 플러그인 훅
    grep -r "use.*${pattern}" src/ \
        --include="*.ts" \
        --include="*.tsx" \
        | grep -i "capacitor\|camera\|filesystem\|network\|geolocation\|device" \
        2>/dev/null | head -20

    # 플러그인 래퍼 함수
    grep -r "export.*function.*${pattern}" src/shared/lib/capacitor \
        --include="*.ts" \
        -n 2>/dev/null | head -20
}
