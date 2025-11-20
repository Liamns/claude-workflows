#!/bin/bash
# notion-config.sh
# Notion configuration loader for Claude Workflow integration
# Compatible with bash 3.2+
#
# Usage: source .claude/lib/notion-config.sh
#
# Provides:
# - load_notion_config: Load and validate Notion configuration
# - get_data_source_url: Get data source URL by type
# - get_column_name: Get Notion column name by internal key
# - get_status_value: Get Notion status value by internal key
# - get_priority_value: Get Notion priority value by internal key

# Prevent multiple sourcing
if [[ -n "${CLAUDE_NOTION_CONFIG_LOADED:-}" ]]; then
    return 0
fi
CLAUDE_NOTION_CONFIG_LOADED=1

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Configuration file path
readonly NOTION_CONFIG_FILE="${SCRIPT_DIR}/../config/notion.json"

# Global cache for loaded configuration
# Note: Using simple assignment for bash 3.2+ compatibility (declare -g requires bash 4.2+)
NOTION_CONFIG_CACHE=""
NOTION_CONFIG_LOADED_FLAG=0

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Configuration Loading
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Load Notion configuration from JSON file
# Output:
#   JSON configuration (cached)
# Returns:
#   0 on success, 1 on failure
load_notion_config() {
    # Return cached config if already loaded
    if [[ $NOTION_CONFIG_LOADED_FLAG -eq 1 ]]; then
        echo "$NOTION_CONFIG_CACHE"
        return 0
    fi

    # Check if config file exists
    if [[ ! -f "$NOTION_CONFIG_FILE" ]]; then
        log_error "Notion configuration file not found: ${NOTION_CONFIG_FILE}"
        log_error "Please create the configuration file first"
        return 1
    fi

    log_info "Loading Notion configuration: ${NOTION_CONFIG_FILE}" >&2

    # Validate JSON format
    local config
    if ! config=$(python3 -c "
import json, sys
try:
    with open('${NOTION_CONFIG_FILE}', 'r', encoding='utf-8') as f:
        data = json.load(f)
    print(json.dumps(data, ensure_ascii=False))
    sys.exit(0)
except json.JSONDecodeError as e:
    print(f'Invalid JSON: {e}', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>&1); then
        log_error "Failed to parse Notion configuration" >&2
        log_error "${config}" >&2
        return 1
    fi

    # Validate required fields
    local required_fields=("database" "columns" "status_values")
    for field in "${required_fields[@]}"; do
        if ! echo "$config" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if '${field}' not in data:
    sys.exit(1)
" 2>/dev/null; then
            log_error "Missing required field in configuration: ${field}" >&2
            return 1
        fi
    done

    # Cache the configuration
    NOTION_CONFIG_CACHE="$config"
    NOTION_CONFIG_LOADED_FLAG=1

    log_success "Notion configuration loaded successfully" >&2
    echo "$config"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Data Source Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Get data source URL by type
# Arguments:
#   $1 - Data source type ("app" or "admin")
# Output:
#   Data source URL (collection://...)
# Returns:
#   0 on success, 1 on failure
get_data_source_url() {
    local source_type="$1"

    if [[ -z "$source_type" ]]; then
        log_error "Data source type cannot be empty"
        return 1
    fi

    # Load config if not already loaded
    local config
    if ! config=$(load_notion_config); then
        return 1
    fi

    # Extract data source URL
    local url
    url=$(echo "$config" | python3 -c "
import json, sys
data = json.load(sys.stdin)
try:
    url = data['database']['data_sources']['${source_type}']['url']
    print(url)
    sys.exit(0)
except KeyError:
    print('Data source not found: ${source_type}', file=sys.stderr)
    sys.exit(1)
")

    if [[ $? -ne 0 ]] || [[ -z "$url" ]]; then
        log_error "Data source not found: ${source_type}"
        log_error "Available sources: app, admin"
        return 1
    fi

    echo "$url"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Column Mapping Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Get Notion column name by internal key
# Arguments:
#   $1 - Internal column key (e.g., "title", "status", "start_date")
# Output:
#   Notion column name (Korean)
# Returns:
#   0 on success, 1 on failure
get_column_name() {
    local column_key="$1"

    if [[ -z "$column_key" ]]; then
        log_error "Column key cannot be empty"
        return 1
    fi

    # Load config if not already loaded
    local config
    if ! config=$(load_notion_config); then
        return 1
    fi

    # Extract column name
    local column_name
    column_name=$(echo "$config" | python3 -c "
import json, sys
data = json.load(sys.stdin)
try:
    name = data['columns']['${column_key}']['notion_name']
    print(name)
    sys.exit(0)
except KeyError:
    print('Column not found: ${column_key}', file=sys.stderr)
    sys.exit(1)
")

    if [[ $? -ne 0 ]] || [[ -z "$column_name" ]]; then
        log_error "Column not found: ${column_key}"
        return 1
    fi

    echo "$column_name"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Value Mapping Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Get Notion status value by internal key
# Arguments:
#   $1 - Internal status key (e.g., "waiting", "researching", "developing")
# Output:
#   Notion status value (Korean)
# Returns:
#   0 on success, 1 on failure
get_status_value() {
    local status_key="$1"

    if [[ -z "$status_key" ]]; then
        log_error "Status key cannot be empty"
        return 1
    fi

    # Load config if not already loaded
    local config
    if ! config=$(load_notion_config); then
        return 1
    fi

    # Extract status value
    local status_value
    status_value=$(echo "$config" | python3 -c "
import json, sys
data = json.load(sys.stdin)
try:
    value = data['status_values']['${status_key}']
    print(value)
    sys.exit(0)
except KeyError:
    print('Status not found: ${status_key}', file=sys.stderr)
    sys.exit(1)
")

    if [[ $? -ne 0 ]] || [[ -z "$status_value" ]]; then
        log_error "Status not found: ${status_key}"
        log_error "Available statuses: waiting, researching, developing, completed, deployed"
        return 1
    fi

    echo "$status_value"
    return 0
}

# Get Notion priority value by internal key
# Arguments:
#   $1 - Internal priority key (e.g., "p0", "p1", "p2", "p3")
# Output:
#   Notion priority value
# Returns:
#   0 on success, 1 on failure
get_priority_value() {
    local priority_key="$1"

    if [[ -z "$priority_key" ]]; then
        log_error "Priority key cannot be empty"
        return 1
    fi

    # Load config if not already loaded
    local config
    if ! config=$(load_notion_config); then
        return 1
    fi

    # Extract priority value
    local priority_value
    priority_value=$(echo "$config" | python3 -c "
import json, sys
data = json.load(sys.stdin)
try:
    value = data['priority_values']['${priority_key}']
    print(value)
    sys.exit(0)
except KeyError:
    print('Priority not found: ${priority_key}', file=sys.stderr)
    sys.exit(1)
")

    if [[ $? -ne 0 ]] || [[ -z "$priority_value" ]]; then
        log_error "Priority not found: ${priority_key}"
        log_error "Available priorities: p0, p1, p2, p3"
        return 1
    fi

    echo "$priority_value"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Utility Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Get database ID
# Output:
#   Database ID
# Returns:
#   0 on success, 1 on failure
get_database_id() {
    local config
    if ! config=$(load_notion_config); then
        return 1
    fi

    echo "$config" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data['database']['id'])
"
}

# Get current page cache file path
# Output:
#   File path to current page cache
get_current_page_cache() {
    local config
    if ! config=$(load_notion_config); then
        return 1
    fi

    echo "$config" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data['cache']['current_page_file'])
"
}

# Export functions
export -f load_notion_config
export -f get_data_source_url
export -f get_column_name
export -f get_status_value
export -f get_priority_value
export -f get_database_id
export -f get_current_page_cache
