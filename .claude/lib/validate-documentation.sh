#!/bin/bash
# validate-documentation.sh
# 문서 검증 모듈 - 문서-코드 일관성 검증
# Phase 3 - User Story 1 구현

# Only set -e when running as script, not when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -e
fi

# 현재 스크립트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 공통 유틸리티 로드 (이미 로드되지 않았다면)
if ! declare -f log_info > /dev/null 2>&1; then
    source "$SCRIPT_DIR/validation-utils.sh"
fi

# 설정 파일 로드 (이미 로드되지 않았다면)
if [[ -z "${VALIDATION_DOC_THRESHOLD_PASS:-}" ]]; then
    CONFIG_FILE="${CONFIG_FILE:-$SCRIPT_DIR/validation-config.sh}"
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck source=.claude/lib/validation-config.sh
        source "$CONFIG_FILE"
    else
        # 기본값
        # shellcheck disable=SC2034  # Used by sourced modules
        readonly VALIDATION_DOC_THRESHOLD_PASS=90
        # shellcheck disable=SC2034
        readonly VALIDATION_DOC_THRESHOLD_WARNING=70
        # shellcheck disable=SC2034
        readonly VALIDATION_SCORE_FILE_EXISTS=10
        # shellcheck disable=SC2034
        readonly VALIDATION_SCORE_STEP_EXISTS=30
        # shellcheck disable=SC2034
        readonly VALIDATION_SCORE_CODE_EXISTS=30
        # shellcheck disable=SC2034
        readonly VALIDATION_SCORE_BALANCE=30
    fi
fi

# ============================================================
# 핵심 검증 함수
# ============================================================

# 모든 슬래시 명령어 문서 검증
validate_all_documentation() {
    local commands_dir="${1:-.claude/commands}"
    local results="[]"
    local total=0
    local passed=0
    local total_consistency=0

    log_info "📄 문서 검증 시작..."
    echo ""

    # 명령어 디렉토리 존재 확인
    if [[ ! -d "$commands_dir" ]]; then
        log_error "명령어 디렉토리 없음: $commands_dir"
        echo "[]"
        return 1
    fi

    # 모든 .md 파일 검증
    for cmd_file in "$commands_dir"/*.md; do
        if [[ ! -f "$cmd_file" ]]; then
            continue
        fi

        local cmd_name=$(basename "$cmd_file" .md)
        log_info "  검증 중: $cmd_name.md"

        # 개별 문서 검증
        local result=$(validate_single_doc "$cmd_file")
        local consistency=$(echo "$result" | grep -o '"consistencyPercentage":[[:space:]]*[0-9]*' | grep -o '[0-9]*$')

        if [[ -z "$consistency" ]]; then
            consistency=0
        fi

        # 결과 분류
        if [[ $consistency -ge $VALIDATION_DOC_THRESHOLD_PASS ]]; then
            log_success "    ✓ $cmd_name - $consistency%"
            ((passed++))
        elif [[ $consistency -ge $VALIDATION_DOC_THRESHOLD_WARNING ]]; then
            log_warning "    ⚠️  $cmd_name - $consistency% (경고)"
        else
            log_error "    ✗ $cmd_name - $consistency% (불일치)"
        fi

        ((total++))
        total_consistency=$((total_consistency + consistency))

        # JSON 배열에 결과 추가
        if command -v jq > /dev/null 2>&1; then
            results=$(echo "$results" | jq ". += [$result]")
        fi
    done

    echo ""
    log_info "  완료: $passed/$total 통과"

    # 평균 일치율 계산
    local avg_consistency=0
    if [[ $total -gt 0 ]]; then
        avg_consistency=$((total_consistency / total))
    fi
    log_info "  평균 일치율: $avg_consistency%"

    # 결과 반환
    if command -v jq > /dev/null 2>&1; then
        echo "$results" | jq -c "{ total: $total, passed: $passed, avgConsistency: $avg_consistency, results: . }"
    else
        echo "{\"total\":$total,\"passed\":$passed,\"avgConsistency\":$avg_consistency,\"results\":[]}"
    fi

    if [[ $passed -eq $total ]]; then
        return 0
    else
        return 1
    fi
}

# 개별 문서 검증
validate_single_doc() {
    local doc_file="$1"
    local command_name=$(basename "$doc_file" .md)

    if [[ ! -f "$doc_file" ]]; then
        log_error "파일 없음: $doc_file"
        echo '{"error":"File not found"}'
        return 1
    fi

    # Step 추출
    local steps=$(extract_steps_from_doc "$doc_file")
    local step_count=$(echo "$steps" | jq 'length' 2>/dev/null || echo "0")

    # 코드 블록 추출
    local code_blocks=$(extract_code_blocks "$doc_file")
    local code_count=$(echo "$code_blocks" | jq 'length' 2>/dev/null || echo "0")

    # 일치율 계산
    local consistency=$(calculate_consistency "$doc_file" "$steps" "$code_blocks")

    # JSON 결과 생성
    if command -v jq > /dev/null 2>&1; then
        jq -n \
            --arg name "$command_name" \
            --arg path "$doc_file" \
            --argjson steps "$steps" \
            --argjson code "$code_blocks" \
            --argjson percent "$consistency" \
            '{
                commandName: $name,
                filePath: $path,
                extractedSteps: $steps,
                codeBlocks: $code,
                stepCount: ($steps | length),
                codeBlockCount: ($code | length),
                consistencyPercentage: $percent,
                timestamp: (now | todate)
            }'
    else
        echo "{\"commandName\":\"$command_name\",\"filePath\":\"$doc_file\",\"consistencyPercentage\":$consistency}"
    fi
}

# Step 패턴 추출
extract_steps_from_doc() {
    local doc_file="$1"

    # 구버전 형식 (### Step N) 먼저 확인
    local steps_raw=$(grep -E "^### Step [0-9]+" "$doc_file" 2>/dev/null || echo "")

    if [[ -n "$steps_raw" ]]; then
        # 구버전 형식 발견
        if command -v jq > /dev/null 2>&1; then
            echo "$steps_raw" | sed 's/^### //' | jq -R . | jq -s '.'
        else
            echo "[]"
        fi
        return 0
    fi

    # 신버전 형식 (### Workflow Steps 섹션의 번호 리스트) 확인
    # Implementation 섹션 내 Workflow Steps 또는 직접 번호 매긴 단계 찾기
    # 두 가지 형식 지원:
    # 1. 번호 리스트: "1. **Step**"
    # 2. 볼드 헤딩: "**Step 1:**"
    local workflow_steps=$(sed -n '/^### Workflow Steps/,/^###/p' "$doc_file" 2>/dev/null | grep -E "^[0-9]\.|^\*\*Step [0-9]+" || echo "")

    if [[ -z "$workflow_steps" ]]; then
        echo "[]"
        return 0
    fi

    # JSON 배열로 변환
    if command -v jq > /dev/null 2>&1; then
        echo "$workflow_steps" | sed -E 's/^[0-9]+\. \*\*//' | sed 's/\*\*:.*//' | jq -R . | jq -s '.'
    else
        echo "[]"
    fi
}

# 코드 블록 추출
extract_code_blocks() {
    local doc_file="$1"
    local blocks="[]"

    # ```bash 블록 찾기
    local in_block=false
    local current_block=""
    local block_count=0

    while IFS= read -r line; do
        if [[ "$line" =~ ^\`\`\`bash ]]; then
            in_block=true
            current_block=""
        elif [[ "$line" =~ ^\`\`\` ]] && [[ "$in_block" == "true" ]]; then
            in_block=false
            ((block_count++))
            # JSON 배열에 추가 (jq 사용)
            if command -v jq > /dev/null 2>&1 && [[ -n "$current_block" ]]; then
                blocks=$(echo "$blocks" | jq --arg code "$current_block" '. += [{type: "bash", content: $code, id: ("block-" + (. | length | tostring))}]')
            fi
        elif [[ "$in_block" == "true" ]]; then
            current_block+="$line"$'\n'
        fi
    done < "$doc_file"

    echo "$blocks"
}

# 일치율 계산
calculate_consistency() {
    local doc_file="$1"
    local steps="$2"
    local code_blocks="$3"

    local step_count=$(echo "$steps" | jq 'length' 2>/dev/null || echo "0")
    local code_count=$(echo "$code_blocks" | jq 'length' 2>/dev/null || echo "0")

    # 기본 점수: 파일 존재
    local score=$VALIDATION_SCORE_FILE_EXISTS

    # Step 존재 여부
    if [[ $step_count -gt 0 ]]; then
        score=$((score + VALIDATION_SCORE_STEP_EXISTS))
    fi

    # 코드 블록 존재 여부
    if [[ $code_count -gt 0 ]]; then
        score=$((score + VALIDATION_SCORE_CODE_EXISTS))
    fi

    # Step과 코드 블록 균형
    if [[ $step_count -gt 0 ]] && [[ $code_count -gt 0 ]]; then
        # Step과 코드 블록 비율이 합리적이면 추가 점수
        local ratio=$((code_count * 100 / step_count))
        if [[ $ratio -ge 50 ]] && [[ $ratio -le 200 ]]; then
            score=$((score + VALIDATION_SCORE_BALANCE))
        else
            score=$((score + VALIDATION_SCORE_BALANCE / 2))
        fi
    fi

    # 100점을 초과하지 않도록
    if [[ $score -gt 100 ]]; then
        score=100
    fi

    echo "$score"
}

# ============================================================
# 보조 함수
# ============================================================

# 불일치 항목 상세 분석
analyze_discrepancies() {
    local doc_file="$1"
    local discrepancies="[]"

    # Step이 있는데 코드가 없는 경우
    local steps=$(extract_steps_from_doc "$doc_file")
    local code_blocks=$(extract_code_blocks "$doc_file")

    local step_count=$(echo "$steps" | jq 'length' 2>/dev/null || echo "0")
    local code_count=$(echo "$code_blocks" | jq 'length' 2>/dev/null || echo "0")

    if [[ $step_count -gt 0 ]] && [[ $code_count -eq 0 ]]; then
        if command -v jq > /dev/null 2>&1; then
            discrepancies=$(echo "$discrepancies" | jq '. += [{"type": "missing_code", "message": "Step이 있으나 코드 예제 없음"}]')
        fi
    fi

    if [[ $step_count -eq 0 ]] && [[ $code_count -gt 0 ]]; then
        if command -v jq > /dev/null 2>&1; then
            discrepancies=$(echo "$discrepancies" | jq '. += [{"type": "missing_steps", "message": "코드는 있으나 Step 구조 없음"}]')
        fi
    fi

    echo "$discrepancies"
}

# 검증 통계 생성
generate_validation_stats() {
    local results="$1"

    if ! command -v jq > /dev/null 2>&1; then
        echo "{}"
        return 1
    fi

    local total=$(echo "$results" | jq '.total')
    local passed=$(echo "$results" | jq '.passed')
    local avg=$(echo "$results" | jq '.avgConsistency')

    jq -n \
        --argjson total "$total" \
        --argjson passed "$passed" \
        --argjson avg "$avg" \
        '{
            totalDocuments: $total,
            passedDocuments: $passed,
            failedDocuments: ($total - $passed),
            averageConsistency: $avg,
            passRate: (if $total > 0 then ($passed * 100 / $total) else 0 end)
        }'
}

# ============================================================
# CLI 인터페이스 (직접 실행 시)
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   문서 검증 모듈                      ║"
    echo "║   Documentation Validation Module     ║"
    echo "╚════════════════════════════════════════╝"
    echo ""

    # 명령줄 인자
    COMMANDS_DIR="${1:-.claude/commands}"

    # 전체 검증 실행
    RESULTS=$(validate_all_documentation "$COMMANDS_DIR")

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "📊 검증 통계"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if command -v jq > /dev/null 2>&1; then
        echo "$RESULTS" | jq .
    else
        echo "$RESULTS"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # 종료 코드 결정
    if [[ $(echo "$RESULTS" | jq -r '.passed == .total' 2>/dev/null) == "true" ]]; then
        log_success "✅ 모든 문서 검증 통과"
        exit 0
    else
        log_warning "⚠️  일부 문서 검증 실패"
        exit 1
    fi
fi
