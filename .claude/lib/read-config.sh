#!/bin/bash
# read-config.sh
# Shared configuration utility for workflow scripts
# Provides read access to workflow-gates.json, constitution.md, and other configs
#
# Usage: source .claude/lib/read-config.sh
#
# Provides functions:
# - get_workflow_gate()
# - get_quality_threshold()
# - get_constitution_rules()
# - get_project_version()
# - is_gate_enabled()

# Prevent multiple sourcing
if [[ -n "${CLAUDE_CONFIG_LOADED:-}" ]]; then
    return 0
fi
CLAUDE_CONFIG_LOADED=1

# Script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities if not already loaded
if [[ -z "${CLAUDE_COMMON_LOADED:-}" ]]; then
    # shellcheck source=.claude/lib/common.sh
    source "${SCRIPT_DIR}/common.sh"
fi

# ==============================================================================
# Configuration Paths
# ==============================================================================

readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly WORKFLOW_GATES_FILE="${PROJECT_ROOT}/.claude/workflow-gates.json"
readonly CONSTITUTION_FILE="${PROJECT_ROOT}/.specify/memory/constitution.md"
readonly PATHS_FILE="${PROJECT_ROOT}/.specify/memory/PATHS.md"
readonly CLAUDE_CONFIG_DIR="${PROJECT_ROOT}/.claude/commands-config"

# Cache directory for parsed JSON (bash 3.2 compatible)
CONFIG_CACHE_DIR="/tmp/.claude-config-cache-$$"
mkdir -p "$CONFIG_CACHE_DIR" 2>/dev/null || true

# ==============================================================================
# JSON Parsing Utilities
# ==============================================================================

# Parse JSON using python (compatible fallback)
parse_json() {
    local json_file="$1"
    local query="$2"

    # Check if file exists
    if [ ! -f "$json_file" ]; then
        log_error "Config file not found: $json_file"
        return 1
    fi

    # Try jq first (fastest)
    if command -v jq &> /dev/null; then
        jq -r "$query" "$json_file" 2>/dev/null || echo ""
        return 0
    fi

    # Fallback to python
    if command -v python3 &> /dev/null; then
        python3 -c "
import json, sys
try:
    with open('$json_file') as f:
        data = json.load(f)
    # Simple path parsing for basic queries
    path = '$query'.strip('.')
    result = data
    for key in path.split('.'):
        if key:
            result = result.get(key, '')
    print(result if result else '')
except:
    print('')
" 2>/dev/null
        return 0
    fi

    log_error "No JSON parser available (need jq or python3)"
    return 1
}

# ==============================================================================
# Workflow Gates Configuration
# ==============================================================================

# Get project version from workflow-gates.json
get_project_version() {
    local cache_file="${CONFIG_CACHE_DIR}/version"

    if [ -f "$cache_file" ]; then
        cat "$cache_file"
        return 0
    fi

    local version
    version=$(parse_json "$WORKFLOW_GATES_FILE" ".version")

    if [ -n "$version" ] && [ "$version" != "null" ]; then
        echo "$version" > "$cache_file"
        echo "$version"
        return 0
    else
        echo "unknown"
        return 1
    fi
}

# Get workflow description
# Usage: get_workflow_description "major"
get_workflow_description() {
    local workflow="$1"

    if [ -z "$workflow" ]; then
        log_error "Workflow name required"
        return 1
    fi

    parse_json "$WORKFLOW_GATES_FILE" ".workflows.${workflow}.description"
}

# Get workflow triggers
# Usage: get_workflow_triggers "major"
get_workflow_triggers() {
    local workflow="$1"

    if [ -z "$workflow" ]; then
        log_error "Workflow name required"
        return 1
    fi

    # Return JSON array of triggers
    parse_json "$WORKFLOW_GATES_FILE" ".workflows.${workflow}.triggers"
}

# Check if a gate is enabled for a workflow
# Usage: is_gate_enabled "major" "pre-implementation" "reusability-search"
is_gate_enabled() {
    local workflow="$1"
    local phase="$2"
    local gate="$3"

    if [ -z "$workflow" ] || [ -z "$phase" ] || [ -z "$gate" ]; then
        log_error "Usage: is_gate_enabled <workflow> <phase> <gate>"
        return 1
    fi

    local enabled
    enabled=$(parse_json "$WORKFLOW_GATES_FILE" ".workflows.${workflow}.gates.${phase}.${gate}.enabled")

    if [ "$enabled" = "true" ]; then
        return 0
    else
        return 1
    fi
}

# Check if a gate is required
# Usage: is_gate_required "major" "pre-implementation" "reusability-search"
is_gate_required() {
    local workflow="$1"
    local phase="$2"
    local gate="$3"

    if [ -z "$workflow" ] || [ -z "$phase" ] || [ -z "$gate" ]; then
        log_error "Usage: is_gate_required <workflow> <phase> <gate>"
        return 1
    fi

    local required
    required=$(parse_json "$WORKFLOW_GATES_FILE" ".workflows.${workflow}.gates.${phase}.${gate}.required")

    if [ "$required" = "true" ]; then
        return 0
    else
        return 1
    fi
}

# Get gate description
# Usage: get_gate_description "major" "pre-implementation" "reusability-search"
get_gate_description() {
    local workflow="$1"
    local phase="$2"
    local gate="$3"

    parse_json "$WORKFLOW_GATES_FILE" ".workflows.${workflow}.gates.${phase}.${gate}.description"
}

# Get workflow token savings estimate
# Usage: get_token_savings "major"
get_token_savings() {
    local workflow="$1"
    parse_json "$WORKFLOW_GATES_FILE" ".workflows.${workflow}.estimated_token_savings"
}

# Get workflow quality level
# Usage: get_quality_level "major"
get_quality_level() {
    local workflow="$1"
    parse_json "$WORKFLOW_GATES_FILE" ".workflows.${workflow}.quality_level"
}

# ==============================================================================
# Common Gates Configuration
# ==============================================================================

# Get commit message format
get_commit_message_format() {
    parse_json "$WORKFLOW_GATES_FILE" ".common_gates.git.commit_message.format"
}

# Get commit message examples
get_commit_message_examples() {
    parse_json "$WORKFLOW_GATES_FILE" ".common_gates.git.commit_message.examples"
}

# Get branch naming patterns
get_branch_patterns() {
    parse_json "$WORKFLOW_GATES_FILE" ".common_gates.git.branch_naming.patterns"
}

# Get reusability target metrics
# Usage: get_reusability_target "reusability_rate"
get_reusability_target() {
    local metric="$1"
    parse_json "$WORKFLOW_GATES_FILE" ".common_gates.reusability.metrics_tracking.targets.${metric}"
}

# ==============================================================================
# Constitution Configuration
# ==============================================================================

# Check if constitution file exists
has_constitution() {
    [ -f "$CONSTITUTION_FILE" ]
}

# Read constitution rules (returns file content)
get_constitution_content() {
    if has_constitution; then
        cat "$CONSTITUTION_FILE"
    else
        log_warning "Constitution file not found: $CONSTITUTION_FILE"
        return 1
    fi
}

# Extract specific section from constitution
# Usage: get_constitution_section "Architecture"
get_constitution_section() {
    local section_name="$1"

    if ! has_constitution; then
        return 1
    fi

    # Extract section between ## headers
    awk -v section="$section_name" '
        /^## / {
            if ($0 ~ section) {
                found=1
                next
            } else if (found) {
                exit
            }
        }
        found { print }
    ' "$CONSTITUTION_FILE"
}

# ==============================================================================
# Paths Configuration
# ==============================================================================

# Check if paths file exists
has_paths_config() {
    [ -f "$PATHS_FILE" ]
}

# Get paths content
get_paths_content() {
    if has_paths_config; then
        cat "$PATHS_FILE"
    else
        log_warning "Paths file not found: $PATHS_FILE"
        return 1
    fi
}

# ==============================================================================
# Validation Functions
# ==============================================================================

# Validate all configuration files exist
validate_config_files() {
    local all_valid=true

    log_info "Validating configuration files..."

    # Check workflow gates
    if [ -f "$WORKFLOW_GATES_FILE" ]; then
        log_success "workflow-gates.json found"
    else
        log_error "workflow-gates.json not found: $WORKFLOW_GATES_FILE"
        all_valid=false
    fi

    # Check constitution (optional)
    if has_constitution; then
        log_success "constitution.md found"
    else
        log_warning "constitution.md not found (optional)"
    fi

    # Check paths (optional)
    if has_paths_config; then
        log_success "PATHS.md found"
    else
        log_warning "PATHS.md not found (optional)"
    fi

    if [ "$all_valid" = true ]; then
        return 0
    else
        return 1
    fi
}

# Validate JSON syntax
validate_workflow_gates_json() {
    log_info "Validating workflow-gates.json syntax..."

    if ! [ -f "$WORKFLOW_GATES_FILE" ]; then
        log_error "File not found: $WORKFLOW_GATES_FILE"
        return 1
    fi

    # Try to parse with jq
    if command -v jq &> /dev/null; then
        if jq empty "$WORKFLOW_GATES_FILE" 2>/dev/null; then
            log_success "JSON syntax valid"
            return 0
        else
            log_error "JSON syntax invalid"
            return 1
        fi
    fi

    # Try with python
    if command -v python3 &> /dev/null; then
        if python3 -c "import json; json.load(open('$WORKFLOW_GATES_FILE'))" 2>/dev/null; then
            log_success "JSON syntax valid"
            return 0
        else
            log_error "JSON syntax invalid"
            return 1
        fi
    fi

    log_warning "Cannot validate JSON (no parser available)"
    return 0
}

# ==============================================================================
# Utility Functions
# ==============================================================================

# List all available workflows
list_workflows() {
    log_info "Available workflows:"

    for workflow in major minor micro epic; do
        local desc
        desc=$(get_workflow_description "$workflow")
        echo "  - ${workflow}: ${desc}"
    done
}

# Display workflow summary
# Usage: show_workflow_summary "major"
show_workflow_summary() {
    local workflow="$1"

    if [ -z "$workflow" ]; then
        log_error "Workflow name required"
        return 1
    fi

    echo ""
    log_info "=== ${workflow} Workflow Summary ==="
    echo ""

    local desc savings quality
    desc=$(get_workflow_description "$workflow")
    savings=$(get_token_savings "$workflow")
    quality=$(get_quality_level "$workflow")

    echo "Description: ${desc}"
    echo "Token Savings: ${savings}"
    echo "Quality Level: ${quality}"
    echo ""

    log_info "Triggers:"
    local triggers
    triggers=$(get_workflow_triggers "$workflow")
    echo "$triggers" | jq -r '.[]' 2>/dev/null || echo "  (unable to parse)"
    echo ""
}

# ==============================================================================
# Cache Management
# ==============================================================================

# Clear configuration cache
clear_config_cache() {
    rm -rf "$CONFIG_CACHE_DIR"
    mkdir -p "$CONFIG_CACHE_DIR" 2>/dev/null || true
    log_info "Configuration cache cleared"
}

# Show cache status
show_cache_status() {
    log_info "Configuration cache status:"

    local cache_count=0
    if [ -d "$CONFIG_CACHE_DIR" ]; then
        cache_count=$(find "$CONFIG_CACHE_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
    fi

    echo "  Cached items: ${cache_count}"

    if [ "$cache_count" -gt 0 ]; then
        find "$CONFIG_CACHE_DIR" -type f -exec basename {} \; 2>/dev/null | sed 's/^/    - /'
    fi
}

# ==============================================================================
# Self-Test
# ==============================================================================

# Run self-test of configuration utilities
test_config_utilities() {
    log_info "=== Testing Configuration Utilities ==="
    echo ""

    # Test 1: Validate config files
    if validate_config_files; then
        log_success "Test 1: Config files validation passed"
    else
        log_error "Test 1: Config files validation failed"
        return 1
    fi

    echo ""

    # Test 2: Read project version
    local version
    version=$(get_project_version)
    if [ -n "$version" ]; then
        log_success "Test 2: Project version: $version"
    else
        log_error "Test 2: Failed to read project version"
        return 1
    fi

    echo ""

    # Test 3: Read workflow description
    local major_desc
    major_desc=$(get_workflow_description "major")
    if [ -n "$major_desc" ]; then
        log_success "Test 3: Major workflow description found"
    else
        log_error "Test 3: Failed to read major workflow description"
        return 1
    fi

    echo ""

    # Test 4: Check gate status
    if is_gate_enabled "major" "pre-implementation" "reusability-search"; then
        log_success "Test 4: Gate status check working"
    else
        log_warning "Test 4: Gate not enabled (expected for some configs)"
    fi

    echo ""
    log_success "=== All Configuration Tests Passed ==="
    return 0
}

# ==============================================================================
# Export Functions
# ==============================================================================

# These functions are available when this file is sourced:
# - get_project_version
# - get_workflow_description
# - get_workflow_triggers
# - is_gate_enabled
# - is_gate_required
# - get_gate_description
# - get_token_savings
# - get_quality_level
# - get_commit_message_format
# - get_commit_message_examples
# - get_branch_patterns
# - get_reusability_target
# - has_constitution
# - get_constitution_content
# - get_constitution_section
# - has_paths_config
# - get_paths_content
# - validate_config_files
# - validate_workflow_gates_json
# - list_workflows
# - show_workflow_summary
# - clear_config_cache
# - show_cache_status
# - test_config_utilities

# ==============================================================================
# Main (for standalone execution)
# ==============================================================================

# If executed directly (not sourced), run self-test
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_config_utilities
fi
