#!/usr/bin/env bash
# command-recommender.sh - 명령어 추천 시스템
# 명령어 완료 후 다음 단계를 추천하고 자동 실행하는 시스템

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="${CLAUDE_DIR}/commands-config"
CONFIG_LOADER="${SCRIPT_DIR}/config-loader.sh"

# config-loader 로드
if [[ ! -f "$CONFIG_LOADER" ]]; then
    echo "ERROR: config-loader.sh not found" >&2
    exit 1
fi

# shellcheck source=config-loader.sh
source "$CONFIG_LOADER"

# 색상 코드와 로깅 함수는 config-loader.sh에서 제공됨
# config-loader에 없는 색상만 추가 정의
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${MAGENTA}[DEBUG]${NC} $*" >&2
    fi
}

# ============================================================================
# YAML next_commands 설정 읽기
# ============================================================================

# YAML에서 next_commands 섹션 읽기
read_next_commands_config() {
    local command="$1"
    local config_file="${CONFIG_DIR}/${command}.yaml"

    if [[ ! -f "$config_file" ]]; then
        log_debug "Config file not found: $config_file"
        echo ""
        return 1
    fi

    # next_commands.enabled 확인
    if command -v yq &> /dev/null; then
        local enabled
        enabled=$(yq eval '.next_commands.enabled // false' "$config_file" 2>/dev/null)

        if [[ "$enabled" != "true" ]]; then
            log_debug "next_commands disabled for $command"
            echo ""
            return 1
        fi

        # next_commands.recommendations 읽기 (JSON 형식으로 출력)
        local recommendations
        recommendations=$(yq eval '.next_commands.recommendations // []' "$config_file" -o=json 2>/dev/null)

        echo "$recommendations"
        return 0
    else
        # yq 없이 간단한 파싱
        if ! grep -q "^next_commands:" "$config_file"; then
            log_debug "next_commands section not found"
            echo ""
            return 1
        fi

        # 간단한 추출 (제한적)
        log_warn "yq not found, using limited YAML parsing"
        echo "[]"
        return 0
    fi
}

# ============================================================================
# 추천 조건 검사
# ============================================================================

# 조건 검사 (bash 명령어 실행)
check_recommendation_condition() {
    local condition="$1"

    if [[ -z "$condition" ]]; then
        # 조건 없으면 항상 true
        return 0
    fi

    log_debug "Checking condition: $condition"

    # 조건 실행 (안전하게)
    if eval "$condition" >/dev/null 2>&1; then
        log_debug "Condition passed"
        return 0
    else
        log_debug "Condition failed"
        return 1
    fi
}

# ============================================================================
# 명령어 추천 및 실행
# ============================================================================

# 다음 명령어 추천
recommend_next_command() {
    local completed_command="$1"
    local exit_code="${2:-0}"

    log_info "Checking for next command recommendations..."

    # next_commands 설정 읽기
    local recommendations
    recommendations=$(read_next_commands_config "$completed_command")

    if [[ -z "$recommendations" || "$recommendations" == "[]" ]]; then
        log_debug "No recommendations configured"
        return 0
    fi

    # Python/jq로 JSON 파싱 (yq가 설치되어 있으므로 jq도 있을 가능성 높음)
    if command -v jq &> /dev/null; then
        parse_and_recommend_with_jq "$recommendations" "$exit_code"
    elif command -v python3 &> /dev/null; then
        parse_and_recommend_with_python "$recommendations" "$exit_code"
    else
        log_warn "No JSON parser available (jq or python3 required)"
        return 1
    fi
}

# jq를 사용한 파싱 및 추천
parse_and_recommend_with_jq() {
    local recommendations="$1"
    local exit_code="$2"

    # trigger 필터링 (on_success/on_failure)
    local trigger="on_success"
    if [[ $exit_code -ne 0 ]]; then
        trigger="on_failure"
    fi

    # 조건에 맞는 추천 필터링
    local filtered
    filtered=$(echo "$recommendations" | jq -r --arg trigger "$trigger" '
        [.[] | select(.trigger == $trigger)] | sort_by(.priority) | .[0]
    ' 2>/dev/null)

    if [[ -z "$filtered" || "$filtered" == "null" ]]; then
        log_debug "No recommendations for trigger: $trigger"
        return 0
    fi

    # 추천 정보 추출
    local next_command
    local condition
    local auto_execute

    next_command=$(echo "$filtered" | jq -r '.command // ""')
    condition=$(echo "$filtered" | jq -r '.condition // ""')
    auto_execute=$(echo "$filtered" | jq -r '.auto_execute // false')

    # 조건 검사
    if [[ -n "$condition" ]]; then
        if ! check_recommendation_condition "$condition"; then
            log_debug "Recommendation condition not met"
            return 0
        fi
    fi

    # 추천 표시
    display_recommendation "$next_command" "$auto_execute"
}

# Python을 사용한 파싱 및 추천
parse_and_recommend_with_python() {
    local recommendations="$1"
    local exit_code="$2"

    local trigger="on_success"
    if [[ $exit_code -ne 0 ]]; then
        trigger="on_failure"
    fi

    # Python으로 JSON 파싱
    local result
    result=$(python3 -c "
import json
import sys

recommendations = json.loads('''$recommendations''')
trigger = '$trigger'

# trigger 필터링 및 우선순위 정렬
filtered = [r for r in recommendations if r.get('trigger') == trigger]
if not filtered:
    sys.exit(0)

# 우선순위 정렬 (낮은 숫자가 높은 우선순위)
filtered.sort(key=lambda x: x.get('priority', 999))
selected = filtered[0]

# 추천 정보 출력
print(json.dumps(selected))
" 2>/dev/null)

    if [[ -z "$result" ]]; then
        log_debug "No recommendations for trigger: $trigger"
        return 0
    fi

    # 추천 정보 추출
    local next_command
    local condition
    local auto_execute

    next_command=$(echo "$result" | python3 -c "import json, sys; print(json.load(sys.stdin).get('command', ''))" 2>/dev/null)
    condition=$(echo "$result" | python3 -c "import json, sys; print(json.load(sys.stdin).get('condition', ''))" 2>/dev/null)
    auto_execute=$(echo "$result" | python3 -c "import json, sys; print(json.load(sys.stdin).get('auto_execute', False))" 2>/dev/null)

    # 조건 검사
    if [[ -n "$condition" ]]; then
        if ! check_recommendation_condition "$condition"; then
            log_debug "Recommendation condition not met"
            return 0
        fi
    fi

    # 추천 표시
    display_recommendation "$next_command" "$auto_execute"
}

# ============================================================================
# 추천 표시 및 실행
# ============================================================================

# 추천 표시 (AskUserQuestion 가이드 출력)
display_recommendation() {
    local next_command="$1"
    local auto_execute="${2:-false}"

    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  다음 단계 추천${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    log_info "추천 명령어: ${CYAN}${next_command}${NC}"
    echo ""

    if [[ "$auto_execute" == "true" ]]; then
        log_info "자동 실행 모드가 활성화되어 있습니다."
        echo ""
    fi

    # Claude를 위한 AskUserQuestion 가이드
    cat << 'EOF'
Note: Claude가 이 메시지를 보면 AskUserQuestion을 사용하여 다음 옵션을 제공해야 합니다:

**질문**: "다음 단계를 진행하시겠습니까?"
**헤더**: "다음 단계"
**multiSelect**: false
**옵션**:
  1. label: "예, 바로 실행"
     description: "추천된 명령어를 즉시 실행합니다"
  2. label: "나중에 수동 실행"
     description: "지금은 건너뛰고 나중에 직접 실행합니다"

사용자가 "예, 바로 실행"을 선택한 경우:
EOF

    echo "  슬래시 명령어를 사용하여 ${next_command} 실행"
    echo ""

    log_success "추천 정보가 Claude에게 전달되었습니다."
}

# ============================================================================
# 메인 함수
# ============================================================================

main() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <completed-command> [exit-code]"
        echo ""
        echo "Examples:"
        echo "  $0 major 0"
        echo "  $0 commit 0"
        echo "  $0 triage 1"
        exit 1
    fi

    local completed_command="$1"
    local exit_code="${2:-0}"

    recommend_next_command "$completed_command" "$exit_code"
}

# 스크립트로 직접 실행된 경우만 main 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
