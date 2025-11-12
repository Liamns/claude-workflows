#!/usr/bin/env bash
# codebase-indexer.sh
# Indexes codebase for modules, patterns, and reusable components

set -euo pipefail

# Source cache-manager
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/cache-manager.sh"

# Configuration
MAX_INDEXING_TIME=30  # seconds
SEARCH_DIRS=("src" ".claude" "lib")
FILE_PATTERNS=("*.ts" "*.tsx" "*.js" "*.jsx" "*.md" "*.sh")

###############################################################################
# index_modules
# Discovers and indexes modules (components, functions, hooks, utils)
# Args:
#   $1 - Project root directory
# Returns: JSON array of modules
###############################################################################
index_modules() {
  local project_root="${1:-.}"
  local modules=()
  local module_json="[]"

  echo "🔍 Indexing modules..." >&2

  # Find TypeScript/JavaScript files
  local files
  files=$(find "$project_root/src" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) 2>/dev/null || true)

  if [[ -z "$files" ]]; then
    echo "⚠️  No source files found in $project_root/src" >&2
    echo "[]"
    return 0
  fi

  # Extract modules from files
  while IFS= read -r filepath; do
    # Extract exports
    local exports
    exports=$(grep -E "^export (const|function|class|interface|type)" "$filepath" 2>/dev/null || true)

    if [[ -z "$exports" ]]; then
      continue
    fi

    # Parse each export
    while IFS= read -r export_line; do
      local module_name
      local module_type
      local signature

      # Determine module type and name
      if [[ "$export_line" =~ export\ const\ ([a-zA-Z0-9_]+)\ =\ \(.*\)\ =\> ]]; then
        # Arrow function component or hook
        module_name="${BASH_REMATCH[1]}"
        if [[ "$module_name" =~ ^use[A-Z] ]]; then
          module_type="hook"
        elif [[ "$export_line" =~ React\.FC|JSX\.Element|\<.*\> ]]; then
          module_type="component"
        else
          module_type="function"
        fi
        signature="$export_line"

      elif [[ "$export_line" =~ export\ function\ ([a-zA-Z0-9_]+) ]]; then
        # Regular function
        module_name="${BASH_REMATCH[1]}"
        module_type="function"
        signature="$export_line"

      elif [[ "$export_line" =~ export\ class\ ([a-zA-Z0-9_]+) ]]; then
        # Class
        module_name="${BASH_REMATCH[1]}"
        module_type="util"
        signature="$export_line"

      elif [[ "$export_line" =~ export\ interface\ ([a-zA-Z0-9_]+) ]]; then
        # Interface (skip for now)
        continue

      else
        # Unknown export type
        continue
      fi

      # Count usage in project
      local usage_count
      usage_count=$(grep -r "import.*$module_name" "$project_root/src" 2>/dev/null | wc -l | tr -d ' ')

      # Build module JSON
      local module_obj
      module_obj=$(jq -n \
        --arg path "$filepath" \
        --arg name "$module_name" \
        --arg type "$module_type" \
        --arg sig "$signature" \
        --argjson usage "$usage_count" \
        '{
          path: $path,
          name: $name,
          type: $type,
          signature: $sig,
          exports: [$name],
          usageCount: $usage
        }')

      # Append to modules array
      module_json=$(echo "$module_json" | jq --argjson obj "$module_obj" '. += [$obj]')

    done <<< "$exports"

  done <<< "$files"

  echo "✅ Indexed $(echo "$module_json" | jq 'length') modules" >&2
  echo "$module_json"
}

###############################################################################
# index_patterns
# Detects common coding patterns in the codebase
# Args:
#   $1 - Project root directory
# Returns: JSON array of patterns
###############################################################################
index_patterns() {
  local project_root="${1:-.}"
  local patterns_json="[]"

  echo "🔍 Indexing patterns..." >&2

  # Pattern 1: try-catch error handling
  local try_catch_count
  try_catch_count=$(grep -r "try\s*{" "$project_root/src" 2>/dev/null | wc -l | tr -d ' ')

  if [[ "$try_catch_count" -gt 0 ]]; then
    local total_functions
    total_functions=$(grep -r "function\|const.*=.*=>" "$project_root/src" 2>/dev/null | wc -l | tr -d ' ')

    local is_standard=false
    if [[ "$total_functions" -gt 0 ]]; then
      local percentage=$((try_catch_count * 100 / total_functions))
      if [[ "$percentage" -gt 70 ]]; then
        is_standard=true
      fi
    fi

    local pattern_id
    pattern_id=$(uuidgen 2>/dev/null || echo "try-catch-$(date +%s)")

    local pattern_obj
    pattern_obj=$(jq -n \
      --arg id "$pattern_id" \
      --arg name "try-catch-error-handling" \
      --arg regex "try\\s*\\{[\\s\\S]*?\\}\\s*catch\\s*\\([\\s\\S]*?\\)\\s*\\{[\\s\\S]*?\\}" \
      --argjson occurrences "$try_catch_count" \
      --argjson isStandard "$is_standard" \
      --arg category "error-handling" \
      '{
        id: $id,
        name: $name,
        regex: $regex,
        occurrences: $occurrences,
        isStandard: $isStandard,
        examples: [],
        category: $category
      }')

    patterns_json=$(echo "$patterns_json" | jq --argjson obj "$pattern_obj" '. += [$obj]')
  fi

  # Pattern 2: React Query usage
  local react_query_count
  react_query_count=$(grep -r "useQuery\|useMutation" "$project_root/src" 2>/dev/null | wc -l | tr -d ' ')

  if [[ "$react_query_count" -gt 0 ]]; then
    local total_api_calls
    total_api_calls=$(grep -r "fetch\|axios\|useQuery\|useMutation" "$project_root/src" 2>/dev/null | wc -l | tr -d ' ')

    local is_standard=false
    if [[ "$total_api_calls" -gt 0 ]]; then
      local percentage=$((react_query_count * 100 / total_api_calls))
      if [[ "$percentage" -gt 70 ]]; then
        is_standard=true
      fi
    fi

    local pattern_id
    pattern_id=$(uuidgen 2>/dev/null || echo "react-query-$(date +%s)")

    local pattern_obj
    pattern_obj=$(jq -n \
      --arg id "$pattern_id" \
      --arg name "react-query-api-pattern" \
      --arg regex "useQuery\\s*\\([\\s\\S]*?\\)|useMutation\\s*\\([\\s\\S]*?\\)" \
      --argjson occurrences "$react_query_count" \
      --argjson isStandard "$is_standard" \
      --arg category "api-call" \
      '{
        id: $id,
        name: $name,
        regex: $regex,
        occurrences: $occurrences,
        isStandard: $isStandard,
        examples: [],
        category: $category
      }')

    patterns_json=$(echo "$patterns_json" | jq --argjson obj "$pattern_obj" '. += [$obj]')
  fi

  echo "✅ Indexed $(echo "$patterns_json" | jq 'length') patterns" >&2
  echo "$patterns_json"
}

###############################################################################
# search_similar
# Searches for modules similar to the given one
# Args:
#   $1 - Module name to search for
#   $2 - Module type (optional)
#   $3 - Cache file (optional)
# Returns: JSON array of similar modules
###############################################################################
search_similar() {
  local search_name="$1"
  local search_type="${2:-}"
  local cache_file="${3:-$CACHE_FILE}"

  # Get all modules from cache
  local all_modules
  all_modules=$(cache_get_modules "$cache_file")

  if [[ "$all_modules" == "[]" ]]; then
    echo "[]"
    return 0
  fi

  # Filter by name similarity
  local similar_modules
  if [[ -n "$search_type" ]]; then
    similar_modules=$(echo "$all_modules" | jq --arg name "$search_name" --arg type "$search_type" \
      '[.[] | select(.name | ascii_downcase | contains($name | ascii_downcase)) | select(.type == $type)]')
  else
    similar_modules=$(echo "$all_modules" | jq --arg name "$search_name" \
      '[.[] | select(.name | ascii_downcase | contains($name | ascii_downcase))]')
  fi

  echo "$similar_modules"
}

###############################################################################
# get_module_info
# Gets detailed information about a module from a file
# Args:
#   $1 - File path
#   $2 - Module name
# Returns: Module information (signature, props, description)
###############################################################################
get_module_info() {
  local filepath="$1"
  local module_name="$2"

  if [[ ! -f "$filepath" ]]; then
    echo "{}"
    return 1
  fi

  # Extract function/component signature
  local signature
  signature=$(grep -A 5 "export.*$module_name" "$filepath" 2>/dev/null | head -10 || true)

  # Extract Props interface (for React components)
  local props_interface=""
  if grep -q "${module_name}Props" "$filepath" 2>/dev/null; then
    props_interface=$(sed -n "/interface ${module_name}Props/,/^}/p" "$filepath" 2>/dev/null || true)
  fi

  # Extract JSDoc description
  local description=""
  local jsdoc
  jsdoc=$(grep -B 10 "export.*$module_name" "$filepath" 2>/dev/null | grep -E "^\s*\*\s*" | sed 's/^\s*\*\s*//' || true)
  if [[ -n "$jsdoc" ]]; then
    description=$(echo "$jsdoc" | head -1)
  fi

  # Build JSON
  jq -n \
    --arg sig "$signature" \
    --arg props "$props_interface" \
    --arg desc "$description" \
    '{
      signature: $sig,
      props: $props,
      description: $desc
    }'
}

###############################################################################
# progressive_index
# Performs progressive indexing with timeout
# Args:
#   $1 - Project root
#   $2 - Timeout in seconds (default: 30)
# Returns: JSON object with modules, patterns, and file hashes
###############################################################################
progressive_index() {
  local project_root="${1:-.}"
  local timeout="${2:-$MAX_INDEXING_TIME}"

  local start_time
  start_time=$(date +%s)

  echo "🚀 Starting progressive indexing (timeout: ${timeout}s)..." >&2

  # Phase 1: Index modules (priority)
  local modules
  modules=$(timeout "$timeout" index_modules "$project_root" 2>&1 || echo "[]")

  # Check remaining time
  local elapsed=$(($(date +%s) - start_time))
  local remaining=$((timeout - elapsed))

  if [[ "$remaining" -le 0 ]]; then
    echo "⏱️  Timeout reached during module indexing" >&2
    # Return partial results
    jq -n \
      --argjson modules "$modules" \
      '{modules: $modules, patterns: [], fileHashes: {}}'
    return 0
  fi

  # Phase 2: Index patterns
  local patterns
  patterns=$(timeout "$remaining" index_patterns "$project_root" 2>&1 || echo "[]")

  # Phase 3: Calculate file hashes
  local file_hashes="{}"
  local files
  files=$(find "$project_root/src" -type f \( -name "*.ts" -o -name "*.tsx" \) 2>/dev/null | head -100 || true)

  while IFS= read -r filepath; do
    if [[ -z "$filepath" ]]; then continue; fi

    local hash
    hash=$(cache_get_file_hash "$filepath" 2>/dev/null || echo "unknown")

    file_hashes=$(echo "$file_hashes" | jq --arg path "$filepath" --arg hash "$hash" '. + {($path): $hash}')
  done <<< "$files"

  local total_elapsed=$(($(date +%s) - start_time))
  echo "✅ Indexing completed in ${total_elapsed}s" >&2

  # Return combined results
  jq -n \
    --argjson modules "$modules" \
    --argjson patterns "$patterns" \
    --argjson fileHashes "$file_hashes" \
    '{modules: $modules, patterns: $patterns, fileHashes: $fileHashes}'
}

###############################################################################
# Main execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-help}" in
    index-modules)
      index_modules "${2:-.}"
      ;;
    index-patterns)
      index_patterns "${2:-.}"
      ;;
    search)
      if [[ -z "${2:-}" ]]; then
        echo "Usage: $0 search <module-name> [type]" >&2
        exit 1
      fi
      search_similar "$2" "${3:-}"
      ;;
    get-info)
      if [[ -z "${2:-}" ]] || [[ -z "${3:-}" ]]; then
        echo "Usage: $0 get-info <filepath> <module-name>" >&2
        exit 1
      fi
      get_module_info "$2" "$3"
      ;;
    progressive)
      progressive_index "${2:-.}" "${3:-30}"
      ;;
    help|*)
      cat <<EOF
Usage: $0 <command> [args]

Commands:
  index-modules [root]             Index all modules
  index-patterns [root]            Index coding patterns
  search <name> [type]             Search for similar modules
  get-info <file> <name>           Get module information
  progressive [root] [timeout]     Progressive indexing with timeout
  help                             Show this help

Examples:
  $0 index-modules .
  $0 search Button component
  $0 progressive . 30
EOF
      ;;
  esac
fi
