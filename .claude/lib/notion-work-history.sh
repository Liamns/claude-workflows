#!/bin/bash
# notion-work-history.sh
# Notion work history management for commit tracking
# Compatible with bash 3.2+
#
# Usage: source .claude/lib/notion-work-history.sh
#
# Provides:
# - get_notion_start_date: Get start date from Notion page
# - extract_work_summary: Extract work summary from commit message
# - format_work_history_entry: Format work history entry
# - add_work_history_on_commit: Add work history entry on commit

# Prevent multiple sourcing
if [[ -n "${CLAUDE_NOTION_WORK_HISTORY_LOADED:-}" ]]; then
    return 0
fi
CLAUDE_NOTION_WORK_HISTORY_LOADED=1

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/notion-utils.sh"
source "${SCRIPT_DIR}/notion-date-utils.sh"
source "${SCRIPT_DIR}/notion-config.sh"

# Work history entry format
readonly WORK_HISTORY_FORMAT="- %s : %s - %s"  # summary : start_date - commit_date

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Date Retrieval Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Get start date from Notion page
# Arguments:
#   $1 - Page ID
# Output:
#   Start date in YYYY-MM-DD format (KST)
# Returns:
#   0 on success, 1 on failure
# Example:
#   get_notion_start_date "page-id-123"  # Returns: 2025-11-18
get_notion_start_date() {
    local page_id="$1"

    if [[ -z "$page_id" ]]; then
        log_error "Page ID cannot be empty" >&2
        return 1
    fi

    log_info "Getting start date from Notion page: ${page_id}" >&2

    # Fetch Notion page
    local page_data
    if ! page_data=$(fetch_notion_page "$page_id"); then
        log_error "Failed to fetch Notion page: ${page_id}" >&2
        return 1
    fi

    # Get start_date column name
    local start_date_col
    if ! start_date_col=$(get_column_name "start_date"); then
        log_error "Failed to get start_date column name" >&2
        return 1
    fi

    # Extract start date from page properties
    local start_date
    start_date=$(echo "$page_data" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    props = data.get('properties', {})

    # Get start date property
    start_date_obj = props.get('${start_date_col}', {}).get('date', {})
    start_date = start_date_obj.get('start', '') if start_date_obj else ''

    if not start_date:
        print('', file=sys.stderr)
        sys.exit(1)

    # Extract date part only (YYYY-MM-DD)
    # Notion returns ISO 8601 format: 2025-11-18 or 2025-11-18T00:00:00.000Z
    start_date = start_date.split('T')[0]

    print(start_date)
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
")

    if [[ -z "$start_date" ]]; then
        log_error "Start date not found in Notion page" >&2
        return 1
    fi

    log_success "Start date: ${start_date}" >&2
    echo "$start_date"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Work Summary Extraction Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Extract work summary from commit message
# Arguments:
#   $1 - Commit message (full)
#   $2 - Workflow context JSON (optional)
# Output:
#   Work summary (max 50 characters)
# Returns:
#   0 on success
# Example:
#   extract_work_summary "feat: Add user login feature\n\nImplements OAuth2..." "{\"title\":\"로그인 기능\"}"
#   # Returns: "Add user login feature"
extract_work_summary() {
    local commit_msg="$1"
    local context="${2:-}"

    if [[ -z "$commit_msg" ]]; then
        log_error "Commit message cannot be empty" >&2
        return 1
    fi

    log_info "Extracting work summary from commit message" >&2

    # Strategy 1: If context has title, use it
    if [[ -n "$context" ]]; then
        local feature_title
        feature_title=$(echo "$context" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    title = data.get('title', '')
    if title:
        print(title[:50])  # Max 50 chars
        sys.exit(0)
except:
    pass
sys.exit(1)
" 2>/dev/null)

        if [[ -n "$feature_title" ]]; then
            log_success "Using feature title from context: ${feature_title}" >&2
            echo "$feature_title"
            return 0
        fi
    fi

    # Strategy 2: Parse commit message first line with Korean type mapping
    # Format: "type: summary" or "type(scope): summary" or just "summary"
    local summary
    summary=$(echo "$commit_msg" | python3 -c "
import sys
import re

commit_msg = sys.stdin.read()
first_line = commit_msg.split('\n')[0].strip()

# Conventional commit type to Korean mapping
type_mapping = {
    'feat': '기능 추가',
    'fix': '버그 수정',
    'docs': '문서 업데이트',
    'style': '스타일 변경',
    'refactor': '리팩토링',
    'test': '테스트',
    'chore': '기타 작업',
    'perf': '성능 개선',
    'ci': 'CI/CD',
    'build': '빌드',
    'revert': '되돌리기'
}

# Extract conventional commit type
match = re.match(r'^([a-z]+)(\([^)]+\))?:\s*(.+)$', first_line)
if match:
    commit_type = match.group(1)
    message = match.group(3)

    # Map to Korean if type exists in mapping
    korean_type = type_mapping.get(commit_type, commit_type)
    summary = f'{korean_type}: {message}'
else:
    # No conventional commit format, use as is
    summary = first_line

# Remove emoji prefix if exists
summary = re.sub(r'^[^\w\s가-힣]+\s*', '', summary)

# Limit to 50 characters
summary = summary[:50]

print(summary)
")

    if [[ -z "$summary" ]]; then
        log_error "Failed to extract summary from commit message" >&2
        return 1
    fi

    log_success "Work summary: ${summary}" >&2
    echo "$summary"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Work Type Extraction Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Extract work type from commit message
# Arguments:
#   $1 - Commit message
# Output:
#   Work type in Korean (기능 추가, 버그 수정 등)
# Returns:
#   0 on success
# Example:
#   extract_work_type "feat: Add user login feature"  # Returns: "기능 추가"
extract_work_type() {
    local commit_msg="$1"

    if [[ -z "$commit_msg" ]]; then
        log_error "Commit message cannot be empty" >&2
        return 1
    fi

    log_info "Extracting work type from commit message" >&2

    # Parse first line
    local work_type
    work_type=$(echo "$commit_msg" | python3 -c "
import sys
import re

commit_msg = sys.stdin.read()
first_line = commit_msg.split('\n')[0].strip()

# Conventional commit type to Korean mapping
type_mapping = {
    'feat': '기능 추가',
    'fix': '버그 수정',
    'docs': '문서',
    'style': '스타일',
    'refactor': '리팩토링',
    'test': '테스트',
    'chore': '기타',
    'perf': '성능',
    'ci': 'CI/CD',
    'build': '빌드',
    'revert': '되돌리기'
}

# Extract conventional commit type
match = re.match(r'^([a-z]+)(\([^)]+\))?:\s*', first_line)
if match:
    commit_type = match.group(1)
    korean_type = type_mapping.get(commit_type, '기타')
    print(korean_type)
else:
    # No conventional commit format
    print('기타')
")

    if [[ -z "$work_type" ]]; then
        log_error "Failed to extract work type" >&2
        return 1
    fi

    log_success "Work type: ${work_type}" >&2
    echo "$work_type"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Formatting Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Format work history entry
# Arguments:
#   $1 - Work summary
#   $2 - Start date (YYYY-MM-DD)
#   $3 - Commit date (YYYY-MM-DD)
# Output:
#   Formatted work history entry
# Returns:
#   0 on success
# Example:
#   format_work_history_entry "Add user login" "2025-11-18" "2025-11-20"
#   # Returns: "- Add user login : 2025-11-18 - 2025-11-20"
format_work_history_entry() {
    local summary="$1"
    local start_date="$2"
    local commit_date="$3"

    if [[ -z "$summary" ]] || [[ -z "$start_date" ]] || [[ -z "$commit_date" ]]; then
        log_error "All arguments required: summary, start_date, commit_date" >&2
        return 1
    fi

    # Format: - [summary] : [start_date] - [commit_date]
    echo "- ${summary} : ${start_date} - ${commit_date}"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Worklog Table Formatting Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Format worklog table entry
# Arguments:
#   $1 - Date/Time (YYYY-MM-DD HH:mm)
#   $2 - Commit hash (short)
#   $3 - Work type (Korean)
#   $4 - Summary
#   $5 - Files changed count
#   $6 - Insertions count
#   $7 - Deletions count
#   $8 - File list (newline separated)
# Output:
#   Markdown table row
# Returns:
#   0 on success
# Example:
#   format_worklog_table_entry "2025-11-20 14:30" "abc123d" "기능 추가" "로그인 API" 3 120 15 "src/api/auth.ts\nsrc/types/user.ts"
format_worklog_table_entry() {
    local date_time="$1"
    local commit_hash="$2"
    local work_type="$3"
    local summary="$4"
    local files_count="$5"
    local insertions="$6"
    local deletions="$7"
    local file_list="$8"

    # Validate required arguments
    if [[ -z "$date_time" ]] || [[ -z "$commit_hash" ]] || [[ -z "$work_type" ]] || [[ -z "$summary" ]]; then
        log_error "Required arguments missing: date_time, commit_hash, work_type, summary" >&2
        return 1
    fi

    # Format change amount
    local changes="+${insertions:-0}/-${deletions:-0}"

    # Format file list with <br> tags
    local file_list_formatted=""
    if [[ -n "$file_list" ]]; then
        # Split by newline and format with <br>
        file_list_formatted=$(echo "$file_list" | grep -v '^$' | head -50 | sed 's/$/<br>/' | tr -d '\n' | sed 's/<br>$//')

        # Truncate long file lists
        local file_count=$(echo "$file_list" | grep -v '^$' | wc -l | tr -d ' ')
        if [[ $file_count -gt 50 ]]; then
            file_list_formatted="${file_list_formatted}<br>외 $((file_count - 50))개"
        fi
    fi

    # Return table row
    echo "| $date_time | $commit_hash | $work_type | $summary | ${files_count:-0} | $changes | $file_list_formatted |"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Main Work History Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Add work history entry on commit
# Arguments:
#   $1 - Page ID
#   $2 - Commit hash
#   $3 - Workflow context JSON (optional)
# Output:
#   Success message
# Returns:
#   0 on success, 1 on failure
# Example:
#   add_work_history_on_commit "page-id-123" "abc123def" "{\"title\":\"로그인 기능\"}"
add_work_history_on_commit() {
    local page_id="$1"
    local commit_hash="$2"
    local context="${3:-}"

    if [[ -z "$page_id" ]]; then
        log_error "Page ID cannot be empty" >&2
        return 1
    fi

    if [[ -z "$commit_hash" ]]; then
        log_error "Commit hash cannot be empty" >&2
        return 1
    fi

    log_info "Adding work history for commit: ${commit_hash}" >&2

    # 1. Get start date from Notion page
    local start_date
    if ! start_date=$(get_notion_start_date "$page_id"); then
        log_error "Failed to get start date" >&2
        return 1
    fi

    # 2. Get commit message
    local commit_msg
    if ! commit_msg=$(git log -1 --format=%B "$commit_hash" 2>/dev/null); then
        log_error "Failed to get commit message for: ${commit_hash}" >&2
        return 1
    fi

    # 3. Get commit date (KST)
    local commit_date
    if ! commit_date=$(parse_git_commit_date "$commit_hash" "date"); then
        log_error "Failed to get commit date" >&2
        return 1
    fi

    # 4. Extract work summary
    local summary
    if ! summary=$(extract_work_summary "$commit_msg" "$context"); then
        log_error "Failed to extract work summary" >&2
        return 1
    fi

    # 5. Format work history entry
    local entry
    if ! entry=$(format_work_history_entry "$summary" "$start_date" "$commit_date"); then
        log_error "Failed to format work history entry" >&2
        return 1
    fi

    log_info "Work history entry: ${entry}" >&2

    # 6. Fetch current page data to get existing work history
    local page_data
    if ! page_data=$(fetch_notion_page "$page_id"); then
        log_error "Failed to fetch Notion page" >&2
        return 1
    fi

    # 7. Get work_history column name
    local work_history_col
    if ! work_history_col=$(get_column_name "work_history"); then
        log_error "Failed to get work_history column name" >&2
        return 1
    fi

    # 8. Extract current work history content
    local current_history
    current_history=$(echo "$page_data" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    props = data.get('properties', {})

    # Get work history property (rich_text type)
    work_history_obj = props.get('${work_history_col}', {}).get('rich_text', [])

    # Concatenate all rich text segments
    current_text = ''.join([t.get('plain_text', '') for t in work_history_obj])

    print(current_text)
except Exception as e:
    print('', file=sys.stderr)
    sys.exit(0)  # Empty history is ok
" 2>/dev/null || echo "")

    # 9. Append new entry to existing history
    local new_history
    if [[ -n "$current_history" ]]; then
        # Add newline before new entry if history exists
        new_history="${current_history}
${entry}"
    else
        # First entry
        new_history="$entry"
    fi

    # 10. Build properties JSON for update
    local properties
    properties=$(python3 -c "
import json
props = {
    '${work_history_col}': '''${new_history}'''
}
print(json.dumps(props, ensure_ascii=False))
")

    if [[ -z "$properties" ]]; then
        log_error "Failed to build properties JSON" >&2
        return 1
    fi

    # 11. Update Notion page
    log_info "Updating Notion page with new work history" >&2
    if ! update_notion_properties "$page_id" "$properties"; then
        log_error "Failed to update Notion page" >&2
        return 1
    fi

    log_success "Work history added successfully" >&2
    log_success "  Entry: ${entry}" >&2

    return 0
}

# Export functions
export -f get_notion_start_date
export -f extract_work_summary
export -f extract_work_type
export -f format_work_history_entry
export -f format_worklog_table_entry
export -f add_work_history_on_commit
