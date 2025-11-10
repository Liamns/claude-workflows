#!/bin/bash
# validate-migration.sh
# 마이그레이션 검증 모듈 - 마이그레이션 시나리오 검증
# Phase 4 - User Story 2 구현

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
# 상수 정의
# ============================================================

# Deprecated 파일 목록 (v1.0 → v2.5 마이그레이션 시 제거되어야 함)
DEPRECATED_FILES_V1=(
    ".claude/commands/major-specify.md"
    ".claude/commands/major-clarify.md"
    ".claude/commands/major-research.md"
    ".claude/agents/architect.md"
    ".claude/agents/test-guardian.md"
    ".claude/agents/fsd-architect.md"
)

# Deprecated 파일 목록 (v2.4/v2.5 → v2.6 마이그레이션 시 제거되어야 함)
DEPRECATED_FILES_V24=(
    ".claude/agents/code-reviewer.md"
    ".claude/agents/security-scanner.md"
)

# Critical 파일 목록 (v2.6에서 반드시 존재해야 함)
CRITICAL_FILES=(
    ".claude/workflow-gates.json"
    ".claude/commands/major.md"
    ".claude/.version"
    ".claude/lib/validate-system.sh"
    ".claude/hooks/pre-commit"
)

# ============================================================
# 핵심 검증 함수
# ============================================================

# 마이그레이션 시나리오 검증
validate_migration_scenario() {
    local from_version="$1"
    local to_version="${2:-2.5.0}"
    local scenario_name="$from_version → $to_version"

    log_info "🔄 마이그레이션 검증: $scenario_name"
    echo ""

    # 임시 디렉토리 생성
    local test_dir=$(create_temp_dir)
    if [[ -z "$test_dir" ]]; then
        log_error "임시 디렉토리 생성 실패"
        return 1
    fi

    # 정리 트랩 설정 (EXIT, INT, TERM 시그널 처리)
    setup_cleanup_trap "cleanup_temp_dir '$test_dir'"

    log_info "  임시 환경: $test_dir"

    # 환경 설정 (from_version에 맞는 파일 구조 생성)
    if ! setup_version_environment "$test_dir" "$from_version"; then
        log_error "  ✗ 환경 설정 실패"
        return 1
    fi

    log_info "  환경 설정 완료: v$from_version"

    # 마이그레이션 시뮬레이션
    # 실제 install.sh를 실행하지 않고, 파일 변경 사항만 시뮬레이션
    if ! simulate_migration "$test_dir" "$from_version" "$to_version"; then
        log_error "  ✗ 마이그레이션 시뮬레이션 실패"
        return 1
    fi

    log_info "  마이그레이션 시뮬레이션 완료"

    # Deprecated 파일 검증
    if ! check_deprecated_files "$test_dir" "$from_version"; then
        log_error "  ✗ Deprecated 파일 검증 실패"
        return 1
    fi

    log_info "  Deprecated 파일 검증 완료"

    # Critical 파일 검증
    if ! check_critical_files "$test_dir"; then
        log_error "  ✗ Critical 파일 검증 실패"
        return 1
    fi

    log_info "  Critical 파일 검증 완료"

    echo ""
    log_success "  ✓ $scenario_name 검증 완료"

    return 0
}

# 버전별 환경 설정
setup_version_environment() {
    local test_dir="$1"
    local version="$2"

    log_info "  환경 설정 중: v$version..."

    case "$version" in
        "1.0.0"|"1.0")
            setup_v1_environment "$test_dir"
            ;;
        "2.4.0"|"2.4")
            setup_v24_environment "$test_dir"
            ;;
        *)
            log_error "지원하지 않는 버전: $version"
            return 1
            ;;
    esac

    return 0
}

# v1.0 환경 설정
setup_v1_environment() {
    local test_dir="$1"

    # 디렉토리 생성
    mkdir -p "$test_dir/.claude/commands"
    mkdir -p "$test_dir/.claude/agents"
    mkdir -p "$test_dir/.claude/lib"

    # v1.0 특징: 분리된 major-* 파일들
    cat > "$test_dir/.claude/commands/major-specify.md" << 'EOF'
# Major Specify (v1.0)

## Description
Feature specification step in v1.0
EOF

    cat > "$test_dir/.claude/commands/major-clarify.md" << 'EOF'
# Major Clarify (v1.0)

## Description
Clarification step in v1.0
EOF

    cat > "$test_dir/.claude/commands/major-research.md" << 'EOF'
# Major Research (v1.0)

## Description
Research step in v1.0
EOF

    # v1.0 에이전트 파일
    cat > "$test_dir/.claude/agents/architect.md" << 'EOF'
# Architect Agent (v1.0)

## Description
Architecture validation agent
EOF

    # v1.0 workflow-gates.json
    cat > "$test_dir/.claude/workflow-gates.json" << 'EOF'
{
  "version": "1.0.0",
  "workflows": {
    "major": {
      "steps": ["specify", "clarify", "research"]
    }
  }
}
EOF

    return 0
}

# v2.4 환경 설정
setup_v24_environment() {
    local test_dir="$1"

    # 디렉토리 생성
    mkdir -p "$test_dir/.claude/commands"
    mkdir -p "$test_dir/.claude/agents"
    mkdir -p "$test_dir/.claude/lib"

    # v2.4 특징: 통합된 major.md
    cat > "$test_dir/.claude/commands/major.md" << 'EOF'
# Major Workflow (v2.4)

## Description
Unified major workflow

### Step 0: Prerequisites
### Step 1: Branch creation
### Step 2: Core questions
EOF

    # v2.4 에이전트 파일 (일부 deprecated)
    cat > "$test_dir/.claude/agents/code-reviewer.md" << 'EOF'
# Code Reviewer Agent (v2.4 - deprecated)

## Description
Code review agent
EOF

    # v2.4 workflow-gates.json
    cat > "$test_dir/.claude/workflow-gates.json" << 'EOF'
{
  "version": "2.4.0",
  "workflows": {
    "major": {
      "unified": true
    }
  }
}
EOF

    return 0
}

# 마이그레이션 시뮬레이션
simulate_migration() {
    local test_dir="$1"
    local from_version="$2"
    local to_version="$3"

    log_info "  마이그레이션 시뮬레이션 중..."

    # Deprecated 파일 제거
    case "$from_version" in
        "1.0.0"|"1.0")
            for file in "${DEPRECATED_FILES_V1[@]}"; do
                local full_path="$test_dir/$file"
                if [[ -f "$full_path" ]]; then
                    rm -f "$full_path"
                fi
            done
            ;;
        "2.4.0"|"2.4")
            for file in "${DEPRECATED_FILES_V24[@]}"; do
                local full_path="$test_dir/$file"
                if [[ -f "$full_path" ]]; then
                    rm -f "$full_path"
                fi
            done
            ;;
    esac

    # v2.5 파일 생성 (없는 경우)
    if [[ ! -f "$test_dir/.claude/commands/major.md" ]]; then
        cat > "$test_dir/.claude/commands/major.md" << 'EOF'
# Major Workflow (v2.5)

Unified workflow with all steps integrated
EOF
    fi

    # .version 파일 생성
    echo "$to_version" > "$test_dir/.claude/.version"

    # workflow-gates.json 업데이트
    cat > "$test_dir/.claude/workflow-gates.json" << EOF
{
  "version": "$to_version",
  "workflows": {
    "major": {
      "unified": true,
      "steps": 15
    }
  }
}
EOF

    return 0
}

# Deprecated 파일 검증
check_deprecated_files() {
    local test_dir="$1"
    local from_version="$2"

    log_info "  Deprecated 파일 확인 중..."

    local deprecated_count=0
    local files_to_check=()

    # 버전에 따라 확인할 파일 목록 선택
    case "$from_version" in
        "1.0.0"|"1.0")
            files_to_check=("${DEPRECATED_FILES_V1[@]}")
            ;;
        "2.4.0"|"2.4")
            files_to_check=("${DEPRECATED_FILES_V24[@]}")
            ;;
    esac

    # 파일이 존재하지 않는지 확인
    for file in "${files_to_check[@]}"; do
        local full_path="$test_dir/$file"
        if [[ -f "$full_path" ]]; then
            log_error "    ✗ Deprecated 파일이 여전히 존재: $file"
            ((deprecated_count++))
        else
            log_success "    ✓ Deprecated 파일 제거됨: $file"
        fi
    done

    if [[ $deprecated_count -gt 0 ]]; then
        log_error "  $deprecated_count개의 Deprecated 파일이 여전히 존재"
        return 1
    fi

    return 0
}

# Critical 파일 검증
check_critical_files() {
    local test_dir="$1"

    log_info "  Critical 파일 확인 중..."

    local missing_count=0

    # 모든 Critical 파일이 존재하는지 확인
    for file in "${CRITICAL_FILES[@]}"; do
        local full_path="$test_dir/$file"
        if [[ ! -f "$full_path" ]]; then
            log_error "    ✗ Critical 파일 없음: $file"
            ((missing_count++))
        else
            log_success "    ✓ Critical 파일 존재: $file"

            # .version 파일의 경우 내용 검증
            if [[ "$file" == ".claude/.version" ]]; then
                local version=$(cat "$full_path")
                if [[ -n "$version" ]]; then
                    log_info "      버전: $version"
                else
                    log_warning "      버전 파일이 비어있음"
                fi
            fi
        fi
    done

    if [[ $missing_count -gt 0 ]]; then
        log_error "  $missing_count개의 Critical 파일이 없음"
        return 1
    fi

    return 0
}

# ============================================================
# 보조 함수
# ============================================================

# 신규 설치 시나리오 검증
validate_fresh_install() {
    log_info "🆕 신규 설치 시나리오 검증..."
    echo ""

    # 임시 디렉토리 생성
    local test_dir=$(create_temp_dir)
    if [[ -z "$test_dir" ]]; then
        log_error "임시 디렉토리 생성 실패"
        return 1
    fi

    # 정리 트랩 설정 (EXIT, INT, TERM 시그널 처리)
    setup_cleanup_trap "cleanup_temp_dir '$test_dir'"

    log_info "  임시 환경: $test_dir"

    # 빈 디렉토리에서 시작 (기존 설치 없음)
    mkdir -p "$test_dir/.claude"

    # v2.6 파일 생성 (신규 설치 시뮬레이션)
    simulate_migration "$test_dir" "none" "2.6.0"

    # Critical 파일 검증
    if ! check_critical_files "$test_dir"; then
        log_error "  ✗ Critical 파일 검증 실패"
        return 1
    fi

    log_info "  Critical 파일 검증 완료"

    # Deprecated 파일이 없어야 함
    local deprecated_count=0
    for file in "${DEPRECATED_FILES_V1[@]}" "${DEPRECATED_FILES_V24[@]}"; do
        local full_path="$test_dir/$file"
        if [[ -f "$full_path" ]]; then
            log_error "    ✗ 신규 설치에 Deprecated 파일 존재: $file"
            ((deprecated_count++))
        fi
    done

    if [[ $deprecated_count -gt 0 ]]; then
        log_error "  ✗ 신규 설치 검증 실패: $deprecated_count개의 Deprecated 파일 발견"
        return 1
    fi

    echo ""
    log_success "  ✓ 신규 설치 시나리오 통과"

    return 0
}

# 롤백 시나리오 검증
validate_rollback_scenario() {
    log_info "🔄 롤백 시나리오 검증..."
    echo ""

    # 임시 디렉토리 생성
    local test_dir=$(create_temp_dir)
    if [[ -z "$test_dir" ]]; then
        log_error "임시 디렉토리 생성 실패"
        return 1
    fi

    # 정리 트랩 설정 (EXIT, INT, TERM 시그널 처리)
    setup_cleanup_trap "cleanup_temp_dir '$test_dir'"

    log_info "  임시 환경: $test_dir"

    # v2.4 환경 설정 (롤백 전 상태)
    setup_v24_environment "$test_dir"

    # 백업 디렉토리 생성 (롤백용)
    local backup_dir="$test_dir/.claude/.backup/test-backup"
    mkdir -p "$backup_dir"

    # Critical 파일 백업
    cp "$test_dir/.claude/workflow-gates.json" "$backup_dir/" 2>/dev/null || true
    cp -r "$test_dir/.claude/commands" "$backup_dir/" 2>/dev/null || true

    log_info "  백업 생성 완료"

    # 마이그레이션 실패 시뮬레이션 (일부 파일만 변경)
    echo "corrupted" > "$test_dir/.claude/workflow-gates.json"
    rm -f "$test_dir/.claude/commands/major.md"

    log_info "  마이그레이션 실패 시뮬레이션"

    # 롤백 수행 (백업에서 복원)
    if [[ -f "$backup_dir/workflow-gates.json" ]]; then
        cp "$backup_dir/workflow-gates.json" "$test_dir/.claude/" 2>/dev/null || true
    fi

    if [[ -d "$backup_dir/commands" ]]; then
        cp -r "$backup_dir/commands/"* "$test_dir/.claude/commands/" 2>/dev/null || true
    fi

    log_info "  롤백 수행 완료"

    # 롤백 후 검증: v2.4 파일이 복원되었는지 확인
    if [[ ! -f "$test_dir/.claude/workflow-gates.json" ]]; then
        log_error "  ✗ workflow-gates.json 복원 실패"
        return 1
    fi

    local version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$test_dir/.claude/workflow-gates.json" | cut -d'"' -f4)
    if [[ "$version" != "2.4.0" ]]; then
        log_error "  ✗ 버전이 올바르게 복원되지 않음: $version"
        return 1
    fi

    log_success "  ✓ workflow-gates.json 복원됨 (v$version)"

    if [[ ! -f "$test_dir/.claude/commands/major.md" ]]; then
        log_error "  ✗ major.md 복원 실패"
        return 1
    fi

    log_success "  ✓ major.md 복원됨"

    echo ""
    log_success "  ✓ 롤백 시나리오 통과"

    return 0
}

# 모든 마이그레이션 시나리오 검증
validate_all_migration_scenarios() {
    local results="{"
    local total=0
    local passed=0

    log_info "🔄 모든 마이그레이션 시나리오 검증..."
    echo ""

    # v1.0 → v2.6 시나리오
    if validate_migration_scenario "1.0.0" "2.6.0"; then
        log_success "✓ v1.0 → v2.6 시나리오 통과"
        ((passed++))
        results+="\"v1_to_v26\":{\"status\":\"PASS\"},"
    else
        log_error "✗ v1.0 → v2.6 시나리오 실패"
        results+="\"v1_to_v26\":{\"status\":\"FAIL\"},"
    fi
    ((total++))

    echo ""

    # v2.4 → v2.6 시나리오
    if validate_migration_scenario "2.4.0" "2.6.0"; then
        log_success "✓ v2.4 → v2.6 시나리오 통과"
        ((passed++))
        results+="\"v24_to_v26\":{\"status\":\"PASS\"},"
    else
        log_error "✗ v2.4 → v2.6 시나리오 실패"
        results+="\"v24_to_v26\":{\"status\":\"FAIL\"},"
    fi
    ((total++))

    echo ""

    # v2.5 → v2.6 시나리오
    if validate_migration_scenario "2.5.0" "2.6.0"; then
        log_success "✓ v2.5 → v2.6 시나리오 통과"
        ((passed++))
        results+="\"v25_to_v26\":{\"status\":\"PASS\"},"
    else
        log_error "✗ v2.5 → v2.6 시나리오 실패"
        results+="\"v25_to_v26\":{\"status\":\"FAIL\"},"
    fi
    ((total++))

    echo ""

    # 신규 설치 시나리오
    if validate_fresh_install; then
        log_success "✓ 신규 설치 시나리오 통과"
        ((passed++))
        results+="\"fresh_install\":{\"status\":\"PASS\"},"
    else
        log_error "✗ 신규 설치 시나리오 실패"
        results+="\"fresh_install\":{\"status\":\"FAIL\"},"
    fi
    ((total++))

    echo ""

    # 롤백 시나리오
    if validate_rollback_scenario; then
        log_success "✓ 롤백 시나리오 통과"
        ((passed++))
        results+="\"rollback\":{\"status\":\"PASS\"},"
    else
        log_error "✗ 롤백 시나리오 실패"
        results+="\"rollback\":{\"status\":\"FAIL\"},"
    fi
    ((total++))

    # 결과 JSON 완성
    results="${results%,}"  # 마지막 쉼표 제거
    results+=",\"total\":$total,\"passed\":$passed}"

    echo ""
    log_info "  완료: $passed/$total 시나리오 통과"

    # JSON 결과 반환
    echo "$results"

    if [[ $passed -eq $total ]]; then
        return 0
    else
        return 1
    fi
}

# ============================================================
# CLI 인터페이스 (직접 실행 시)
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   마이그레이션 검증 모듈              ║"
    echo "║   Migration Validation Module         ║"
    echo "╚════════════════════════════════════════╝"
    echo ""

    # 명령줄 인자
    FROM_VERSION="${1:-all}"
    TO_VERSION="${2:-2.5.0}"

    if [[ "$FROM_VERSION" == "all" ]]; then
        # 모든 시나리오 검증
        RESULTS=$(validate_all_migration_scenarios)

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_info "📊 검증 결과"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "$RESULTS" | (command -v jq > /dev/null 2>&1 && jq . || cat)
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # 종료 코드
        PASSED=$(echo "$RESULTS" | grep -o '"passed":[0-9]*' | cut -d':' -f2)
        TOTAL=$(echo "$RESULTS" | grep -o '"total":[0-9]*' | cut -d':' -f2)

        if [[ "$PASSED" == "$TOTAL" ]]; then
            log_success "✅ 모든 마이그레이션 시나리오 통과"
            exit 0
        else
            log_error "❌ 일부 마이그레이션 시나리오 실패"
            exit 1
        fi
    else
        # 개별 시나리오 검증
        if validate_migration_scenario "$FROM_VERSION" "$TO_VERSION"; then
            log_success "✅ 마이그레이션 검증 성공"
            exit 0
        else
            log_error "❌ 마이그레이션 검증 실패"
            exit 1
        fi
    fi
fi
