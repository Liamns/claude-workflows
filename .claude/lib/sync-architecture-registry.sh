#!/usr/bin/env bash
#
# sync-architecture-registry.sh
# 아키텍처 디렉토리를 스캔하여 registry.json을 자동으로 동기화합니다.
#
# Usage:
#   bash .claude/lib/sync-architecture-registry.sh [--verify-only]
#
# Options:
#   --verify-only  동기화 없이 검증만 수행
#   --help         도움말 표시

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCHITECTURES_DIR="${SCRIPT_DIR}/../architectures"
REGISTRY_FILE="${ARCHITECTURES_DIR}/registry.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Flags
VERIFY_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --verify-only)
      VERIFY_ONLY=true
      shift
      ;;
    --help)
      echo "Usage: $0 [--verify-only]"
      echo ""
      echo "Options:"
      echo "  --verify-only  동기화 없이 검증만 수행"
      echo "  --help         도움말 표시"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*"
}

# Extract value from JSON using grep and sed
extract_json_value() {
  local file="$1"
  local key="$2"

  # Simple JSON extraction (works for string values)
  grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$file" | \
    sed 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | \
    head -1
}

# Extract array from JSON
extract_json_array() {
  local file="$1"
  local key="$2"

  # Extract array values
  sed -n "/\"$key\"/,/\]/p" "$file" | \
    grep -o '"[^"]*"' | \
    sed 's/"//g' | \
    grep -v "^$key$"
}

# Scan architecture directories
scan_architectures() {
  local type="$1"  # frontend, backend, fullstack, mobile
  local type_dir="${ARCHITECTURES_DIR}/${type}"

  if [[ ! -d "$type_dir" ]]; then
    log_warn "Directory not found: $type_dir"
    return
  fi

  # Find all config.json files
  while IFS= read -r config_file; do
    local arch_dir
    arch_dir="$(dirname "$config_file")"
    local arch_name
    arch_name="$(basename "$arch_dir")"

    # Extract metadata from config.json
    local display_name
    display_name=$(extract_json_value "$config_file" "name")
    local description
    description=$(extract_json_value "$config_file" "description")
    local version
    version=$(extract_json_value "$config_file" "version")

    # Build config path
    local config_path=".claude/architectures/${type}/${arch_name}/config.json"

    # Output architecture info
    echo "${type}|${arch_name}|${display_name}|${description}|${config_path}|${version}"

  done < <(find "$type_dir" -maxdepth 2 -name "config.json" -type f)
}

# Verify registry consistency
verify_registry() {
  local errors=0

  log_info "Verifying registry.json consistency..."

  if [[ ! -f "$REGISTRY_FILE" ]]; then
    log_error "Registry file not found: $REGISTRY_FILE"
    return 1
  fi

  # Scan all architecture types
  local all_architectures=()

  for type in frontend backend fullstack mobile; do
    while IFS='|' read -r type arch_name display_name description config_path version; do
      all_architectures+=("${type}|${arch_name}|${display_name}|${description}|${config_path}|${version}")

      # Check if exists in registry
      if ! grep -q "\"${arch_name}\":" "$REGISTRY_FILE"; then
        log_error "Architecture not found in registry: ${type}/${arch_name}"
        ((errors++))
      else
        # Verify config path
        local registry_path
        registry_path=$(grep -A 10 "\"${arch_name}\":" "$REGISTRY_FILE" | \
                       grep "configPath" | \
                       sed 's/.*"configPath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

        if [[ "$registry_path" != "$config_path" ]]; then
          log_error "Config path mismatch for ${arch_name}: expected ${config_path}, got ${registry_path}"
          ((errors++))
        fi

        # Verify name
        local registry_name
        registry_name=$(grep -A 10 "\"${arch_name}\":" "$REGISTRY_FILE" | \
                       grep "\"name\"" | head -1 | \
                       sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

        if [[ "$registry_name" != "$display_name" ]]; then
          log_warn "Name mismatch for ${arch_name}: expected '${display_name}', got '${registry_name}'"
        fi
      fi
    done < <(scan_architectures "$type")
  done

  # Check for orphaned entries in registry
  log_info "Checking for orphaned registry entries..."

  for type in frontend backend fullstack mobile; do
    local type_section
    type_section=$(sed -n "/\"$type\":/,/^[[:space:]]*}/p" "$REGISTRY_FILE")

    # Extract architecture keys from this section
    local arch_keys
    arch_keys=$(echo "$type_section" | grep -o '"[^"]*"[[:space:]]*:[[:space:]]*{' | sed 's/"//g' | sed 's/[[:space:]]*:[[:space:]]*{//')

    for key in $arch_keys; do
      # Skip non-architecture keys
      [[ "$key" == "$type" ]] && continue

      # Check if config file exists
      local config_path
      config_path=$(grep -A 10 "\"${key}\":" "$REGISTRY_FILE" | \
                   grep "configPath" | \
                   sed 's/.*"configPath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

      if [[ -n "$config_path" ]] && [[ ! -f "${SCRIPT_DIR}/../${config_path#.claude/}" ]]; then
        log_error "Orphaned registry entry: ${type}/${key} (config not found: ${config_path})"
        ((errors++))
      fi
    done
  done

  if [[ $errors -eq 0 ]]; then
    log_success "Registry verification passed! All architectures are in sync."
    return 0
  else
    log_error "Registry verification failed with $errors error(s)"
    return 1
  fi
}

# Generate registry entry
generate_registry_entry() {
  local type="$1"
  local arch_name="$2"
  local display_name="$3"
  local description="$4"
  local config_path="$5"

  cat <<EOF
      "${arch_name}": {
        "name": "${display_name}",
        "description": "${description}",
        "aliases": [],
        "compatibility": [],
        "configPath": "${config_path}",
        "enabled": true
      }
EOF
}

# Sync registry (not implemented - requires careful JSON manipulation)
sync_registry() {
  log_warn "Auto-sync not yet implemented. Please manually update registry.json if needed."
  log_info "Use --verify-only to check for inconsistencies."
  return 1
}

# Main execution
main() {
  log_info "Architecture Registry Sync Tool"
  log_info "Registry file: $REGISTRY_FILE"
  echo ""

  if [[ "$VERIFY_ONLY" == true ]]; then
    verify_registry
    exit $?
  else
    # First verify
    if verify_registry; then
      log_success "No sync needed - registry is already up to date."
      exit 0
    else
      log_info "Registry is out of sync. Manual update required."
      log_info "Run with --verify-only to see detailed differences."
      exit 1
    fi
  fi
}

# Run main
main
