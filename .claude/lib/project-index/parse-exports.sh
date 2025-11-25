#!/usr/bin/env bash
# Parse exports from TypeScript/JavaScript files
# Epic 006 - Feature 004: Project Indexing and Caching
# Task: T011 - Parse exports using regex (80% accuracy target)

# Parse exports from a file
# Arguments: $1 = file path
# Returns: newline-separated list of exported symbols
parse_exports() {
    local file_path="$1"

    if [ ! -f "$file_path" ]; then
        return
    fi

    # Extract export statements using grep and sed
    # Patterns:
    # - export const X
    # - export function X
    # - export class X
    # - export type X
    # - export interface X
    # - export { X, Y, Z }
    # - export default X

    declare -a exports
    exports=()

    # Pattern 1: export const/let/var NAME
    while IFS= read -r line; do
        exports+=("$line")
    done < <(grep -oE 'export (const|let|var) [A-Za-z0-9_]+' "$file_path" 2>/dev/null | sed -E 's/export (const|let|var) //')

    # Pattern 2: export function NAME
    while IFS= read -r line; do
        exports+=("$line")
    done < <(grep -oE 'export (function|async function) [A-Za-z0-9_]+' "$file_path" 2>/dev/null | sed -E 's/export (async )?function //')

    # Pattern 3: export class NAME
    while IFS= read -r line; do
        exports+=("$line")
    done < <(grep -oE 'export class [A-Za-z0-9_]+' "$file_path" 2>/dev/null | sed 's/export class //')

    # Pattern 4: export type NAME
    while IFS= read -r line; do
        exports+=("$line")
    done < <(grep -oE 'export type [A-Za-z0-9_]+' "$file_path" 2>/dev/null | sed 's/export type //')

    # Pattern 5: export interface NAME
    while IFS= read -r line; do
        exports+=("$line")
    done < <(grep -oE 'export interface [A-Za-z0-9_]+' "$file_path" 2>/dev/null | sed 's/export interface //')

    # Pattern 6: export { X, Y, Z }
    while IFS= read -r line; do
        # Extract names between braces
        local names=$(echo "$line" | sed -E 's/export \{ ([^}]+) \}.*/\1/' | tr ',' '\n' | sed 's/^ *//;s/ *$//')
        while IFS= read -r name; do
            # Remove "as" aliases
            name=$(echo "$name" | sed -E 's/ as .*//')
            [ -n "$name" ] && exports+=("$name")
        done <<< "$names"
    done < <(grep -oE 'export \{ [^}]+ \}' "$file_path" 2>/dev/null)

    # Pattern 7: export default (try to get the name)
    if grep -q 'export default' "$file_path" 2>/dev/null; then
        local default_name=$(grep -oE 'export default [A-Za-z0-9_]+' "$file_path" 2>/dev/null | head -1 | sed 's/export default //')
        [ -n "$default_name" ] && exports+=("$default_name")
    fi

    # Remove duplicates and print
    if [ ${#exports[@]} -gt 0 ]; then
        printf '%s\n' "${exports[@]}" | sort -u
    fi
}

# Export function
export -f parse_exports
