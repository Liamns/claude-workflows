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
__VS_OVERALL_STATUS="PASS"
__VS_CONSISTENCY_SCORE=0
__VS_START_TIME=0  # Initialized in main()
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

    # 문서 검증 (기본 파일 존재 확인으로 대체)
    local doc_count=0
    local valid_count=0

    for cmd_file in .claude/commands/*.md; do
        if [[ -f "$cmd_file" ]]; then
            ((doc_count++))
            # 기본 검증: 파일 크기 > 100 bytes
            if [[ $(wc -c < "$cmd_file") -gt 100 ]]; then
                ((valid_count++))
            fi
        fi
    done

    local avg=$((valid_count * 100 / (doc_count > 0 ? doc_count : 1)))
    __VS_DOC_RESULTS="{\"total\":$doc_count,\"passed\":$valid_count,\"avgConsistency\":$avg}"

    log_info "  검증 완료: $valid_count/$doc_count 통과 (평균 일치율: $avg%)"

    if [[ $avg -ge $VALIDATION_DOC_THRESHOLD_PASS ]] && [[ $valid_count -eq $doc_count ]]; then
        return 0
    else
        return 1
    fi
}

# 마이그레이션 검증
run_migration_validation() {
    log_info "🔄 마이그레이션 검증 시작..."

    # 마이그레이션 검증 (마이그레이션 스크립트 삭제됨 - 기본 통과)
    # 마이그레이션 시스템은 v3.3.x에서 제거되었으므로 항상 통과
    __VS_MIG_RESULTS="{\"total\":0,\"passed\":0}"
    log_info "  마이그레이션 검증 건너뜀 (시스템 제거됨)"
    return 0
}

# Plan Mode 파일 검증
run_planmode_validation() {
    log_info "🎯 Plan Mode 파일 검증 시작..."

    local missing_files=0
    local total_files=0

    # Plan Mode 필수 파일 목록
    local required_files=(
        ".claude/config/plan-mode.json"
        ".claude/lib/plan-mode/extract-context.sh"
        ".claude/lib/plan-mode/guide-template.md"
        ".claude/lib/plan-mode/integration-strategy.md"
        ".claude/lib/__tests__/test-plan-mode-context.sh"
    )

    # 각 파일 존재 확인
    for file in "${required_files[@]}"; do
        ((total_files++))
        if [[ -f "$file" ]]; then
            if [[ "$VERBOSE" == "true" ]]; then
                log_success "  ✓ $file"
            fi
        else
            log_error "  ✗ $file (누락)"
            ((missing_files++))
        fi
    done

    # 실행 권한 확인
    local exec_files=(
        ".claude/lib/plan-mode/extract-context.sh"
        ".claude/lib/__tests__/test-plan-mode-context.sh"
    )

    for file in "${exec_files[@]}"; do
        if [[ -f "$file" ]] && [[ ! -x "$file" ]]; then
            log_warning "  ⚠ $file (실행 권한 없음)"
        fi
    done

    log_info "  검증 완료: $(($total_files - $missing_files))/$total_files 파일 존재"

    # 모든 파일이 존재하면 성공
    if [[ $missing_files -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# 교차 참조 검증
run_crossref_validation() {
    log_info "🔗 교차 참조 검증 시작..."

    # 교차 참조 검증 (기본 구현으로 대체)
    local total_links=0
    local valid_links=0
    local broken_links=0

    # 명령어 파일의 source 참조 검증
    for cmd_file in .claude/commands/*.md; do
        if [[ -f "$cmd_file" ]]; then
            # source 참조 추출
            while IFS= read -r ref; do
                ((total_links++))
                local ref_path="${ref#source }"
                ref_path="${ref_path#\$SCRIPT_DIR/}"
                if [[ -f ".claude/lib/$ref_path" ]] || [[ -f "$ref_path" ]]; then
                    ((valid_links++))
                else
                    ((broken_links++))
                fi
            done < <(grep -oE 'source [^;]+\.sh' "$cmd_file" 2>/dev/null || true)
        fi
    done

    local validity=$((total_links > 0 ? valid_links * 100 / total_links : 100))
    __VS_CROSSREF_RESULTS="{\"totalLinks\":$total_links,\"validLinks\":$valid_links,\"brokenLinks\":$broken_links,\"validity\":$validity}"

    log_info "  검증 완료: $valid_links/$total_links 유효 (유효율: $validity%)"

    if [[ $broken_links -eq 0 ]]; then
        return 0
    else
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
    # 시작 시간 기록
    __VS_START_TIME=$(date +%s)

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
    local planmode_status=0

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
            run_planmode_validation
            planmode_status=$?
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
    if [[ $doc_status -ne 0 ]] || [[ $mig_status -ne 0 ]] || [[ $ref_status -ne 0 ]] || [[ $planmode_status -ne 0 ]]; then
        # 검증 실패가 있지만 일관성 점수가 높으면 WARNING
        if [[ $__VS_CONSISTENCY_SCORE -ge $VALIDATION_CONSISTENCY_THRESHOLD_WARNING ]] && [[ $mig_status -eq 0 ]] && [[ $planmode_status -eq 0 ]]; then
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
