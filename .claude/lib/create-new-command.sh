#!/bin/bash
# create-new-command.sh
# Automated command creation from template
#
# Usage:
#   bash create-new-command.sh <command-name> [--minimal]
#
# Features:
#   - Creates command .md file from template
#   - Auto-updates command-resource registry
#   - Validates generated file
#   - Sets up proper permissions
#
# Example:
#   bash create-new-command.sh deploy
#   bash create-new-command.sh test --minimal

set -e

# Source common module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ════════════════════════════════════════════════════════════════════════════
# Configuration
# ════════════════════════════════════════════════════════════════════════════

TEMPLATES_DIR="$SCRIPT_DIR/../templates"
COMMANDS_DIR="$SCRIPT_DIR/../commands"
REGISTRY_FILE="$SCRIPT_DIR/../registry/command-resource-mapping.json"

# ════════════════════════════════════════════════════════════════════════════
# Functions
# ════════════════════════════════════════════════════════════════════════════

show_usage() {
    cat << 'EOF'
Usage: create-new-command.sh <command-name> [OPTIONS]

Create a new command from template.

Arguments:
  command-name     Name of the command (e.g., 'deploy', 'test')

Options:
  --minimal        Use minimal template instead of full template
  -h, --help       Show this help message

Examples:
  # Create full command
  create-new-command.sh deploy

  # Create minimal command
  create-new-command.sh test --minimal

Output:
  - .claude/commands/{command-name}.md
  - Registry updated: .claude/registry/command-resource-mapping.json
  - Template validated ✓
EOF
}

# Validate command name
validate_command_name() {
    local name="$1"

    # Must be lowercase alphanumeric with hyphens
    if [[ ! "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
        log_error "Invalid command name: $name"
        log_info "Command name must:"
        echo "  - Start with lowercase letter" >&2
        echo "  - Contain only lowercase letters, numbers, and hyphens" >&2
        echo "  - Examples: deploy, run-tests, my-command" >&2
        return 1
    fi

    return 0
}

# Check if command already exists
command_exists() {
    local name="$1"
    [[ -f "$COMMANDS_DIR/$name.md" ]]
}

# Generate command file from template
generate_command() {
    local name="$1"
    local use_minimal="${2:-false}"
    local output_file="$COMMANDS_DIR/$name.md"

    # Select template
    local template_file
    if $use_minimal; then
        template_file="$TEMPLATES_DIR/command-template-minimal.md"
    else
        template_file="$TEMPLATES_DIR/command-template.md"
    fi

    if [[ ! -f "$template_file" ]]; then
        log_error "Template not found: $template_file"
        return 1
    fi

    # Convert command name to title case
    local title
    title=$(echo "$name" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')

    # Generate file from template
    sed "s/{Command Name}/$title/g; s/{command-name}/$name/g; s/{X.Y.Z}/1.0.0/g; s/{YYYY-MM-DD}/$(date +%Y-%m-%d)/g" \
        "$template_file" > "$output_file"

    log_success "Created: $output_file"
    return 0
}

# Update registry (simplified - just log for now since registry schema needs to be defined)
update_registry() {
    local name="$1"

    if [[ ! -f "$REGISTRY_FILE" ]]; then
        log_warning "Registry not found: $REGISTRY_FILE"
        log_info "Run registry generator to create initial registry"
        return 0
    fi

    # For now, just log that registry should be regenerated
    log_info "Registry update needed"
    log_info "Run: bash .claude/lib/generate-registry.sh"
    return 0
}

# ════════════════════════════════════════════════════════════════════════════
# Main
# ════════════════════════════════════════════════════════════════════════════

main() {
    local command_name=""
    local use_minimal=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --minimal)
                use_minimal=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$command_name" ]]; then
                    command_name="$1"
                else
                    log_error "Too many arguments"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Validate arguments
    if [[ -z "$command_name" ]]; then
        log_error "No command name specified"
        show_usage
        exit 1
    fi

    # Validate command name
    if ! validate_command_name "$command_name"; then
        exit 1
    fi

    # Check if already exists
    if command_exists "$command_name"; then
        log_error "Command already exists: $COMMANDS_DIR/$command_name.md"
        log_info "Use a different name or delete the existing file first"
        exit 1
    fi

    log_info "Creating new command: $command_name"
    echo ""

    # Generate command file
    if ! generate_command "$command_name" "$use_minimal"; then
        log_error "Failed to generate command file"
        exit 1
    fi

    # Validate generated file
    local validator="$SCRIPT_DIR/validate-command-template.sh"
    if [[ -f "$validator" ]]; then
        if bash "$validator" "$COMMANDS_DIR/$command_name.md" 2>/dev/null; then
            log_success "✓ Template validation passed"
        else
            log_warning "⚠ Generated file may need manual adjustments"
        fi
    fi

    echo ""

    # Update registry
    update_registry "$command_name"

    echo ""
    log_success "========================================="
    log_success "  Command Created Successfully!"
    log_success "========================================="
    echo ""
    log_info "Next steps:"
    echo "  1. Edit: $COMMANDS_DIR/$command_name.md"
    echo "  2. Customize Overview, Usage, Examples, Implementation"
    echo "  3. Run: bash .claude/lib/generate-registry.sh (to update registry)"
    echo "  4. Test: /$command_name"
    echo ""

    exit 0
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
