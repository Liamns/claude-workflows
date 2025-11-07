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

# Version Configuration
INSTALLER_VERSION="2.5.0"
TARGET_VERSION="2.5.0"

# Repository Configuration
REPO_URL="https://github.com/Liamns/claude-workflows"
REPO_BRANCH="main"

# Installation Configuration
TARGET_DIR=""
TEMP_DIR=""
BACKUP_DIR=""
EXISTING_VERSION=""
NEEDS_MIGRATION=false
DRY_RUN=false
FORCE_INSTALL=false
LOG_FILE=""

# Functions
# Logging function
log_to_file() {
    if [ -n "$LOG_FILE" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    fi
}

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Claude Code Workflows Installer     ║${NC}"
    echo -e "${BLUE}║   Version ${INSTALLER_VERSION}                        ║${NC}"
    echo -e "${BLUE}║   Real-time Metrics Dashboard         ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
    log_to_file "SUCCESS: $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    log_to_file "ERROR: $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
    log_to_file "INFO: $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    log_to_file "WARNING: $1"
}

cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Trap cleanup on exit
trap cleanup EXIT

# Validate and normalize target directory
validate_target_dir() {
    local dir="$1"

    # Convert to absolute path
    if [[ ! "$dir" = /* ]]; then
        dir="$(cd "$dir" 2>/dev/null && pwd)" || {
            print_error "Cannot access directory: $dir"
            exit 1
        }
    fi

    # Ensure directory exists
    if [ ! -d "$dir" ]; then
        print_error "Target directory does not exist: $dir"
        exit 1
    fi

    # Check write permissions
    if [ ! -w "$dir" ]; then
        print_error "No write permission for directory: $dir"
        exit 1
    fi

    # Prevent installation in system directories
    case "$dir" in
        /|/bin|/sbin|/usr|/usr/bin|/usr/sbin|/etc|/boot|/sys|/proc|/dev)
            print_error "Cannot install to system directory: $dir"
            exit 1
            ;;
    esac

    echo "$dir"
}

# Create safe temp directory
create_temp_dir() {
    local temp_dir
    temp_dir=$(mktemp -d 2>/dev/null) || {
        print_error "Failed to create temporary directory"
        exit 1
    }

    if [ ! -d "$temp_dir" ]; then
        print_error "Temporary directory creation failed"
        exit 1
    fi

    echo "$temp_dir"
}

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
    local target_version="$TARGET_VERSION"

    print_info "========================================="
    print_info "  Migration Required"
    print_info "  Current: $current_version → Target: $target_version"
    print_info "========================================="
    echo ""

    # v1.0.x → v2.4.0
    if [[ "$current_version" =~ ^1\. ]] || [ -f "$TARGET_DIR/.claude/commands/major-specify.md" ]; then
        print_info "Running v1.0 → v2.4.0 migration..."
        if [ -f "$TARGET_DIR/.claude/lib/migrate-v1-to-v2.sh" ]; then
            if bash "$TARGET_DIR/.claude/lib/migrate-v1-to-v2.sh"; then
                print_success "v1.0 → v2.4.0 migration completed"
            else
                print_error "v1.0 → v2.4.0 migration failed"
                return 1
            fi
        else
            print_warning "Migration script not found, will be installed with new files"
        fi
        echo ""
    fi

    # v2.4.x → v2.5.0
    if [[ "$current_version" =~ ^2\.4\. ]] || [ -f "$TARGET_DIR/.claude/agents/implementer-unified.md" ]; then
        print_info "Running v2.4 → v2.5.0 migration..."
        if [ -f "$TARGET_DIR/.claude/lib/migrate-v2-to-v25.sh" ]; then
            if bash "$TARGET_DIR/.claude/lib/migrate-v2-to-v25.sh"; then
                print_success "v2.4 → v2.5.0 migration completed"
            else
                print_error "v2.4 → v2.5.0 migration failed"
                return 1
            fi
        else
            print_warning "Migration script not found, will be installed with new files"
        fi
        echo ""
    fi

    return 0
}

# Verify installation
verify_installation() {
    local errors=0

    print_info "Verifying installation..."
    echo ""

    # Check critical files
    local critical_files=(
        ".claude/workflow-gates.json"
        ".claude/commands/major.md"
        ".claude/commands/triage.md"
        ".claude/lib/cache-helper.sh"
        ".claude/lib/metrics-collector.sh"
    )

    for file in "${critical_files[@]}"; do
        if [ -f "$TARGET_DIR/$file" ]; then
            print_success "✓ $file"
        else
            print_error "✗ $file (MISSING)"
            ((errors++))
        fi
    done

    echo ""

    # Check directories
    local critical_dirs=(
        ".claude/commands"
        ".claude/agents"
        ".claude/skills"
        ".claude/lib"
        ".claude/cache"
    )

    for dir in "${critical_dirs[@]}"; do
        if [ -d "$TARGET_DIR/$dir" ]; then
            local file_count=$(find "$TARGET_DIR/$dir" -type f 2>/dev/null | wc -l | tr -d ' ')
            print_success "✓ $dir/ ($file_count files)"
        else
            print_error "✗ $dir/ (MISSING)"
            ((errors++))
        fi
    done

    echo ""

    if [ $errors -eq 0 ]; then
        print_success "Installation verification passed!"
        log_to_file "Installation verification: PASSED"
        return 0
    else
        print_error "Installation verification failed with $errors errors"
        log_to_file "Installation verification: FAILED ($errors errors)"
        return 1
    fi
}

# Main installation
install_workflows() {
    print_header

    # Setup logging
    if [ -z "$LOG_FILE" ]; then
        mkdir -p "$TARGET_DIR/.claude/.backup"
        LOG_FILE="$TARGET_DIR/.claude/.backup/install-$(date +%Y%m%d-%H%M%S).log"
        log_to_file "Installation started"
        log_to_file "Installer version: $INSTALLER_VERSION"
        log_to_file "Target version: $TARGET_VERSION"
    fi

    print_info "Target directory: $TARGET_DIR"
    print_info "Log file: $LOG_FILE"
    print_info "Installing workflows..."
    echo ""

    # Detect existing installation
    EXISTING_VERSION=$(detect_installation)

    if [ "$EXISTING_VERSION" != "none" ]; then
        print_warning "Existing installation detected: v$EXISTING_VERSION"

        # Create backup
        BACKUP_DIR=$(create_backup)
        echo ""

        # Compare versions
        VERSION_COMPARISON=$(version_compare "$EXISTING_VERSION" "$TARGET_VERSION")

        if [ "$VERSION_COMPARISON" = "less" ]; then
            print_info "Upgrade detected: v$EXISTING_VERSION → v$TARGET_VERSION"
            print_info "Migration scripts will run after file installation"
            NEEDS_MIGRATION=true
        elif [ "$VERSION_COMPARISON" = "equal" ]; then
            print_warning "Same version detected: v$EXISTING_VERSION"

            # Ask for confirmation if not forced
            if [ "$FORCE_INSTALL" = false ]; then
                echo ""
                print_warning "This will reinstall the same version."
                echo -n "Do you want to continue? (y/N): "
                read -r response
                case "$response" in
                    [yY][eE][sS]|[yY])
                        print_info "Reinstalling..."
                        ;;
                    *)
                        print_info "Installation cancelled by user"
                        exit 0
                        ;;
                esac
            else
                print_warning "Reinstalling (forced)..."
            fi
        else
            print_warning "Downgrade detected: v$EXISTING_VERSION → v$TARGET_VERSION"
            print_error "Downgrade is not supported and may cause issues."

            if [ "$FORCE_INSTALL" = false ]; then
                echo -n "Are you sure you want to continue? (y/N): "
                read -r response
                case "$response" in
                    [yY][eE][sS]|[yY])
                        print_warning "Proceeding with downgrade..."
                        ;;
                    *)
                        print_info "Installation cancelled by user"
                        exit 0
                        ;;
                esac
            fi
        fi
        echo ""
    else
        print_info "Fresh installation - no existing version detected"
        echo ""
    fi

    # Clone repository to temp directory
    print_info "Downloading workflows from GitHub..."
    print_info "Repository: $REPO_URL"
    print_info "Branch: $REPO_BRANCH"

    # Clone with progress
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would clone: git clone --branch $REPO_BRANCH --depth 1 $REPO_URL"
        print_success "[DRY RUN] Download simulated"
    else
        local git_output
        git_output=$(git clone --branch "$REPO_BRANCH" --depth 1 "$REPO_URL" "$TEMP_DIR" 2>&1)
        local git_status=$?

        if [ $git_status -eq 0 ]; then
            print_success "Downloaded successfully"
        else
            print_error "Failed to download from GitHub"
            echo ""
            print_error "Git error output:"
            echo "$git_output"
            echo ""
            print_info "Please check:"
            print_info "  - Internet connection"
            print_info "  - Repository URL: $REPO_URL"
            print_info "  - Git is installed: $(command -v git || echo 'NOT FOUND')"
            exit 1
        fi
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
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$TARGET_DIR/.claude/commands"
        mkdir -p "$TARGET_DIR/.claude/config"
        mkdir -p "$TARGET_DIR/.claude/templates"
        mkdir -p "$TARGET_DIR/.claude/cache/metrics"
        mkdir -p "$TARGET_DIR/.claude/cache/workflow-history"
    fi
    print_success ".claude directory ready"

    # Copy slash commands (excluding deprecated and backup)
    if [ -d "$TEMP_DIR/.claude/commands" ]; then
        print_info "Installing Slash Commands (9개)..."
        if [ "$DRY_RUN" = false ]; then
            # Copy files, excluding deprecated and backup directories
            find "$TEMP_DIR/.claude/commands" -maxdepth 1 -type f -name "*.md" -exec cp {} "$TARGET_DIR/.claude/commands/" \;
        fi
        print_success "Slash Commands installed (start, triage, major, minor, micro, commit, pr-review, review, dashboard)"
    else
        print_warning ".claude/commands/ directory not found in repository"
    fi

    # Copy templates (excluding deprecated and backup)
    if [ -d "$TEMP_DIR/.claude/templates" ]; then
        print_info "Installing Templates..."
        if [ "$DRY_RUN" = false ]; then
            # Copy all files and subdirectories
            cp -r "$TEMP_DIR/.claude/templates/"* "$TARGET_DIR/.claude/templates/" 2>/dev/null || true
            # Remove deprecated and backup directories if they exist
            rm -rf "$TARGET_DIR/.claude/templates/deprecated" "$TARGET_DIR/.claude/templates/.backup" 2>/dev/null || true
        fi
        print_success "Templates installed"
    else
        print_warning ".claude/templates/ directory not found in repository"
    fi

    # Copy workflow-gates.json
    if [ -f "$TEMP_DIR/workflow-gates.json" ]; then
        print_info "Installing workflow-gates.json..."
        if [ "$DRY_RUN" = false ]; then
            cp "$TEMP_DIR/workflow-gates.json" "$TARGET_DIR/.claude/"
        fi
        print_success "workflow-gates.json installed (with model optimization)"
    else
        print_warning "workflow-gates.json not found in repository"
    fi

    # Copy agents (excluding deprecated and backup)
    if [ -d "$TEMP_DIR/.claude/agents" ]; then
        print_info "Installing Unified Agents (6개)..."
        if [ "$DRY_RUN" = false ]; then
            cp -r "$TEMP_DIR/.claude/agents" "$TARGET_DIR/.claude/"
            # Remove deprecated and backup directories if they exist
            rm -rf "$TARGET_DIR/.claude/agents/deprecated" "$TARGET_DIR/.claude/agents/.backup" 2>/dev/null || true
        fi
        print_success "Unified agents installed (architect-unified, reviewer-unified, implementer-unified, documenter-unified 등)"
    else
        print_warning "agents/ directory not found in repository"
    fi

    # Copy skills (excluding deprecated and backup)
    if [ -d "$TEMP_DIR/.claude/skills" ]; then
        print_info "Installing Skills (15개)..."
        if [ "$DRY_RUN" = false ]; then
            cp -r "$TEMP_DIR/.claude/skills" "$TARGET_DIR/.claude/"
            # Remove deprecated and backup directories if they exist
            rm -rf "$TARGET_DIR/.claude/skills/deprecated" "$TARGET_DIR/.claude/skills/.backup" 2>/dev/null || true
        fi
        print_success "Skills installed (bug-fix-pattern, api-integration, form-validation, platform-detection 등)"
    else
        print_warning "skills/ directory not found in repository"
    fi

    # Copy lib (helper scripts, excluding deprecated and backup)
    if [ -d "$TEMP_DIR/.claude/lib" ]; then
        print_info "Installing Library Scripts..."
        if [ "$DRY_RUN" = false ]; then
            cp -r "$TEMP_DIR/.claude/lib" "$TARGET_DIR/.claude/"
            # Remove deprecated and backup directories if they exist
            rm -rf "$TARGET_DIR/.claude/lib/deprecated" "$TARGET_DIR/.claude/lib/.backup" 2>/dev/null || true
            chmod +x "$TARGET_DIR/.claude/lib/"*.sh 2>/dev/null || true
        fi
        print_success "Library scripts installed (cache-helper, metrics-collector, dashboard-generator, git-stats-helper)"
    else
        print_warning "lib/ directory not found in repository"
    fi

    # Copy documentation (excluding deprecated and backup)
    if [ -d "$TEMP_DIR/docs" ]; then
        print_info "Installing Documentation..."
        if [ "$DRY_RUN" = false ]; then
            cp -r "$TEMP_DIR/docs" "$TARGET_DIR/.claude/"
            # Remove deprecated and backup directories if they exist
            rm -rf "$TARGET_DIR/.claude/docs/deprecated" "$TARGET_DIR/.claude/docs/.backup" 2>/dev/null || true
        fi
        print_success "Documentation installed (SUB-AGENTS-GUIDE, SKILLS-GUIDE, MODEL-OPTIMIZATION-GUIDE 등)"
    else
        print_warning "docs/ directory not found in repository"
    fi

    # Copy architectures system (v2.2.0, excluding deprecated and backup)
    if [ -d "$TEMP_DIR/architectures" ]; then
        print_info "Installing Multi-Architecture Support System..."
        if [ "$DRY_RUN" = false ]; then
            cp -r "$TEMP_DIR/architectures" "$TARGET_DIR/.claude/"
            # Remove deprecated and backup directories if they exist
            rm -rf "$TARGET_DIR/.claude/architectures/deprecated" "$TARGET_DIR/.claude/architectures/.backup" 2>/dev/null || true
        fi
        print_success "Architecture system installed (FSD, Atomic, Clean, Hexagonal, DDD 등)"
    else
        print_warning "architectures/ directory not found in repository"
    fi

    # Copy model optimization configs (v2.2.0, excluding deprecated and backup)
    if [ -d "$TEMP_DIR/.claude/config" ]; then
        print_info "Installing Model Optimization Configs..."
        if [ "$DRY_RUN" = false ]; then
            # Copy all files and subdirectories
            cp -r "$TEMP_DIR/.claude/config/"* "$TARGET_DIR/.claude/config/" 2>/dev/null || true
            # Remove deprecated and backup directories if they exist
            rm -rf "$TARGET_DIR/.claude/config/deprecated" "$TARGET_DIR/.claude/config/.backup" 2>/dev/null || true
        fi
        print_success "Model configs installed (model-router.yaml, user-preferences.yaml)"
    else
        print_warning ".claude/config/ directory not found in repository"
    fi

    # Create .specify directory structure (optional, created by /start command)
    print_info "Creating .specify directory structure..."
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$TARGET_DIR/.specify/memory"
        mkdir -p "$TARGET_DIR/.specify/templates"
        mkdir -p "$TARGET_DIR/.specify/scripts/bash"
        mkdir -p "$TARGET_DIR/.specify/steering"
        mkdir -p "$TARGET_DIR/.specify/specs"
    fi

    # Copy .specify templates (excluding deprecated and backup)
    if [ -d "$TEMP_DIR/.specify/templates" ]; then
        print_info "Installing .specify templates..."
        if [ "$DRY_RUN" = false ]; then
            cp -r "$TEMP_DIR/.specify/templates/"* "$TARGET_DIR/.specify/templates/" 2>/dev/null || true
            # Remove deprecated and backup directories if they exist
            rm -rf "$TARGET_DIR/.specify/templates/deprecated" "$TARGET_DIR/.specify/templates/.backup" 2>/dev/null || true
        fi
        print_success ".specify templates installed"
    fi

    # Copy constitution template
    if [ -f "$TEMP_DIR/.specify/memory/constitution.md" ]; then
        if [ "$DRY_RUN" = false ]; then
            cp "$TEMP_DIR/.specify/memory/constitution.md" "$TARGET_DIR/.specify/memory/"
        fi
        print_success "Constitution template installed"
    fi

    # Final cleanup: Remove any deprecated or backup directories from root levels
    print_info "Cleaning up deprecated and backup directories..."
    if [ "$DRY_RUN" = false ]; then
        rm -rf "$TARGET_DIR/.claude/deprecated" "$TARGET_DIR/.specify/deprecated" 2>/dev/null || true
    fi
    # Note: Keep .claude/.backup as it's created by this installer for user backups
    print_success "Cleanup complete"

    echo ""
    print_success "File installation complete!"
    echo ""

    # Run migrations if needed
    if [ "$NEEDS_MIGRATION" = true ] && [ "$EXISTING_VERSION" != "none" ]; then
        if ! run_migrations "$EXISTING_VERSION"; then
            print_error "Migration failed. Installation may be incomplete."
            log_to_file "Migration failed"
            echo ""
            print_warning "You can find the backup at: $BACKUP_DIR"
            print_info "You may need to restore manually or reinstall."
            exit 1
        fi
    fi

    # Verify installation
    echo ""
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Installation verification skipped"
    else
        if ! verify_installation; then
            print_warning "Installation completed with errors"
            print_info "Please check the log file: $LOG_FILE"
            if [ -n "$BACKUP_DIR" ]; then
                print_info "Backup location: $BACKUP_DIR"
            fi
            exit 1
        fi
    fi

    # Print summary
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Installed Components (v$TARGET_VERSION):${NC}"
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
    echo "Claude Code Workflows Installer v$INSTALLER_VERSION"
    echo ""
    echo "Usage: $0 [OPTIONS] [target_directory]"
    echo ""
    echo "Options:"
    echo "  -h, --help        Show this help message"
    echo "  -v, --version     Show installer version"
    echo "  --dry-run         Simulate installation without making changes"
    echo "  --force           Skip confirmation prompts"
    echo "  --branch BRANCH   Install from specific branch (default: main)"
    echo ""
    echo "Examples:"
    echo "  $0                        # Install to current directory"
    echo "  $0 /path/to/project       # Install to specific directory"
    echo "  $0 --dry-run .            # Simulate installation"
    echo "  $0 --force .              # Force install without prompts"
    echo "  $0 --branch dev .         # Install from dev branch"
    echo ""
    echo "Remote installation:"
    echo "  curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash"
    echo "  curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash -s -- --force"
}

# Show version
show_version() {
    echo "Claude Code Workflows Installer"
    echo "Version: $INSTALLER_VERSION"
    echo "Target Version: $TARGET_VERSION"
    echo "Repository: $REPO_URL"
}

# Parse arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force)
                FORCE_INSTALL=true
                shift
                ;;
            --branch)
                if [ -z "$2" ]; then
                    echo "Error: --branch requires a branch name"
                    exit 1
                fi
                REPO_BRANCH="$2"
                shift 2
                ;;
            -*)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                # This is the target directory
                TARGET_DIR="$1"
                shift
                ;;
        esac
    done

    # Set default target directory if not specified
    if [ -z "$TARGET_DIR" ]; then
        TARGET_DIR="."
    fi

    # Validate and normalize target directory
    TARGET_DIR=$(validate_target_dir "$TARGET_DIR")

    # Create temp directory
    TEMP_DIR=$(create_temp_dir)

    # Display parsed options if dry-run
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY RUN MODE]${NC}"
        echo "Target Directory: $TARGET_DIR"
        echo "Repository Branch: $REPO_BRANCH"
        echo "Force Install: $FORCE_INSTALL"
        echo ""
    fi
}

# Parse command line arguments
parse_arguments "$@"

# Run installation
install_workflows

# Final summary
echo ""
if [ -n "$BACKUP_DIR" ]; then
    print_info "Backup location: $BACKUP_DIR"
fi
print_info "Installation log: $LOG_FILE"
echo ""
log_to_file "Installation completed successfully"
print_success "Installation completed successfully!"
