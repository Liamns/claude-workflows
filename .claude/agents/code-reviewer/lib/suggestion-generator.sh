#!/usr/bin/env bash
# suggestion-generator.sh
# Generates code review suggestions based on codebase context

set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/cache-manager.sh"
source "$SCRIPT_DIR/codebase-indexer.sh"
source "$SCRIPT_DIR/similarity-analyzer.sh"

###############################################################################
# generate_reusability_suggestion
# Generates a reusability suggestion
# Args:
#   $1 - Target module JSON
#   $2 - Suggested module JSON (with similarity score)
#   $3 - File path in PR
#   $4 - Line number
# Returns: Formatted suggestion string
###############################################################################
generate_reusability_suggestion() {
  local target_module="$1"
  local suggested_module="$2"
  local filepath="$3"
  local line_number="$4"

  local target_name suggested_path suggested_name usage_count similarity_score
  target_name=$(echo "$target_module" | jq -r '.name')
  suggested_path=$(echo "$suggested_module" | jq -r '.path')
  suggested_name=$(echo "$suggested_module" | jq -r '.name')
  usage_count=$(echo "$suggested_module" | jq -r '.usageCount')
  similarity_score=$(echo "$suggested_module" | jq -r '.similarityScore // 0')

  # Convert similarity score to percentage
  local similarity_pct
  similarity_pct=$(echo "scale=0; $similarity_score * 100 / 1" | bc)

  # Generate import statement
  local import_statement
  import_statement=$(generate_import_statement "$suggested_path" "$suggested_name")

  # Format suggestion
  cat <<EOF

⚠️  Reusability Issue ($filepath:$line_number)
Consider reusing existing $suggested_name instead of creating $target_name

📊 Similarity: ${similarity_pct}%
📍 Existing Module:
   Path: $suggested_path
   Name: $suggested_name
   Usage: $usage_count times in codebase

💡 Suggested Fix:
$import_statement

📝 Rationale:
   Reduces code duplication and maintains consistency across the application.
   High similarity (${similarity_pct}%) suggests the same functionality can be achieved
   by reusing the existing module.

EOF
}

###############################################################################
# generate_duplication_suggestion
# Generates a code duplication warning
# Args:
#   $1 - Target module JSON
#   $2 - Duplicate module JSON (with similarity score)
#   $3 - File path in PR
#   $4 - Line number
# Returns: Formatted suggestion string
###############################################################################
generate_duplication_suggestion() {
  local target_module="$1"
  local duplicate_module="$2"
  local filepath="$3"
  local line_number="$4"

  local target_name duplicate_path duplicate_name similarity_score
  target_name=$(echo "$target_module" | jq -r '.name')
  duplicate_path=$(echo "$duplicate_module" | jq -r '.path')
  duplicate_name=$(echo "$duplicate_module" | jq -r '.name')
  similarity_score=$(echo "$duplicate_module" | jq -r '.similarityScore // 0')

  local similarity_pct
  similarity_pct=$(echo "scale=0; $similarity_score * 100 / 1" | bc)

  # Generate import statement
  local import_statement
  import_statement=$(generate_import_statement "$duplicate_path" "$duplicate_name")

  # Format suggestion
  cat <<EOF

❌ Duplication Detected ($filepath:$line_number)
Function/Component "$target_name" duplicates existing "$duplicate_name"

📊 Similarity Score: ${similarity_pct}%
📍 Existing Module:
   Path: $duplicate_path
   Name: $duplicate_name

💡 Suggested Fix:
   Remove duplicate implementation and import from existing module:

$import_statement

📝 Rationale:
   DRY (Don't Repeat Yourself) principle violation.
   ${similarity_pct}% code overlap detected with existing implementation.

EOF
}

###############################################################################
# generate_pattern_violation_suggestion
# Generates a pattern violation warning
# Args:
#   $1 - Pattern name
#   $2 - Is standard (true/false)
#   $3 - File path in PR
#   $4 - Line number
#   $5 - Suggested pattern (optional)
# Returns: Formatted suggestion string
###############################################################################
generate_pattern_violation_suggestion() {
  local pattern_name="$1"
  local is_standard="$2"
  local filepath="$3"
  local line_number="$4"
  local suggested_pattern="${5:-}"

  # If pattern is standard, don't warn
  if [[ "$is_standard" == "true" ]]; then
    return 0
  fi

  # Format suggestion
  cat <<EOF

ℹ️  Pattern Notice ($filepath:$line_number)
Non-standard pattern detected: $pattern_name

📊 This pattern is not widely used in the codebase (<70% adoption).

EOF

  if [[ -n "$suggested_pattern" ]]; then
    cat <<EOF
💡 Suggested Standard Pattern:
$suggested_pattern

📝 Rationale:
   Using standard patterns improves code consistency and maintainability.

EOF
  fi
}

###############################################################################
# generate_import_statement
# Generates an import statement for a module
# Args:
#   $1 - Module file path
#   $2 - Module name
# Returns: Import statement
###############################################################################
generate_import_statement() {
  local module_path="$1"
  local module_name="$2"

  # Convert file path to import path
  # Example: src/shared/ui/Button/Button.tsx -> @/shared/ui/Button
  local import_path
  import_path=$(echo "$module_path" | sed 's|^src/||' | sed 's|/[^/]*\.tsx\?$||' | sed 's|/[^/]*\.jsx\?$||')

  echo "import { $module_name } from '@/$import_path';"
}

###############################################################################
# analyze_pr_changes
# Analyzes PR changes for reusability and duplication
# Args:
#   $1 - PR diff or changed files JSON array
#   $2 - Cache file (optional)
# Returns: JSON array of suggestions
###############################################################################
analyze_pr_changes() {
  local changed_files="$1"
  local cache_file="${2:-$CACHE_FILE}"

  local suggestions="[]"

  # Get all modules from cache
  local all_modules
  all_modules=$(cache_get_modules "$cache_file")

  if [[ "$all_modules" == "[]" ]]; then
    echo "⚠️  No modules in cache. Run indexing first." >&2
    echo "[]"
    return 0
  fi

  # Parse changed files (assuming JSON array of file paths)
  local file_count
  file_count=$(echo "$changed_files" | jq 'length')

  for ((i=0; i<file_count; i++)); do
    local filepath
    filepath=$(echo "$changed_files" | jq -r ".[$i]")

    # Skip non-source files
    if [[ ! "$filepath" =~ \.(ts|tsx|js|jsx)$ ]]; then
      continue
    fi

    # Extract exports from this file
    local exports
    exports=$(grep -E "^export (const|function|class)" "$filepath" 2>/dev/null || true)

    if [[ -z "$exports" ]]; then
      continue
    fi

    # Analyze each export
    while IFS= read -r export_line; do
      # Extract module name
      local module_name
      if [[ "$export_line" =~ export\ (const|function|class)\ ([a-zA-Z0-9_]+) ]]; then
        module_name="${BASH_REMATCH[2]}"
      else
        continue
      fi

      # Create temporary module object
      local new_module
      new_module=$(jq -n \
        --arg path "$filepath" \
        --arg name "$module_name" \
        --arg sig "$export_line" \
        '{path: $path, name: $name, type: "unknown", signature: $sig, exports: [$name], usageCount: 0}')

      # Find similar modules
      local duplicates
      duplicates=$(find_duplicates "$new_module" "$all_modules" "0.8")

      # Generate suggestions for each duplicate
      local dup_count
      dup_count=$(echo "$duplicates" | jq 'length')

      for ((j=0; j<dup_count; j++)); do
        local duplicate
        duplicate=$(echo "$duplicates" | jq ".[$j]")

        # Generate suggestion text
        local suggestion_text
        suggestion_text=$(generate_reusability_suggestion "$new_module" "$duplicate" "$filepath" "1")

        # Add to suggestions array
        local suggestion_obj
        suggestion_obj=$(jq -n \
          --arg type "reusability" \
          --arg severity "warning" \
          --arg message "$suggestion_text" \
          --arg filepath "$filepath" \
          --argjson line 1 \
          '{type: $type, severity: $severity, message: $message, filePath: $filepath, lineNumber: $line}')

        suggestions=$(echo "$suggestions" | jq --argjson obj "$suggestion_obj" '. += [$obj]')
      done

    done <<< "$exports"
  done

  echo "$suggestions"
}

###############################################################################
# format_suggestions_output
# Formats suggestions for terminal output
# Args:
#   $1 - Suggestions JSON array
# Returns: Formatted text
###############################################################################
format_suggestions_output() {
  local suggestions="$1"

  local count
  count=$(echo "$suggestions" | jq 'length')

  if [[ "$count" -eq 0 ]]; then
    cat <<EOF

✅ No reusability or duplication issues found!

All code appears to follow best practices.

EOF
    return 0
  fi

  echo ""
  echo "📊 Code Review Results with Codebase Context"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Found $count suggestion(s):"
  echo ""

  for ((i=0; i<count; i++)); do
    local message
    message=$(echo "$suggestions" | jq -r ".[$i].message")
    echo "$message"
    echo ""
  done
}

###############################################################################
# Main execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-help}" in
    analyze)
      if [[ -z "${2:-}" ]]; then
        echo "Usage: $0 analyze <changed-files-json>" >&2
        exit 1
      fi
      analyze_pr_changes "$2"
      ;;
    format)
      if [[ -z "${2:-}" ]]; then
        echo "Usage: $0 format <suggestions-json>" >&2
        exit 1
      fi
      format_suggestions_output "$2"
      ;;
    help|*)
      cat <<EOF
Usage: $0 <command> [args]

Commands:
  analyze <files-json>          Analyze PR changes
  format <suggestions-json>     Format suggestions for output
  help                          Show this help

Examples:
  $0 analyze '["src/components/MyButton.tsx"]'
  $0 format '\$suggestions'

EOF
      ;;
  esac
fi
