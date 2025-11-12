#!/usr/bin/env bash
# cache-manager.sh
# Manages codebase index cache (memory + file)

set -euo pipefail

# Cache file location
CACHE_FILE="${CLAUDE_CACHE_DIR:-.claude/cache}/codebase-index.json"
CACHE_VERSION="1.0.0"

# In-memory cache (associative arrays)
declare -A MEMORY_CACHE_MODULES=()
declare -A MEMORY_CACHE_PATTERNS=()
declare -A MEMORY_CACHE_HASHES=()
MEMORY_CACHE_LOADED=false

###############################################################################
# cache_load
# Loads cache from file into memory
# Returns: 0 on success, 1 on failure
###############################################################################
cache_load() {
  local cache_file="${1:-$CACHE_FILE}"

  # Check if file exists
  if [[ ! -f "$cache_file" ]]; then
    echo "⚠️  Cache file not found: $cache_file" >&2
    return 1
  fi

  # Validate JSON structure
  if ! jq empty "$cache_file" 2>/dev/null; then
    echo "⚠️  Invalid JSON in cache file" >&2
    return 1
  fi

  # Check version compatibility
  local file_version
  file_version=$(jq -r '.version // "0.0.0"' "$cache_file")
  if [[ "$file_version" != "$CACHE_VERSION" ]]; then
    echo "⚠️  Cache version mismatch (file: $file_version, expected: $CACHE_VERSION)" >&2
    return 1
  fi

  # Load into memory
  # Note: In Bash, we'll keep it simple and just validate the file
  # Actual loading will happen on-demand via jq queries
  MEMORY_CACHE_LOADED=true

  echo "✅ Cache loaded from $cache_file" >&2
  return 0
}

###############################################################################
# cache_save
# Saves cache from memory to file
# Args:
#   $1 - JSON content to save
# Returns: 0 on success, 1 on failure
###############################################################################
cache_save() {
  local content="$1"
  local cache_file="${2:-$CACHE_FILE}"

  # Ensure directory exists
  mkdir -p "$(dirname "$cache_file")"

  # Validate JSON
  if ! echo "$content" | jq empty 2>/dev/null; then
    echo "⚠️  Invalid JSON content, cannot save cache" >&2
    return 1
  fi

  # Save to temp file first
  local temp_file="${cache_file}.tmp.$$"
  echo "$content" | jq '.' > "$temp_file"

  # Atomic move
  mv "$temp_file" "$cache_file"

  echo "✅ Cache saved to $cache_file" >&2
  return 0
}

###############################################################################
# cache_invalidate
# Invalidates cache (deletes file and clears memory)
# Returns: 0 on success
###############################################################################
cache_invalidate() {
  local cache_file="${1:-$CACHE_FILE}"

  # Clear memory cache
  MEMORY_CACHE_MODULES=()
  MEMORY_CACHE_PATTERNS=()
  MEMORY_CACHE_HASHES=()
  MEMORY_CACHE_LOADED=false

  # Delete file cache
  if [[ -f "$cache_file" ]]; then
    rm -f "$cache_file"
    echo "✅ Cache invalidated: $cache_file" >&2
  fi

  return 0
}

###############################################################################
# cache_is_valid
# Checks if cache is valid (not stale)
# Returns: 0 if valid, 1 if invalid/stale
###############################################################################
cache_is_valid() {
  local cache_file="${1:-$CACHE_FILE}"
  local project_root="${2:-.}"

  # Check if file exists
  if [[ ! -f "$cache_file" ]]; then
    return 1
  fi

  # Check version
  local file_version
  file_version=$(jq -r '.version // "0.0.0"' "$cache_file")
  if [[ "$file_version" != "$CACHE_VERSION" ]]; then
    echo "⚠️  Cache version mismatch" >&2
    return 1
  fi

  # Check if any tracked files changed
  # Get file hashes from cache
  local cached_hashes
  cached_hashes=$(jq -r '.fileHashes | to_entries[] | "\(.key):\(.value)"' "$cache_file")

  while IFS=: read -r filepath expected_hash; do
    # Skip if file doesn't exist anymore
    if [[ ! -f "$filepath" ]]; then
      echo "⚠️  Cached file no longer exists: $filepath" >&2
      return 1
    fi

    # Calculate current hash
    local current_hash
    current_hash=$(cache_get_file_hash "$filepath")

    # Compare hashes
    if [[ "$current_hash" != "$expected_hash" ]]; then
      echo "⚠️  File changed: $filepath" >&2
      return 1
    fi
  done <<< "$cached_hashes"

  return 0
}

###############################################################################
# cache_get_file_hash
# Calculates MD5 hash of a file
# Args:
#   $1 - File path
# Returns: Hash string
###############################################################################
cache_get_file_hash() {
  local filepath="$1"

  if [[ ! -f "$filepath" ]]; then
    echo "ERROR: File not found: $filepath" >&2
    return 1
  fi

  # Use md5sum or md5 depending on availability
  if command -v md5sum >/dev/null 2>&1; then
    md5sum "$filepath" | awk '{print $1}'
  elif command -v md5 >/dev/null 2>&1; then
    md5 -q "$filepath"
  else
    # Fallback: use file modification time
    stat -f %m "$filepath" 2>/dev/null || stat -c %Y "$filepath" 2>/dev/null
  fi
}

###############################################################################
# cache_get_modules
# Retrieves modules from cache
# Returns: JSON array of modules
###############################################################################
cache_get_modules() {
  local cache_file="${1:-$CACHE_FILE}"

  if [[ ! -f "$cache_file" ]]; then
    echo "[]"
    return 0
  fi

  jq -r '.modules // []' "$cache_file"
}

###############################################################################
# cache_get_patterns
# Retrieves patterns from cache
# Returns: JSON array of patterns
###############################################################################
cache_get_patterns() {
  local cache_file="${1:-$CACHE_FILE}"

  if [[ ! -f "$cache_file" ]]; then
    echo "[]"
    return 0
  fi

  jq -r '.patterns // []' "$cache_file"
}

###############################################################################
# cache_update
# Updates cache with new data
# Args:
#   $1 - Project root
#   $2 - Modules JSON array
#   $3 - Patterns JSON array
#   $4 - File hashes JSON object
# Returns: 0 on success
###############################################################################
cache_update() {
  local project_root="$1"
  local modules="$2"
  local patterns="$3"
  local file_hashes="$4"
  local cache_file="${5:-$CACHE_FILE}"

  local timestamp
  timestamp=$(date +%s)

  # Build cache JSON
  local cache_content
  cache_content=$(jq -n \
    --arg version "$CACHE_VERSION" \
    --argjson timestamp "$timestamp" \
    --arg projectRoot "$project_root" \
    --argjson modules "$modules" \
    --argjson patterns "$patterns" \
    --argjson fileHashes "$file_hashes" \
    '{
      version: $version,
      timestamp: $timestamp,
      projectRoot: $projectRoot,
      modules: $modules,
      patterns: $patterns,
      fileHashes: $fileHashes
    }')

  cache_save "$cache_content" "$cache_file"
}

###############################################################################
# Main execution (for testing)
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Run as standalone script
  case "${1:-help}" in
    load)
      cache_load "${2:-$CACHE_FILE}"
      ;;
    save)
      if [[ -z "${2:-}" ]]; then
        echo "Usage: $0 save <json-content>" >&2
        exit 1
      fi
      cache_save "$2"
      ;;
    invalidate)
      cache_invalidate "${2:-$CACHE_FILE}"
      ;;
    is-valid)
      if cache_is_valid "${2:-$CACHE_FILE}" "${3:-.}"; then
        echo "✅ Cache is valid"
        exit 0
      else
        echo "❌ Cache is invalid or stale"
        exit 1
      fi
      ;;
    get-hash)
      if [[ -z "${2:-}" ]]; then
        echo "Usage: $0 get-hash <filepath>" >&2
        exit 1
      fi
      cache_get_file_hash "$2"
      ;;
    get-modules)
      cache_get_modules "${2:-$CACHE_FILE}"
      ;;
    get-patterns)
      cache_get_patterns "${2:-$CACHE_FILE}"
      ;;
    help|*)
      cat <<EOF
Usage: $0 <command> [args]

Commands:
  load [cache-file]              Load cache from file
  save <json-content>            Save JSON content to cache
  invalidate [cache-file]        Invalidate (delete) cache
  is-valid [cache-file] [root]   Check if cache is valid
  get-hash <filepath>            Get file hash
  get-modules [cache-file]       Get modules from cache
  get-patterns [cache-file]      Get patterns from cache
  help                           Show this help

Examples:
  $0 load
  $0 is-valid
  $0 get-modules
  $0 invalidate
EOF
      ;;
  esac
fi
