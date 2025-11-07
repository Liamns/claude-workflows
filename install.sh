#!/bin/bash

# Claude Code Workflows Installer
# Version: 2.3.0 - Code Review System, Multi-Architecture & Model Optimization

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
    echo -e "${BLUE}║   Version 2.3.0                        ║${NC}"
    echo -e "${BLUE}║   Code Review + Multi-Architecture    ║${NC}"
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
    mkdir -p "$TARGET_DIR/.claude/config"
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

    # Copy workflow-gates.json (v2 with model optimization)
    if [ -f "$TEMP_DIR/workflow-gates-v2.json" ]; then
        print_info "Installing workflow-gates-v2.json..."
        cp "$TEMP_DIR/workflow-gates-v2.json" "$TARGET_DIR/.claude/workflow-gates.json"
        print_success "workflow-gates.json installed (v2 with model optimization)"
    elif [ -f "$TEMP_DIR/workflow-gates.json" ]; then
        print_info "Installing workflow-gates.json..."
        cp "$TEMP_DIR/workflow-gates.json" "$TARGET_DIR/.claude/"
        print_success "workflow-gates.json installed"
    else
        print_warning "workflow-gates.json not found in repository"
    fi

    # Copy agents
    if [ -d "$TEMP_DIR/agents" ]; then
        print_info "Installing Sub-agents (10개)..."
        cp -r "$TEMP_DIR/agents" "$TARGET_DIR/.claude/"
        print_success "Sub-agents installed (code-reviewer, security-scanner, impact-analyzer 등)"
    else
        print_warning "agents/ directory not found in repository"
    fi

    # Copy skills
    if [ -d "$TEMP_DIR/skills" ]; then
        print_info "Installing Skills (13개)..."
        cp -r "$TEMP_DIR/skills" "$TARGET_DIR/.claude/"
        print_success "Skills installed (test-coverage-analyzer, code-metrics-collector, dependency-tracer 등)"
    else
        print_warning "skills/ directory not found in repository"
    fi

    # Copy documentation
    if [ -d "$TEMP_DIR/docs" ]; then
        print_info "Installing Documentation..."
        cp -r "$TEMP_DIR/docs" "$TARGET_DIR/.claude/"
        print_success "Documentation installed (SUB-AGENTS-GUIDE, SKILLS-GUIDE, MODEL-OPTIMIZATION-GUIDE 등)"
    else
        print_warning "docs/ directory not found in repository"
    fi

    # Copy architectures system (v2.2.0)
    if [ -d "$TEMP_DIR/architectures" ]; then
        print_info "Installing Multi-Architecture Support System..."
        cp -r "$TEMP_DIR/architectures" "$TARGET_DIR/.claude/"
        print_success "Architecture system installed (FSD, Atomic, Clean, Hexagonal, DDD 등)"
    else
        print_warning "architectures/ directory not found in repository"
    fi

    # Copy model optimization configs (v2.2.0)
    if [ -d "$TEMP_DIR/.claude/config" ]; then
        print_info "Installing Model Optimization Configs..."
        cp -r "$TEMP_DIR/.claude/config/"* "$TARGET_DIR/.claude/config/" 2>/dev/null || true
        print_success "Model configs installed (model-router.yaml, user-preferences.yaml)"
    else
        print_warning ".claude/config/ directory not found in repository"
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
    echo -e "${GREEN}Installed Components (v2.3.0):${NC}"
    echo ""
    echo "📁 $TARGET_DIR/.claude/"
    echo "   ├── commands/        (13 Slash Commands + /review)"
    echo "   ├── templates/       (문서 템플릿)"
    echo "   ├── agents/          (10 Sub-agents with Review System)"
    echo "   ├── skills/          (13 Skills with Analysis Tools)"
    echo "   ├── docs/            (가이드 문서 + Model Optimization Guide)"
    echo "   ├── architectures/   (🆕 Multi-Architecture Support)"
    echo "   │   ├── frontend/    (FSD, Atomic, MVC)"
    echo "   │   ├── backend/     (Clean, Hexagonal, DDD)"
    echo "   │   └── fullstack/   (Monorepo, JAMstack)"
    echo "   ├── config/          (🆕 Model & User Preferences)"
    echo "   │   ├── model-router.yaml"
    echo "   │   └── user-preferences.yaml"
    echo "   └── workflow-gates.json (v2 with Model Optimization)"
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
    echo "1. 프로젝트 초기 설정 (🆕 아키텍처 선택 포함):"
    echo "   /start              # Architecture 선택 및 Constitution 생성"
    echo ""
    echo "2. 자동 워크플로 선택 (🆕 모델 최적화 포함):"
    echo "   /triage [작업 설명]         # 최적 워크플로 + 모델 자동 선택"
    echo ""
    echo "3. 코드 리뷰 (🆕 v2.3):"
    echo "   /review [target]             # 종합 코드 리뷰"
    echo "   /review --staged             # 스테이징 변경사항 리뷰"
    echo "   /review --diff HEAD~1        # Git diff 리뷰"
    echo "   /review [target] --adv       # 심층 분석 모드"
    echo ""
    echo "4. 워크플로 명령어 (지능형 모델 스위칭):"
    echo "   /major [feature-name]        # Opus → Sonnet 자동 전환"
    echo "   /minor [feature-or-issue]    # Sonnet/Haiku 자동 선택"
    echo "   /micro [description]         # Haiku 우선 사용"
    echo ""
    echo "5. Git 자동화:"
    echo "   /commit             # Conventional Commits 자동 생성"
    echo "   /pr-review [PR#]    # GitHub PR 자동 리뷰"
    echo ""
    echo "6. 모델 옵션 (🆕):"
    echo "   --model=opus        # 특정 모델 강제 사용"
    echo "   --use-context7      # Context7 강제 활성화"
    echo "   --optimize-cost     # 비용 최적화 우선"
    echo ""
    echo "7. 아키텍처 관련:"
    echo "   /architecture-info  # 현재 아키텍처 정보"
    echo "   /architecture-switch # 아키텍처 변경"
    echo ""
    echo "8. Sub-agents 및 Skills:"
    echo "   - 자동으로 활성화됩니다"
    echo "   - Model Optimization 적용됨"
    echo "   - Context7 통합 (조건부)"
    echo ""
    echo "9. 자세한 사용법:"
    echo "   ${REPO_URL}#readme"
    echo "   .claude/docs/MODEL-OPTIMIZATION-GUIDE.md"
    echo "   .claude/docs/ARCHITECTURE-GUIDE.md"
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
