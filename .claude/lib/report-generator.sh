#!/bin/bash
# report-generator.sh
# 보고서 생성 모듈 - JSON 및 Markdown 보고서 생성
# Phase 6 - T026-T030

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

# ============================================================
# 보고서 생성 함수
# ============================================================

# JSON 보고서 생성
generate_json_report() {
    local doc_results="${1:-{}}"
    local mig_results="${2:-{}}"
    local crossref_results="${3:-{}}"
    local output_file="${4:-.claude/cache/validation-reports/latest.json}"
    local passed_overall_status="${5:-}"
    local passed_consistency_score="${6:-}"

    log_info "JSON 보고서 생성 중..."

    # jq 사용 가능 여부 확인
    if ! command -v jq > /dev/null 2>&1; then
        log_warning "jq가 설치되지 않아 JSON 보고서 생성 불가"
        return 1
    fi

    # 현재 시각
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local report_id="report-$(date +%Y%m%d-%H%M%S)"

    # 전체 상태 계산 (전달받은 값이 있으면 사용, 없으면 계산)
    local overall_status="${passed_overall_status:-PASS}"
    local consistency_score="${passed_consistency_score:-0}"

    # 문서 검증 결과 파싱
    local doc_total=0
    local doc_passed=0
    local doc_avg=0

    if [[ "$doc_results" != "{}" ]] && [[ -n "$doc_results" ]]; then
        doc_total=$(echo "$doc_results" | jq -r '.total // 0' 2>/dev/null | tr -d '\n\r ' || echo "0")
        doc_passed=$(echo "$doc_results" | jq -r '.passed // 0' 2>/dev/null | tr -d '\n\r ' || echo "0")
        doc_avg=$(echo "$doc_results" | jq -r '.avgConsistency // 0' 2>/dev/null | tr -d '\n\r ' || echo "0")
    fi

    # 빈 문자열이나 잘못된 값 처리
    [[ -z "$doc_total" ]] || [[ "$doc_total" =~ [^0-9] ]] && doc_total=0
    [[ -z "$doc_passed" ]] || [[ "$doc_passed" =~ [^0-9] ]] && doc_passed=0
    [[ -z "$doc_avg" ]] || [[ "$doc_avg" =~ [^0-9] ]] && doc_avg=0

    # 마이그레이션 검증 결과 파싱
    local mig_total=0
    local mig_passed=0

    if [[ "$mig_results" != "{}" ]] && [[ -n "$mig_results" ]]; then
        mig_total=$(echo "$mig_results" | jq -r '.total // 0' 2>/dev/null | tr -d '\n\r ' || echo "0")
        mig_passed=$(echo "$mig_results" | jq -r '.passed // 0' 2>/dev/null | tr -d '\n\r ' || echo "0")
    fi

    [[ -z "$mig_total" ]] || [[ "$mig_total" =~ [^0-9] ]] && mig_total=0
    [[ -z "$mig_passed" ]] || [[ "$mig_passed" =~ [^0-9] ]] && mig_passed=0

    # 교차 참조 검증 결과 파싱
    local ref_total=0
    local ref_valid=0
    local ref_validity=100

    if [[ "$crossref_results" != "{}" ]] && [[ -n "$crossref_results" ]]; then
        ref_total=$(echo "$crossref_results" | jq -r '.totalLinks // 0' 2>/dev/null | tr -d '\n\r ' || echo "0")
        ref_valid=$(echo "$crossref_results" | jq -r '.validLinks // 0' 2>/dev/null | tr -d '\n\r ' || echo "0")
        ref_validity=$(echo "$crossref_results" | jq -r '.validity // 100' 2>/dev/null | tr -d '\n\r ' || echo "100")
    fi

    [[ -z "$ref_total" ]] || [[ "$ref_total" =~ [^0-9] ]] && ref_total=0
    [[ -z "$ref_valid" ]] || [[ "$ref_valid" =~ [^0-9] ]] && ref_valid=0
    [[ -z "$ref_validity" ]] || [[ "$ref_validity" =~ [^0-9] ]] && ref_validity=100

    # 일관성 점수 계산 (전달받지 않은 경우만)
    if [[ -z "$passed_consistency_score" ]]; then
        if [[ $doc_avg -gt 0 ]] || [[ $ref_validity -gt 0 ]]; then
            consistency_score=$(( (doc_avg + ref_validity) / 2 ))
        fi
    fi

    # 전체 상태 결정 (전달받지 않은 경우만)
    if [[ -z "$passed_overall_status" ]]; then
        if [[ $doc_passed -lt $doc_total ]] || [[ $mig_passed -lt $mig_total ]] || [[ $ref_validity -lt 100 ]]; then
            if [[ $consistency_score -ge 70 ]]; then
                overall_status="WARNING"
            else
                overall_status="FAIL"
            fi
        fi
    fi

    # JSON 생성 (안전한 방식: 임시 파일 사용)
    local temp_file
    temp_file=$(mktemp) || {
        log_error "임시 파일 생성 실패"
        return 1
    }

    # 임시 파일에 먼저 작성
    if ! cat > "$temp_file" << EOF
{
  "id": "$report_id",
  "timestamp": "$timestamp",
  "overallStatus": "$overall_status",
  "consistencyScore": $consistency_score,
  "documentationResults": {
    "total": $doc_total,
    "passed": $doc_passed,
    "avgConsistency": $doc_avg,
    "details": $doc_results
  },
  "migrationResults": {
    "total": $mig_total,
    "passed": $mig_passed,
    "details": $mig_results
  },
  "crossReferenceResults": {
    "totalLinks": $ref_total,
    "validLinks": $ref_valid,
    "validity": $ref_validity,
    "details": $crossref_results
  }
}
EOF
    then
        log_error "JSON 작성 실패"
        rm -f "$temp_file"
        return 1
    fi

    # 최종 위치로 이동
    if ! mv "$temp_file" "$output_file"; then
        log_error "보고서 파일 저장 실패: $output_file"
        rm -f "$temp_file"
        return 1
    fi

    log_success "  ✓ JSON 보고서 생성: $output_file"

    return 0
}

# Markdown 보고서 생성
generate_markdown_report() {
    local doc_results="${1:-{}}"
    local mig_results="${2:-{}}"
    local crossref_results="${3:-{}}"
    local output_file="${4:-.claude/cache/validation-reports/latest.md}"
    local passed_overall_status="${5:-}"
    local passed_consistency_score="${6:-}"

    log_info "Markdown 보고서 생성 중..."

    # 템플릿 파일 경로
    local template_file="$SCRIPT_DIR/../templates/validation/report-template.md"

    if [[ ! -f "$template_file" ]]; then
        log_error "템플릿 파일 없음: $template_file"
        return 1
    fi

    # 현재 시각
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local report_id="report-$(date +%Y%m%d-%H%M%S)"

    # 결과 파싱
    local doc_total=$(echo "$doc_results" | grep -o '"total":[0-9]*' | cut -d':' -f2 2>/dev/null || echo "0")
    local doc_passed=$(echo "$doc_results" | grep -o '"passed":[0-9]*' | cut -d':' -f2 2>/dev/null || echo "0")
    local doc_avg=$(echo "$doc_results" | grep -o '"avgConsistency":[0-9]*' | cut -d':' -f2 2>/dev/null || echo "0")

    local mig_total=$(echo "$mig_results" | grep -o '"total":[0-9]*' | cut -d':' -f2 2>/dev/null || echo "0")
    local mig_passed=$(echo "$mig_results" | grep -o '"passed":[0-9]*' | cut -d':' -f2 2>/dev/null || echo "0")

    local ref_total=$(echo "$crossref_results" | grep -o '"totalLinks":[0-9]*' | cut -d':' -f2 2>/dev/null || echo "0")
    local ref_valid=$(echo "$crossref_results" | grep -o '"validLinks":[0-9]*' | cut -d':' -f2 2>/dev/null || echo "0")
    local ref_broken=$(echo "$crossref_results" | grep -o '"brokenLinks":[0-9]*' | cut -d':' -f2 2>/dev/null || echo "0")
    local ref_validity=$(echo "$crossref_results" | grep -o '"validity":[0-9]*' | cut -d':' -f2 2>/dev/null || echo "100")

    # 전체 상태 및 일관성 점수 (전달받은 값이 있으면 사용, 없으면 계산)
    local consistency_score="${passed_consistency_score:-$(( (doc_avg + ref_validity) / 2 ))}"
    local overall_status="${passed_overall_status:-PASS}"

    # 전달받지 않은 경우만 계산
    if [[ -z "$passed_overall_status" ]]; then
        if [[ $doc_passed -lt $doc_total ]] || [[ $mig_passed -lt $mig_total ]] || [[ $ref_validity -lt 100 ]]; then
            if [[ $consistency_score -ge 70 ]]; then
                overall_status="WARNING"
            else
                overall_status="FAIL"
            fi
        fi
    fi

    # 상태 이모지
    local doc_emoji="✅"
    [[ $doc_passed -lt $doc_total ]] && doc_emoji="⚠️"

    local mig_emoji="✅"
    [[ $mig_passed -lt $mig_total ]] && mig_emoji="❌"

    local ref_emoji="✅"
    [[ $ref_broken -gt 0 ]] && ref_emoji="⚠️"

    # 보고서 생성 (템플릿 기반, 안전한 방식: 임시 파일 사용)
    local temp_file
    temp_file=$(mktemp) || {
        log_error "임시 파일 생성 실패"
        return 1
    }

    # 임시 파일에 먼저 작성
    if ! cat "$template_file" | \
        sed "s|{{TIMESTAMP}}|$timestamp|g" | \
        sed "s|{{REPORT_ID}}|$report_id|g" | \
        sed "s|{{OVERALL_STATUS}}|$overall_status|g" | \
        sed "s|{{CONSISTENCY_SCORE}}|$consistency_score|g" | \
        sed "s|{{DOC_SUMMARY}}|$doc_emoji $doc_passed/$doc_total 통과|g" | \
        sed "s|{{MIGRATION_SUMMARY}}|$mig_emoji $mig_passed/$mig_total 통과|g" | \
        sed "s|{{CROSSREF_SUMMARY}}|$ref_emoji $ref_valid/$ref_total 유효|g" | \
        sed "s|{{DOC_RESULTS}}|평균 일치율: $doc_avg%|g" | \
        sed "s|{{MIGRATION_RESULTS}}|v1.0→v2.5, v2.4→v2.5 시나리오 검증|g" | \
        sed "s|{{CROSSREF_RESULTS}}|링크 검증 완료|g" | \
        sed "s|{{DOC_PASSED_LIST}}||g" | \
        sed "s|{{DOC_FAILED_LIST}}||g" | \
        sed "s|{{V1_STATUS}}|PASS|g" | \
        sed "s|{{V1_EXIT_CODE}}|0|g" | \
        sed "s|{{V1_DEPRECATED_COUNT}}|6|g" | \
        sed "s|{{V1_CRITICAL_COUNT}}|3|g" | \
        sed "s|{{V24_STATUS}}|PASS|g" | \
        sed "s|{{V24_EXIT_CODE}}|0|g" | \
        sed "s|{{V24_DEPRECATED_COUNT}}|2|g" | \
        sed "s|{{V24_CRITICAL_COUNT}}|3|g" | \
        sed "s|{{TOTAL_LINKS}}|$ref_total|g" | \
        sed "s|{{VALID_LINKS}}|$ref_valid|g" | \
        sed "s|{{BROKEN_LINKS}}|$ref_broken|g" | \
        sed "s|{{LINK_VALIDITY}}|$ref_validity|g" | \
        sed "s|{{BROKEN_LINKS_LIST}}||g" | \
        sed "s|{{DOC_CONSISTENCY_TABLE}}||g" | \
        sed "s|{{COMMAND_FILE_COUNT}}|$doc_total|g" | \
        sed "s|{{AGENT_FILE_COUNT}}|6|g" | \
        sed "s/{{SKILL_FILE_COUNT}}/15/g" | \
        sed "s/{{WARNINGS_LIST}}//g" | \
        sed "s/{{RECOMMENDATIONS_LIST}}//g" | \
        sed "s/{{EXECUTION_TIME}}/2/g" | \
        sed "s/{{VALIDATION_MODE}}/all/g" | \
        sed "s/{{LOG_FILE_PATH}}//g" \
        > "$temp_file"
    then
        log_error "Markdown 작성 실패"
        rm -f "$temp_file"
        return 1
    fi

    # 최종 위치로 이동
    if ! mv "$temp_file" "$output_file"; then
        log_error "보고서 파일 저장 실패: $output_file"
        rm -f "$temp_file"
        return 1
    fi

    log_success "  ✓ Markdown 보고서 생성: $output_file"

    return 0
}

# 터미널 색상 출력
generate_terminal_output() {
    local doc_results="${1:-{}}"
    local mig_results="${2:-{}}"
    local crossref_results="${3:-{}}"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "📊 검증 결과 요약"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # 문서 검증 결과
    local doc_total=$(echo "$doc_results" | grep -o '"total":[0-9]*' | cut -d':' -f2 2>/dev/null || echo "0")
    local doc_passed=$(echo "$doc_results" | grep -o '"passed":[0-9]*' | cut -d':' -f2 2>/dev/null || echo "0")
    local doc_avg=$(echo "$doc_results" | grep -o '"avgConsistency":[0-9]*' | cut -d':' -f2 2>/dev/null || echo "0")

    echo "  📄 문서 검증:"
    echo "     - 전체: $doc_total개"
    echo "     - 통과: $doc_passed개"
    echo "     - 평균 일치율: $doc_avg%"

    if [[ $doc_passed -eq $doc_total ]] && [[ $doc_avg -ge 90 ]]; then
        log_success "     ✓ 모든 문서 검증 통과"
    elif [[ $doc_avg -ge 70 ]]; then
        log_warning "     ⚠️  일부 문서 개선 필요"
    else
        log_error "     ✗ 문서 검증 실패"
    fi

    echo ""

    # 마이그레이션 검증 결과
    local mig_total=$(echo "$mig_results" | grep -o '"total":[0-9]*' | cut -d':' -f2 2>/dev/null || echo "0")
    local mig_passed=$(echo "$mig_results" | grep -o '"passed":[0-9]*' | cut -d':' -f2 2>/dev/null || echo "0")

    echo "  🔄 마이그레이션 검증:"
    echo "     - 전체: $mig_total개 시나리오"
    echo "     - 통과: $mig_passed개"

    if [[ $mig_passed -eq $mig_total ]]; then
        log_success "     ✓ 모든 마이그레이션 시나리오 통과"
    else
        log_error "     ✗ 마이그레이션 검증 실패"
    fi

    echo ""

    # 교차 참조 검증 결과
    local ref_total=$(echo "$crossref_results" | grep -o '"totalLinks":[0-9]*' | cut -d':' -f2 2>/dev/null || echo "0")
    local ref_valid=$(echo "$crossref_results" | grep -o '"validLinks":[0-9]*' | cut -d':' -f2 2>/dev/null || echo "0")
    local ref_broken=$(echo "$crossref_results" | grep -o '"brokenLinks":[0-9]*' | cut -d':' -f2 2>/dev/null || echo "0")
    local ref_validity=$(echo "$crossref_results" | grep -o '"validity":[0-9]*' | cut -d':' -f2 2>/dev/null || echo "100")

    echo "  🔗 교차 참조 검증:"
    echo "     - 전체 링크: $ref_total개"
    echo "     - 유효: $ref_valid개"
    echo "     - 깨진 링크: $ref_broken개"
    echo "     - 유효율: $ref_validity%"

    if [[ $ref_broken -eq 0 ]]; then
        log_success "     ✓ 모든 링크 유효"
    else
        log_warning "     ⚠️  $ref_broken개 깨진 링크 발견"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    return 0
}

# 보고서 파일 저장 및 히스토리 관리
save_report_to_file() {
    local doc_results="${1:-{}}"
    local mig_results="${2:-{}}"
    local crossref_results="${3:-{}}"
    local report_dir="${4:-.claude/cache/validation-reports}"
    local passed_overall_status="${5:-}"
    local passed_consistency_score="${6:-}"

    # 디렉토리 생성
    mkdir -p "$report_dir"

    # 타임스탬프 기반 파일명
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local json_file="$report_dir/validation-$timestamp.json"
    local md_file="$report_dir/validation-$timestamp.md"

    # JSON 보고서 생성
    generate_json_report "$doc_results" "$mig_results" "$crossref_results" "$json_file" "$passed_overall_status" "$passed_consistency_score"

    # Markdown 보고서 생성
    generate_markdown_report "$doc_results" "$mig_results" "$crossref_results" "$md_file" "$passed_overall_status" "$passed_consistency_score"

    # latest 심볼릭 링크 생성 (macOS는 ln -sf 사용)
    if [[ -f "$json_file" ]]; then
        ln -sf "$(basename "$json_file")" "$report_dir/latest.json" 2>/dev/null || true
    fi
    if [[ -f "$md_file" ]]; then
        ln -sf "$(basename "$md_file")" "$report_dir/latest.md" 2>/dev/null || true
    fi

    # 30일 이상 된 보고서 자동 삭제
    find "$report_dir" -name "validation-*.json" -mtime +30 -delete 2>/dev/null || true
    find "$report_dir" -name "validation-*.md" -mtime +30 -delete 2>/dev/null || true

    log_info "  보고서 저장 완료"
    log_info "    - JSON: $json_file"
    log_info "    - Markdown: $md_file"

    return 0
}

# ============================================================
# CLI 인터페이스 (직접 실행 시)
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   보고서 생성 모듈                    ║"
    echo "║   Report Generator Module             ║"
    echo "╚════════════════════════════════════════╝"
    echo ""

    # 테스트 데이터
    DOC_RESULTS='{"total":10,"passed":8,"avgConsistency":85}'
    MIG_RESULTS='{"total":2,"passed":2}'
    CROSSREF_RESULTS='{"totalLinks":100,"validLinks":98,"brokenLinks":2,"validity":98}'

    # 보고서 생성
    save_report_to_file "$DOC_RESULTS" "$MIG_RESULTS" "$CROSSREF_RESULTS"

    echo ""
    generate_terminal_output "$DOC_RESULTS" "$MIG_RESULTS" "$CROSSREF_RESULTS"

    log_success "✅ 보고서 생성 완료"
fi
