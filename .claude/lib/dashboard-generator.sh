#!/bin/bash
# Dashboard Generator
# Generates beautiful terminal dashboards for workflow metrics

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
RESET='\033[0m'

# Box drawing characters
BOX_TL="╔"
BOX_TR="╗"
BOX_BL="╚"
BOX_BR="╝"
BOX_H="═"
BOX_V="║"
BOX_ML="╠"
BOX_MR="╣"

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/metrics-collector.sh" 2>/dev/null || true
source "$SCRIPT_DIR/git-stats-helper.sh" 2>/dev/null || true

# Draw horizontal line
draw_line() {
    local width="${1:-50}"
    local left="${2:-$BOX_ML}"
    local right="${3:-$BOX_MR}"
    local char="${4:-$BOX_H}"

    echo -n "$left"
    for ((i=0; i<width-2; i++)); do
        echo -n "$char"
    done
    echo "$right"
}

# Draw box top
draw_box_top() {
    local width="${1:-50}"
    draw_line "$width" "$BOX_TL" "$BOX_TR" "$BOX_H"
}

# Draw box bottom
draw_box_bottom() {
    local width="${1:-50}"
    draw_line "$width" "$BOX_BL" "$BOX_BR" "$BOX_H"
}

# Draw text line in box
draw_box_line() {
    local text="$1"
    local width="${2:-50}"
    local color="${3:-$RESET}"

    local text_len=${#text}
    local padding=$((width - text_len - 4))

    echo -n "$BOX_V "
    echo -n -e "${color}${text}${RESET}"
    printf "%${padding}s" ""
    echo " $BOX_V"
}

# Format number with commas
format_number() {
    local num="$1"
    if command -v numfmt &> /dev/null; then
        numfmt --grouping "$num" 2>/dev/null || echo "$num"
    else
        # Fallback: simple formatting
        echo "$num" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'
    fi
}

# Format percentage
format_percent() {
    local value="$1"
    local color=""

    if [ "$value" -ge 80 ]; then
        color="$GREEN"
    elif [ "$value" -ge 50 ]; then
        color="$YELLOW"
    else
        color="$RED"
    fi

    echo -e "${color}${value}%${RESET}"
}

# Format boolean as checkmark
format_bool() {
    local value="$1"
    if [ "$value" = "true" ]; then
        echo -e "${GREEN}✓${RESET}"
    else
        echo -e "${RED}✗${RESET}"
    fi
}

# Generate token usage section
dashboard_section_tokens() {
    local metrics="$1"
    local width="${2:-50}"

    local total=$(echo "$metrics" | jq -r '.tokens.total_used // 0' 2>/dev/null || echo "0")
    local saved=$(echo "$metrics" | jq -r '.tokens.saved // 0' 2>/dev/null || echo "0")
    local efficiency=$(echo "$metrics" | jq -r '.tokens.efficiency_percent // 0' 2>/dev/null || echo "0")

    # Calculate savings percentage
    local total_potential=$((total + saved))
    local savings_pct=0
    if [ "$total_potential" -gt 0 ]; then
        savings_pct=$((saved * 100 / total_potential))
    fi

    draw_box_line "📊 토큰 사용량" "$width" "$BOLD$CYAN"
    draw_box_line "  총 사용: $(format_number $total) | 절감: $(format_number $saved) ($(format_percent $savings_pct))" "$width"
}

# Generate performance section
dashboard_section_performance() {
    local metrics="$1"
    local width="${2:-50}"

    local exec_time=$(echo "$metrics" | jq -r '.performance.execution_time_seconds // 0' 2>/dev/null || echo "0")
    local cache_hits=$(echo "$metrics" | jq -r '.performance.cache_hits // 0' 2>/dev/null || echo "0")
    local cache_misses=$(echo "$metrics" | jq -r '.performance.cache_misses // 0' 2>/dev/null || echo "0")
    local cache_rate=$(echo "$metrics" | jq -r '.performance.cache_hit_rate_percent // 0' 2>/dev/null || echo "0")
    local parallel=$(echo "$metrics" | jq -r '.performance.parallel_agents // 0' 2>/dev/null || echo "0")

    # Format execution time
    local time_str="${exec_time}s"
    if [ "$exec_time" -gt 60 ]; then
        local minutes=$((exec_time / 60))
        local seconds=$((exec_time % 60))
        time_str="${minutes}m ${seconds}s"
    fi

    draw_line "$width"
    draw_box_line "⚡ 성능 메트릭" "$width" "$BOLD$YELLOW"
    draw_box_line "  실행 시간: $time_str | 캐시 히트: $(format_percent $cache_rate)" "$width"
    if [ "$parallel" -gt 0 ]; then
        draw_box_line "  병렬 에이전트: $parallel" "$width"
    fi
}

# Generate quality section
dashboard_section_quality() {
    local metrics="$1"
    local width="${2:-50}"

    local coverage=$(echo "$metrics" | jq -r '.quality.test_coverage_percent // 0' 2>/dev/null || echo "0")
    local type_check=$(echo "$metrics" | jq -r '.quality.type_check_passed // false' 2>/dev/null || echo "false")
    local lint=$(echo "$metrics" | jq -r '.quality.lint_passed // false' 2>/dev/null || echo "false")
    local security=$(echo "$metrics" | jq -r '.quality.security_issues // 0' 2>/dev/null || echo "0")

    draw_line "$width"
    draw_box_line "✅ 품질 지표" "$width" "$BOLD$GREEN"

    # Show coverage if available
    if [ "$coverage" -gt 0 ]; then
        draw_box_line "  커버리지: $(format_percent $coverage) | 타입 체크: $(format_bool $type_check)" "$width"
    else
        draw_box_line "  타입 체크: $(format_bool $type_check) | 린트: $(format_bool $lint)" "$width"
    fi

    # Show security issues if any
    if [ "$security" -gt 0 ]; then
        draw_box_line "  보안 이슈: ${RED}${security}${RESET}" "$width"
    fi
}

# Generate productivity section
dashboard_section_productivity() {
    local metrics="$1"
    local width="${2:-50}"

    local tasks=$(echo "$metrics" | jq -r '.productivity.tasks_completed // 0' 2>/dev/null || echo "0")
    local bugs=$(echo "$metrics" | jq -r '.productivity.bugs_fixed // 0' 2>/dev/null || echo "0")
    local features=$(echo "$metrics" | jq -r '.productivity.features_added // 0' 2>/dev/null || echo "0")
    local files=$(echo "$metrics" | jq -r '.productivity.files_changed // 0' 2>/dev/null || echo "0")
    local lines_add=$(echo "$metrics" | jq -r '.productivity.lines_added // 0' 2>/dev/null || echo "0")
    local lines_del=$(echo "$metrics" | jq -r '.productivity.lines_removed // 0' 2>/dev/null || echo "0")

    draw_line "$width"
    draw_box_line "🎯 생산성 지표" "$width" "$BOLD$MAGENTA"
    draw_box_line "  작업: $tasks | 버그: $bugs | 기능: $features" "$width"

    if [ "$files" -gt 0 ]; then
        draw_box_line "  변경 파일: $files | +$lines_add -$lines_del" "$width"
    fi
}

# Generate Git section
dashboard_section_git() {
    local width="${1:-50}"

    if ! command -v git &> /dev/null || [ ! -d .git ]; then
        return
    fi

    local git_stats=$(git_stats_all 2>/dev/null || echo '{}')
    local today_commits=$(echo "$git_stats" | jq -r '.today.commits // 0' 2>/dev/null || echo "0")
    local branch=$(echo "$git_stats" | jq -r '.branch.branch // "unknown"' 2>/dev/null || echo "unknown")
    local uncommitted=$(echo "$git_stats" | jq -r '.uncommitted.staged + .uncommitted.unstaged + .uncommitted.untracked // 0' 2>/dev/null || echo "0")

    draw_line "$width"
    draw_box_line "🔧 Git 상태" "$width" "$BOLD$BLUE"
    draw_box_line "  브랜치: $branch | 오늘 커밋: $today_commits" "$width"

    if [ "$uncommitted" -gt 0 ]; then
        draw_box_line "  변경사항: ${YELLOW}${uncommitted}${RESET} 파일" "$width"
    fi
}

# Generate full dashboard
dashboard_generate() {
    local mode="${1:-current}"  # current, daily, summary
    local width=50

    # Initialize metrics
    metrics_init

    # Get metrics based on mode
    local metrics=""
    case "$mode" in
        current)
            metrics=$(metrics_export)
            ;;
        daily)
            metrics=$(metrics_get_daily)
            ;;
        summary)
            metrics=$(cat "$SUMMARY_FILE" 2>/dev/null || echo '{}')
            ;;
    esac

    # Generate dashboard
    echo ""
    draw_box_top "$width"
    draw_box_line "🚀 Claude Workflow Dashboard" "$width" "$BOLD$WHITE"

    # Show mode
    case "$mode" in
        current)
            local session_start=$(echo "$metrics" | jq -r '.session_start // "unknown"' 2>/dev/null || echo "unknown")
            draw_box_line "현재 세션 - $session_start" "$width" "$GRAY"
            ;;
        daily)
            local date=$(echo "$metrics" | jq -r '.date // "unknown"' 2>/dev/null || echo "unknown")
            draw_box_line "오늘의 통계 - $date" "$width" "$GRAY"
            ;;
        summary)
            draw_box_line "전체 누적 통계" "$width" "$GRAY"
            ;;
    esac

    draw_line "$width"

    # Generate sections based on mode
    if [ "$mode" = "summary" ]; then
        # Summary view
        local total_workflows=$(echo "$metrics" | jq -r '.lifetime.total_workflows // 0' 2>/dev/null || echo "0")
        local total_tokens=$(echo "$metrics" | jq -r '.lifetime.total_tokens_used // 0' 2>/dev/null || echo "0")
        local total_saved=$(echo "$metrics" | jq -r '.lifetime.total_tokens_saved // 0' 2>/dev/null || echo "0")
        local total_tasks=$(echo "$metrics" | jq -r '.lifetime.total_tasks_completed // 0' 2>/dev/null || echo "0")

        draw_box_line "📈 전체 워크플로우: $(format_number $total_workflows)" "$width" "$BOLD"
        draw_box_line "📊 토큰 사용: $(format_number $total_tokens)" "$width"
        draw_box_line "💰 토큰 절감: $(format_number $total_saved)" "$width"
        draw_box_line "✅ 완료 작업: $(format_number $total_tasks)" "$width"
    else
        # Current/Daily view
        dashboard_section_tokens "$metrics" "$width"
        dashboard_section_performance "$metrics" "$width"
        dashboard_section_quality "$metrics" "$width"
        dashboard_section_productivity "$metrics" "$width"
        dashboard_section_git "$width"
    fi

    draw_box_bottom "$width"
    echo ""
}

# Show help
dashboard_help() {
    cat <<EOF
Usage: dashboard [OPTIONS]

Options:
  --current     현재 세션 통계 (기본값)
  --today       오늘의 통계
  --summary     전체 누적 통계
  --reset       현재 세션 초기화
  --help        이 도움말 표시

Examples:
  dashboard              # 현재 세션 대시보드
  dashboard --today      # 오늘의 통계
  dashboard --summary    # 전체 통계
  dashboard --reset      # 메트릭 초기화
EOF
}

# Main entry point
dashboard_main() {
    local mode="current"

    case "${1:-}" in
        --current)
            mode="current"
            ;;
        --today|--daily)
            mode="daily"
            ;;
        --summary)
            mode="summary"
            ;;
        --reset)
            metrics_reset
            return 0
            ;;
        --help|-h)
            dashboard_help
            return 0
            ;;
        "")
            mode="current"
            ;;
        *)
            echo "Unknown option: $1"
            dashboard_help
            return 1
            ;;
    esac

    dashboard_generate "$mode"
}

# Export functions
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    export -f dashboard_generate
    export -f dashboard_main
    export -f dashboard_help
else
    # Run if executed directly
    dashboard_main "$@"
fi
