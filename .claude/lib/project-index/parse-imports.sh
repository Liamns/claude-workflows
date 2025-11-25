#!/usr/bin/env bash
# Parse imports from TypeScript/JavaScript files
# Epic 006 - Feature 004: Project Indexing and Caching
# Task: T012 - Parse imports using regex (80% accuracy target)

# Parse imports from a file
# Arguments: $1 = file path
# Returns: newline-separated list of imported symbols
parse_imports() {
    local file_path="$1"

    if [ ! -f "$file_path" ]; then
        return
    fi

    # Extract import statements using grep and sed
    # Patterns:
    # - import { X, Y, Z } from '...'
    # - import X from '...'
    # - import * as X from '...'
    # - import type { X } from '...'

    declare -a imports
    imports=()

    # Pattern 1: import { X, Y, Z } from
    while IFS= read -r line; do
        # Extract names between braces
        local names=$(echo "$line" | sed -E 's/import (type )?(\{|type \{) ([^}]+) \}.*/\3/' | tr ',' '\n' | sed 's/^ *//;s/ *$//')
        while IFS= read -r name; do
            # Remove "as" aliases and "type" keyword
            name=$(echo "$name" | sed -E 's/ as .*//' | sed 's/^type //')
            [ -n "$name" ] && imports+=("$name")
        done <<< "$names"
    done < <(grep -oE 'import (type )?\{[^}]+\} from' "$file_path" 2>/dev/null)

    # Pattern 2: import X from (default import)
    while IFS= read -r line; do
        local name=$(echo "$line" | sed -E "s/import ([A-Za-z0-9_]+) from.*/\1/")
        [ -n "$name" ] && imports+=("$name")
    done < <(grep -oE "import [A-Za-z0-9_]+ from ['\"]" "$file_path" 2>/dev/null)

    # Pattern 3: import * as X from
    while IFS= read -r line; do
        local name=$(echo "$line" | sed -E 's/import \* as ([A-Za-z0-9_]+) from.*/\1/')
        [ -n "$name" ] && imports+=("$name")
    done < <(grep -oE 'import \* as [A-Za-z0-9_]+ from' "$file_path" 2>/dev/null)

    # Remove duplicates and print
    if [ ${#imports[@]} -gt 0 ]; then
        printf '%s\n' "${imports[@]}" | sort -u
    fi
}

# Export function
export -f parse_imports
