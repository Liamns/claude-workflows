#!/bin/bash
# migrate-to-template.sh
# Migrates legacy command documentation to the new template format
#
# Usage:
#   bash migrate-to-template.sh <input.md> <output.md>
#   bash migrate-to-template.sh --in-place <file.md>
#
# Section mapping:
#   "Description" / "Command Description" → "Overview"
#   "How to Use" / "How It Works" → "Usage"
#   "Example Usage" / "Usage Examples" → "Examples"
#   "Code Implementation" / "Internal Implementation" → "Implementation"
#
# Features:
#   - Creates backup before migration
#   - Preserves all content
#   - Maps legacy section names to template names
#   - Validates output with template validator

set -e

# Source common module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ════════════════════════════════════════════════════════════════════════════
# Functions
# ════════════════════════════════════════════════════════════════════════════

show_usage() {
    cat << 'EOF'
Usage: migrate-to-template.sh [OPTIONS] <input.md> [output.md]

Migrate legacy command documentation to the new template format.

Options:
  --in-place       Migrate file in-place (overwrites original with backup)
  -h, --help       Show this help message

Arguments:
  input.md         Legacy command documentation file
  output.md        Output file (optional, defaults to input.md if --in-place)

Examples:
  # Migrate to new file
  migrate-to-template.sh old.md new.md

  # Migrate in-place
  migrate-to-template.sh --in-place .claude/commands/major.md

Section Mapping:
  Description → Overview
  How to Use → Usage
  Example Usage → Examples
  Code Implementation → Implementation
EOF
}

# Normalize section name to template standard (bash 3.2 compatible)
normalize_section() {
    local section="$1"

    # Use case statement instead of associative array (bash 3.2 compatible)
    case "$section" in
        "Description"|"Command Description"|"About")
            echo "Overview"
            ;;
        "How to Use"|"How It Works"|"Syntax"|"사용법")
            echo "Usage"
            ;;
        "Example Usage"|"Usage Examples"|"Sample Usage"|"Examples")
            echo "Examples"
            ;;
        "Code Implementation"|"Internal Implementation"|"Architecture"|"Implementation"|"🔧 Implementation")
            echo "Implementation"
            ;;
        *)
            # Return as-is if no mapping found
            echo "$section"
            ;;
    esac
}

# Extract title (# Header)
extract_title() {
    local file="$1"
    grep -E '^#[[:space:]]+[^#]' "$file" | head -1 | sed -E 's/^#[[:space:]]+//' || echo "Untitled Command"
}

# Extract content between two headers
extract_section_content() {
    local file="$1"
    local section_name="$2"
    local next_section="${3:-}"

    local start_line end_line

    # Find start line (## Section Name)
    start_line=$(grep -n "^##[[:space:]]*${section_name}" "$file" | cut -d: -f1 | head -1)

    if [[ -z "$start_line" ]]; then
        return 1
    fi

    # Find end line (next ## header or EOF)
    if [[ -n "$next_section" ]]; then
        end_line=$(grep -n "^##[[:space:]]*${next_section}" "$file" | cut -d: -f1 | head -1)
    else
        # Find next ## header after start_line
        end_line=$(tail -n +$((start_line + 1)) "$file" | grep -n "^##[[:space:]]" | cut -d: -f1 | head -1)
        if [[ -n "$end_line" ]]; then
            end_line=$((start_line + end_line))
        else
            end_line=$(wc -l < "$file")
        fi
    fi

    if [[ -z "$end_line" ]]; then
        end_line=$(wc -l < "$file")
    fi

    # Extract content (skip the header line itself)
    sed -n "$((start_line + 1)),$((end_line - 1))p" "$file"
    return 0
}

# Migrate document
migrate_document() {
    local input_file="$1"
    local output_file="$2"

    # Validate input
    if [[ ! -f "$input_file" ]]; then
        log_error "Input file not found: $input_file"
        return 1
    fi

    # Create backup
    cp "$input_file" "${input_file}.backup"
    log_info "Backup created: ${input_file}.backup"

    # Extract title
    local title
    title=$(extract_title "$input_file")

    # Extract all sections from input
    local all_sections
    all_sections=$(grep -E '^##[[:space:]]+[^#]' "$input_file" | sed -E 's/^##[[:space:]]+//' || true)

    # Start building output
    {
        echo "# $title"
        echo ""

        # Process each required section
        local required_sections=("Overview" "Usage" "Examples" "Implementation")

        for target_section in "${required_sections[@]}"; do
            echo "## $target_section"
            echo ""

            local found=false
            local content=""

            # Try to find matching legacy section
            while IFS= read -r legacy_section; do
                local normalized
                normalized=$(normalize_section "$legacy_section")

                if [[ "$normalized" == "$target_section" ]]; then
                    content=$(extract_section_content "$input_file" "$legacy_section")
                    if [[ -n "$content" ]]; then
                        echo "$content"
                        found=true
                        break
                    fi
                fi
            done <<< "$all_sections"

            # If no matching section found, add placeholder
            if ! $found; then
                echo "{TODO: Add $target_section content}"
            fi

            echo ""
        done

        # Add any additional sections that don't map to required ones
        while IFS= read -r section; do
            local normalized
            normalized=$(normalize_section "$section")

            # Skip if this is a required section (already processed)
            if [[ "$normalized" == "Overview" ]] || \
               [[ "$normalized" == "Usage" ]] || \
               [[ "$normalized" == "Examples" ]] || \
               [[ "$normalized" == "Implementation" ]]; then
                continue
            fi

            # Add this additional section
            echo "## $section"
            echo ""

            local content
            content=$(extract_section_content "$input_file" "$section")
            if [[ -n "$content" ]]; then
                echo "$content"
            fi
            echo ""
        done <<< "$all_sections"

        # Add version footer
        echo "---"
        echo ""
        echo "**Last Updated**: $(date +%Y-%m-%d)"

    } > "$output_file"

    log_success "Migration complete: $output_file"
    return 0
}

# ════════════════════════════════════════════════════════════════════════════
# Main
# ════════════════════════════════════════════════════════════════════════════

main() {
    local in_place=false
    local input_file=""
    local output_file=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --in-place)
                in_place=true
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
                if [[ -z "$input_file" ]]; then
                    input_file="$1"
                elif [[ -z "$output_file" ]]; then
                    output_file="$1"
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
    if [[ -z "$input_file" ]]; then
        log_error "No input file specified"
        show_usage
        exit 1
    fi

    # Set output file
    if $in_place; then
        output_file="$input_file"
    elif [[ -z "$output_file" ]]; then
        log_error "No output file specified (use --in-place to modify original)"
        show_usage
        exit 1
    fi

    # Perform migration
    if migrate_document "$input_file" "$output_file"; then
        # Validate result if validator exists
        local validator="$SCRIPT_DIR/validate-command-template.sh"
        if [[ -f "$validator" ]]; then
            if bash "$validator" "$output_file" 2>/dev/null; then
                log_success "✓ Migrated document passes template validation"
            else
                log_warning "⚠ Migrated document may need manual adjustments"
            fi
        fi
        exit 0
    else
        log_error "Migration failed"
        exit 1
    fi
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
