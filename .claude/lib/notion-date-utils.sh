#!/bin/bash
# notion-date-utils.sh
# KST date/time utilities for Notion integration
# Compatible with bash 3.2+ and macOS date command
#
# Usage: source .claude/lib/notion-date-utils.sh
#
# Provides:
# - get_kst_date: Get current date in KST (YYYY-MM-DD)
# - get_kst_datetime: Get current datetime in KST (YYYY-MM-DD HH:MM:SS)
# - format_notion_date: Convert Notion date to KST
# - parse_git_commit_date: Convert Git commit date to KST

# Prevent multiple sourcing
if [[ -n "${CLAUDE_NOTION_DATE_UTILS_LOADED:-}" ]]; then
    return 0
fi
CLAUDE_NOTION_DATE_UTILS_LOADED=1

# KST timezone offset (UTC+9)
readonly KST_TIMEZONE="Asia/Seoul"
readonly KST_OFFSET_SECONDS=32400  # 9 * 3600

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Current Time Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Get current date in KST
# Output:
#   Date string in YYYY-MM-DD format
# Returns:
#   0 on success
# Example:
#   get_kst_date  # Returns: 2025-11-20
get_kst_date() {
    # Use TZ environment variable for KST timezone
    TZ="${KST_TIMEZONE}" date '+%Y-%m-%d'
    return 0
}

# Get current datetime in KST
# Output:
#   Datetime string in YYYY-MM-DD HH:MM:SS format
# Returns:
#   0 on success
# Example:
#   get_kst_datetime  # Returns: 2025-11-20 14:30:45
get_kst_datetime() {
    # Use TZ environment variable for KST timezone
    TZ="${KST_TIMEZONE}" date '+%Y-%m-%d %H:%M:%S'
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Notion Date Conversion Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Convert Notion date to KST
# Arguments:
#   $1 - Notion date string (ISO 8601 format, e.g., "2025-11-20T05:30:45.000Z")
#   $2 - Output format (optional, default: "%Y-%m-%d")
#        - "date": YYYY-MM-DD
#        - "datetime": YYYY-MM-DD HH:MM:SS
#        - custom strftime format
# Output:
#   Formatted date/time string in KST
# Returns:
#   0 on success, 1 on failure
# Examples:
#   format_notion_date "2025-11-20T05:30:45.000Z"           # Returns: 2025-11-20
#   format_notion_date "2025-11-20T05:30:45.000Z" "datetime" # Returns: 2025-11-20 14:30:45
format_notion_date() {
    local notion_date="$1"
    local format="${2:-date}"

    if [[ -z "$notion_date" ]]; then
        echo "Error: Notion date cannot be empty" >&2
        return 1
    fi

    # Convert format aliases to strftime format
    case "$format" in
        "date")
            format="%Y-%m-%d"
            ;;
        "datetime")
            format="%Y-%m-%d %H:%M:%S"
            ;;
    esac

    # Remove timezone suffix for parsing
    # Supports: "2025-11-20T05:30:45.000Z", "2025-11-20T05:30:45Z", "2025-11-20T05:30:45+00:00"
    local clean_date
    clean_date=$(echo "$notion_date" | sed -E 's/(\.000)?Z$//; s/\+00:00$//')

    # Parse ISO 8601 date using date command
    # Note: macOS date command requires -j flag for parsing
    local kst_date
    if date --version >/dev/null 2>&1; then
        # GNU date (Linux)
        kst_date=$(TZ="${KST_TIMEZONE}" date -d "$notion_date" +"$format" 2>/dev/null)
    else
        # BSD date (macOS)
        # Strategy: Parse as UTC timestamp, then convert to KST
        # 1. Convert ISO 8601 to BSD format for parsing as UTC
        local bsd_format
        bsd_format=$(echo "$clean_date" | sed -E 's/([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})/\1\2\3\4\5.\6/')

        # 2. Parse as UTC and get Unix timestamp
        local timestamp
        timestamp=$(TZ=UTC date -j -f "%Y%m%d%H%M.%S" "$bsd_format" +"%s" 2>/dev/null)

        if [[ -z "$timestamp" ]]; then
            echo "Error: Failed to parse date format: $notion_date" >&2
            return 1
        fi

        # 3. Convert Unix timestamp to KST
        kst_date=$(TZ="${KST_TIMEZONE}" date -r "$timestamp" +"$format" 2>/dev/null)
    fi

    if [[ -z "$kst_date" ]]; then
        echo "Error: Failed to parse Notion date: $notion_date" >&2
        return 1
    fi

    echo "$kst_date"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Git Date Conversion Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Convert Git commit date to KST
# Arguments:
#   $1 - Git commit hash (optional, default: HEAD)
#   $2 - Output format (optional, default: "date")
#        - "date": YYYY-MM-DD
#        - "datetime": YYYY-MM-DD HH:MM:SS
#        - custom strftime format
# Output:
#   Formatted date/time string in KST
# Returns:
#   0 on success, 1 on failure
# Examples:
#   parse_git_commit_date                    # Returns: 2025-11-20 (HEAD commit)
#   parse_git_commit_date "abc123"           # Returns: 2025-11-20 (specific commit)
#   parse_git_commit_date "HEAD" "datetime"  # Returns: 2025-11-20 14:30:45
parse_git_commit_date() {
    local commit_hash="${1:-HEAD}"
    local format="${2:-date}"

    # Convert format aliases to strftime format
    case "$format" in
        "date")
            format="%Y-%m-%d"
            ;;
        "datetime")
            format="%Y-%m-%d %H:%M:%S"
            ;;
    esac

    # Get commit date in Unix timestamp format
    local timestamp
    if ! timestamp=$(git log -1 --format=%ct "$commit_hash" 2>/dev/null); then
        echo "Error: Failed to get commit date for $commit_hash" >&2
        return 1
    fi

    if [[ -z "$timestamp" ]]; then
        echo "Error: Commit not found: $commit_hash" >&2
        return 1
    fi

    # Convert Unix timestamp to KST
    local kst_date
    if date --version >/dev/null 2>&1; then
        # GNU date (Linux)
        kst_date=$(TZ="${KST_TIMEZONE}" date -d "@$timestamp" +"$format")
    else
        # BSD date (macOS)
        kst_date=$(TZ="${KST_TIMEZONE}" date -r "$timestamp" +"$format")
    fi

    echo "$kst_date"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Utility Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Check if a date string is in valid YYYY-MM-DD format
# Arguments:
#   $1 - Date string to validate
# Returns:
#   0 if valid, 1 if invalid
is_valid_date_format() {
    local date_str="$1"

    if [[ ! "$date_str" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        return 1
    fi

    return 0
}

# Get date N days ago in KST
# Arguments:
#   $1 - Number of days ago (default: 0)
#   $2 - Output format (optional, default: "date")
# Output:
#   Formatted date string in KST
# Returns:
#   0 on success, 1 on failure
# Examples:
#   get_kst_date_ago 0      # Returns: 2025-11-20 (today)
#   get_kst_date_ago 1      # Returns: 2025-11-19 (yesterday)
#   get_kst_date_ago 7      # Returns: 2025-11-13 (7 days ago)
get_kst_date_ago() {
    local days_ago="${1:-0}"
    local format="${2:-date}"

    # Convert format aliases
    case "$format" in
        "date")
            format="%Y-%m-%d"
            ;;
        "datetime")
            format="%Y-%m-%d %H:%M:%S"
            ;;
    esac

    # Calculate date N days ago
    local kst_date
    if date --version >/dev/null 2>&1; then
        # GNU date (Linux)
        kst_date=$(TZ="${KST_TIMEZONE}" date -d "${days_ago} days ago" +"$format")
    else
        # BSD date (macOS)
        kst_date=$(TZ="${KST_TIMEZONE}" date -v-"${days_ago}"d +"$format")
    fi

    echo "$kst_date"
    return 0
}

# Export functions
export -f get_kst_date
export -f get_kst_datetime
export -f format_notion_date
export -f parse_git_commit_date
export -f is_valid_date_format
export -f get_kst_date_ago
