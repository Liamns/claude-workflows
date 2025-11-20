#!/bin/bash
# notion-search.sh
# Notion database search functions with filter support
# Compatible with bash 3.2+
#
# Usage: source .claude/lib/notion-search.sh
#
# Provides:
# - search_by_keyword: Search Notion pages by keyword
# - search_by_priority: Filter search by priority
# - search_by_group: Filter search by feature group
# - convert_search_to_question: Convert search results to AskUserQuestion format

# Prevent multiple sourcing
if [[ -n "${CLAUDE_NOTION_SEARCH_LOADED:-}" ]]; then
    return 0
fi
CLAUDE_NOTION_SEARCH_LOADED=1

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/notion-utils.sh"
source "${SCRIPT_DIR}/notion-config.sh"
source "${SCRIPT_DIR}/ask-user-question-adapter.sh"

# Maximum number of search results to return (AskUserQuestion limit: 4)
readonly MAX_SEARCH_RESULTS=4

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Search Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Search Notion pages by keyword
# Arguments:
#   $1 - Search keyword
#   $2 - Data source type (optional: "app" or "admin", default: "app")
# Output:
#   JSON array of search results (max 4 items)
# Returns:
#   0 on success, 1 on failure
# Example:
#   search_by_keyword "회원 관리" "app"
search_by_keyword() {
    local keyword="$1"
    local source_type="${2:-app}"

    if [[ -z "$keyword" ]]; then
        log_error "Search keyword cannot be empty" >&2
        return 1
    fi

    log_info "Searching Notion: '${keyword}' in ${source_type}" >&2

    # Get data source URL
    local data_source_url
    if ! data_source_url=$(get_data_source_url "$source_type"); then
        log_error "Failed to get data source URL for: ${source_type}" >&2
        return 1
    fi

    # Perform search with data source filter
    local search_results
    if ! search_results=$(search_notion_pages "$keyword" "$data_source_url"); then
        log_error "Notion search failed for keyword: ${keyword}" >&2
        return 1
    fi

    # Limit results to MAX_SEARCH_RESULTS
    local limited_results
    limited_results=$(echo "$search_results" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if isinstance(data, list):
    print(json.dumps(data[:${MAX_SEARCH_RESULTS}], ensure_ascii=False))
else:
    print(json.dumps(data, ensure_ascii=False))
")

    log_success "Found $(echo "$limited_results" | python3 -c "import json, sys; print(len(json.load(sys.stdin)))"  2>/dev/null || echo 0) results" >&2
    echo "$limited_results"
    return 0
}

# Filter search results by priority
# Arguments:
#   $1 - JSON search results array
#   $2 - Priority filter (e.g., "P0", "P1", "P2", "P3")
# Output:
#   Filtered JSON array
# Returns:
#   0 on success, 1 on failure
# Example:
#   search_by_priority "$results" "P0"
search_by_priority() {
    local results_json="$1"
    local priority_filter="$2"

    if [[ -z "$results_json" ]]; then
        log_error "Search results cannot be empty" >&2
        return 1
    fi

    if [[ -z "$priority_filter" ]]; then
        # No filter, return original results
        echo "$results_json"
        return 0
    fi

    log_info "Filtering by priority: ${priority_filter}" >&2

    # Get priority column name from config
    local priority_column
    if ! priority_column=$(get_column_name "priority"); then
        log_error "Failed to get priority column name" >&2
        return 1
    fi

    # Filter results by priority
    local filtered_results
    filtered_results=$(echo "$results_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
priority_col = '${priority_column}'
priority_filter = '${priority_filter}'

if not isinstance(data, list):
    print(json.dumps(data, ensure_ascii=False))
    sys.exit(0)

filtered = [
    item for item in data
    if item.get('properties', {}).get(priority_col, {}).get('select', {}).get('name') == priority_filter
]

print(json.dumps(filtered[:${MAX_SEARCH_RESULTS}], ensure_ascii=False))
")

    log_success "Filtered to $(echo "$filtered_results" | python3 -c "import json, sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo 0) results" >&2
    echo "$filtered_results"
    return 0
}

# Filter search results by feature group
# Arguments:
#   $1 - JSON search results array
#   $2 - Group filter (e.g., "인증", "주문", "배송")
# Output:
#   Filtered JSON array
# Returns:
#   0 on success, 1 on failure
# Example:
#   search_by_group "$results" "인증"
search_by_group() {
    local results_json="$1"
    local group_filter="$2"

    if [[ -z "$results_json" ]]; then
        log_error "Search results cannot be empty" >&2
        return 1
    fi

    if [[ -z "$group_filter" ]]; then
        # No filter, return original results
        echo "$results_json"
        return 0
    fi

    log_info "Filtering by group: ${group_filter}" >&2

    # Get group column name from config
    local group_column
    if ! group_column=$(get_column_name "group"); then
        log_error "Failed to get group column name" >&2
        return 1
    fi

    # Filter results by group
    local filtered_results
    filtered_results=$(echo "$results_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
group_col = '${group_column}'
group_filter = '${group_filter}'

if not isinstance(data, list):
    print(json.dumps(data, ensure_ascii=False))
    sys.exit(0)

filtered = [
    item for item in data
    if item.get('properties', {}).get(group_col, {}).get('select', {}).get('name') == group_filter
]

print(json.dumps(filtered[:${MAX_SEARCH_RESULTS}], ensure_ascii=False))
")

    log_success "Filtered to $(echo "$filtered_results" | python3 -c "import json, sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo 0) results" >&2
    echo "$filtered_results"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# AskUserQuestion Conversion
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Convert search results to AskUserQuestion format
# Arguments:
#   $1 - JSON search results array
#   $2 - Question text (optional, default: "어떤 기능을 작업하시겠습니까?")
#   $3 - Header text (optional, default: "Feature")
# Output:
#   JSON in AskUserQuestion format
# Returns:
#   0 on success, 1 on failure
# Example:
#   convert_search_to_question "$results"
convert_search_to_question() {
    local results_json="$1"
    local question_text="${2:-어떤 기능을 작업하시겠습니까?}"
    local header_text="${3:-Feature}"

    if [[ -z "$results_json" ]]; then
        log_error "Search results cannot be empty" >&2
        return 1
    fi

    # Validate header length (max 12 characters)
    if [[ ${#header_text} -gt 12 ]]; then
        log_error "Header must be max 12 characters, got: ${#header_text}" >&2
        return 1
    fi

    log_info "Converting search results to AskUserQuestion format" >&2

    # Get title column name
    local title_column
    if ! title_column=$(get_column_name "title"); then
        log_error "Failed to get title column name" >&2
        return 1
    fi

    # Get priority and status columns for description
    local priority_column status_column
    priority_column=$(get_column_name "priority" 2>/dev/null || echo "우선순위")
    status_column=$(get_column_name "status" 2>/dev/null || echo "진행현황")

    # Extract options from search results
    local options_array=()
    while IFS= read -r option; do
        if [[ -n "$option" ]]; then
            options_array+=("$option")
        fi
    done < <(echo "$results_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
title_col = '${title_column}'
priority_col = '${priority_column}'
status_col = '${status_column}'

if not isinstance(data, list):
    sys.exit(1)

for item in data[:${MAX_SEARCH_RESULTS}]:
    props = item.get('properties', {})

    # Extract title
    title_obj = props.get(title_col, {})
    if title_obj.get('type') == 'title':
        title = ''.join([t.get('plain_text', '') for t in title_obj.get('title', [])])
    else:
        title = str(title_obj.get('title', 'Untitled'))

    # Extract priority and status for description
    priority = props.get(priority_col, {}).get('select', {}).get('name', '-')
    status = props.get(status_col, {}).get('status', {}).get('name', '-')

    # Format: label|description
    description = f'{priority} | {status}'
    print(f'{title}|{description}')
")

    # Check if any results found
    if [[ ${#options_array[@]} -eq 0 ]]; then
        log_error "No search results to convert" >&2
        return 1
    fi

    # Check result count (2-4 required by AskUserQuestion)
    if [[ ${#options_array[@]} -lt 2 ]]; then
        log_error "Need at least 2 search results, got: ${#options_array[@]}" >&2
        return 1
    fi

    # Convert to AskUserQuestion format using adapter
    local question_json
    if ! question_json=$(convert_shell_menu_to_askuserquestion \
        "$question_text" \
        "$header_text" \
        "false" \
        "${options_array[@]}"); then
        log_error "Failed to convert to AskUserQuestion format" >&2
        return 1
    fi

    log_success "Converted ${#options_array[@]} results to AskUserQuestion format" >&2
    echo "$question_json"
    return 0
}

# Export functions
export -f search_by_keyword
export -f search_by_priority
export -f search_by_group
export -f convert_search_to_question
