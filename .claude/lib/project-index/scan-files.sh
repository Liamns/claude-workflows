#!/usr/bin/env bash
# File scanning logic
# Epic 006 - Feature 004: Project Indexing and Caching
# Task: T005 - Scan files with find, exclude .gitignore patterns

# Scan project files and return paths
# Arguments: $1 = project root path
# Returns: newline-separated list of file paths
scan_project_files() {
    local project_root="$1"

    # Directories to exclude (common patterns)
    local exclude_patterns=(
        -path "*/node_modules" -prune -o
        -path "*/.git" -prune -o
        -path "*/dist" -prune -o
        -path "*/build" -prune -o
        -path "*/.next" -prune -o
        -path "*/.cache" -prune -o
        -path "*/coverage" -prune -o
        -path "*/.claude/cache" -prune -o
    )

    # File extensions to index
    local file_patterns=(
        -name "*.ts"
        -o -name "*.tsx"
        -o -name "*.js"
        -o -name "*.jsx"
        -o -name "*.sh"
        -o -name "*.md"
    )

    # Find files
    find "$project_root" \
        "${exclude_patterns[@]}" \
        \( "${file_patterns[@]}" \) \
        -type f \
        -print 2>/dev/null | sort
}

# Export function
export -f scan_project_files
