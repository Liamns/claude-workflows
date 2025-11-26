#!/usr/bin/env bash
# Format search results as JSON
# Epic 006 - Feature 004: Project Indexing and Caching
# Task: T016 - Format results for JSON output

# Format results as JSON
# Arguments: $1 = jq query results (JSON array)
# Returns: formatted JSON output
format_search_results() {
    local results="$1"

    # Pretty print JSON
    echo "$results" | jq '.'
}

# Export function
export -f format_search_results
