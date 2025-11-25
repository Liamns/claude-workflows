#!/usr/bin/env bash
# Search functionality for project index
# Epic 006 - Feature 004: Project Indexing and Caching
# Task: T015, T016 - Search using jq and format results

# Search in index
# Arguments: $1 = query string, $2 = index file path
search_in_index() {
    local query="$1"
    local index_file="$2"

    # Color codes
    local GREEN='\033[0;32m'
    local BLUE='\033[0;34m'
    local YELLOW='\033[1;33m'
    local NC='\033[0m' # No Color

    # Search criteria: path, exports, imports
    local results=$(jq --arg query "$query" '
        .files[] |
        select(
            (.path | contains($query)) or
            (.exports[]? | contains($query)) or
            (.imports[]? | contains($query))
        )
    ' "$index_file" 2>/dev/null)

    if [ -z "$results" ]; then
        echo "No results found for \"$query\""
        return 1
    fi

    # Count results
    local count=$(echo "$results" | jq -s 'length')

    echo -e "${GREEN}Found $count result(s):${NC}"
    echo ""

    # Format and display results
    echo "$results" | jq -r --arg blue "$BLUE" --arg yellow "$YELLOW" --arg nc "$NC" '
        "\($blue)📄 \(.path)\($nc)",
        "   Type: \(.type)",
        (if .exports | length > 0 then "   Exports: \(.exports | join(", "))" else "" end),
        (if .imports | length > 0 then "   Imports: \(.imports | join(", "))" else "" end),
        ""
    ' | grep -v '^""$'

    return 0
}

# Export function
export -f search_in_index
