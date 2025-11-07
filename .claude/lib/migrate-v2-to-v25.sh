#!/bin/bash

# migrate-v2-to-v25.sh
# v2.4.x → v2.5.0 마이그레이션 스크립트
# 메트릭스 시스템 및 새로운 디렉토리 구조 설정

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

# v2.4.x 설치 확인
check_v24_installation() {
    log_info "v2.4.x 설치 확인 중..."

    # v2.4 특징: 통합된 에이전트 파일들이 존재
    if [ -f ".claude/agents/implementer-unified.md" ] && \
       [ -f ".claude/agents/reviewer-unified.md" ] && \
       [ -f ".claude/commands/major.md" ]; then
        log_success "v2.4.x 설치 감지됨"
        return 0
    else
        log_warning "v2.4.x 설치가 아님 - 먼저 v2.4로 업그레이드 필요"
        return 1
    fi
}

# v2.5.0 메트릭스 디렉토리 구조 생성
setup_metrics_directories() {
    log_info "메트릭스 디렉토리 구조 생성 중..."

    local dirs=(
        ".claude/cache/metrics"
        ".claude/cache/metrics/daily"
        ".claude/cache/metrics/workflow"
        ".claude/cache/workflow-history"
        ".claude/logs"
    )

    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_success "생성: $dir"
        else
            log_info "이미 존재: $dir"
        fi
    done
}

# 기존 캐시 메타데이터 백업
backup_cache_metadata() {
    local backup_dir="$1"

    log_info "기존 캐시 메타데이터 백업 중..."

    if [ -d ".claude/cache" ]; then
        cp -r ".claude/cache" "$backup_dir/" 2>/dev/null || true
        log_success "캐시 백업 완료"
    fi
}

# 메트릭스 시스템 초기화
initialize_metrics() {
    log_info "메트릭스 시스템 초기화 중..."

    # 메트릭스 초기 파일 생성
    local metrics_file=".claude/cache/metrics/stats.json"

    if [ ! -f "$metrics_file" ]; then
        cat > "$metrics_file" << 'EOF'
{
  "version": "2.5.0",
  "initialized_at": "TIMESTAMP",
  "workflows": {
    "major": {"count": 0, "avg_duration": 0, "success_rate": 0},
    "minor": {"count": 0, "avg_duration": 0, "success_rate": 0},
    "micro": {"count": 0, "avg_duration": 0, "success_rate": 0}
  },
  "token_usage": {
    "total": 0,
    "saved": 0,
    "efficiency": 0
  },
  "quality_metrics": {
    "test_coverage": 0,
    "type_safety": 0,
    "code_quality": 0
  }
}
EOF
        # 타임스탬프 설정
        local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/TIMESTAMP/$timestamp/" "$metrics_file"
        else
            sed -i "s/TIMESTAMP/$timestamp/" "$metrics_file"
        fi

        log_success "메트릭스 초기 파일 생성 완료"
    else
        log_info "메트릭스 파일 이미 존재"
    fi
}

# workflow-gates.json 버전 업데이트
update_workflow_gates_version() {
    local gates_file=".claude/workflow-gates.json"

    if [ -f "$gates_file" ]; then
        log_info "workflow-gates.json 버전 업데이트 중..."

        # 버전만 2.5.0으로 업데이트 (macOS/Linux 호환)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' 's/"version": "2\.[0-9]\.[0-9]"/"version": "2.5.0"/' "$gates_file"
        else
            sed -i 's/"version": "2\.[0-9]\.[0-9]"/"version": "2.5.0"/' "$gates_file"
        fi

        log_success "버전 업데이트 완료"
    fi
}

# 메인 마이그레이션 프로세스
main() {
    log_info "========================================="
    log_info "  v2.4 → v2.5.0 마이그레이션 시작"
    log_info "========================================="
    echo ""

    # v2.4.x 확인
    if ! check_v24_installation; then
        log_error "v2.4.x가 설치되어 있지 않습니다"
        log_info "먼저 v1.0 → v2.4.0 마이그레이션을 실행하세요"
        exit 1
    fi

    # 백업 생성
    log_info "백업 생성 중..."
    BACKUP_DIR=$(create_backup)
    log_success "백업 위치: $BACKUP_DIR"
    echo ""

    # 캐시 백업
    backup_cache_metadata "$BACKUP_DIR"
    echo ""

    # 메트릭스 디렉토리 설정
    setup_metrics_directories
    echo ""

    # 메트릭스 초기화
    initialize_metrics
    echo ""

    # workflow-gates.json 버전 업데이트
    update_workflow_gates_version
    echo ""

    # 완료
    log_success "========================================="
    log_success "  v2.4 → v2.5.0 마이그레이션 완료!"
    log_success "========================================="
    echo ""
    log_info "새로운 기능:"
    echo "  • 실시간 메트릭스 대시보드 (/dashboard)"
    echo "  • 워크플로우 히스토리 추적"
    echo "  • 토큰 사용량 자동 모니터링"
    echo "  • 품질 메트릭 자동 수집"
    echo "  • 백업 위치: $BACKUP_DIR"
    echo ""
    log_warning "대시보드를 확인하려면 /dashboard 명령어를 사용하세요"
    echo ""
}

# 스크립트 실행
main "$@"
