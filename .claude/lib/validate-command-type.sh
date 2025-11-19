#!/usr/bin/env bash
# validate-command-type.sh - 슬래시 명령어 타입 검증
# 명령어가 타입 정의 및 필수 요소를 가지고 있는지 검증합니다

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="${CLAUDE_DIR}/commands-config"
COMMANDS_DIR="${CLAUDE_DIR}/commands"
WORKFLOW_GATES="${CLAUDE_DIR}/workflow-gates.json"

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
# 로깅 함수
# ============================================================================

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
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${MAGENTA}[DEBUG]${NC} $*" >&2
    fi
}

# ============================================================================
# 명령어 타입 감지
# ============================================================================

# YAML에서 type 필드 읽기, 없으면 파일 구조로 추론
detect_command_type() {
    local command="$1"
    local config_file="${CONFIG_DIR}/${command}.yaml"

    # 1. YAML 파일에서 type 필드 읽기
    if [[ -f "$config_file" ]]; then
        if command -v yq &> /dev/null; then
            local yaml_type
            yaml_type=$(yq eval '.type // ""' "$config_file" 2>/dev/null)

            if [[ -n "$yaml_type" ]]; then
                echo "$yaml_type"
                return 0
            fi
        else
            # yq 없이 간단한 grep
            local yaml_type
            yaml_type=$(grep -E "^type:" "$config_file" 2>/dev/null | sed 's/type:[[:space:]]*//' | tr -d '"' || echo "")

            if [[ -n "$yaml_type" ]]; then
                echo "$yaml_type"
                return 0
            fi
        fi
    fi

    # 2. workflow-gates.json에서 확인
    if [[ -f "$WORKFLOW_GATES" ]]; then
        if command -v jq &> /dev/null; then
            if jq -e ".workflows.${command}" "$WORKFLOW_GATES" >/dev/null 2>&1; then
                echo "workflow"
                return 0
            fi
        else
            if grep -q "\"${command}\":" "$WORKFLOW_GATES" 2>/dev/null; then
                echo "workflow"
                return 0
            fi
        fi
    fi

    # 3. 파일 구조로 추론
    if [[ -f "$config_file" ]]; then
        # agents 또는 skills 있으면 workflow
        if grep -qE "^(agents|skills):" "$config_file" 2>/dev/null; then
            echo "workflow"
            return 0
        fi

        # script.path 있으면 utility
        if grep -qE "^script:" "$config_file" 2>/dev/null; then
            echo "utility"
            return 0
        fi

        # prompts 있으면 hybrid
        if grep -qE "^prompts:" "$config_file" 2>/dev/null; then
            echo "hybrid"
            return 0
        fi
    fi

    # 4. 기본값: unknown
    echo "unknown"
    return 1
}

# ============================================================================
# Workflow 명령어 검증
# ============================================================================

validate_workflow_command() {
    local command="$1"
    local config_file="${CONFIG_DIR}/${command}.yaml"
    local has_errors=false

    log_debug "Validating workflow command: $command"

    if [[ ! -f "$config_file" ]]; then
        log_error "Config file not found: $config_file"
        return 1
    fi

    # agents 필드 확인
    local has_agents=false
    if grep -qE "^agents:" "$config_file" 2>/dev/null; then
        has_agents=true
        log_success "  agents: ✓"
    else
        log_error "  agents: ✗ (Required for workflow)"
        has_errors=true
    fi

    # skills 필드 확인 (선택 사항이지만 권장)
    local has_skills=false
    if grep -qE "^skills:" "$config_file" 2>/dev/null; then
        has_skills=true
        log_success "  skills: ✓"
    else
        log_warn "  skills: - (Optional but recommended)"
    fi

    # workflow_definition 확인 (workflow-gates.json 참조)
    local has_workflow_def=false
    if grep -qE "^workflow_definition:" "$config_file" 2>/dev/null; then
        has_workflow_def=true
        log_success "  workflow_definition: ✓"
    else
        log_warn "  workflow_definition: - (Optional)"
    fi

    if [[ "$has_errors" == "true" ]]; then
        return 1
    fi

    return 0
}

# ============================================================================
# Utility 명령어 검증
# ============================================================================

validate_utility_command() {
    local command="$1"
    local config_file="${CONFIG_DIR}/${command}.yaml"
    local has_errors=false

    log_debug "Validating utility command: $command"

    if [[ ! -f "$config_file" ]]; then
        log_error "Config file not found: $config_file"
        return 1
    fi

    # script.path 필드 확인 (utility는 스크립트 실행이 주 목적)
    local script_path=""
    if command -v yq &> /dev/null; then
        script_path=$(yq eval '.script.path // ""' "$config_file" 2>/dev/null)
    else
        script_path=$(grep -A1 "^script:" "$config_file" 2>/dev/null | grep "path:" | sed 's/.*path:[[:space:]]*//' | tr -d '"' || echo "")
    fi

    if [[ -n "$script_path" ]]; then
        log_success "  script.path: ✓ ($script_path)"

        # 스크립트 파일 존재 확인
        local full_script_path="${CLAUDE_DIR}/${script_path}"
        if [[ -f "$full_script_path" ]]; then
            log_success "  script exists: ✓"
        else
            log_warn "  script exists: - (File not found: $full_script_path)"
        fi
    else
        log_warn "  script.path: - (Utility commands typically have scripts)"
    fi

    # prompts 확인 (hybrid일 수도 있음)
    if grep -qE "^prompts:" "$config_file" 2>/dev/null; then
        log_info "  prompts: ✓ (Hybrid utility)"
    fi

    return 0
}

# ============================================================================
# Hybrid 명령어 검증
# ============================================================================

validate_hybrid_command() {
    local command="$1"
    local config_file="${CONFIG_DIR}/${command}.yaml"
    local has_errors=false

    log_debug "Validating hybrid command: $command"

    if [[ ! -f "$config_file" ]]; then
        log_error "Config file not found: $config_file"
        return 1
    fi

    # prompts 또는 script 중 하나 이상 있어야 함
    local has_prompts=false
    local has_script=false

    if grep -qE "^prompts:" "$config_file" 2>/dev/null; then
        has_prompts=true
        log_success "  prompts: ✓"
    fi

    if grep -qE "^script:" "$config_file" 2>/dev/null; then
        has_script=true
        log_success "  script: ✓"
    fi

    if [[ "$has_prompts" == "false" && "$has_script" == "false" ]]; then
        log_error "  Hybrid command requires prompts or script"
        has_errors=true
    fi

    if [[ "$has_errors" == "true" ]]; then
        return 1
    fi

    return 0
}

# ============================================================================
# 메인 검증 함수
# ============================================================================

validate_command() {
    local command="$1"

    echo ""
    echo -e "${CYAN}Validating command: ${command}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # 타입 감지
    local cmd_type
    cmd_type=$(detect_command_type "$command")

    echo -e "  Type: ${MAGENTA}${cmd_type}${NC}"

    # 타입별 검증
    local validation_result=0
    case "$cmd_type" in
        workflow)
            validate_workflow_command "$command" || validation_result=$?
            ;;
        utility)
            validate_utility_command "$command" || validation_result=$?
            ;;
        hybrid)
            validate_hybrid_command "$command" || validation_result=$?
            ;;
        unknown)
            log_error "  Unknown command type - cannot validate"
            validation_result=1
            ;;
        *)
            log_error "  Invalid type: $cmd_type"
            validation_result=1
            ;;
    esac

    # 결과 출력
    echo ""
    if [[ $validation_result -eq 0 ]]; then
        echo -e "  Status: ${GREEN}✅ PASS${NC}"
    else
        echo -e "  Status: ${RED}❌ FAIL${NC}"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    return $validation_result
}

# ============================================================================
# 메인 함수
# ============================================================================

main() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <command-name>"
        echo ""
        echo "Examples:"
        echo "  $0 major"
        echo "  $0 commit"
        echo "  $0 triage"
        echo ""
        echo "Options:"
        echo "  --debug    Enable debug output"
        exit 1
    fi

    # 옵션 파싱
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --debug)
                DEBUG=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    local command="$1"

    validate_command "$command"
}

# 스크립트로 직접 실행된 경우만 main 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
