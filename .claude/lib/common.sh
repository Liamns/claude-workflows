#!/bin/bash
# common.sh
# Common utility functions shared across all .claude scripts
# Compatible with bash 3.2+
#
# Usage: source .claude/lib/common.sh
#
# Provides:
# - Logging functions (log_info, log_success, log_warning, log_error)
# - File validation (check_file_exists, validate_json)
# - Backup creation (create_backup)
# - SHA256 tool detection (detect_sha256_tool)

# Prevent multiple sourcing
if [[ -n "${CLAUDE_COMMON_LOADED:-}" ]]; then
    return 0
fi
CLAUDE_COMMON_LOADED=1

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Logging Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Log informational message
# Arguments:
#   $1 - Message to log
# Output:
#   Blue info icon + message to stdout
#   Optional: Appends to LOG_FILE if set
log_info() {
    local message="$1"
    echo -e "${BLUE}ℹ${NC} $message"
    [[ -n "${LOG_FILE:-}" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $message" >> "$LOG_FILE"
    return 0
}

# Log success message
# Arguments:
#   $1 - Message to log
# Output:
#   Green checkmark + message to stdout
#   Optional: Appends to LOG_FILE if set
log_success() {
    local message="$1"
    echo -e "${GREEN}✓${NC} $message"
    [[ -n "${LOG_FILE:-}" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $message" >> "$LOG_FILE"
    return 0
}

# Log warning message
# Arguments:
#   $1 - Message to log
# Output:
#   Yellow warning icon + message to stdout
#   Optional: Appends to LOG_FILE if set
log_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠${NC} $message"
    [[ -n "${LOG_FILE:-}" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $message" >> "$LOG_FILE"
    return 0
}

# Log error message
# Arguments:
#   $1 - Message to log
# Output:
#   Red X + message to stderr
#   Optional: Appends to LOG_FILE if set
log_error() {
    local message="$1"
    echo -e "${RED}✗${NC} $message" >&2
    [[ -n "${LOG_FILE:-}" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $message" >> "$LOG_FILE"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# File Validation Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Check if a file exists
# Arguments:
#   $1 - File path to check
# Returns:
#   0 if file exists, 1 otherwise
check_file_exists() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        return 0
    else
        return 1
    fi
}

# Validate JSON file syntax
# Arguments:
#   $1 - Path to JSON file
# Returns:
#   0 if valid JSON, 1 otherwise
# Note:
#   Requires jq to be installed. Falls back gracefully if not available.
validate_json() {
    local json_file="$1"

    # Check file exists
    if ! check_file_exists "$json_file"; then
        log_error "JSON file not found: $json_file"
        return 1
    fi

    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        log_warning "jq not found - cannot validate JSON"
        return 1
    fi

    # Validate using jq
    if jq empty "$json_file" 2>/dev/null; then
        return 0
    else
        log_error "Invalid JSON: $json_file"
        return 1
    fi
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Backup Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Create timestamped backup directory
# Arguments:
#   $1 - Backup type/context (optional, defaults to "backup")
# Output:
#   Prints the created backup directory path
# Returns:
#   0 on success, 1 on failure
# Example:
#   backup_dir=$(create_backup "migration")
create_backup() {
    local context="${1:-backup}"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_dir=".claude/.backup/${context}-${timestamp}"

    if mkdir -p "$backup_dir"; then
        echo "$backup_dir"
        return 0
    else
        log_error "Failed to create backup directory: $backup_dir"
        return 1
    fi
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# System Detection Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Detect available SHA256 hashing tool
# Output:
#   Command string for SHA256 hashing
# Returns:
#   0 if tool found, 1 if no tool available
# Priority:
#   1. shasum (macOS default)
#   2. sha256sum (Linux default)
#   3. openssl (universal fallback)
# Example:
#   sha_cmd=$(detect_sha256_tool)
#   $sha_cmd myfile.txt
detect_sha256_tool() {
    # Priority 1: shasum (macOS default)
    if command -v shasum &> /dev/null; then
        echo "shasum -a 256"
        return 0
    fi

    # Priority 2: sha256sum (Linux default)
    if command -v sha256sum &> /dev/null; then
        echo "sha256sum"
        return 0
    fi

    # Priority 3: openssl (universal fallback)
    if command -v openssl &> /dev/null; then
        echo "openssl dgst -sha256"
        return 0
    fi

    log_error "No SHA256 tool found (tried: shasum, sha256sum, openssl)"
    return 1
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Module Initialization
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Self-test when executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== common.sh self-test ==="
    echo ""

    # Test logging functions
    log_info "Testing log_info"
    log_success "Testing log_success"
    log_warning "Testing log_warning"
    log_error "Testing log_error"
    echo ""

    # Test file validation
    echo "Testing check_file_exists..."
    if check_file_exists "${BASH_SOURCE[0]}"; then
        log_success "check_file_exists works"
    else
        log_error "check_file_exists failed"
    fi
    echo ""

    # Test JSON validation (if jq available)
    echo "Testing validate_json..."
    if command -v jq &> /dev/null; then
        temp_json=$(mktemp)
        echo '{"test": "value"}' > "$temp_json"
        if validate_json "$temp_json"; then
            log_success "validate_json works"
        else
            log_error "validate_json failed"
        fi
        rm -f "$temp_json"
    else
        log_warning "jq not found - skipping validate_json test"
    fi
    echo ""

    # Test backup creation
    echo "Testing create_backup..."
    backup_dir=$(create_backup "test")
    if [[ -d "$backup_dir" ]]; then
        log_success "create_backup created: $backup_dir"
        rmdir "$backup_dir"
    else
        log_error "create_backup failed"
    fi
    echo ""

    # Test SHA256 tool detection
    echo "Testing detect_sha256_tool..."
    if sha_tool=$(detect_sha256_tool); then
        log_success "SHA256 tool: $sha_tool"
    else
        log_error "No SHA256 tool found"
    fi
    echo ""

    log_success "common.sh self-test complete"
fi
