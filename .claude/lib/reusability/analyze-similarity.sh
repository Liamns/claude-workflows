#!/bin/bash
# 유사도 점수 계산

calculate_function_similarity() {
    local source_file="$1"
    local target_file="$2"
    local pattern="$3"

    # 함수 시그니처 추출
    local source_sig=$(grep -A 5 "function.*${pattern}" "$source_file" 2>/dev/null | head -6)
    local target_sig=$(grep -A 5 "function.*${pattern}" "$target_file" 2>/dev/null | head -6)

    # 파라미터 개수 비교
    local source_params=$(echo "$source_sig" | grep -o "," | wc -l)
    local target_params=$(echo "$target_sig" | grep -o "," | wc -l)

    local score=0

    # 시그니처 완전 일치
    if [ "$source_sig" = "$target_sig" ]; then
        score=100
    # 파라미터 개수 일치
    elif [ "$source_params" -eq "$target_params" ]; then
        score=70
    # 함수명만 일치
    else
        score=40
    fi

    echo "$score"
}

calculate_component_similarity() {
    local source_file="$1"
    local target_file="$2"
    local pattern="$3"

    local score=0

    # Props 타입 비교
    local source_props=$(grep -A 10 "interface.*Props" "$source_file" 2>/dev/null | head -11)
    local target_props=$(grep -A 10 "interface.*Props" "$target_file" 2>/dev/null | head -11)

    if [ "$source_props" = "$target_props" ]; then
        score=$((score + 60))
    elif [ -n "$source_props" ] && [ -n "$target_props" ]; then
        score=$((score + 30))
    fi

    # 반환 JSX 유사도
    local source_jsx=$(grep -A 5 "return (" "$source_file" 2>/dev/null | head -6)
    local target_jsx=$(grep -A 5 "return (" "$target_file" 2>/dev/null | head -6)

    if echo "$source_jsx" | grep -q "$target_jsx"; then
        score=$((score + 40))
    fi

    echo "$score"
}

score_to_recommendation() {
    local score="$1"
    local module_path="$2"

    if [ "$score" -ge 90 ]; then
        echo "✅ REUSE (${score}%): ${module_path}"
        echo "   → 그대로 import하여 사용하세요"
    elif [ "$score" -ge 70 ]; then
        echo "🔧 EXTEND (${score}%): ${module_path}"
        echo "   → 기존 모듈을 확장하거나 wrapper를 만드세요"
    elif [ "$score" -ge 50 ]; then
        echo "📝 ADAPT (${score}%): ${module_path}"
        echo "   → 패턴을 참고하여 작성하세요"
    else
        echo "🆕 CREATE (${score}%): 새로운 모듈 작성"
        echo "   → 유사한 모듈이 없습니다"
    fi
}
