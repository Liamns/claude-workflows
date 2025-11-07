#!/bin/bash

# Claude Code Workflows Installer
# Version: 2.5.0 - Real-time Metrics Dashboard

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
    echo -e "${BLUE}║   Version 2.5.0                        ║${NC}"
    echo -e "${BLUE}║   Real-time Metrics Dashboard         ║${NC}"
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

# Detect existing installation and version
detect_installation() {
    if [ -f "$TARGET_DIR/.claude/workflow-gates.json" ]; then
        # Extract version using grep (compatible with systems without jq)
        local version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$TARGET_DIR/.claude/workflow-gates.json" | cut -d'"' -f4)
        echo "$version"
    else
        echo "none"
    fi
}

# Compare semantic versions
version_compare() {
    local ver1=$1
    local ver2=$2

    if [ "$ver1" = "$ver2" ]; then
        echo "equal"
        return
    fi

    # Simple version comparison (assumes semantic versioning)
    local IFS=.
    local i ver1_arr=($ver1) ver2_arr=($ver2)

    for ((i=0; i<${#ver1_arr[@]}; i++)); do
        if [[ -z ${ver2_arr[i]} ]]; then
            echo "greater"
            return
        fi
        if ((10#${ver1_arr[i]} > 10#${ver2_arr[i]})); then
            echo "greater"
            return
        fi
        if ((10#${ver1_arr[i]} < 10#${ver2_arr[i]})); then
            echo "less"
            return
        fi
    done
    echo "equal"
}

# Create backup of existing installation
create_backup() {
    local backup_dir="$TARGET_DIR/.claude/.backup/install-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"

    print_info "Creating backup at: $backup_dir"

    # Backup critical files
    if [ -f "$TARGET_DIR/.claude/workflow-gates.json" ]; then
        cp "$TARGET_DIR/.claude/workflow-gates.json" "$backup_dir/"
    fi
    if [ -d "$TARGET_DIR/.claude/config" ]; then
        cp -r "$TARGET_DIR/.claude/config" "$backup_dir/" 2>/dev/null || true
    fi
    if [ -d "$TARGET_DIR/.claude/cache" ]; then
        cp -r "$TARGET_DIR/.claude/cache" "$backup_dir/" 2>/dev/null || true
    fi

    print_success "Backup created"
    echo "$backup_dir"
}

# Run migration scripts based on detected version
run_migrations() {
    local current_version=$1
    local target_version="2.5.0"

    print_info "========================================="
    print_info "  Migration Required"
    print_info "  Current: $current_version → Target: $target_version"
    print_info "========================================="
    echo ""

    # v1.0.x → v2.4.0
    if [[ "$current_version" =~ ^1\. ]] || [ -f "$TARGET_DIR/.claude/commands/major-specify.md" ]; then
        print_info "Running v1.0 → v2.4.0 migration..."
        if [ -f "$TARGET_DIR/.claude/lib/migrate-v1-to-v2.sh" ]; then
            bash "$TARGET_DIR/.claude/lib/migrate-v1-to-v2.sh"
            print_success "v1.0 → v2.4.0 migration completed"
        else
            print_warning "Migration script not found, will be installed with new files"
        fi
        echo ""
    fi

    # v2.4.x → v2.5.0
    if [[ "$current_version" =~ ^2\.4\. ]] || [ -f "$TARGET_DIR/.claude/agents/implementer-unified.md" ]; then
        print_info "Running v2.4 → v2.5.0 migration..."
        if [ -f "$TARGET_DIR/.claude/lib/migrate-v2-to-v25.sh" ]; then
            bash "$TARGET_DIR/.claude/lib/migrate-v2-to-v25.sh"
            print_success "v2.4 → v2.5.0 migration completed"
        else
            print_warning "Migration script not found, will be installed with new files"
        fi
        echo ""
    fi
}

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

    # Detect existing installation
    EXISTING_VERSION=$(detect_installation)

    if [ "$EXISTING_VERSION" != "none" ]; then
        print_warning "Existing installation detected: v$EXISTING_VERSION"

        # Create backup
        BACKUP_DIR=$(create_backup)
        echo ""

        # Compare versions
        VERSION_COMPARISON=$(version_compare "$EXISTING_VERSION" "2.5.0")

        if [ "$VERSION_COMPARISON" = "less" ]; then
            print_info "Upgrade detected: v$EXISTING_VERSION → v2.5.0"
            print_info "Migration scripts will run after file installation"
            NEEDS_MIGRATION=true
        elif [ "$VERSION_COMPARISON" = "equal" ]; then
            print_warning "Same version detected. Reinstalling..."
        else
            print_warning "Downgrade detected. This is not recommended."
        fi
        echo ""
    else
        print_info "Fresh installation - no existing version detected"
        NEEDS_MIGRATION=false
        echo ""
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

    # Check dependencies
    print_info "Checking dependencies..."

    # Check for jq (optional but recommended for metrics dashboard)
    if ! command -v jq &> /dev/null; then
        print_warning "jq not found - Metrics dashboard will have limited functionality"
        print_info "Install jq for full metrics support:"
        print_info "  macOS: brew install jq"
        print_info "  Ubuntu/Debian: sudo apt-get install jq"
        print_info "  CentOS/RHEL: sudo yum install jq"
    else
        print_success "jq found - Full metrics support enabled"
    fi

    # Create .claude directory structure
    print_info "Creating .claude directory structure..."
    mkdir -p "$TARGET_DIR/.claude/commands"
    mkdir -p "$TARGET_DIR/.claude/config"
    mkdir -p "$TARGET_DIR/.claude/templates"
    mkdir -p "$TARGET_DIR/.claude/cache/metrics"
    mkdir -p "$TARGET_DIR/.claude/cache/workflow-history"
    print_success ".claude directory ready"

    # Copy slash commands
    if [ -d "$TEMP_DIR/.claude/commands" ]; then
        print_info "Installing Slash Commands (10개)..."
        cp -r "$TEMP_DIR/.claude/commands/"* "$TARGET_DIR/.claude/commands/" 2>/dev/null || true
        print_success "Slash Commands installed (triage, major, minor, micro, test, commit, pr-review, review 등)"
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
        print_success "workflow-gates.json installed (with model optimization)"
    else
        print_warning "workflow-gates.json not found in repository"
    fi

    # Copy agents
    if [ -d "$TEMP_DIR/.claude/agents" ]; then
        print_info "Installing Unified Agents (6개)..."
        cp -r "$TEMP_DIR/.claude/agents" "$TARGET_DIR/.claude/"
        print_success "Unified agents installed (architect-unified, reviewer-unified, implementer-unified, documenter-unified 등)"
    else
        print_warning "agents/ directory not found in repository"
    fi

    # Copy skills
    if [ -d "$TEMP_DIR/.claude/skills" ]; then
        print_info "Installing Skills (13개)..."
        cp -r "$TEMP_DIR/.claude/skills" "$TARGET_DIR/.claude/"
        print_success "Skills installed (bug-fix-pattern, api-integration, form-validation, platform-detection 등)"
    else
        print_warning "skills/ directory not found in repository"
    fi

    # Copy lib (helper scripts)
    if [ -d "$TEMP_DIR/.claude/lib" ]; then
        print_info "Installing Library Scripts..."
        cp -r "$TEMP_DIR/.claude/lib" "$TARGET_DIR/.claude/"
        chmod +x "$TARGET_DIR/.claude/lib/"*.sh 2>/dev/null || true
        print_success "Library scripts installed (cache-helper, metrics-collector, dashboard-generator, git-stats-helper)"
    else
        print_warning "lib/ directory not found in repository"
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
    print_success "File installation complete!"
    echo ""

    # Run migrations if needed
    if [ "$NEEDS_MIGRATION" = true ] && [ "$EXISTING_VERSION" != "none" ]; then
        run_migrations "$EXISTING_VERSION"
    fi

    # Print summary
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Installed Components (v2.5.0):${NC}"
    echo ""
    echo "📁 $TARGET_DIR/.claude/"
    echo "   ├── commands/        (11 Slash Commands + /dashboard)"
    echo "   ├── templates/       (문서 템플릿)"
    echo "   ├── agents/          (6 Unified Agents - 통합 최적화)"
    echo "   ├── skills/          (13 Skills - 자동 활성화)"
    echo "   ├── lib/             (Helper Scripts)"
    echo "   │   ├── cache-helper.sh"
    echo "   │   ├── metrics-collector.sh"
    echo "   │   ├── dashboard-generator.sh"
    echo "   │   └── git-stats-helper.sh"
    echo "   ├── cache/           (Metrics & Cache Data)"
    echo "   │   ├── metrics/"
    echo "   │   └── workflow-history/"
    echo "   ├── docs/            (PROJECT-CONTEXT, 가이드 문서)"
    echo "   ├── architectures/   (Multi-Architecture Support)"
    echo "   │   ├── frontend/    (FSD, Atomic Design)"
    echo "   │   ├── backend/     (Clean, Hexagonal, DDD)"
    echo "   │   └── fullstack/   (Monorepo, JAMstack)"
    echo "   ├── config/          (Model & User Preferences)"
    echo "   │   ├── model-router.yaml"
    echo "   │   └── user-preferences.yaml"
    echo "   └── workflow-gates.json (Model Optimization 포함)"
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
    echo "2. 자동 워크플로 선택:"
    echo "   /triage [작업 설명]         # 최적 워크플로 + 모델 자동 선택"
    echo ""
    echo "3. 테스트 자동화 (🆕 v2.4):"
    echo "   /test                        # 테스트 요구사항 분석 및 자동 생성"
    echo ""
    echo "4. 코드 리뷰:"
    echo "   /review [target]             # 종합 코드 리뷰"
    echo "   /review --staged             # 스테이징 변경사항 리뷰"
    echo "   /review --diff HEAD~1        # Git diff 리뷰"
    echo "   /review [target] --adv       # 심층 분석 모드"
    echo ""
    echo "5. 워크플로 명령어 (🆕 통합 Major):"
    echo "   /major                       # 통합 Major 워크플로 (2개 질문만)"
    echo "   /minor [feature-or-issue]    # 버그 수정 워크플로"
    echo "   /micro [description]         # 간단한 변경"
    echo ""
    echo "6. Git 자동화:"
    echo "   /commit             # Conventional Commits 자동 생성"
    echo "   /pr-review [PR#]    # GitHub PR 자동 리뷰"
    echo ""
    echo "7. 📊 실시간 메트릭스 대시보드 (🆕 v2.5):"
    echo "   /dashboard          # 현재 세션 메트릭"
    echo "   /dashboard --today  # 오늘의 통계"
    echo "   /dashboard --summary # 전체 누적 통계"
    echo ""
    echo "8. 모델 옵션:"
    echo "   --model=opus        # 특정 모델 강제 사용"
    echo "   --use-context7      # Context7 강제 활성화"
    echo "   --optimize-cost     # 비용 최적화 우선"
    echo ""
    echo "8. 아키텍처 관련:"
    echo "   /architecture-info  # 현재 아키텍처 정보"
    echo "   /architecture-switch # 아키텍처 변경"
    echo ""
    echo "9. Agents 및 Skills:"
    echo "   - 6개 통합 에이전트 자동 활성화"
    echo "   - 13개 스킬 자동 적용"
    echo "   - 워크플로우별 최적화 적용"
    echo ""
    echo "10. 자세한 사용법:"
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
