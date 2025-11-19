#!/usr/bin/env bash
# validate-all-commands.sh - 모든 슬래시 명령어 검증
# 모든 명령어를 한 번에 검증하고 통계를 출력합니다

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
COMMANDS_DIR="${CLAUDE_DIR}/commands"
VALIDATOR="${SCRIPT_DIR}/validate-command-type.sh"

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

# ============================================================================
# 명령어 목록 수집
# ============================================================================

collect_commands() {
    local commands=()

    # .claude/commands/*.md 파일에서 명령어 이름 추출
    if [[ -d "$COMMANDS_DIR" ]]; then
        while IFS= read -r md_file; do
            if [[ -f "$md_file" ]]; then
                local command_name
                command_name=$(basename "$md_file" .md)
                commands+=("$command_name")
            fi
        done < <(find "$COMMANDS_DIR" -maxdepth 1 -name "*.md" -type f)
    fi

    # 배열을 줄바꿈으로 구분하여 출력
    printf '%s\n' "${commands[@]}" | sort
}

# ============================================================================
# 모든 명령어 검증
# ============================================================================

validate_all() {
    local verbose="${1:-false}"

    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  Validating All Slash Commands${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # 명령어 목록 수집
    log_info "Collecting commands..."
    local commands=()
    while IFS= read -r cmd; do
        commands+=("$cmd")
    done < <(collect_commands)

    local total=${#commands[@]}
    log_info "Found ${total} commands"
    echo ""

    # 검증 결과 추적
    local pass_count=0
    local fail_count=0
    local failed_commands=()

    # 각 명령어 검증
    for command in "${commands[@]}"; do
        if [[ "$verbose" == "true" ]]; then
            # 상세 출력
            if bash "$VALIDATOR" "$command"; then
                ((pass_count++))
            else
                ((fail_count++))
                failed_commands+=("$command")
            fi
        else
            # 간단한 출력
            echo -n "  Validating ${command}... "
            if bash "$VALIDATOR" "$command" >/dev/null 2>&1; then
                echo -e "${GREEN}✓ PASS${NC}"
                ((pass_count++))
            else
                echo -e "${RED}✗ FAIL${NC}"
                ((fail_count++))
                failed_commands+=("$command")
            fi
        fi
    done

    # 통계 출력
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  Validation Statistics${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Total Commands:  ${MAGENTA}${total}${NC}"
    echo -e "  ${GREEN}✓${NC} Passed:         ${GREEN}${pass_count}${NC}"
    echo -e "  ${RED}✗${NC} Failed:         ${RED}${fail_count}${NC}"

    # 성공률 계산
    if [[ $total -gt 0 ]]; then
        local success_rate
        success_rate=$(awk "BEGIN {printf \"%.1f\", ($pass_count / $total) * 100}")
        echo -e "  Success Rate:    ${CYAN}${success_rate}%${NC}"
    fi

    echo ""

    # 실패한 명령어 목록
    if [[ ${#failed_commands[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Failed Commands:${NC}"
        for cmd in "${failed_commands[@]}"; do
            echo -e "  ${RED}✗${NC} $cmd"
        done
        echo ""
    fi

    # 결과 반환
    if [[ $fail_count -eq 0 ]]; then
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║${NC}  ✅ All validations passed!${GREEN}║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║${NC}  ❌ Some validations failed${RED}║${NC}"
        echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        return 1
    fi
}

# ============================================================================
# 메인 함수
# ============================================================================

main() {
    local verbose=false

    # 옵션 파싱
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v)
                verbose=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [options]"
                echo ""
                echo "Validates all slash commands in .claude/commands/"
                echo ""
                echo "Options:"
                echo "  --verbose, -v    Show detailed validation output"
                echo "  --help, -h       Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0"
                echo "  $0 --verbose"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    # Validator 스크립트 확인
    if [[ ! -f "$VALIDATOR" ]]; then
        log_error "Validator script not found: $VALIDATOR"
        exit 1
    fi

    validate_all "$verbose"
}

# 스크립트로 직접 실행된 경우만 main 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
