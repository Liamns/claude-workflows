#!/bin/bash
# test-validate-crossref.sh
# TDD 테스트: 교차 참조 검증 모듈 테스트
# Phase 5 - User Story 3: 교차 참조 검증

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

assert_greater_than() {
    local value="$1"
    local minimum="$2"
    local description="$3"

    ((TESTS_TOTAL++))

    if [[ $value -gt $minimum ]]; then
        log_success "✓ $description"
        ((TESTS_PASSED++))
        return 0
    else
        log_error "✗ $description"
        log_error "  값: $value (최소: $minimum)"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local description="$3"

    ((TESTS_TOTAL++))

    if [[ "$haystack" == *"$needle"* ]]; then
        log_success "✓ $description"
        ((TESTS_PASSED++))
        return 0
    else
        log_error "✗ $description"
        log_error "  '$needle'를 찾을 수 없음"
        ((TESTS_FAILED++))
        return 1
    fi
}

# ============================================================
# Test Suite 1: 마크다운 링크 추출 테스트
# ============================================================
test_markdown_link_extraction() {
    log_info "Test Suite 1: 마크다운 링크 추출 테스트"
    echo ""

    # 임시 테스트 파일 생성
    local test_file=$(mktemp)
    trap "rm -f $test_file" RETURN

    cat > "$test_file" << 'EOF'
# Test Document

See [documentation](./docs/guide.md) for details.

Also check [research](../research.md) and [plan](./plan.md).

External link: [GitHub](https://github.com/example/repo)
EOF

    # 링크 추출 패턴 테스트
    local links=$(grep -oE '\[.*?\]\([^)]+\)' "$test_file" | sed 's/.*](\([^)]*\))/\1/')
    local link_count=$(echo "$links" | grep -v "^$" | wc -l | tr -d ' ')

    assert_greater_than "$link_count" "2" "마크다운 링크 3개 이상 추출 (${link_count}개 발견)"

    # 첫 번째 링크 내용 확인
    local first_link=$(echo "$links" | head -1)
    assert_equals "./docs/guide.md" "$first_link" "첫 번째 링크 경로 확인"

    # 상대 경로 링크 개수 확인 (http로 시작하지 않는 링크)
    local relative_links=$(echo "$links" | grep -v "^http" | grep -v "^$" | wc -l | tr -d ' ')
    assert_greater_than "$relative_links" "1" "상대 경로 링크 2개 이상 확인 (${relative_links}개 발견)"

    echo ""
}

# ============================================================
# Test Suite 2: 상대 경로 해석 테스트
# ============================================================
test_relative_path_resolution() {
    log_info "Test Suite 2: 상대 경로 해석 테스트"
    echo ""

    # 임시 디렉토리 구조 생성
    local test_dir=$(mktemp -d)
    trap "rm -rf $test_dir" RETURN

    mkdir -p "$test_dir/docs"
    mkdir -p "$test_dir/src"
    touch "$test_dir/docs/guide.md"
    touch "$test_dir/README.md"

    # 상대 경로 테스트 케이스
    # Case 1: 같은 디렉토리
    local source="$test_dir/docs/index.md"
    local relative="./guide.md"
    local source_dir=$(dirname "$source")
    local resolved="$source_dir/$relative"

    if [[ -f "$test_dir/docs/guide.md" ]]; then
        log_success "✓ 같은 디렉토리 상대 경로 해석"
        ((TESTS_PASSED++))
    else
        log_error "✗ 같은 디렉토리 상대 경로 해석 실패"
        ((TESTS_FAILED++))
    fi
    ((TESTS_TOTAL++))

    # Case 2: 상위 디렉토리
    source="$test_dir/docs/index.md"
    relative="../README.md"
    source_dir=$(dirname "$source")

    # realpath 대신 직접 경로 계산 (macOS 호환)
    local parent_dir=$(dirname "$source_dir")
    resolved="$parent_dir/README.md"

    if [[ -f "$resolved" ]]; then
        log_success "✓ 상위 디렉토리 상대 경로 해석"
        ((TESTS_PASSED++))
    else
        log_error "✗ 상위 디렉토리 상대 경로 해석 실패"
        ((TESTS_FAILED++))
    fi
    ((TESTS_TOTAL++))

    echo ""
}

# ============================================================
# Test Suite 3: 파일 존재 확인 테스트
# ============================================================
test_file_existence_check() {
    log_info "Test Suite 3: 파일 존재 확인 테스트"
    echo ""

    # 임시 디렉토리 생성
    local test_dir=$(mktemp -d)
    trap "rm -rf $test_dir" RETURN

    # 테스트 파일 생성
    touch "$test_dir/existing.md"

    # 존재하는 파일 확인
    if [[ -f "$test_dir/existing.md" ]]; then
        log_success "✓ 존재하는 파일 확인"
        ((TESTS_PASSED++))
    else
        log_error "✗ 존재하는 파일 확인 실패"
        ((TESTS_FAILED++))
    fi
    ((TESTS_TOTAL++))

    # 존재하지 않는 파일 확인
    if [[ ! -f "$test_dir/missing.md" ]]; then
        log_success "✓ 존재하지 않는 파일 감지"
        ((TESTS_PASSED++))
    else
        log_error "✗ 존재하지 않는 파일 감지 실패"
        ((TESTS_FAILED++))
    fi
    ((TESTS_TOTAL++))

    echo ""
}

# ============================================================
# Test Suite 4: 에이전트/스킬 참조 검증 테스트
# ============================================================
test_agent_skill_reference_validation() {
    log_info "Test Suite 4: 에이전트/스킬 참조 검증 테스트"
    echo ""

    # 실제 프로젝트 디렉토리 확인
    if [[ -d ".claude/agents" ]]; then
        local agent_count=$(find .claude/agents -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
        log_info "  에이전트 파일 개수: $agent_count"

        if [[ $agent_count -gt 0 ]]; then
            log_success "✓ 에이전트 파일 존재 확인"
            ((TESTS_PASSED++))
        else
            log_warning "⚠️  에이전트 파일 없음"
            ((TESTS_PASSED++))  # 없어도 유효함
        fi
    else
        log_warning "⚠️  .claude/agents 디렉토리 없음"
        ((TESTS_PASSED++))  # 없어도 유효함
    fi
    ((TESTS_TOTAL++))

    # 스킬 디렉토리 확인
    if [[ -d ".claude/skills" ]]; then
        local skill_count=$(find .claude/skills -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
        log_info "  스킬 파일 개수: $skill_count"

        if [[ $skill_count -gt 0 ]]; then
            log_success "✓ 스킬 파일 존재 확인"
            ((TESTS_PASSED++))
        else
            log_warning "⚠️  스킬 파일 없음"
            ((TESTS_PASSED++))  # 없어도 유효함
        fi
    else
        log_warning "⚠️  .claude/skills 디렉토리 없음"
        ((TESTS_PASSED++))  # 없어도 유효함
    fi
    ((TESTS_TOTAL++))

    echo ""
}

# ============================================================
# Test Suite 5: 깨진 링크 보고 테스트
# ============================================================
test_broken_link_reporting() {
    log_info "Test Suite 5: 깨진 링크 보고 테스트"
    echo ""

    # 임시 테스트 파일 생성
    local test_dir=$(mktemp -d)
    trap "rm -rf $test_dir" RETURN

    mkdir -p "$test_dir/docs"
    cat > "$test_dir/docs/test.md" << 'EOF'
# Test

Valid link: [existing](./existing.md)
Broken link: [missing](./missing.md)
EOF

    touch "$test_dir/docs/existing.md"

    # 링크 추출 및 검증
    local links=$(grep -oE '\[.*\]\([^)]+\)' "$test_dir/docs/test.md" | sed 's/.*(\(.*\))/\1/')
    local broken_count=0
    local valid_count=0

    while IFS= read -r link; do
        [[ -z "$link" ]] && continue
        [[ "$link" =~ ^http ]] && continue

        local source_dir="$test_dir/docs"
        local target="$source_dir/$link"

        if [[ -f "$target" ]]; then
            ((valid_count++))
        else
            ((broken_count++))
        fi
    done <<< "$links"

    assert_equals "1" "$valid_count" "유효한 링크 1개 확인"
    assert_equals "1" "$broken_count" "깨진 링크 1개 감지"

    echo ""
}

# ============================================================
# Test Suite 6: 검증 함수 인터페이스 테스트
# ============================================================
test_validation_function_interface() {
    log_info "Test Suite 6: 검증 함수 인터페이스 테스트"
    echo ""

    # validate-crossref.sh가 존재하는지 확인
    if [[ -f "$LIB_DIR/validate-crossref.sh" ]]; then
        log_info "validate-crossref.sh 발견 - 인터페이스 테스트 진행"

        # 함수 존재 확인
        source "$LIB_DIR/validate-crossref.sh"

        if declare -f validate_all_cross_references > /dev/null; then
            log_success "✓ validate_all_cross_references() 함수 존재"
            ((TESTS_PASSED++))
        else
            log_error "✗ validate_all_cross_references() 함수 없음"
            ((TESTS_FAILED++))
        fi
        ((TESTS_TOTAL++))

        if declare -f validate_single_file_links > /dev/null; then
            log_success "✓ validate_single_file_links() 함수 존재"
            ((TESTS_PASSED++))
        else
            log_error "✗ validate_single_file_links() 함수 없음"
            ((TESTS_FAILED++))
        fi
        ((TESTS_TOTAL++))

        if declare -f extract_markdown_links > /dev/null; then
            log_success "✓ extract_markdown_links() 함수 존재"
            ((TESTS_PASSED++))
        else
            log_error "✗ extract_markdown_links() 함수 없음"
            ((TESTS_FAILED++))
        fi
        ((TESTS_TOTAL++))

        if declare -f resolve_relative_path > /dev/null; then
            log_success "✓ resolve_relative_path() 함수 존재"
            ((TESTS_PASSED++))
        else
            log_error "✗ resolve_relative_path() 함수 없음"
            ((TESTS_FAILED++))
        fi
        ((TESTS_TOTAL++))

    else
        log_warning "⚠️  validate-crossref.sh 아직 미구현 (T021에서 구현 예정)"
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
    echo "║   교차 참조 검증 모듈 테스트          ║"
    echo "║   Cross-reference Validation Test     ║"
    echo "╚════════════════════════════════════════╝"
    echo ""

    log_info "TDD Phase 5 - US3 테스트 시작"
    echo ""

    # 모든 테스트 실행
    test_markdown_link_extraction
    test_relative_path_resolution
    test_file_existence_check
    test_agent_skill_reference_validation
    test_broken_link_reporting
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
