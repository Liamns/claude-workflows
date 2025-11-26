#!/usr/bin/env bash
# Index helper for reusability checker integration
# Epic 006 - Feature 004: Project Indexing and Caching
# Task: T022 - Integration helper for Feature 001

# Try to search in index first, fallback to grep if needed
# Arguments: $1 = query string
# Returns: search results or empty if not found
try_index_search() {
    local query="$1"
    local index_file="/Users/hk/Documents/claude-workflow/.claude/cache/project-index.json"
    local index_script="/Users/hk/Documents/claude-workflow/.claude/lib/project-index/project-index.sh"

    # Check if index exists
    if [ ! -f "$index_file" ]; then
        # No index, signal to use fallback
        return 1
    fi

    # Check if index is stale (older than 1 day)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local index_age=$(( $(date +%s) - $(stat -f "%m" "$index_file") ))
    else
        local index_age=$(( $(date +%s) - $(stat -c "%Y" "$index_file") ))
    fi

    local one_day=86400
    if [ "$index_age" -gt "$one_day" ]; then
        # Index is stale, suggest update but continue
        echo "⚠️  Index is older than 1 day. Consider running: bash $index_script --update" >&2
    fi

    # Search in index
    local results
    results=$(bash "$index_script" --search "$query" 2>/dev/null)

    if [ -n "$results" ] && ! echo "$results" | grep -q "No results found"; then
        # Results found in index
        echo "$results"
        return 0
    else
        # No results in index, signal to use fallback
        return 1
    fi
}

# Get file candidates from index
# Arguments: $1 = query string
# Returns: newline-separated list of file paths
get_file_candidates_from_index() {
    local query="$1"
    local index_file="/Users/hk/Documents/claude-workflow/.claude/cache/project-index.json"

    if [ ! -f "$index_file" ]; then
        return 1
    fi

    # Extract just the file paths
    jq -r --arg query "$query" '
        .files[] |
        select(
            (.path | contains($query)) or
            (.exports[]? | contains($query)) or
            (.imports[]? | contains($query))
        ) |
        .path
    ' "$index_file" 2>/dev/null
}

# Check if component/module exists in index
# Arguments: $1 = component/module name
# Returns: 0 if exists, 1 if not found
check_exists_in_index() {
    local name="$1"
    local index_file="/Users/hk/Documents/claude-workflow/.claude/cache/project-index.json"

    if [ ! -f "$index_file" ]; then
        return 1
    fi

    # Check if name appears in exports
    local count
    count=$(jq --arg name "$name" '
        .files[] |
        select(.exports[]? | contains($name))
    ' "$index_file" 2>/dev/null | jq -s 'length')

    if [ "$count" -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

# Export functions
export -f try_index_search
export -f get_file_candidates_from_index
export -f check_exists_in_index
