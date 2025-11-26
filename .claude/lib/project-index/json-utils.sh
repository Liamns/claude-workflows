#!/usr/bin/env bash
# JSON utility functions
# Epic 006 - Feature 004: Project Indexing and Caching
# Task: T007, T008 - Create index JSON and save/load functions

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/detect-type.sh" 2>/dev/null || true
source "$SCRIPT_DIR/parse-exports.sh" 2>/dev/null || true
source "$SCRIPT_DIR/parse-imports.sh" 2>/dev/null || true

# Create JSON index from file list
# Arguments: $1 = newline-separated file paths, $2 = output file path
create_index_json() {
    local files_input="$1"
    local output_file="$2"
    local project_root="/Users/hk/Documents/claude-workflow"

    # Get current timestamp
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Start JSON structure
    local json_content="{\"version\":\"1.0.0\",\"lastUpdated\":\"$timestamp\",\"files\":["

    local first=true
    local file_count=0
    declare -a directories
    directories=()

    # Process each file
    while IFS= read -r file_path; do
        [ -z "$file_path" ] && continue

        # Get relative path
        local rel_path="${file_path#$project_root/}"

        # Collect directory
        local dir_path=$(dirname "$rel_path")
        local found=false
        if [ ${#directories[@]} -gt 0 ]; then
            for d in "${directories[@]}"; do
                if [ "$d" = "$dir_path" ]; then
                    found=true
                    break
                fi
            done
        fi
        if [ "$found" = false ]; then
            directories+=("$dir_path")
        fi

        # Detect type
        local file_type=$(detect_file_type "$rel_path")

        # Get file modification time
        if [[ "$OSTYPE" == "darwin"* ]]; then
            local mtime=$(stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%SZ" "$file_path" 2>/dev/null || echo "$timestamp")
        else
            local mtime=$(stat -c "%y" "$file_path" 2>/dev/null | cut -d' ' -f1 || echo "$timestamp")
        fi

        # Parse exports and imports (if applicable)
        local exports="[]"
        local imports="[]"

        if [[ "$file_path" == *.ts ]] || [[ "$file_path" == *.tsx ]] || [[ "$file_path" == *.js ]] || [[ "$file_path" == *.jsx ]]; then
            if type parse_exports &>/dev/null; then
                exports=$(parse_exports "$file_path" | jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
            fi
            if type parse_imports &>/dev/null; then
                imports=$(parse_imports "$file_path" | jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
            fi
        fi

        # Add comma if not first
        if [ "$first" = false ]; then
            json_content+=","
        fi
        first=false

        # Add file entry (escape double quotes in paths)
        local escaped_path=$(echo "$rel_path" | sed 's/"/\\"/g')
        json_content+="{\"path\":\"$escaped_path\",\"type\":\"$file_type\",\"exports\":$exports,\"imports\":$imports,\"lastModified\":\"$mtime\"}"

        ((file_count++))
    done <<< "$files_input"

    # Close files array
    json_content+="],"

    # Add directories array
    json_content+="\"directories\":["
    first=true
    for dir in "${directories[@]}"; do
        if [ "$first" = false ]; then
            json_content+=","
        fi
        first=false
        local escaped_dir=$(echo "$dir" | sed 's/"/\\"/g')
        json_content+="\"$escaped_dir\""
    done
    json_content+="]}"

    # Write to file
    echo "$json_content" | jq '.' > "$output_file" 2>/dev/null || echo "$json_content" > "$output_file"

    echo "  Indexed $file_count files"
}

# Load index from file
# Arguments: $1 = index file path
# Returns: JSON content
load_index_json() {
    local index_file="$1"

    if [ ! -f "$index_file" ]; then
        echo "{}"
        return 1
    fi

    cat "$index_file"
}

# Export functions
export -f create_index_json
export -f load_index_json
