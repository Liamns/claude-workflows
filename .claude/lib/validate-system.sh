#!/bin/bash
# validate-system.sh
# 문서 및 설치 검증 시스템 - 메인 스크립트
# 사용법: bash .claude/lib/validate-system.sh [OPTIONS]

set -e

# 현재 스크립트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 공통 유틸리티 로드
source "$SCRIPT_DIR/validation-utils.sh"

# 설정 파일 로드
CONFIG_FILE="${CONFIG_FILE:-$SCRIPT_DIR/validation-config.sh}"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=.claude/lib/validation-config.sh
    source "$CONFIG_FILE"
else
    # 기본값 (설정 파일 없을 때 호환성 유지)
    # shellcheck disable=SC2034  # Used by sourced modules
    readonly VALIDATION_DOC_THRESHOLD_PASS=90
    # shellcheck disable=SC2034
    readonly VALIDATION_DOC_THRESHOLD_WARNING=70
    # shellcheck disable=SC2034
    readonly VALIDATION_CONSISTENCY_THRESHOLD_PASS=90
    # shellcheck disable=SC2034
    readonly VALIDATION_CONSISTENCY_THRESHOLD_WARNING=70
    # shellcheck disable=SC2034
    readonly VALIDATION_REPORT_RETENTION_DAYS=30
fi

# 기본 설정
VALIDATION_MODE="all"  # all, docs-only, migration-only, crossref-only
DRY_RUN=false
VERBOSE=false
QUIET=false
REPORT_DIR=".claude/cache/validation-reports"
LOG_FILE=""

# 전역 변수 (네임스페이스: __VS_ = Validate System)
__VS___VS_OVERALL_STATUS="PASS"
__VS___VS_CONSISTENCY_SCORE=0
__VS___VS_START_TIME=$(date +%s)
__VS_DOC_RESULTS="{}"
__VS_MIG_RESULTS="{}"
__VS_CROSSREF_RESULTS="{}"

# 사용법 표시
usage() {
    cat << EOF
사용법: $0 [OPTIONS]

문서 및 설치 검증 시스템 - 문서-코드 일관성 및 마이그레이션 검증

옵션:
    --docs-only          문서 검증만 실행
    --migration-only     마이그레이션 검증만 실행
    --crossref-only      교차 참조 검증만 실행
    --dry-run            드라이런 모드 (실제 변경 없음)
    --verbose, -v        상세 출력
    --quiet, -q          최소 출력
    --help, -h           도움말 표시

예시:
    $0                          # 전체 검증
    $0 --docs-only              # 문서만 검증
    $0 --migration-only --dry-run  # 마이그레이션 드라이런
    $0 --verbose                # 상세 출력과 함께 전체 검증

보고서 위치: $REPORT_DIR/
EOF
}

# 인자 파싱
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --docs-only)
                VALIDATION_MODE="docs-only"
                shift
                ;;
            --migration-only)
                VALIDATION_MODE="migration-only"
                shift
                ;;
            --crossref-only)
                VALIDATION_MODE="crossref-only"
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --quiet|-q)
                QUIET=true
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                log_error "알 수 없는 옵션: $1"
                usage
                exit 1
                ;;
        esac
    done

    # quiet와 verbose는 동시 사용 불가
    if [[ "$QUIET" == "true" ]] && [[ "$VERBOSE" == "true" ]]; then
        log_error "--quiet와 --verbose는 동시에 사용할 수 없습니다"
        exit 1
    fi
}

# 헤더 출력
print_header() {
    if [[ "$QUIET" != "true" ]]; then
        echo ""
        echo "╔════════════════════════════════════════╗"
        echo "║   문서 및 설치 검증 시스템            ║"
        echo "║   Documentation & Installation         ║"
        echo "║   Validation System                    ║"
        echo "╚════════════════════════════════════════╝"
        echo ""
    fi
}

# 환경 설정
setup_environment() {
    # 로그 파일 생성
    mkdir -p "$REPORT_DIR"
    LOG_FILE="$REPORT_DIR/validation-$(date +%Y%m%d-%H%M%S).log"
    export LOG_FILE

    if [[ "$VERBOSE" == "true" ]]; then
        log_info "로그 파일: $LOG_FILE"
        log_info "검증 모드: $VALIDATION_MODE"
        log_info "드라이런: $DRY_RUN"
    fi
}

# 문서 검증
run_documentation_validation() {
    log_info "📄 문서 검증 시작..."

    # validate-documentation.sh 로드
    if [[ -f "$SCRIPT_DIR/validate-documentation.sh" ]]; then
        source "$SCRIPT_DIR/validate-documentation.sh"

        # 전체 문서 검증 실행
        local doc_results=$(validate_all_documentation ".claude/commands" 2>&1)

        # JSON 부분만 추출 (마지막 줄)
        local json_result=$(echo "$doc_results" | tail -1)
        __VS_DOC_RESULTS="$json_result"

        # 결과 파싱
        local total=$(parse_json_field "$json_result" "total" "0")
        local passed=$(parse_json_field "$json_result" "passed" "0")
        local avg=$(parse_json_field "$json_result" "avgConsistency" "0")

        log_info "  검증 완료: $passed/$total 통과 (평균 일치율: $avg%)"

        # 일치율 임계값 이상이면 성공
        if [[ $avg -ge $VALIDATION_DOC_THRESHOLD_PASS ]] && [[ $passed -eq $total ]]; then
            return 0
        else
            return 1
        fi
    else
        log_error "validate-documentation.sh 파일 없음"
        return 1
    fi
}

# 마이그레이션 검증
run_migration_validation() {
    log_info "🔄 마이그레이션 검증 시작..."

    # validate-migration.sh 로드
    if [[ -f "$SCRIPT_DIR/validate-migration.sh" ]]; then
        source "$SCRIPT_DIR/validate-migration.sh"

        # 전체 마이그레이션 시나리오 검증
        local mig_results=$(validate_all_migration_scenarios 2>&1)

        # JSON 부분만 추출 (마지막 줄)
        local json_result=$(echo "$mig_results" | tail -1)
        __VS_MIG_RESULTS="$json_result"

        # 결과 파싱
        local total=$(parse_json_field "$json_result" "total" "0")
        local passed=$(parse_json_field "$json_result" "passed" "0")

        log_info "  검증 완료: $passed/$total 시나리오 통과"

        # 모두 통과하면 성공
        if [[ $passed -eq $total ]] && [[ $total -gt 0 ]]; then
            return 0
        else
            return 1
        fi
    else
        log_error "validate-migration.sh 파일 없음"
        return 1
    fi
}

# 교차 참조 검증
run_crossref_validation() {
    log_info "🔗 교차 참조 검증 시작..."

    # validate-crossref.sh 로드
    if [[ -f "$SCRIPT_DIR/validate-crossref.sh" ]]; then
        source "$SCRIPT_DIR/validate-crossref.sh"

        # 전체 교차 참조 검증
        local crossref_results=$(validate_all_cross_references ".claude" 2>&1)

        # JSON 부분만 추출 (마지막 줄)
        local json_result=$(echo "$crossref_results" | tail -1)
        __VS_CROSSREF_RESULTS="$json_result"

        # 결과 파싱
        local total=$(parse_json_field "$json_result" "totalLinks" "0")
        local valid=$(parse_json_field "$json_result" "validLinks" "0")
        local broken=$(parse_json_field "$json_result" "brokenLinks" "0")
        local validity=$(parse_json_field "$json_result" "validity" "100")

        log_info "  검증 완료: $valid/$total 유효 (유효율: $validity%)"

        # 깨진 링크가 없으면 성공
        if [[ $broken -eq 0 ]]; then
            return 0
        else
            return 1
        fi
    else
        log_error "validate-crossref.sh 파일 없음"
        return 1
    fi
}

# 보고서 생성
generate_report() {
    log_info "📊 보고서 생성 중..."

    # report-generator.sh 로드
    if [[ -f "$SCRIPT_DIR/report-generator.sh" ]]; then
        source "$SCRIPT_DIR/report-generator.sh"

        # 검증 결과 수집 (전역 변수에서)
        local doc_results="${__VS_DOC_RESULTS:-{}}"
        local mig_results="${__VS_MIG_RESULTS:-{}}"
        local crossref_results="${__VS_CROSSREF_RESULTS:-{}}"

        # 보고서 생성 (계산된 전체 상태 및 일관성 점수 전달)
        save_report_to_file "$doc_results" "$mig_results" "$crossref_results" "$REPORT_DIR" "$__VS_OVERALL_STATUS" "$__VS_CONSISTENCY_SCORE"

        return 0
    else
        log_warning "report-generator.sh 파일 없음 - 보고서 생성 건너뜀"
        return 0
    fi
}

# 결과 요약
print_summary() {
    if [[ "$QUIET" == "true" ]]; then
        return
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "📊 검증 결과 요약"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # 실행 시간 계산
    local end_time=$(date +%s)
    local duration=$((end_time - __VS_START_TIME))

    echo "  전체 상태: $__VS_OVERALL_STATUS"
    echo "  일관성 점수: $__VS_CONSISTENCY_SCORE/100"
    echo "  실행 시간: ${duration}초"
    echo ""

    if [[ "$__VS_OVERALL_STATUS" == "PASS" ]]; then
        log_success "✅ 모든 검증 통과"
    elif [[ "$__VS_OVERALL_STATUS" == "WARNING" ]]; then
        log_warning "⚠️  일부 경고 발견"
    else
        log_error "❌ 검증 실패"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# 메인 함수
main() {
    # 인자 파싱
    parse_arguments "$@"

    # 헤더 출력
    print_header

    # 환경 설정
    setup_environment

    # 전제조건 검증
    if [[ "$VERBOSE" == "true" ]]; then
        validate_prerequisites || log_warning "일부 전제조건 미충족 (계속 진행)"
        echo ""
    fi

    # 검증 실행 (각 검증의 실패를 기록하되 계속 진행)
    # 에러 수집 모드: set -e를 비활성화하여 모든 검증을 실행
    set +e

    local doc_status=0
    local mig_status=0
    local ref_status=0

    case "$VALIDATION_MODE" in
        "docs-only")
            run_documentation_validation
            doc_status=$?
            ;;
        "migration-only")
            run_migration_validation
            mig_status=$?
            ;;
        "crossref-only")
            run_crossref_validation
            ref_status=$?
            ;;
        "all")
            run_documentation_validation
            doc_status=$?
            echo ""
            run_migration_validation
            mig_status=$?
            echo ""
            run_crossref_validation
            ref_status=$?
            ;;
    esac

    # 에러 수집 완료 후 set -e 재활성화
    set -e

    # 일관성 점수 계산 (문서 + 교차참조 평균)
    local doc_avg=$(parse_json_field "$__VS_DOC_RESULTS" "avgConsistency" "0")
    local ref_validity=$(parse_json_field "$__VS_CROSSREF_RESULTS" "validity" "100")

    __VS_CONSISTENCY_SCORE=$(( (doc_avg + ref_validity) / 2 ))

    # 전체 상태 결정
    if [[ $doc_status -ne 0 ]] || [[ $mig_status -ne 0 ]] || [[ $ref_status -ne 0 ]]; then
        # 검증 실패가 있지만 일관성 점수가 높으면 WARNING
        if [[ $__VS_CONSISTENCY_SCORE -ge $VALIDATION_CONSISTENCY_THRESHOLD_WARNING ]] && [[ $mig_status -eq 0 ]]; then
            __VS_OVERALL_STATUS="WARNING"
        else
            __VS_OVERALL_STATUS="FAIL"
        fi
    fi

    echo ""

    # 보고서 생성
    generate_report

    # 결과 요약
    print_summary

    # 종료 코드 반환
    if [[ "$__VS_OVERALL_STATUS" == "PASS" ]]; then
        return 0
    elif [[ "$__VS_OVERALL_STATUS" == "WARNING" ]]; then
        return 2
    else
        return 1
    fi
}

# 스크립트 실행
main "$@"
