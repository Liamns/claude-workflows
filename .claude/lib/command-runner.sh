#!/usr/bin/env bash
# command-runner.sh - 통합 명령어 실행기
# 모든 슬래시 커맨드의 표준화된 실행 엔진

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_LOADER="${SCRIPT_DIR}/config-loader.sh"

# config-loader 로드
if [[ ! -f "$CONFIG_LOADER" ]]; then
    echo "ERROR: config-loader.sh not found" >&2
    exit 1
fi

# shellcheck source=config-loader.sh
source "$CONFIG_LOADER"

# ============================================================================
# 색상 코드
# ============================================================================

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# ============================================================================
# 전역 변수
# ============================================================================

COMMAND_NAME=""
COMMAND_TYPE=""  # workflow | utility
CONFIG_FILE=""
VERBOSE=false
DRY_RUN=false

# ============================================================================
# 로깅 함수
# ============================================================================

log_step() {
    echo -e "${CYAN}➜${NC} $*"
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

log_debug() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${MAGENTA}[DEBUG]${NC} $*" >&2
    fi
}

# ============================================================================
# 명령어 타입 감지
# ============================================================================

detect_command_type() {
    local command="$1"
    local workflow_gates="${CLAUDE_DIR}/workflow-gates.json"

    # workflow-gates.json에서 확인
    if [[ -f "$workflow_gates" ]]; then
        if grep -q "\"${command}\":" "$workflow_gates" 2>/dev/null; then
            echo "workflow"
            return 0
        fi
    fi

    # commands-config에서 type 필드 확인
    local config_type
    config_type=$(get_config_value "$command" "type" "utility" 2>/dev/null)
    echo "$config_type"
}

# ============================================================================
# Prerequisites 확인
# ============================================================================

check_prerequisites() {
    local command="$1"

    log_step "Checking prerequisites for '$command'..."

    # Config에서 prerequisites 읽기
    local config_file="${CLAUDE_DIR}/commands-config/${command}.yaml"

    if [[ ! -f "$config_file" ]]; then
        log_debug "No config file, skipping prerequisite check"
        return 0
    fi

    # yq로 prerequisites 파싱 (있다면)
    if command -v yq &> /dev/null; then
        local required_tools
        required_tools=$(yq eval '.prerequisites[]' "$config_file" 2>/dev/null || echo "")

        if [[ -n "$required_tools" ]]; then
            while IFS= read -r tool; do
                if [[ -n "$tool" ]]; then
                    if ! command -v "$tool" &> /dev/null; then
                        log_error "Required tool not found: $tool"
                        return 1
                    else
                        log_debug "  ✓ $tool"
                    fi
                fi
            done <<< "$required_tools"
        fi
    fi

    log_success "Prerequisites check passed"
    return 0
}

# ============================================================================
# Pre-execution Hooks
# ============================================================================

run_pre_hooks() {
    local command="$1"

    log_step "Running pre-execution hooks..."

    local hooks_dir="${CLAUDE_DIR}/hooks/pre-command"
    local hook_script="${hooks_dir}/${command}.sh"

    if [[ -f "$hook_script" ]]; then
        log_info "Executing pre-hook: $hook_script"
        if bash "$hook_script"; then
            log_success "Pre-hook completed successfully"
        else
            log_error "Pre-hook failed"
            return 1
        fi
    else
        log_debug "No pre-hook found for '$command'"
    fi

    return 0
}

# ============================================================================
# Post-execution Hooks
# ============================================================================

run_post_hooks() {
    local command="$1"
    local exit_code="$2"

    log_step "Running post-execution hooks..."

    local hooks_dir="${CLAUDE_DIR}/hooks/post-command"
    local hook_script="${hooks_dir}/${command}.sh"

    if [[ -f "$hook_script" ]]; then
        log_info "Executing post-hook: $hook_script"
        bash "$hook_script" "$exit_code" || log_warn "Post-hook failed (non-critical)"
    else
        log_debug "No post-hook found for '$command'"
    fi

    return 0
}

# ============================================================================
# 명령어 실행
# ============================================================================

execute_command() {
    local command="$1"
    shift
    local args=("$@")

    log_step "Executing command: $command"

    # 명령어별 전용 스크립트 확인
    local command_script="${CLAUDE_DIR}/lib/${command}.sh"

    if [[ -f "$command_script" ]]; then
        log_info "Running dedicated script: $command_script"

        if [[ "$DRY_RUN" == true ]]; then
            log_warn "DRY RUN: Would execute: bash $command_script ${args[*]}"
            return 0
        fi

        if bash "$command_script" "${args[@]}"; then
            log_success "Command executed successfully"
            return 0
        else
            log_error "Command execution failed"
            return 1
        fi
    else
        log_info "No dedicated script found, command will be handled by Claude AI"
        log_debug "Config file: ${CONFIG_FILE}"
        return 0
    fi
}

# ============================================================================
# 메인 실행 플로우
# ============================================================================

run_command() {
    local command="$1"
    shift
    local args=("$@")

    COMMAND_NAME="$command"

    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  Command Runner: /${command}${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # 1. 설정 로드
    log_step "Loading configuration..."
    CONFIG_FILE=$(load_config "$command" 2>&1) || {
        log_warn "Failed to load config, using defaults"
    }

    # 2. 명령어 타입 감지
    COMMAND_TYPE=$(detect_command_type "$command")
    log_info "Command type: $COMMAND_TYPE"

    # 3. Prerequisites 확인
    if ! check_prerequisites "$command"; then
        log_error "Prerequisites check failed"
        return 1
    fi

    # 4. Pre-execution hooks
    if ! run_pre_hooks "$command"; then
        log_error "Pre-execution hooks failed"
        return 1
    fi

    # 5. 명령어 실행
    local exit_code=0
    if ! execute_command "$command" "${args[@]}"; then
        exit_code=$?
        log_error "Command execution failed (exit code: $exit_code)"
    fi

    # 6. Post-execution hooks
    run_post_hooks "$command" "$exit_code"

    # 7. 결과 출력
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║${NC}  ✅ Command completed successfully${GREEN}║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    else
        echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║${NC}  ✗ Command failed with exit code: $exit_code${RED}║${NC}"
        echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    fi
    echo ""

    return $exit_code
}

# ============================================================================
# 메인 함수
# ============================================================================

main() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <command> [args...]"
        echo ""
        echo "Examples:"
        echo "  $0 pr --base main"
        echo "  $0 review src/components"
        echo "  $0 major feature-name"
        echo ""
        echo "Options:"
        echo "  --verbose    Enable debug output"
        echo "  --dry-run    Show what would be executed"
        exit 1
    fi

    # 옵션 파싱
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    local command="$1"
    shift

    run_command "$command" "$@"
}

# 스크립트로 직접 실행된 경우만 main 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
