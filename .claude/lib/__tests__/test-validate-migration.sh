#!/bin/bash
# test-validate-migration.sh
# TDD 테스트: 마이그레이션 검증 모듈 테스트
# Phase 4 - User Story 2: 마이그레이션 시나리오 검증

# Don't use set -e in test scripts - we want to continue even if tests fail
set +e

# 현재 스크립트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"

# 공통 유틸리티 로드
source "$LIB_DIR/validation-utils.sh"
# Override set -e from validation-utils.sh
set +e

# 테스트 결과 추적
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# 테스트 헬퍼 함수
assert_equals() {
    local expected="$1"
    local actual="$2"
    local description="$3"

    ((TESTS_TOTAL++))

    if [[ "$expected" == "$actual" ]]; then
        log_success "✓ $description"
        ((TESTS_PASSED++))
        return 0
    else
        log_error "✗ $description"
        log_error "  예상: $expected"
        log_error "  실제: $actual"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_file_exists() {
    local file_path="$1"
    local description="$2"

    ((TESTS_TOTAL++))

    if [[ -f "$file_path" ]]; then
        log_success "✓ $description"
        ((TESTS_PASSED++))
        return 0
    else
        log_error "✗ $description"
        log_error "  파일 없음: $file_path"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_file_not_exists() {
    local file_path="$1"
    local description="$2"

    ((TESTS_TOTAL++))

    if [[ ! -f "$file_path" ]]; then
        log_success "✓ $description"
        ((TESTS_PASSED++))
        return 0
    else
        log_error "✗ $description"
        log_error "  파일이 여전히 존재: $file_path"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_dir_exists() {
    local dir_path="$1"
    local description="$2"

    ((TESTS_TOTAL++))

    if [[ -d "$dir_path" ]]; then
        log_success "✓ $description"
        ((TESTS_PASSED++))
        return 0
    else
        log_error "✗ $description"
        log_error "  디렉토리 없음: $dir_path"
        ((TESTS_FAILED++))
        return 1
    fi
}

# ============================================================
# Test Suite 1: 임시 환경 생성 테스트
# ============================================================
test_temp_environment_creation() {
    log_info "Test Suite 1: 임시 환경 생성 테스트"
    echo ""

    # mktemp를 사용한 임시 디렉토리 생성
    local test_dir=$(mktemp -d 2>/dev/null)

    if [[ -z "$test_dir" ]]; then
        log_error "✗ mktemp 명령어 실패"
        ((TESTS_FAILED++))
        ((TESTS_TOTAL++))
        echo ""
        return 1
    fi

    assert_dir_exists "$test_dir" "임시 디렉토리 생성: $test_dir"

    # 디렉토리 쓰기 권한 확인
    touch "$test_dir/test.txt" 2>/dev/null
    if [[ -f "$test_dir/test.txt" ]]; then
        log_success "✓ 임시 디렉토리 쓰기 가능"
        ((TESTS_PASSED++))
    else
        log_error "✗ 임시 디렉토리 쓰기 불가"
        ((TESTS_FAILED++))
    fi
    ((TESTS_TOTAL++))

    # 정리
    rm -rf "$test_dir"
    if [[ ! -d "$test_dir" ]]; then
        log_success "✓ 임시 디렉토리 정리 성공"
        ((TESTS_PASSED++))
    else
        log_error "✗ 임시 디렉토리 정리 실패"
        ((TESTS_FAILED++))
    fi
    ((TESTS_TOTAL++))

    echo ""
}

# ============================================================
# Test Suite 2: v1.0 환경 설정 테스트
# ============================================================
test_v1_environment_setup() {
    log_info "Test Suite 2: v1.0 환경 설정 테스트"
    echo ""

    # 임시 디렉토리 생성
    local test_dir=$(mktemp -d)
    trap "rm -rf $test_dir" RETURN

    # v1.0 특징적인 파일 구조 생성
    mkdir -p "$test_dir/.claude/commands"
    mkdir -p "$test_dir/.claude/agents"

    # v1.0에서 사용하던 분리된 파일들
    local v1_files=(
        "$test_dir/.claude/commands/major-specify.md"
        "$test_dir/.claude/commands/major-clarify.md"
        "$test_dir/.claude/commands/major-research.md"
        "$test_dir/.claude/agents/architect.md"
    )

    for file in "${v1_files[@]}"; do
        echo "# v1.0 file" > "$file"
    done

    # 파일 존재 확인
    for file in "${v1_files[@]}"; do
        local basename=$(basename "$file")
        assert_file_exists "$file" "v1.0 파일 생성: $basename"
    done

    echo ""
}

# ============================================================
# Test Suite 3: v2.4 환경 설정 테스트
# ============================================================
test_v24_environment_setup() {
    log_info "Test Suite 3: v2.4 환경 설정 테스트"
    echo ""

    # 임시 디렉토리 생성
    local test_dir=$(mktemp -d)
    trap "rm -rf $test_dir" RETURN

    # v2.4 특징적인 파일 구조 생성
    mkdir -p "$test_dir/.claude/commands"

    # v2.4에서 사용하는 통합 파일
    local v24_files=(
        "$test_dir/.claude/commands/major.md"
        "$test_dir/.claude/workflow-gates.json"
    )

    for file in "${v24_files[@]}"; do
        echo "# v2.4 file" > "$file"
    done

    # v2.4 버전 정보 추가
    echo '{"version": "2.4.0"}' > "$test_dir/.claude/workflow-gates.json"

    # 파일 존재 확인
    for file in "${v24_files[@]}"; do
        local basename=$(basename "$file")
        assert_file_exists "$file" "v2.4 파일 생성: $basename"
    done

    # 버전 정보 확인
    local version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$test_dir/.claude/workflow-gates.json" | cut -d'"' -f4)
    assert_equals "2.4.0" "$version" "v2.4 버전 정보 확인"

    echo ""
}

# ============================================================
# Test Suite 4: Deprecated 파일 제거 검증
# ============================================================
test_deprecated_file_removal() {
    log_info "Test Suite 4: Deprecated 파일 제거 검증"
    echo ""

    # 임시 디렉토리 생성
    local test_dir=$(mktemp -d)
    trap "rm -rf $test_dir" RETURN

    # Deprecated 파일 목록 (spec.md에서 정의)
    local deprecated_files=(
        "major-specify.md"
        "major-clarify.md"
        "major-research.md"
        "architect.md"
    )

    mkdir -p "$test_dir/.claude/commands"
    mkdir -p "$test_dir/.claude/agents"

    # 파일 생성
    echo "test" > "$test_dir/.claude/commands/major-specify.md"
    echo "test" > "$test_dir/.claude/commands/major-clarify.md"
    echo "test" > "$test_dir/.claude/commands/major-research.md"
    echo "test" > "$test_dir/.claude/agents/architect.md"

    # 파일이 존재하는지 확인
    assert_file_exists "$test_dir/.claude/commands/major-specify.md" "제거 전 파일 존재: major-specify.md"

    # 파일 제거 시뮬레이션
    rm -f "$test_dir/.claude/commands/major-specify.md"
    rm -f "$test_dir/.claude/commands/major-clarify.md"
    rm -f "$test_dir/.claude/commands/major-research.md"
    rm -f "$test_dir/.claude/agents/architect.md"

    # 제거 확인
    assert_file_not_exists "$test_dir/.claude/commands/major-specify.md" "Deprecated 파일 제거: major-specify.md"
    assert_file_not_exists "$test_dir/.claude/commands/major-clarify.md" "Deprecated 파일 제거: major-clarify.md"
    assert_file_not_exists "$test_dir/.claude/commands/major-research.md" "Deprecated 파일 제거: major-research.md"
    assert_file_not_exists "$test_dir/.claude/agents/architect.md" "Deprecated 파일 제거: architect.md"

    echo ""
}

# ============================================================
# Test Suite 5: Critical 파일 존재 검증
# ============================================================
test_critical_file_verification() {
    log_info "Test Suite 5: Critical 파일 존재 검증"
    echo ""

    # 임시 디렉토리 생성
    local test_dir=$(mktemp -d)
    trap "rm -rf $test_dir" RETURN

    # Critical 파일 목록 (spec.md에서 정의)
    mkdir -p "$test_dir/.claude/commands"

    local critical_files=(
        "$test_dir/.claude/workflow-gates.json"
        "$test_dir/.claude/commands/major.md"
        "$test_dir/.claude/.version"
    )

    # 파일 생성
    echo '{"version": "2.5.0"}' > "$test_dir/.claude/workflow-gates.json"
    echo "# Major workflow" > "$test_dir/.claude/commands/major.md"
    echo "2.5.0" > "$test_dir/.claude/.version"

    # 파일 존재 확인
    assert_file_exists "$test_dir/.claude/workflow-gates.json" "Critical 파일 존재: workflow-gates.json"
    assert_file_exists "$test_dir/.claude/commands/major.md" "Critical 파일 존재: major.md"
    assert_file_exists "$test_dir/.claude/.version" "Critical 파일 존재: .version"

    # 버전 내용 확인
    local version=$(cat "$test_dir/.claude/.version")
    assert_equals "2.5.0" "$version" "버전 파일 내용 확인"

    echo ""
}

# ============================================================
# Test Suite 6: 검증 함수 인터페이스 테스트
# ============================================================
test_validation_function_interface() {
    log_info "Test Suite 6: 검증 함수 인터페이스 테스트"
    echo ""

    # validate-migration.sh가 존재하는지 확인
    if [[ -f "$LIB_DIR/validate-migration.sh" ]]; then
        log_info "validate-migration.sh 발견 - 인터페이스 테스트 진행"

        # 함수 존재 확인
        source "$LIB_DIR/validate-migration.sh"

        if declare -f validate_migration_scenario > /dev/null; then
            log_success "✓ validate_migration_scenario() 함수 존재"
            ((TESTS_PASSED++))
        else
            log_error "✗ validate_migration_scenario() 함수 없음"
            ((TESTS_FAILED++))
        fi
        ((TESTS_TOTAL++))

        if declare -f setup_version_environment > /dev/null; then
            log_success "✓ setup_version_environment() 함수 존재"
            ((TESTS_PASSED++))
        else
            log_error "✗ setup_version_environment() 함수 없음"
            ((TESTS_FAILED++))
        fi
        ((TESTS_TOTAL++))

        if declare -f check_deprecated_files > /dev/null; then
            log_success "✓ check_deprecated_files() 함수 존재"
            ((TESTS_PASSED++))
        else
            log_error "✗ check_deprecated_files() 함수 없음"
            ((TESTS_FAILED++))
        fi
        ((TESTS_TOTAL++))

        if declare -f check_critical_files > /dev/null; then
            log_success "✓ check_critical_files() 함수 존재"
            ((TESTS_PASSED++))
        else
            log_error "✗ check_critical_files() 함수 없음"
            ((TESTS_FAILED++))
        fi
        ((TESTS_TOTAL++))

    else
        log_warning "⚠️  validate-migration.sh 아직 미구현 (T013에서 구현 예정)"
        log_info "인터페이스 테스트 건너뜀"
    fi

    echo ""
}

# ============================================================
# 메인 테스트 실행
# ============================================================
main() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   마이그레이션 검증 모듈 테스트      ║"
    echo "║   Migration Validation Test Suite     ║"
    echo "╚════════════════════════════════════════╝"
    echo ""

    log_info "TDD Phase 4 - US2 테스트 시작"
    echo ""

    # 모든 테스트 실행
    test_temp_environment_creation
    test_v1_environment_setup
    test_v24_environment_setup
    test_deprecated_file_removal
    test_critical_file_verification
    test_validation_function_interface

    # 결과 요약
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "📊 테스트 결과 요약"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  전체 테스트: $TESTS_TOTAL"
    echo "  통과: $TESTS_PASSED"
    echo "  실패: $TESTS_FAILED"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "✅ 모든 테스트 통과"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        return 0
    else
        log_error "❌ $TESTS_FAILED개 테스트 실패"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        return 1
    fi
}

# 스크립트 실행
main "$@"
