#!/bin/bash

# Claude Code Workflows Installer
# Version: 2.0.0

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
    echo -e "${BLUE}║   Version 2.0.0                        ║${NC}"
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

    # Clone repository to temp directory
    print_info "Downloading workflows from GitHub..."
    if git clone --quiet "$REPO_URL" "$TEMP_DIR" 2>/dev/null; then
        print_success "Downloaded successfully"
    else
        print_error "Failed to download from GitHub"
        print_info "Please check your internet connection or repository URL"
        exit 1
    fi

    # Create .claude directory structure
    print_info "Creating .claude directory structure..."
    mkdir -p "$TARGET_DIR/.claude/commands"
    mkdir -p "$TARGET_DIR/.claude/templates"
    print_success ".claude directory ready"

    # Copy slash commands
    if [ -d "$TEMP_DIR/.claude/commands" ]; then
        print_info "Installing Slash Commands (12개)..."
        cp -r "$TEMP_DIR/.claude/commands/"* "$TARGET_DIR/.claude/commands/" 2>/dev/null || true
        print_success "Slash Commands installed (triage, commit, pr-review, major, minor, micro 등)"
    else
        print_warning ".claude/commands/ directory not found in repository"
    fi

    # Copy templates
    if [ -d "$TEMP_DIR/.claude/templates" ]; then
        print_info "Installing Templates..."
        cp -r "$TEMP_DIR/.claude/templates/"* "$TARGET_DIR/.claude/templates/" 2>/dev/null || true
        print_success "Templates installed"
    else
        print_warning ".claude/templates/ directory not found in repository"
    fi

    # Copy workflow-gates.json
    if [ -f "$TEMP_DIR/workflow-gates.json" ]; then
        print_info "Installing workflow-gates.json..."
        cp "$TEMP_DIR/workflow-gates.json" "$TARGET_DIR/.claude/"
        print_success "workflow-gates.json installed"
    else
        print_warning "workflow-gates.json not found in repository"
    fi

    # Copy agents
    if [ -d "$TEMP_DIR/agents" ]; then
        print_info "Installing Sub-agents (8개)..."
        cp -r "$TEMP_DIR/agents" "$TARGET_DIR/.claude/"
        print_success "Sub-agents installed (smart-committer, code-reviewer, quick-fixer 등)"
    else
        print_warning "agents/ directory not found in repository"
    fi

    # Copy skills
    if [ -d "$TEMP_DIR/skills" ]; then
        print_info "Installing Skills (8개)..."
        cp -r "$TEMP_DIR/skills" "$TARGET_DIR/.claude/"
        print_success "Skills installed (commit-guard, bug-fix-pattern, api-integration 등)"
    else
        print_warning "skills/ directory not found in repository"
    fi

    # Copy documentation
    if [ -d "$TEMP_DIR/docs" ]; then
        print_info "Installing Documentation..."
        cp -r "$TEMP_DIR/docs" "$TARGET_DIR/.claude/"
        print_success "Documentation installed (SUB-AGENTS-GUIDE, SKILLS-GUIDE 등)"
    else
        print_warning "docs/ directory not found in repository"
    fi

    # Create .specify directory structure (optional, created by /start command)
    print_info "Creating .specify directory structure..."
    mkdir -p "$TARGET_DIR/.specify/memory"
    mkdir -p "$TARGET_DIR/.specify/templates"
    mkdir -p "$TARGET_DIR/.specify/scripts/bash"
    mkdir -p "$TARGET_DIR/.specify/steering"
    mkdir -p "$TARGET_DIR/.specify/specs"

    # Copy .specify templates
    if [ -d "$TEMP_DIR/.specify/templates" ]; then
        print_info "Installing .specify templates..."
        cp -r "$TEMP_DIR/.specify/templates/"* "$TARGET_DIR/.specify/templates/" 2>/dev/null || true
        print_success ".specify templates installed"
    fi

    # Copy constitution template
    if [ -f "$TEMP_DIR/.specify/memory/constitution.md" ]; then
        cp "$TEMP_DIR/.specify/memory/constitution.md" "$TARGET_DIR/.specify/memory/"
        print_success "Constitution template installed"
    fi

    echo ""
    print_success "Installation complete!"
    echo ""

    # Print summary
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Installed Components:${NC}"
    echo ""
    echo "📁 $TARGET_DIR/.claude/"
    echo "   ├── commands/        (12 Slash Commands)"
    echo "   ├── templates/       (문서 템플릿)"
    echo "   ├── agents/          (8 Sub-agents)"
    echo "   ├── skills/          (8 Skills)"
    echo "   ├── docs/            (가이드 문서)"
    echo "   └── workflow-gates.json"
    echo ""
    echo "📁 $TARGET_DIR/.specify/"
    echo "   ├── memory/          (constitution.md)"
    echo "   ├── templates/       (spec, plan, tasks)"
    echo "   ├── scripts/bash/"
    echo "   ├── steering/"
    echo "   └── specs/"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Print next steps
    echo -e "${GREEN}Next Steps:${NC}"
    echo ""
    echo "1. 프로젝트 초기 설정:"
    echo "   /start              # Constitution 생성 및 .specify/ 구조 완성"
    echo ""
    echo "2. 자동 워크플로 선택 (🆕):"
    echo "   /triage [작업 설명]         # AI가 최적 워크플로 자동 선택"
    echo ""
    echo "3. 워크플로 명령어:"
    echo "   /major [feature-name]        # 신규 기능 (통합 워크플로)"
    echo "   /minor [feature-or-issue]    # 버그 수정, 기능 개선"
    echo "   /micro [description]         # 빠른 수정"
    echo ""
    echo "4. Git 자동화 (🆕):"
    echo "   /commit             # Conventional Commits 자동 생성"
    echo "   /pr-review [PR#]    # GitHub PR 자동 리뷰"
    echo ""
    echo "5. 단계별 실행 (Major):"
    echo "   /major-specify [feature-name]"
    echo "   /major-clarify [feature-number]"
    echo "   /major-plan [feature-number]"
    echo "   /major-tasks [feature-number]"
    echo "   /major-implement [feature-number]"
    echo ""
    echo "6. Sub-agents 및 Skills는 자동으로 활성화됩니다"
    echo ""
    echo "7. 자세한 사용법:"
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
