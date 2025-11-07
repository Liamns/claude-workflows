#!/bin/bash

# migrate-v1-to-v2.sh
# v1.0.x → v2.4.0 마이그레이션 스크립트
# Breaking changes 처리 및 deprecated 파일 정리

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로깅 함수
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# 백업 디렉토리 생성
create_backup() {
    local backup_dir=".claude/.backup/migration-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    echo "$backup_dir"
}

# v1.0 설치 확인
check_v1_installation() {
    log_info "v1.0 설치 확인 중..."

    # v1.0 특징: major-*.md 파일들이 존재
    if [ -f ".claude/commands/major-specify.md" ] || \
       [ -f ".claude/commands/major-clarify.md" ] || \
       [ -f ".claude/agents/architect.md" ]; then
        log_success "v1.0.x 설치 감지됨"
        return 0
    else
        log_warning "v1.0.x 설치가 아니거나 이미 마이그레이션됨"
        return 1
    fi
}

# Deprecated 파일 목록
DEPRECATED_COMMANDS=(
    ".claude/commands/major-specify.md"
    ".claude/commands/major-clarify.md"
    ".claude/commands/major-plan.md"
    ".claude/commands/major-tasks.md"
    ".claude/commands/major-implement.md"
)

DEPRECATED_AGENTS=(
    ".claude/agents/architect.md"
    ".claude/agents/fsd-architect.md"
    ".claude/agents/code-reviewer.md"
    ".claude/agents/quick-fixer.md"
    ".claude/agents/test-guardian.md"
    ".claude/agents/smart-committer.md"
    ".claude/agents/changelog-writer.md"
    ".claude/agents/security-scanner.md"
    ".claude/agents/impact-analyzer.md"
)

# 파일 백업 및 삭제
backup_and_remove_files() {
    local backup_dir="$1"
    local files=("${@:2}")

    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            # 백업
            local backup_path="$backup_dir/$(dirname "$file")"
            mkdir -p "$backup_path"
            cp "$file" "$backup_path/$(basename "$file")"

            # 삭제
            rm "$file"
            log_success "삭제됨: $file (백업됨)"
        fi
    done
}

# 메인 마이그레이션 프로세스
main() {
    log_info "========================================="
    log_info "  v1.0 → v2.4.0 마이그레이션 시작"
    log_info "========================================="
    echo ""

    # v1.0 확인
    if ! check_v1_installation; then
        log_info "마이그레이션 불필요 - 건너뜀"
        exit 0
    fi

    # 백업 생성
    log_info "백업 생성 중..."
    BACKUP_DIR=$(create_backup)
    log_success "백업 위치: $BACKUP_DIR"
    echo ""

    # Deprecated commands 제거
    log_info "Deprecated 명령어 제거 중..."
    backup_and_remove_files "$BACKUP_DIR" "${DEPRECATED_COMMANDS[@]}"
    echo ""

    # Deprecated agents 제거
    log_info "Deprecated 에이전트 제거 중..."
    backup_and_remove_files "$BACKUP_DIR" "${DEPRECATED_AGENTS[@]}"
    echo ""

    # workflow-gates.json 백업 (형식 변경 가능성)
    if [ -f ".claude/workflow-gates.json" ]; then
        log_info "workflow-gates.json 백업 중..."
        cp ".claude/workflow-gates.json" "$BACKUP_DIR/"
        log_success "백업 완료"
    fi
    echo ""

    # 사용자 커스터마이징 확인
    log_info "사용자 수정사항 확인 중..."
    if [ -f ".claude/config/user-preferences.yaml" ]; then
        cp ".claude/config/user-preferences.yaml" "$BACKUP_DIR/"
        log_success "user-preferences.yaml 백업됨"
    fi
    echo ""

    # 완료
    log_success "========================================="
    log_success "  v1.0 → v2.4.0 마이그레이션 완료!"
    log_success "========================================="
    echo ""
    log_info "변경사항:"
    echo "  • 5개 major-*.md 명령어 → 통합 /major 명령어"
    echo "  • 8개 에이전트 → 4개 통합 에이전트"
    echo "  • 백업 위치: $BACKUP_DIR"
    echo ""
    log_warning "주의: 신규 설치가 완료되면 /major 명령어를 사용하세요"
    echo ""
}

# 스크립트 실행
main "$@"
