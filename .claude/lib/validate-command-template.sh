#!/bin/bash
# validate-command-template.sh
# Validates that a command markdown file conforms to the required template structure
#
# Usage:
#   bash validate-command-template.sh <file.md>
#   bash validate-command-template.sh --score <file.md>
#
# Required sections (in order):
#   1. Overview - Command description and purpose
#   2. Usage - How to use the command
#   3. Examples - Usage examples
#   4. Implementation - Internal details
#
# Exit codes:
#   0 - Valid template
#   1 - Invalid template or file not found

set -e

# Source common module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ════════════════════════════════════════════════════════════════════════════
# Configuration
# ════════════════════════════════════════════════════════════════════════════

# Required sections in order
REQUIRED_SECTIONS=(
    "Overview"
    "Usage"
    "Examples"
    "Implementation"
)

# ════════════════════════════════════════════════════════════════════════════
# Functions
# ════════════════════════════════════════════════════════════════════════════

show_usage() {
    cat << 'EOF'
Usage: validate-command-template.sh [OPTIONS] <file.md>

Validates that a command documentation file conforms to the required template.

Options:
  --score          Output compliance score (0-100) instead of pass/fail
  -h, --help       Show this help message

Required sections:
  1. Overview      - Command description and purpose
  2. Usage         - How to use the command
  3. Examples      - Usage examples
  4. Implementation - Internal implementation details

Examples:
  # Validate a file
  validate-command-template.sh .claude/commands/major.md

  # Get compliance score
  validate-command-template.sh --score .claude/commands/major.md

Exit codes:
  0 - Valid template (or successful score calculation)
  1 - Invalid template or file not found
EOF
}

# Extract all markdown headers (## Header Name)
extract_sections() {
    local file="$1"
    grep -E '^##[[:space:]]+[^#]' "$file" | sed -E 's/^##[[:space:]]+//' || true
}

# Check if a section exists
section_exists() {
    local sections="$1"
    local section_name="$2"

    echo "$sections" | grep -qF "$section_name"
}

# Validate section order
validate_section_order() {
    local file="$1"
    local sections

    sections=$(extract_sections "$file")

    if [[ -z "$sections" ]]; then
        return 1
    fi

    # Extract line numbers for each required section
    local overview_line usage_line examples_line impl_line

    overview_line=$(grep -n "^## Overview" "$file" | cut -d: -f1 | head -1)
    usage_line=$(grep -n "^## Usage" "$file" | cut -d: -f1 | head -1)
    examples_line=$(grep -n "^## Examples" "$file" | cut -d: -f1 | head -1)
    impl_line=$(grep -n "^## Implementation" "$file" | cut -d: -f1 | head -1)

    # All sections must exist
    if [[ -z "$overview_line" ]] || [[ -z "$usage_line" ]] || \
       [[ -z "$examples_line" ]] || [[ -z "$impl_line" ]]; then
        return 1
    fi

    # Check order: Overview < Usage < Examples < Implementation
    if [[ "$overview_line" -lt "$usage_line" ]] && \
       [[ "$usage_line" -lt "$examples_line" ]] && \
       [[ "$examples_line" -lt "$impl_line" ]]; then
        return 0
    else
        return 1
    fi
}

# Calculate compliance score (0-100)
calculate_score() {
    local file="$1"
    local score=0
    local sections

    # Empty file = 0
    if [[ ! -s "$file" ]]; then
        echo "0"
        return 0
    fi

    sections=$(extract_sections "$file")

    # No headers = 0
    if [[ -z "$sections" ]]; then
        echo "0"
        return 0
    fi

    # Each required section is worth 25 points
    for section in "${REQUIRED_SECTIONS[@]}"; do
        if section_exists "$sections" "$section"; then
            ((score += 25))
        fi
    done

    # Bonus: Correct order = 100 total
    if [[ $score -eq 100 ]]; then
        if ! validate_section_order "$file"; then
            # Penalty for wrong order: -10 points
            ((score -= 10))
        fi
    fi

    echo "$score"
    return 0
}

# Validate template
validate_template() {
    local file="$1"
    local sections
    local missing=()

    # Check file exists and is not empty
    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi

    if [[ ! -s "$file" ]]; then
        log_error "File is empty: $file"
        return 1
    fi

    # Extract sections
    sections=$(extract_sections "$file")

    if [[ -z "$sections" ]]; then
        log_error "No markdown headers found in file"
        return 1
    fi

    # Check required sections
    for section in "${REQUIRED_SECTIONS[@]}"; do
        if ! section_exists "$sections" "$section"; then
            missing+=("$section")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required sections:"
        for section in "${missing[@]}"; do
            echo "  - $section" >&2
        done
        return 1
    fi

    # Validate section order
    if ! validate_section_order "$file"; then
        log_error "Sections are not in the correct order"
        log_info "Expected order: Overview → Usage → Examples → Implementation"
        return 1
    fi

    # All checks passed
    return 0
}

# ════════════════════════════════════════════════════════════════════════════
# Main
# ════════════════════════════════════════════════════════════════════════════

main() {
    local mode="validate"
    local file=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --score)
                mode="score"
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
                file="$1"
                shift
                ;;
        esac
    done

    # Validate arguments
    if [[ -z "$file" ]]; then
        log_error "No file specified"
        show_usage
        exit 1
    fi

    # Execute based on mode
    if [[ "$mode" == "score" ]]; then
        score=$(calculate_score "$file")
        echo "$score"
        exit 0
    else
        if validate_template "$file"; then
            log_success "Template validation passed: $file"
            exit 0
        else
            exit 1
        fi
    fi
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
