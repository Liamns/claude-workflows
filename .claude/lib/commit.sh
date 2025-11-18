#!/bin/bash
# commit.sh
# Smart commit automation using documenter-unified agent
# Generates Conventional Commits format messages with context analysis
#
# Usage: bash .claude/lib/commit.sh
#
# Prerequisites:
# - Git repository with staged changes
# - documenter-unified agent available
# - Notion MCP (optional) for changelog integration

set -euo pipefail

# Script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source dependencies
# shellcheck source=.claude/lib/common.sh
source "${SCRIPT_DIR}/common.sh"

# ==============================================================================
# Configuration
# ==============================================================================

readonly COMMIT_FOOTER="🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

readonly CONVENTIONAL_TYPES=(
    "feat:새로운 기능 추가"
    "fix:버그 수정"
    "docs:문서 변경"
    "style:코드 포맷팅 (기능 변경 없음)"
    "refactor:코드 리팩토링"
    "perf:성능 개선"
    "test:테스트 추가 또는 수정"
    "chore:빌드 프로세스 또는 도구 변경"
    "ci:CI 설정 변경"
    "build:빌드 시스템 변경"
)

# ==============================================================================
# Pre-flight Checks
# ==============================================================================

# Check if we're in a git repository
check_git_repository() {
    log_info "Git 저장소 확인 중..."

    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Git 저장소가 아닙니다."
        log_error "git init을 먼저 실행하세요."
        return 1
    fi

    log_success "Git 저장소 확인 완료"
    return 0
}

# Check if there are staged changes
check_staged_changes() {
    log_info "스테이징된 변경사항 확인 중..."

    if ! git diff --cached --quiet 2>/dev/null; then
        log_success "스테이징된 변경사항이 있습니다."
        return 0
    else
        log_warning "스테이징된 변경사항이 없습니다."
        log_info "다음 명령어로 파일을 스테이징하세요:"
        log_info "  git add <files>"
        return 1
    fi
}

# ==============================================================================
# Change Analysis
# ==============================================================================

# Get list of staged files
get_staged_files() {
    git diff --cached --name-only
}

# Get detailed diff of staged changes
get_staged_diff() {
    git diff --cached
}

# Get recent commit messages for style consistency
get_recent_commits() {
    local count="${1:-10}"
    git log -n "$count" --pretty=format:"%s" 2>/dev/null || echo ""
}

# Display change summary
display_change_summary() {
    log_info "변경사항 요약:"
    echo ""

    local files_changed
    files_changed=$(get_staged_files | wc -l | tr -d ' ')

    local additions deletions
    additions=$(git diff --cached --numstat | awk '{s+=$1} END {print s}' || echo "0")
    deletions=$(git diff --cached --numstat | awk '{s+=$2} END {print s}' || echo "0")

    echo "  Files changed: ${files_changed}"
    echo "  Lines added:   +${additions}"
    echo "  Lines deleted: -${deletions}"
    echo ""

    log_info "변경된 파일:"
    get_staged_files | head -10 | sed 's/^/  /'

    local total_files
    total_files=$(get_staged_files | wc -l | tr -d ' ')
    if [ "$total_files" -gt 10 ]; then
        echo "  ... and $((total_files - 10)) more files"
    fi
    echo ""
}

# ==============================================================================
# Commit Type Detection
# ==============================================================================

# Detect commit type from changed files
detect_commit_type() {
    local files
    files=$(get_staged_files)

    # Check for documentation changes
    if echo "$files" | grep -qE '\.(md|txt|rst)$'; then
        if echo "$files" | grep -qvE '\.(md|txt|rst)$'; then
            # Mixed docs and code
            echo "mixed"
        else
            # Only docs
            echo "docs"
        fi
        return 0
    fi

    # Check for test files
    if echo "$files" | grep -qE 'test|spec|__tests__'; then
        echo "test"
        return 0
    fi

    # Check for CI/build files
    if echo "$files" | grep -qE '\.github|\.gitlab|Dockerfile|docker-compose|package\.json|yarn\.lock'; then
        echo "ci"
        return 0
    fi

    # Check for style/formatting files
    if echo "$files" | grep -qE '\.prettierrc|\.eslintrc|\.editorconfig'; then
        echo "style"
        return 0
    fi

    # Default to analyzing diff for feature vs fix
    local diff
    diff=$(get_staged_diff)

    if echo "$diff" | grep -qiE '\+.*fix|bug|error|issue'; then
        echo "fix"
    else
        echo "feat"
    fi
}

# Extract scope from file paths
extract_scope() {
    local files
    files=$(get_staged_files)

    # Try to find common directory
    local common_dir
    common_dir=$(echo "$files" | sed 's|/[^/]*$||' | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')

    if [ -n "$common_dir" ]; then
        # Get the last meaningful directory name
        basename "$common_dir"
    else
        # Use the first file's directory
        echo "$files" | head -1 | sed 's|/[^/]*$||' | xargs basename
    fi
}

# ==============================================================================
# Commit Message Generation
# ==============================================================================

# Generate commit message using analysis
generate_commit_message() {
    log_info "커밋 메시지 생성 중..."

    local commit_type
    commit_type=$(detect_commit_type)

    local scope
    scope=$(extract_scope)

    local diff
    diff=$(get_staged_diff)

    local recent_commits
    recent_commits=$(get_recent_commits)

    # Build context for AI
    local context="Staged Changes Summary:
Files: $(get_staged_files | wc -l | tr -d ' ')
Detected Type: ${commit_type}
Detected Scope: ${scope}

Recent Commit Messages (for style consistency):
${recent_commits}

Staged Diff:
${diff}

---

Generate a Conventional Commits format message with:
1. Type: ${commit_type}
2. Scope: ${scope} (adjust if needed)
3. Subject: Clear, concise description (max 72 chars)
4. Body: Bullet points explaining changes (optional, only if complex)

Format:
<type>(<scope>): <subject>

- <detail 1>
- <detail 2>

Rules:
- Subject in imperative mood (\"add\" not \"added\")
- No period at end of subject
- Body is optional for simple changes
- Focus on WHAT and WHY, not HOW"

    # This is where the documenter-unified agent would be called
    # For now, return the context for the AI to process
    echo "$context"
}

# Format final commit message with footer
format_commit_message() {
    local message="$1"

    # Add footer
    echo "${message}

${COMMIT_FOOTER}"
}

# ==============================================================================
# Commit Execution
# ==============================================================================

# Execute commit with generated message
execute_commit() {
    local message="$1"

    log_info "커밋 실행 중..."

    # Use heredoc to preserve formatting
    if git commit -m "$(cat <<EOF
${message}
EOF
)"; then
        local commit_hash
        commit_hash=$(git rev-parse --short HEAD)

        log_success "커밋 완료: ${commit_hash}"

        # Display commit details
        echo ""
        log_info "커밋 정보:"
        git show --stat --pretty=format:"%h - %s%n%b" HEAD | head -20
        echo ""

        return 0
    else
        log_error "커밋 실패"
        log_warning "Pre-commit hook이 실패했을 수 있습니다."
        log_info "에러를 확인하고 다시 시도하세요."
        return 1
    fi
}

# ==============================================================================
# Breaking Change Detection
# ==============================================================================

# Check for breaking changes in diff
detect_breaking_changes() {
    local diff
    diff=$(get_staged_diff)

    # Check for API signature changes
    if echo "$diff" | grep -qE '^\-.*export (function|class|interface|type)'; then
        log_warning "Breaking change 감지: API 시그니처 변경"
        return 0
    fi

    # Check for removed exports
    if echo "$diff" | grep -qE '^\-.*export'; then
        log_warning "Breaking change 감지: Export 제거"
        return 0
    fi

    return 1
}

# Add breaking change footer if needed
add_breaking_change_footer() {
    local message="$1"
    local breaking_description="$2"

    echo "${message}

BREAKING CHANGE: ${breaking_description}"
}

# ==============================================================================
# Main Workflow
# ==============================================================================

main() {
    log_info "=== Smart Commit 시작 ==="
    echo ""

    # Pre-flight checks
    check_git_repository || exit 1
    check_staged_changes || exit 1

    echo ""

    # Display change summary
    display_change_summary

    # Check for breaking changes
    local has_breaking_changes=false
    if detect_breaking_changes; then
        has_breaking_changes=true
        echo ""
        log_warning "⚠️  Breaking changes가 감지되었습니다."
        log_info "커밋 메시지에 BREAKING CHANGE 푸터가 추가됩니다."
        echo ""
    fi

    # Generate commit message
    # NOTE: In actual implementation, this would call the documenter-unified agent
    # For now, we'll output the context that would be sent to the agent
    log_info "=== 커밋 메시지 생성 컨텍스트 ==="
    echo ""
    echo "다음 정보를 documenter-unified 에이전트로 전송합니다:"
    echo ""

    local commit_context
    commit_context=$(generate_commit_message)
    echo "$commit_context"

    echo ""
    log_info "=== 에이전트 사용 방법 ==="
    echo ""
    echo "실제 사용 시에는 documenter-unified 에이전트가:"
    echo "1. 위 컨텍스트를 분석"
    echo "2. Conventional Commits 형식의 메시지 생성"
    echo "3. 최근 커밋 스타일과 일관성 유지"
    echo "4. 자동으로 커밋 실행"
    echo ""

    log_success "스크립트 완료"
    log_info "현재는 컨텍스트만 출력하며, 실제 커밋은 실행되지 않습니다."
    log_info "에이전트 통합 후 자동 커밋이 실행됩니다."

    return 0
}

# ==============================================================================
# Script Entry Point
# ==============================================================================

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
