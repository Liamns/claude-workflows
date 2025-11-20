#!/bin/bash
# notion-update.sh
# Notion page property update functions for workflow integration
# Compatible with bash 3.2+
#
# Usage: source .claude/lib/notion-update.sh
#
# Provides:
# - get_current_user_id: Get current Notion MCP user ID
# - update_notion_start: Update page when work starts
# - update_notion_complete: Update page when work completes
# - update_status: Update page status only

# Prevent multiple sourcing
if [[ -n "${CLAUDE_NOTION_UPDATE_LOADED:-}" ]]; then
    return 0
fi
CLAUDE_NOTION_UPDATE_LOADED=1

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/notion-utils.sh"
source "${SCRIPT_DIR}/notion-date-utils.sh"
source "${SCRIPT_DIR}/notion-config.sh"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# User Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Get current Notion MCP user ID
# Output:
#   User ID string
# Returns:
#   0 on success, 1 on failure
# Example:
#   get_current_user_id  # Returns: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
get_current_user_id() {
    log_info "Getting current Notion user ID" >&2

    # Call Notion MCP get-self
    local response
    if ! response=$(call_notion_mcp "mcp__notion-company__notion-get-self" "{}"); then
        log_error "Failed to get current user" >&2
        return 1
    fi

    # Extract user ID from response
    local user_id
    user_id=$(echo "$response" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    user_id = data.get('id', '')
    if not user_id:
        print('User ID not found in response', file=sys.stderr)
        sys.exit(1)
    print(user_id)
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
")

    if [[ -z "$user_id" ]]; then
        log_error "Failed to extract user ID" >&2
        return 1
    fi

    log_success "Current user ID: ${user_id}" >&2
    echo "$user_id"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Update Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Update Notion page when work starts
# Arguments:
#   $1 - Page ID
# Output:
#   Success message
# Returns:
#   0 on success, 1 on failure
# Example:
#   update_notion_start "page-id-123"
update_notion_start() {
    local page_id="$1"

    if [[ -z "$page_id" ]]; then
        log_error "Page ID cannot be empty" >&2
        return 1
    fi

    log_info "Updating Notion page for work start: ${page_id}" >&2

    # Get current KST date
    local kst_date
    if ! kst_date=$(get_kst_date); then
        log_error "Failed to get KST date" >&2
        return 1
    fi

    # Get column names from config
    local start_date_col status_col assignee_col
    if ! start_date_col=$(get_column_name "start_date"); then
        log_error "Failed to get start_date column name" >&2
        return 1
    fi

    if ! status_col=$(get_column_name "status"); then
        log_error "Failed to get status column name" >&2
        return 1
    fi

    if ! assignee_col=$(get_column_name "assignee"); then
        log_error "Failed to get assignee column name" >&2
        return 1
    fi

    # Get status value
    local developing_status
    if ! developing_status=$(get_status_value "developing"); then
        log_error "Failed to get 'developing' status value" >&2
        return 1
    fi

    # Get current user ID
    local user_id
    if ! user_id=$(get_current_user_id); then
        log_error "Failed to get current user ID" >&2
        return 1
    fi

    # Build properties JSON
    # Date format: "date:{column}:start" and "date:{column}:is_datetime"
    # Person format: Use user ID string directly (Notion will convert to people array)
    local properties
    properties=$(python3 -c "
import json
props = {
    'date:${start_date_col}:start': '${kst_date}',
    'date:${start_date_col}:is_datetime': 0,
    '${status_col}': '${developing_status}',
    '${assignee_col}': '${user_id}'
}
print(json.dumps(props, ensure_ascii=False))
")

    if [[ -z "$properties" ]]; then
        log_error "Failed to build properties JSON" >&2
        return 1
    fi

    log_info "Properties to update: ${properties}" >&2

    # Update Notion page
    if ! update_notion_properties "$page_id" "$properties"; then
        log_error "Failed to update Notion page" >&2
        return 1
    fi

    log_success "Notion page updated for work start" >&2
    log_success "  - Start date: ${kst_date}" >&2
    log_success "  - Status: ${developing_status}" >&2
    log_success "  - Assignee: ${user_id}" >&2

    return 0
}

# Update Notion page when work completes
# Arguments:
#   $1 - Page ID
# Output:
#   Success message
# Returns:
#   0 on success, 1 on failure
# Example:
#   update_notion_complete "page-id-123"
update_notion_complete() {
    local page_id="$1"

    if [[ -z "$page_id" ]]; then
        log_error "Page ID cannot be empty" >&2
        return 1
    fi

    log_info "Updating Notion page for work completion: ${page_id}" >&2

    # Get current KST date
    local kst_date
    if ! kst_date=$(get_kst_date); then
        log_error "Failed to get KST date" >&2
        return 1
    fi

    # Get column names from config
    local deadline_col status_col
    if ! deadline_col=$(get_column_name "deadline"); then
        log_error "Failed to get deadline column name" >&2
        return 1
    fi

    if ! status_col=$(get_column_name "status"); then
        log_error "Failed to get status column name" >&2
        return 1
    fi

    # Get status value
    local completed_status
    if ! completed_status=$(get_status_value "completed"); then
        log_error "Failed to get 'completed' status value" >&2
        return 1
    fi

    # Build properties JSON
    local properties
    properties=$(python3 -c "
import json
props = {
    'date:${deadline_col}:start': '${kst_date}',
    'date:${deadline_col}:is_datetime': 0,
    '${status_col}': '${completed_status}'
}
print(json.dumps(props, ensure_ascii=False))
")

    if [[ -z "$properties" ]]; then
        log_error "Failed to build properties JSON" >&2
        return 1
    fi

    log_info "Properties to update: ${properties}" >&2

    # Update Notion page
    if ! update_notion_properties "$page_id" "$properties"; then
        log_error "Failed to update Notion page" >&2
        return 1
    fi

    log_success "Notion page updated for work completion" >&2
    log_success "  - Deadline: ${kst_date}" >&2
    log_success "  - Status: ${completed_status}" >&2

    return 0
}

# Update Notion page status only
# Arguments:
#   $1 - Page ID
#   $2 - Status key (e.g., "waiting", "researching", "developing", "completed", "deployed")
# Output:
#   Success message
# Returns:
#   0 on success, 1 on failure
# Example:
#   update_status "page-id-123" "researching"
update_status() {
    local page_id="$1"
    local status_key="$2"

    if [[ -z "$page_id" ]]; then
        log_error "Page ID cannot be empty" >&2
        return 1
    fi

    if [[ -z "$status_key" ]]; then
        log_error "Status key cannot be empty" >&2
        return 1
    fi

    log_info "Updating Notion page status: ${page_id} -> ${status_key}" >&2

    # Get column name from config
    local status_col
    if ! status_col=$(get_column_name "status"); then
        log_error "Failed to get status column name" >&2
        return 1
    fi

    # Get status value
    local status_value
    if ! status_value=$(get_status_value "$status_key"); then
        log_error "Failed to get status value for: ${status_key}" >&2
        return 1
    fi

    # Build properties JSON
    local properties
    properties=$(python3 -c "
import json
props = {
    '${status_col}': '${status_value}'
}
print(json.dumps(props, ensure_ascii=False))
")

    if [[ -z "$properties" ]]; then
        log_error "Failed to build properties JSON" >&2
        return 1
    fi

    log_info "Properties to update: ${properties}" >&2

    # Update Notion page
    if ! update_notion_properties "$page_id" "$properties"; then
        log_error "Failed to update Notion page" >&2
        return 1
    fi

    log_success "Notion page status updated" >&2
    log_success "  - Status: ${status_value}" >&2

    return 0
}

# Export functions
export -f get_current_user_id
export -f update_notion_start
export -f update_notion_complete
export -f update_status
