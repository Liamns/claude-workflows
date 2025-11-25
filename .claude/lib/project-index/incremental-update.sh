#!/usr/bin/env bash
# Incremental update logic
# Epic 006 - Feature 004: Project Indexing and Caching
# Task: T020 - Update only changed files using git diff

# Perform incremental update
# Arguments: $1 = project root, $2 = index file path
perform_incremental_update() {
    local project_root="$1"
    local index_file="$2"

    # Source dependencies
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/detect-type.sh"
    source "$SCRIPT_DIR/parse-exports.sh"
    source "$SCRIPT_DIR/parse-imports.sh"

    echo "  Detecting changed files..."

    # Get list of changed files from last commit
    local changed_files
    changed_files=$(git -C "$project_root" diff --name-only HEAD~1 2>/dev/null || echo "")

    if [ -z "$changed_files" ]; then
        echo "  No changes detected in last commit"
        return 0
    fi

    # Count changed files
    local change_count=$(echo "$changed_files" | wc -l | tr -d ' ')
    echo "  Found $change_count changed file(s)"

    # Filter to only files we index
    local file_patterns='\.ts$|\.tsx$|\.js$|\.jsx$|\.sh$|\.md$'
    local updated_count=0

    while IFS= read -r file; do
        [ -z "$file" ] && continue

        # Check if file matches our patterns
        if ! echo "$file" | grep -qE "$file_patterns"; then
            continue
        fi

        local full_path="$project_root/$file"

        # If file was deleted
        if [ ! -f "$full_path" ]; then
            # Remove from index
            jq --arg path "$file" '.files |= map(select(.path != $path))' \
                "$index_file" > "$index_file.tmp" && mv "$index_file.tmp" "$index_file"
            echo "    Removed: $file"
            ((updated_count++))
            continue
        fi

        # File exists - update or add it
        local file_type=$(detect_file_type "$file")

        # Get modification time
        if [[ "$OSTYPE" == "darwin"* ]]; then
            local mtime=$(stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%SZ" "$full_path" 2>/dev/null)
        else
            local mtime=$(stat -c "%y" "$full_path" 2>/dev/null | cut -d' ' -f1)
        fi

        # Parse exports and imports
        local exports="[]"
        local imports="[]"

        if [[ "$file" =~ \.(ts|tsx|js|jsx)$ ]]; then
            exports=$(parse_exports "$full_path" | jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
            imports=$(parse_imports "$full_path" | jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
        fi

        # Update or add entry in index
        local entry=$(jq -n \
            --arg path "$file" \
            --arg type "$file_type" \
            --argjson exports "$exports" \
            --argjson imports "$imports" \
            --arg mtime "$mtime" \
            '{path: $path, type: $type, exports: $exports, imports: $imports, lastModified: $mtime}')

        # Remove old entry and add new one
        jq --argjson entry "$entry" --arg path "$file" \
            '.files |= (map(select(.path != $path)) + [$entry])' \
            "$index_file" > "$index_file.tmp" && mv "$index_file.tmp" "$index_file"

        echo "    Updated: $file"
        ((updated_count++))

    done <<< "$changed_files"

    # Update lastUpdated timestamp
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    jq --arg ts "$timestamp" '.lastUpdated = $ts' \
        "$index_file" > "$index_file.tmp" && mv "$index_file.tmp" "$index_file"

    echo "  Updated $updated_count file(s) in index"
}

# Export function
export -f perform_incremental_update
