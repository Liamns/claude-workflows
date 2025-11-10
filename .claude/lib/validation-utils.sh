#!/bin/bash
# validation-utils.sh
# 공통 유틸리티 함수 - 모든 검증 스크립트에서 재사용

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로깅 함수들

log_info() {
    local message="$1"
    echo -e "${BLUE}ℹ${NC} $message"
    [[ -n "${LOG_FILE:-}" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $message" >> "$LOG_FILE"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}✓${NC} $message"
    [[ -n "${LOG_FILE:-}" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $message" >> "$LOG_FILE"
}

log_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠${NC} $message"
    [[ -n "${LOG_FILE:-}" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $message" >> "$LOG_FILE"
}

log_error() {
    local message="$1"
    echo -e "${RED}✗${NC} $message" >&2
    [[ -n "${LOG_FILE:-}" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $message" >> "$LOG_FILE"
}

# 전제조건 검증

validate_prerequisites() {
    log_info "전제조건 검증 중..."

    local errors=0

    # Bash 버전 확인
    if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
        log_error "Bash 4.0+ 필요 (현재: ${BASH_VERSION})"
        ((errors++))
    else
        log_success "Bash 버전: ${BASH_VERSION}"
    fi

    # Git 저장소 확인
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Git 저장소가 아닙니다"
        ((errors++))
    else
        log_success "Git 저장소 확인"
    fi

    # 필수 명령어 확인
    local required_commands=("grep" "sed" "diff" "mktemp" "date")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "필수 명령어 없음: $cmd"
            ((errors++))
        fi
    done

    if [[ $errors -eq 0 ]]; then
        log_success "모든 전제조건 충족"
    fi

    # jq 확인 (선택적)
    if ! command -v jq &> /dev/null; then
        log_warning "jq 없음 - JSON 보고서 생성 불가 (선택적)"
    else
        log_success "jq 사용 가능"
    fi

    return $errors
}

# 파일/디렉토리 존재 확인

check_file_exists() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        return 0
    else
        return 1
    fi
}

check_dir_exists() {
    local dir_path="$1"
    if [[ -d "$dir_path" ]]; then
        return 0
    else
        return 1
    fi
}

# 임시 디렉토리 관리

create_temp_dir() {
    local temp_dir
    temp_dir=$(mktemp -d 2>/dev/null) || {
        log_error "임시 디렉토리 생성 실패"
        return 1
    }

    if [[ ! -d "$temp_dir" ]]; then
        log_error "임시 디렉토리 생성 실패"
        return 1
    fi

    echo "$temp_dir"
    return 0
}

cleanup_temp_dir() {
    local temp_dir="$1"

    # 안전성 검사
    if [[ -z "$temp_dir" ]]; then
        log_warning "cleanup_temp_dir: 빈 경로"
        return 1
    fi

    # 보안: /tmp, /var/tmp, /var/folders (macOS) 하위만 허용
    case "$temp_dir" in
        /tmp/*|/var/tmp/*|/var/folders/*)
            if [[ -d "$temp_dir" ]]; then
                rm -rf "$temp_dir"
                log_info "임시 디렉토리 정리: $temp_dir"
                return 0
            else
                log_warning "디렉토리 없음: $temp_dir"
                return 1
            fi
            ;;
        *)
            log_error "cleanup_temp_dir: 안전하지 않은 경로: $temp_dir"
            return 1
            ;;
    esac
}

# 버전 검증 (install.sh에서 재사용)

verify_version_file() {
    local version_file="$1"
    if [[ ! -f "$version_file" ]]; then
        log_error "버전 파일 없음: $version_file"
        return 1
    fi

    local version=$(cat "$version_file")
    if [[ -z "$version" ]]; then
        log_error "버전 파일이 비어있음"
        return 1
    fi

    log_success "버전: $version"
    return 0
}

detect_current_version() {
    # .claude/.version 파일 확인 (v2.5+)
    if [[ -f ".claude/.version" ]]; then
        cat ".claude/.version"
        return 0
    fi

    # workflow-gates.json 확인 (v2.0+)
    if [[ -f ".claude/workflow-gates.json" ]]; then
        local version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' ".claude/workflow-gates.json" | cut -d'"' -f4)
        if [[ -n "$version" ]]; then
            echo "$version"
            return 0
        fi
    fi

    echo "unknown"
    return 1
}

# 파일 카운트

count_files_in_dir() {
    local dir_path="$1"
    local pattern="${2:-*}"

    if [[ ! -d "$dir_path" ]]; then
        echo "0"
        return 1
    fi

    local count=$(find "$dir_path" -maxdepth 1 -type f -name "$pattern" 2>/dev/null | wc -l | tr -d ' ')
    echo "$count"
    return 0
}

# 보고서 타임스탬프 생성

generate_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

generate_report_filename() {
    date +"%Y-%m-%d-%H%M%S"
}

# 에러 처리 핸들러

handle_error() {
    local error_code=$1
    local error_message="${2:-Unknown error}"
    log_error "$error_message (코드: $error_code)"
    exit "$error_code"
}

# 진행률 표시

show_progress() {
    local current=$1
    local total=$2
    local description="${3:-진행 중}"

    local percentage=$((current * 100 / total))
    echo -ne "\r${description}: $current/$total ($percentage%)"

    if [[ $current -eq $total ]]; then
        echo ""  # 줄바꿈
    fi
}

# Trap 설정 - 여러 시그널 처리 (EXIT, INT, TERM)

setup_cleanup_trap() {
    local cleanup_cmd="$1"

    # 단순하고 안전한 trap 설정 (기존 trap은 덮어씀)
    # shellcheck disable=SC2064
    trap "$cleanup_cmd" EXIT INT TERM
}

# 사용 예시 (이 파일을 단독 실행하면 테스트)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== validation-utils.sh 테스트 ==="
    echo ""

    validate_prerequisites
    echo ""

    log_info "테스트 정보 메시지"
    log_success "테스트 성공 메시지"
    log_warning "테스트 경고 메시지"
    log_error "테스트 에러 메시지"
    echo ""

    log_info "현재 버전: $(detect_current_version)"
    log_info "명령어 파일 수: $(count_files_in_dir '.claude/commands' '*.md')"
    echo ""

    show_progress 1 10 "테스트 진행"
    sleep 0.1
    show_progress 5 10 "테스트 진행"
    sleep 0.1
    show_progress 10 10 "테스트 진행"
    echo ""

    log_success "validation-utils.sh 테스트 완료"
fi
