#!/bin/bash
# install-git-hooks.sh
# Install git hooks for command template validation
#
# Usage:
#   bash .claude/lib/install-git-hooks.sh
#
# This script installs:
#   - pre-commit: Validates command template files before commit

set -e

# Source common module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ════════════════════════════════════════════════════════════════════════════
# Configuration
# ════════════════════════════════════════════════════════════════════════════

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    log_error "Not in a git repository"
    exit 1
}

HOOKS_DIR="$REPO_ROOT/.git/hooks"

# ════════════════════════════════════════════════════════════════════════════
# Functions
# ════════════════════════════════════════════════════════════════════════════

install_hook() {
    local hook_name="$1"
    local hook_file="$HOOKS_DIR/$hook_name"

    # Create hook content
    cat > "$hook_file" << 'HOOK_EOF'
#!/bin/bash
# pre-commit hook for command template validation
# Validates that any modified command files follow the template structure

set -e

# Get the repository root
REPO_ROOT=$(git rev-parse --show-toplevel)
VALIDATOR="$REPO_ROOT/.claude/lib/validate-command-template.sh"

# Only validate if validator exists
if [[ ! -f "$VALIDATOR" ]]; then
    exit 0
fi

# Get list of staged .md files in .claude/commands/
STAGED_COMMANDS=$(git diff --cached --name-only --diff-filter=ACM | grep '^\.claude/commands/.*\.md$' || true)

# If no command files staged, allow commit
if [[ -z "$STAGED_COMMANDS" ]]; then
    exit 0
fi

echo "🔍 Validating command templates..."
echo ""

# Track validation results
FAILED_FILES=()
PASSED_COUNT=0

# Validate each staged command file
while IFS= read -r file; do
    if [[ -f "$REPO_ROOT/$file" ]]; then
        echo "Checking: $file"

        if bash "$VALIDATOR" "$REPO_ROOT/$file" 2>&1 | grep -q "Template validation passed"; then
            echo "  ✓ Valid"
            ((PASSED_COUNT++))
        else
            echo "  ✗ Failed validation"
            FAILED_FILES+=("$file")
        fi
        echo ""
    fi
done <<< "$STAGED_COMMANDS"

# If any files failed, block commit
if [[ ${#FAILED_FILES[@]} -gt 0 ]]; then
    echo "❌ Pre-commit validation failed!"
    echo ""
    echo "The following command files do not follow the template structure:"
    for file in "${FAILED_FILES[@]}"; do
        echo "  - $file"
    done
    echo ""
    echo "Please fix these files or run:"
    echo "  bash .claude/lib/migrate-to-template.sh <file>"
    echo ""
    echo "To bypass this check (not recommended):"
    echo "  git commit --no-verify"
    exit 1
fi

echo "✅ All command templates validated successfully ($PASSED_COUNT files)"
exit 0
HOOK_EOF

    # Make hook executable
    chmod +x "$hook_file"

    log_success "Installed: $hook_name"
}

# ════════════════════════════════════════════════════════════════════════════
# Main
# ════════════════════════════════════════════════════════════════════════════

main() {
    log_info "Installing Git hooks..."
    echo ""

    # Ensure hooks directory exists
    if [[ ! -d "$HOOKS_DIR" ]]; then
        log_error "Git hooks directory not found: $HOOKS_DIR"
        exit 1
    fi

    # Install pre-commit hook
    install_hook "pre-commit"

    echo ""
    log_success "Git hooks installed successfully!"
    echo ""
    log_info "Installed hooks:"
    echo "  - pre-commit: Validates command template files"
    echo ""
    log_info "To bypass hook validation (not recommended):"
    echo "  git commit --no-verify"
    echo ""
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
