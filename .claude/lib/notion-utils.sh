#!/bin/bash
# notion-utils.sh
# Notion MCP wrapper functions for Claude Workflow integration
# Compatible with bash 3.2+
#
# Usage: source .claude/lib/notion-utils.sh
#
# Provides:
# - call_notion_mcp: Low-level MCP tool invocation
# - search_notion_pages: Search Notion database by keyword
# - fetch_notion_page: Fetch page content by ID
# - update_notion_properties: Update page properties
# - create_notion_page: Create new page

# Prevent multiple sourcing
if [[ -n "${CLAUDE_NOTION_UTILS_LOADED:-}" ]]; then
    return 0
fi
CLAUDE_NOTION_UTILS_LOADED=1

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Notion MCP server name (from claude_desktop_config.json)
readonly NOTION_MCP_SERVER="notion-company"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Validation Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Validate JSON string format
# Arguments:
#   $1 - JSON string to validate
# Returns:
#   0 if valid JSON, 1 otherwise
# Note:
#   Complements validate_json() in common.sh which validates JSON files.
#   This function validates in-memory JSON strings.
validate_json_string() {
    local json_str="$1"

    if [[ -z "$json_str" ]]; then
        log_error "JSON string cannot be empty"
        return 1
    fi

    # Validate using Python's json.tool
    if ! echo "$json_str" | python3 -m json.tool &>/dev/null; then
        log_error "Invalid JSON string format"
        return 1
    fi

    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Low-Level MCP Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Call Notion MCP tool
# Arguments:
#   $1 - Tool name (e.g., "mcp__notion-company__notion-search")
#   $2 - JSON parameters (optional)
# Output:
#   JSON response from MCP server
# Returns:
#   0 on success, 1 on failure
call_notion_mcp() {
    local tool_name="$1"
    local params="${2:-{}}"

    log_info "Calling Notion MCP: ${tool_name}"

    # Validate tool name format
    if [[ ! "$tool_name" =~ ^mcp__notion-company__ ]]; then
        log_error "Invalid Notion MCP tool name: ${tool_name}"
        log_error "Tool name must start with 'mcp__notion-company__'"
        return 1
    fi

    # Validate JSON parameters
    if ! validate_json_string "$params"; then
        log_error "Invalid JSON parameters for MCP call"
        return 1
    fi

    # Call MCP tool via Claude SDK
    # Note: This is a placeholder - actual implementation depends on Claude SDK
    local response
    if ! response=$(mcp_call "$tool_name" "$params" 2>&1); then
        log_error "Notion MCP call failed: ${tool_name}"
        log_error "Error: ${response}"
        return 1
    fi

    # Validate JSON response
    if ! validate_json_string "$response"; then
        log_error "Invalid JSON response from Notion MCP"
        return 1
    fi

    echo "$response"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Search Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Search Notion pages by keyword
# Arguments:
#   $1 - Search query (keyword)
#   $2 - Data source URL (optional, e.g., "collection://...")
#   $3 - Teamspace ID (optional)
# Output:
#   JSON array of search results
# Returns:
#   0 on success, 1 on failure
search_notion_pages() {
    local query="$1"
    local data_source_url="${2:-}"
    local teamspace_id="${3:-}"

    if [[ -z "$query" ]]; then
        log_error "Search query cannot be empty"
        return 1
    fi

    log_info "Searching Notion: '${query}'"

    # Build search parameters
    local params="{\"query\": \"${query}\", \"query_type\": \"internal\"}"

    # Add optional filters
    if [[ -n "$data_source_url" ]]; then
        params=$(echo "$params" | python3 -c "
import sys, json
data = json.load(sys.stdin)
data['data_source_url'] = '${data_source_url}'
print(json.dumps(data))
")
    fi

    if [[ -n "$teamspace_id" ]]; then
        params=$(echo "$params" | python3 -c "
import sys, json
data = json.load(sys.stdin)
data['teamspace_id'] = '${teamspace_id}'
print(json.dumps(data))
")
    fi

    # Call MCP search
    local response
    if ! response=$(call_notion_mcp "mcp__notion-company__notion-search" "$params"); then
        log_error "Notion search failed"
        return 1
    fi

    log_success "Notion search completed"
    echo "$response"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Fetch Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Fetch Notion page content by ID
# Arguments:
#   $1 - Page ID or URL
# Output:
#   JSON page content
# Returns:
#   0 on success, 1 on failure
fetch_notion_page() {
    local page_id="$1"

    if [[ -z "$page_id" ]]; then
        log_error "Page ID cannot be empty"
        return 1
    fi

    log_info "Fetching Notion page: ${page_id}"

    # Build fetch parameters
    local params="{\"id\": \"${page_id}\"}"

    # Call MCP fetch
    local response
    if ! response=$(call_notion_mcp "mcp__notion-company__notion-fetch" "$params"); then
        log_error "Notion fetch failed"
        return 1
    fi

    log_success "Notion page fetched"
    echo "$response"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Update Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Update Notion page properties
# Arguments:
#   $1 - Page ID
#   $2 - JSON properties object
# Output:
#   Success/failure message
# Returns:
#   0 on success, 1 on failure
update_notion_properties() {
    local page_id="$1"
    local properties="$2"

    if [[ -z "$page_id" ]]; then
        log_error "Page ID cannot be empty"
        return 1
    fi

    if [[ -z "$properties" ]]; then
        log_error "Properties cannot be empty"
        return 1
    fi

    log_info "Updating Notion page properties: ${page_id}"

    # Build update parameters
    local params
    params=$(python3 -c "
import json
data = {
    'data': {
        'page_id': '${page_id}',
        'command': 'update_properties',
        'properties': json.loads('${properties}')
    }
}
print(json.dumps(data))
")

    # Call MCP update
    local response
    if ! response=$(call_notion_mcp "mcp__notion-company__notion-update-page" "$params"); then
        log_error "Notion update failed"
        return 1
    fi

    log_success "Notion page properties updated"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Create Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Create new Notion page
# Arguments:
#   $1 - Parent ID or data source URL
#   $2 - JSON properties object
#   $3 - Page content (Notion-flavored Markdown, optional)
# Output:
#   JSON created page info
# Returns:
#   0 on success, 1 on failure
create_notion_page() {
    local parent="$1"
    local properties="$2"
    local content="${3:-}"

    if [[ -z "$parent" ]]; then
        log_error "Parent ID/URL cannot be empty"
        return 1
    fi

    if [[ -z "$properties" ]]; then
        log_error "Properties cannot be empty"
        return 1
    fi

    log_info "Creating Notion page"

    # Determine parent type
    local parent_type
    local parent_value
    if [[ "$parent" =~ ^collection:// ]]; then
        parent_type="data_source_id"
        parent_value="${parent#collection://}"
    else
        parent_type="page_id"
        parent_value="$parent"
    fi

    # Build create parameters
    local params
    params=$(python3 -c "
import json
parent = {'${parent_type}': '${parent_value}'}
properties = json.loads('${properties}')
page = {'properties': properties}
if '${content}':
    page['content'] = '''${content}'''
data = {
    'parent': parent,
    'pages': [page]
}
print(json.dumps(data))
")

    # Call MCP create
    local response
    if ! response=$(call_notion_mcp "mcp__notion-company__notion-create-pages" "$params"); then
        log_error "Notion page creation failed"
        return 1
    fi

    log_success "Notion page created"
    echo "$response"
    return 0
}

# Export functions
export -f validate_json_string
export -f call_notion_mcp
export -f search_notion_pages
export -f fetch_notion_page
export -f update_notion_properties
export -f create_notion_page
