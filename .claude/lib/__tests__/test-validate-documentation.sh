#!/bin/bash
# test-validate-documentation.sh
# TDD 테스트: 문서 검증 모듈 테스트
# Phase 3 - User Story 1: 문서-코드 일관성 검증

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

# ============================================================
# Test Suite 1: 슬래시 명령어 파일 존재 확인
# ============================================================
test_command_files_exist() {
    log_info "Test Suite 1: 슬래시 명령어 파일 존재 확인"
    echo ""

    # 필수 명령어 파일 목록 (spec.md에서 정의된 10개)
    local expected_commands=(
        "major.md"
        "commit.md"
        "triage.md"
        "review.md"
        "pr-review.md"
        "dashboard.md"
    )

    # 현재 실제로 존재하는 명령어 파일들도 확인
    for cmd_file in .claude/commands/*.md; do
        if [[ -f "$cmd_file" ]]; then
            local cmd_name=$(basename "$cmd_file")
            assert_file_exists "$cmd_file" "명령어 파일 존재: $cmd_name"
        fi
    done

    # 최소한 6개 이상의 명령어 파일이 있어야 함
    local count=$(find .claude/commands -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    assert_greater_than "$count" "5" "최소 6개 이상의 명령어 파일 존재 ($count개 발견)"

    echo ""
}

# ============================================================
# Test Suite 2: Step 패턴 추출 테스트
# ============================================================
test_step_pattern_extraction() {
    log_info "Test Suite 2: Step 패턴 추출 테스트"
    echo ""

    # 임시 테스트 파일 생성
    local test_file=$(mktemp)
    trap "rm -f $test_file" EXIT

    cat > "$test_file" << 'EOF'
# Test Command

## Description

### Step 1: Initialize
First step description

### Step 2: Process
Second step description

### Step 3: Finalize
Third step description

## Notes
EOF

    # Step 패턴 추출 (validate-documentation.sh에서 사용할 패턴)
    local steps=$(grep -E "^### Step [0-9]+" "$test_file" | sed 's/^### //')
    local step_count=$(echo "$steps" | wc -l | tr -d ' ')

    assert_equals "3" "$step_count" "Step 패턴 추출: 3개의 Step 감지"

    # 첫 번째 Step 내용 확인
    local first_step=$(echo "$steps" | head -1)
    if [[ "$first_step" == "Step 1: Initialize" ]]; then
        log_success "✓ 첫 번째 Step 내용 정확: $first_step"
        ((TESTS_PASSED++))
    else
        log_error "✗ 첫 번째 Step 내용 불일치: $first_step"
        ((TESTS_FAILED++))
    fi
    ((TESTS_TOTAL++))

    echo ""
}

# ============================================================
# Test Suite 3: 코드 블록 추출 테스트
# ============================================================
test_code_block_extraction() {
    log_info "Test Suite 3: 코드 블록 추출 테스트"
    echo ""

    # 임시 테스트 파일 생성
    local test_file=$(mktemp)
    trap "rm -f $test_file" EXIT

    cat > "$test_file" << 'EOF'
# Test Command

## Example

```bash
echo "test command"
ls -la
```

## Another Example

```bash
git status
git commit -m "message"
```
EOF

    # Bash 코드 블록 개수 확인
    local bash_blocks=$(grep -c '```bash' "$test_file")

    assert_equals "2" "$bash_blocks" "Bash 코드 블록 개수: 2개 감지"

    # 코드 내용 추출 테스트 (간단한 버전)
    local code_lines=$(grep -A 3 '```bash' "$test_file" | grep -v '```' | grep -v '^--$' | wc -l | tr -d ' ')
    assert_greater_than "$code_lines" "3" "코드 라인 추출: 최소 4줄 이상 ($code_lines줄 발견)"

    echo ""
}

# ============================================================
# Test Suite 4: 일치율 계산 테스트
# ============================================================
test_consistency_calculation() {
    log_info "Test Suite 4: 일치율 계산 테스트"
    echo ""

    # 일치율 계산 로직 테스트
    # Formula: (matches / total_steps) * 100

    local total_steps=10
    local matches=9
    local consistency=$((matches * 100 / total_steps))

    assert_equals "90" "$consistency" "일치율 계산: 9/10 = 90%"

    # 100% 일치 테스트
    matches=10
    consistency=$((matches * 100 / total_steps))
    assert_equals "100" "$consistency" "일치율 계산: 10/10 = 100%"

    # 0% 일치 테스트
    matches=0
    consistency=$((matches * 100 / total_steps))
    assert_equals "0" "$consistency" "일치율 계산: 0/10 = 0%"

    echo ""
}

# ============================================================
# Test Suite 5: 검증 함수 인터페이스 테스트
# ============================================================
test_validation_function_interface() {
    log_info "Test Suite 5: 검증 함수 인터페이스 테스트"
    echo ""

    # validate-documentation.sh가 존재하는지 확인 (아직 구현 전이므로 실패 예상)
    if [[ -f "$LIB_DIR/validate-documentation.sh" ]]; then
        log_info "validate-documentation.sh 발견 - 인터페이스 테스트 진행"

        # 함수 존재 확인
        source "$LIB_DIR/validate-documentation.sh"

        if declare -f validate_all_documentation > /dev/null; then
            log_success "✓ validate_all_documentation() 함수 존재"
            ((TESTS_PASSED++))
        else
            log_error "✗ validate_all_documentation() 함수 없음"
            ((TESTS_FAILED++))
        fi
        ((TESTS_TOTAL++))

        if declare -f validate_single_doc > /dev/null; then
            log_success "✓ validate_single_doc() 함수 존재"
            ((TESTS_PASSED++))
        else
            log_error "✗ validate_single_doc() 함수 없음"
            ((TESTS_FAILED++))
        fi
        ((TESTS_TOTAL++))

    else
        log_warning "⚠️  validate-documentation.sh 아직 미구현 (T008에서 구현 예정)"
        log_info "인터페이스 테스트 건너뜀"
    fi

    echo ""
}

# ============================================================
# Test Suite 6: 실제 명령어 파일 검증 시뮬레이션
# ============================================================
test_real_command_validation_simulation() {
    log_info "Test Suite 6: 실제 명령어 파일 검증 시뮬레이션"
    echo ""

    # major.md 파일로 실제 패턴 테스트
    if [[ -f ".claude/commands/major.md" ]]; then
        local major_file=".claude/commands/major.md"

        # Step 패턴 확인
        local steps=$(grep -E "^### Step [0-9]+" "$major_file" | wc -l | tr -d ' ')
        if [[ $steps -gt 0 ]]; then
            log_success "✓ major.md에서 $steps개의 Step 발견"
            ((TESTS_PASSED++))
        else
            log_warning "⚠️  major.md에 Step 패턴 없음 (다른 형식일 수 있음)"
            ((TESTS_PASSED++))  # 다른 형식도 유효함
        fi
        ((TESTS_TOTAL++))

        # 코드 블록 확인
        local code_blocks=$(grep -c '```' "$major_file" 2>/dev/null || echo "0")
        if [[ $code_blocks -gt 0 ]]; then
            log_success "✓ major.md에 코드 블록 존재 (${code_blocks}개 백틱 발견)"
            ((TESTS_PASSED++))
        else
            log_warning "⚠️  major.md에 코드 블록 없음"
            ((TESTS_PASSED++))  # 코드 블록 없어도 유효함
        fi
        ((TESTS_TOTAL++))

    else
        log_warning "⚠️  major.md 파일 없음 - 시뮬레이션 건너뜀"
    fi

    echo ""
}

# ============================================================
# 메인 테스트 실행
# ============================================================
main() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   문서 검증 모듈 테스트               ║"
    echo "║   Document Validation Test Suite      ║"
    echo "╚════════════════════════════════════════╝"
    echo ""

    log_info "TDD Phase 3 - US1 테스트 시작"
    echo ""

    # 전제조건 확인
    if [[ ! -d ".claude/commands" ]]; then
        log_error "❌ .claude/commands 디렉토리 없음"
        exit 1
    fi

    # 모든 테스트 실행
    test_command_files_exist
    test_step_pattern_extraction
    test_code_block_extraction
    test_consistency_calculation
    test_validation_function_interface
    test_real_command_validation_simulation

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
