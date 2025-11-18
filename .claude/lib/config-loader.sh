#!/usr/bin/env bash
# config-loader.sh - YAML 설정 파일 로더
# 명령어 설정 파일을 로드하고 병합하는 유틸리티

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

CLAUDE_DIR="${CLAUDE_DIR:-.claude}"
CONFIG_DIR="${CLAUDE_DIR}/commands-config"
BASE_CONFIG="${CONFIG_DIR}/_base.yaml"

# ============================================================================
# 색상 코드
# ============================================================================

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ============================================================================
# 로깅 함수
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# ============================================================================
# YAML 파싱 함수 (간단한 구현)
# ============================================================================

# YAML 값 추출 (키: 값 형식)
get_yaml_value() {
    local file="$1"
    local key="$2"
    local default="${3:-}"

    if [[ ! -f "$file" ]]; then
        echo "$default"
        return 1
    fi

    # 단순 키-값 추출 (중첩 구조는 미지원)
    local value
    value=$(grep -E "^${key}:" "$file" | sed "s/^${key}:[[:space:]]*//" | tr -d '"' || echo "$default")

    echo "$value"
}

# YAML 섹션 존재 여부 확인
yaml_section_exists() {
    local file="$1"
    local section="$2"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    grep -q "^${section}:" "$file"
}

# ============================================================================
# 설정 파일 검증
# ============================================================================

validate_config_file() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        log_error "설정 파일을 찾을 수 없습니다: $config_file"
        return 1
    fi

    # 기본 YAML 문법 검사 (yq 또는 python 사용 가능)
    if command -v yq &> /dev/null; then
        if ! yq eval '.' "$config_file" > /dev/null 2>&1; then
            log_error "잘못된 YAML 문법: $config_file"
            return 1
        fi
    fi

    log_info "설정 파일 검증 통과: $config_file"
    return 0
}

# ============================================================================
# 설정 로드 함수
# ============================================================================

load_config() {
    local command_name="$1"
    local config_file="${CONFIG_DIR}/${command_name}.yaml"

    log_info "설정 로드 중: $command_name"

    # Base 설정 확인
    if [[ ! -f "$BASE_CONFIG" ]]; then
        log_warn "Base 설정 파일이 없습니다: $BASE_CONFIG"
    else
        log_info "Base 설정 로드: $BASE_CONFIG"
    fi

    # 명령어별 설정 확인
    if [[ ! -f "$config_file" ]]; then
        log_warn "명령어 설정 파일이 없습니다: $config_file"
        log_warn "Base 설정만 사용합니다"
        return 0
    fi

    # 설정 파일 검증
    if ! validate_config_file "$config_file"; then
        return 1
    fi

    log_success "설정 로드 완료: $command_name"

    # 설정 파일 경로 반환
    echo "$config_file"
    return 0
}

# ============================================================================
# 설정 병합 함수
# ============================================================================

merge_configs() {
    local base_config="$1"
    local command_config="$2"
    local output_file="${3:-}"

    log_info "설정 병합 중..."

    # yq 사용 가능한 경우
    if command -v yq &> /dev/null; then
        if [[ -n "$output_file" ]]; then
            yq eval-all '. as $item ireduce ({}; . * $item)' \
                "$base_config" "$command_config" > "$output_file"
        else
            yq eval-all '. as $item ireduce ({}; . * $item)' \
                "$base_config" "$command_config"
        fi
    else
        log_warn "yq가 설치되지 않아 설정 병합을 건너뜁니다"
        cat "$command_config"
    fi

    return 0
}

# ============================================================================
# 설정 값 가져오기
# ============================================================================

get_config_value() {
    local command_name="$1"
    local key="$2"
    local default="${3:-}"

    local config_file
    config_file=$(load_config "$command_name" 2>/dev/null) || {
        echo "$default"
        return 1
    }

    get_yaml_value "$config_file" "$key" "$default"
}

# ============================================================================
# 설정 덤프 (디버깅용)
# ============================================================================

dump_config() {
    local command_name="$1"
    local config_file

    config_file=$(load_config "$command_name") || return 1

    log_info "=== Configuration for '$command_name' ==="
    cat "$config_file"
    log_info "========================================="
}

# ============================================================================
# 메인 실행 (스크립트로 직접 실행 시)
# ============================================================================

main() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  load <command-name>          - Load config for command"
        echo "  validate <config-file>       - Validate YAML syntax"
        echo "  get <command-name> <key>     - Get config value"
        echo "  dump <command-name>          - Dump full config"
        exit 1
    fi

    local action="$1"
    shift

    case "$action" in
        load)
            load_config "$@"
            ;;
        validate)
            validate_config_file "$@"
            ;;
        get)
            get_config_value "$@"
            ;;
        dump)
            dump_config "$@"
            ;;
        *)
            log_error "Unknown action: $action"
            exit 1
            ;;
    esac
}

# 스크립트로 직접 실행된 경우만 main 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
