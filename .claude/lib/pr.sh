#!/bin/bash
# pr.sh
# Automated pull request creation with intelligent descriptions
# Uses documenter-unified agent for PR content generation
#
# Usage: bash .claude/lib/pr.sh [--base <branch>] [--draft] [--no-push]
#
# Prerequisites:
# - Git repository with commits
# - GitHub CLI (gh) installed and authenticated
# - Remote repository configured

set -euo pipefail

# Script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source dependencies
# shellcheck source=.claude/lib/common.sh
source "${SCRIPT_DIR}/common.sh"

# ==============================================================================
# Configuration
# ==============================================================================

readonly PR_FOOTER="🤖 Generated with [Claude Code](https://claude.com/claude-code)"

# Default options
BASE_BRANCH=""
IS_DRAFT=false
NO_PUSH=false

# ==============================================================================
# Argument Parsing
# ==============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --base)
                BASE_BRANCH="$2"
                shift 2
                ;;
            --draft)
                IS_DRAFT=true
                shift
                ;;
            --no-push)
                NO_PUSH=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                log_info "Usage: pr.sh [--base <branch>] [--draft] [--no-push]"
                exit 1
                ;;
        esac
    done
}

# ==============================================================================
# Pre-flight Checks
# ==============================================================================

# Check if we're in a git repository
check_git_repository() {
    log_info "Git 저장소 확인 중..."

    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Git 저장소가 아닙니다."
        return 1
    fi

    log_success "Git 저장소 확인 완료"
    return 0
}

# Check if GitHub CLI is installed
check_gh_cli() {
    log_info "GitHub CLI 확인 중..."

    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh)가 설치되지 않았습니다."
        log_info "설치 방법:"
        log_info "  macOS: brew install gh"
        log_info "  Linux: https://cli.github.com/"
        return 1
    fi

    log_success "GitHub CLI 확인 완료"
    return 0
}

# Check if GitHub CLI is authenticated
check_gh_auth() {
    log_info "GitHub 인증 확인 중..."

    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI가 인증되지 않았습니다."
        log_info "다음 명령어를 실행하세요:"
        log_info "  gh auth login"
        return 1
    fi

    log_success "GitHub 인증 확인 완료"
    return 0
}

# ==============================================================================
# Branch Information
# ==============================================================================

# Get current branch name
get_current_branch() {
    git rev-parse --abbrev-ref HEAD
}

# Auto-detect base branch
detect_base_branch() {
    # Check if main exists
    if git rev-parse --verify main &> /dev/null; then
        echo "main"
    # Check if master exists
    elif git rev-parse --verify master &> /dev/null; then
        echo "master"
    # Check remote default branch
    elif git remote show origin | grep "HEAD branch" | awk '{print $NF}' 2>/dev/null; then
        git remote show origin | grep "HEAD branch" | awk '{print $NF}'
    else
        echo "main"
    fi
}

# Get commit count between branches
get_commit_count() {
    local base="$1"
    local head="$2"
    git rev-list --count "${base}..${head}" 2>/dev/null || echo "0"
}

# Check if branch exists on remote
check_remote_branch() {
    local branch="$1"
    git ls-remote --heads origin "$branch" | grep -q "$branch"
}

# ==============================================================================
# Change Analysis
# ==============================================================================

# Get commit messages since divergence
get_commit_messages() {
    local base="$1"
    local head="$2"
    git log "${base}..${head}" --pretty=format:"%s" 2>/dev/null || echo ""
}

# Get commit details with body
get_commit_details() {
    local base="$1"
    local head="$2"
    git log "${base}..${head}" --pretty=format:"%s%n%b" 2>/dev/null || echo ""
}

# Get diff statistics
get_diff_stats() {
    local base="$1"
    local head="$2"

    local files_changed additions deletions

    # Get stats
    local stats
    stats=$(git diff --shortstat "${base}...${head}" 2>/dev/null || echo "")

    if [ -n "$stats" ]; then
        files_changed=$(echo "$stats" | awk '{print $1}')
        additions=$(echo "$stats" | awk '{print $4}')
        deletions=$(echo "$stats" | awk '{print $6}')
    else
        files_changed=0
        additions=0
        deletions=0
    fi

    echo "${files_changed}|${additions}|${deletions}"
}

# Get list of changed files
get_changed_files() {
    local base="$1"
    local head="$2"
    git diff --name-only "${base}...${head}" 2>/dev/null || echo ""
}

# Display branch analysis
display_branch_analysis() {
    local current_branch="$1"
    local base_branch="$2"

    echo ""
    log_info "📊 Analyzing branch: ${current_branch}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Get commit count
    local commit_count
    commit_count=$(get_commit_count "$base_branch" "$current_branch")

    # Get diff stats
    local stats
    stats=$(get_diff_stats "$base_branch" "$current_branch")
    local files_changed additions deletions
    IFS='|' read -r files_changed additions deletions <<< "$stats"

    echo "Base branch: ${base_branch}"
    echo "Commits: ${commit_count}"
    echo "Files changed: ${files_changed}"
    echo "+ Additions: ${additions}"
    echo "- Deletions: ${deletions}"
    echo ""

    # Show commit messages
    log_info "Recent commits:"
    get_commit_messages "$base_branch" "$current_branch" | head -5 | sed 's/^/  /'
    echo ""
}

# ==============================================================================
# PR Description Generation
# ==============================================================================

# Generate PR title from commits
generate_pr_title() {
    local base="$1"
    local head="$2"

    # Get the most recent commit message
    local latest_commit
    latest_commit=$(git log -1 --pretty=format:"%s" "$head")

    # If it's a conventional commit, use it
    if echo "$latest_commit" | grep -qE '^(feat|fix|docs|style|refactor|perf|test|chore)\(.*\):'; then
        echo "$latest_commit"
    else
        # Otherwise, try to find a conventional commit in the range
        local first_conventional
        first_conventional=$(get_commit_messages "$base" "$head" | grep -E '^(feat|fix|docs|style|refactor|perf|test|chore)\(.*\):' | head -1)

        if [ -n "$first_conventional" ]; then
            echo "$first_conventional"
        else
            # Fallback to latest commit
            echo "$latest_commit"
        fi
    fi
}

# Generate PR body
generate_pr_body() {
    local base="$1"
    local head="$2"

    log_info "🔍 Generating PR description..."

    # Get commit messages
    local commits
    commits=$(get_commit_messages "$base" "$head")

    # Get changed files
    local files
    files=$(get_changed_files "$base" "$head")

    # Build PR body context
    local context="Branch Comparison:
Base: ${base}
Head: ${head}
Commits: $(get_commit_count "$base" "$head")

Commit Messages:
${commits}

Changed Files:
${files}

---

Generate a comprehensive PR description with:

## Summary
- Bullet points summarizing main changes (3-5 bullets)
- Focus on WHAT changed and WHY

## Changes
- Group changes by area/module
- List key files modified

## Test Plan
- [ ] Manual testing steps
- [ ] Automated test commands
- [ ] CI/CD verification steps

Keep it concise but informative.
Use present tense (\"Add\" not \"Added\")."

    # Return context for AI processing
    echo "$context"
}

# Format final PR body with footer
format_pr_body() {
    local body="$1"

    echo "${body}

${PR_FOOTER}"
}

# ==============================================================================
# Push Operations
# ==============================================================================

# Push current branch to remote
push_branch() {
    local branch="$1"

    log_info "Pushing branch to remote..."

    if git push -u origin "$branch" 2>&1; then
        log_success "Branch pushed: ${branch}"
        return 0
    else
        log_error "Failed to push branch"
        return 1
    fi
}

# ==============================================================================
# PR Creation
# ==============================================================================

# Create pull request using gh CLI
create_pull_request() {
    local title="$1"
    local body="$2"
    local base="$3"
    local draft="$4"

    log_info "📝 Creating pull request..."

    local gh_args=(
        "pr" "create"
        "--title" "$title"
        "--body" "$body"
        "--base" "$base"
    )

    # Add draft flag if needed
    if [ "$draft" = true ]; then
        gh_args+=("--draft")
    fi

    # Execute gh pr create
    if gh "${gh_args[@]}"; then
        echo ""
        log_success "✅ Pull Request Created!"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        # Get PR URL
        local pr_url
        pr_url=$(gh pr view --json url --jq .url 2>/dev/null || echo "")

        if [ -n "$pr_url" ]; then
            echo "Title: ${title}"
            echo ""
            echo "URL: ${pr_url}"
            echo ""
        fi

        # Show next steps
        log_info "Next steps:"
        echo "  - Review the PR description"
        echo "  - Request reviewers"
        echo "  - Wait for CI/CD checks"

        if [ "$draft" = true ]; then
            echo "  - Mark as 'Ready for review' when complete"
        fi

        echo ""
        return 0
    else
        log_error "Failed to create pull request"
        return 1
    fi
}

# ==============================================================================
# Main Workflow
# ==============================================================================

main() {
    # Parse arguments
    parse_arguments "$@"

    log_info "=== Pull Request 생성 시작 ==="
    echo ""

    # Pre-flight checks
    check_git_repository || exit 1
    check_gh_cli || exit 1
    check_gh_auth || exit 1

    # Get current branch
    local current_branch
    current_branch=$(get_current_branch)

    if [ "$current_branch" = "main" ] || [ "$current_branch" = "master" ]; then
        log_error "현재 main/master 브랜치입니다."
        log_info "Feature 브랜치에서 PR을 생성하세요."
        exit 1
    fi

    log_success "Current branch: ${current_branch}"

    # Detect or use base branch
    if [ -z "$BASE_BRANCH" ]; then
        BASE_BRANCH=$(detect_base_branch)
        log_info "Auto-detected base branch: ${BASE_BRANCH}"
    fi

    # Check if we have commits
    local commit_count
    commit_count=$(get_commit_count "$BASE_BRANCH" "$current_branch")

    if [ "$commit_count" -eq 0 ]; then
        log_error "No commits to create PR"
        log_info "Base branch와 동일하거나 커밋이 없습니다."
        exit 1
    fi

    # Display analysis
    display_branch_analysis "$current_branch" "$BASE_BRANCH"

    # Push branch if needed
    if [ "$NO_PUSH" = false ]; then
        if ! check_remote_branch "$current_branch"; then
            push_branch "$current_branch" || exit 1
        else
            log_info "Branch already exists on remote"
        fi
    fi

    # Generate PR content
    local pr_title
    pr_title=$(generate_pr_title "$BASE_BRANCH" "$current_branch")

    log_info "=== PR 생성 컨텍스트 ==="
    echo ""
    echo "다음 정보를 documenter-unified 에이전트로 전송합니다:"
    echo ""

    local pr_body_context
    pr_body_context=$(generate_pr_body "$BASE_BRANCH" "$current_branch")
    echo "$pr_body_context"

    echo ""
    log_info "=== 에이전트 사용 방법 ==="
    echo ""
    echo "실제 사용 시에는 documenter-unified 에이전트가:"
    echo "1. 위 컨텍스트를 분석"
    echo "2. PR description 생성"
    echo "3. Summary, Changes, Test Plan 섹션 작성"
    echo "4. gh pr create 명령어로 PR 생성"
    echo ""

    echo "Generated PR Title:"
    echo "  ${pr_title}"
    echo ""

    log_success "스크립트 완료"
    log_info "현재는 컨텍스트만 출력하며, 실제 PR은 생성되지 않습니다."
    log_info "에이전트 통합 후 자동으로 PR이 생성됩니다."

    # Example of what would be called:
    # local pr_body
    # pr_body=$(call_documenter_agent "$pr_body_context")
    # pr_body=$(format_pr_body "$pr_body")
    # create_pull_request "$pr_title" "$pr_body" "$BASE_BRANCH" "$IS_DRAFT"

    return 0
}

# ==============================================================================
# Script Entry Point
# ==============================================================================

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
