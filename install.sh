#!/bin/bash

# Claude Code Workflows Installer
# Version: 1.0.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/Liamns/claude-workflows"
TARGET_DIR="${1:-.}"
TEMP_DIR=$(mktemp -d)

# Functions
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Claude Code Workflows Installer     ║${NC}"
    echo -e "${BLUE}║   Version 1.0.0                        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Trap cleanup on exit
trap cleanup EXIT

# Main installation
install_workflows() {
    print_header

    print_info "Target directory: $TARGET_DIR"
    print_info "Installing workflows..."
    echo ""

    # Check if target directory exists
    if [ ! -d "$TARGET_DIR" ]; then
        print_error "Target directory does not exist: $TARGET_DIR"
        exit 1
    fi

    # Create .claude directory if it doesn't exist
    print_info "Creating .claude directory..."
    mkdir -p "$TARGET_DIR/.claude"
    print_success ".claude directory ready"

    # Clone repository to temp directory
    print_info "Downloading workflows from GitHub..."
    if git clone --quiet "$REPO_URL" "$TEMP_DIR" 2>/dev/null; then
        print_success "Downloaded successfully"
    else
        print_error "Failed to download from GitHub"
        print_info "Please check your internet connection or repository URL"
        exit 1
    fi

    # Copy agents
    if [ -d "$TEMP_DIR/agents" ]; then
        print_info "Installing Sub-agents (7개)..."
        cp -r "$TEMP_DIR/agents" "$TARGET_DIR/.claude/"
        print_success "Sub-agents installed"
    else
        print_warning "agents/ directory not found in repository"
    fi

    # Copy skills
    if [ -d "$TEMP_DIR/skills" ]; then
        print_info "Installing Skills (7개)..."
        cp -r "$TEMP_DIR/skills" "$TARGET_DIR/.claude/"
        print_success "Skills installed"
    else
        print_warning "skills/ directory not found in repository"
    fi

    # Copy workflow-gates.json
    if [ -f "$TEMP_DIR/workflow-gates.json" ]; then
        print_info "Installing workflow-gates.json..."
        cp "$TEMP_DIR/workflow-gates.json" "$TARGET_DIR/.claude/"
        print_success "workflow-gates.json installed"
    else
        print_warning "workflow-gates.json not found in repository"
    fi

    echo ""
    print_success "Installation complete!"
    echo ""

    # Print summary
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Installed Components:${NC}"
    echo ""
    echo "📁 $TARGET_DIR/.claude/"
    echo "   ├── agents/          (7 Sub-agents)"
    echo "   ├── skills/          (7 Skills)"
    echo "   └── workflow-gates.json"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Print next steps
    echo -e "${GREEN}Next Steps:${NC}"
    echo ""
    echo "1. 워크플로가 활성화되었습니다!"
    echo "2. Claude Code에서 다음 명령어를 사용할 수 있습니다:"
    echo "   - Major 워크플로: /speckit.specify"
    echo "   - Sub-agents: quick-fixer, fsd-architect, test-guardian 등"
    echo "   - Skills: 자동으로 상황에 맞게 실행됩니다"
    echo ""
    echo "3. 자세한 사용법은 README.md를 참고하세요:"
    echo "   ${REPO_URL}#readme"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Show usage
usage() {
    echo "Usage: $0 [target_directory]"
    echo ""
    echo "Example:"
    echo "  $0                    # Install to current directory"
    echo "  $0 /path/to/project   # Install to specific directory"
    echo ""
    echo "Or use with curl:"
    echo "  curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash"
}

# Parse arguments
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi

# Run installation
install_workflows
