# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.6.0] - 2025-01-10

### Added 🆕
- **✅ 강화된 Validation 시스템** - 4가지 마이그레이션 시나리오 완전 검증
  - v1.0 → v2.6 마이그레이션 검증
  - v2.4 → v2.6 마이그레이션 검증
  - v2.5 → v2.6 마이그레이션 검증 (신규)
  - 신규 설치 시나리오 검증 (신규)
  - 롤백 시나리오 자동 테스트 (신규)
- **🔄 자동 롤백 기능** - 마이그레이션 실패 시 이전 상태로 안전하게 복구
  - `rollback_from_backup()` 함수 추가
  - Critical 파일 우선 복원 (workflow-gates.json, config/, cache/)
  - 마이그레이션 실패 시 자동 호출
- **📋 Pre-commit Hook 통합** - .claude/ 변경사항 자동 검증
  - `.claude/hooks/pre-commit` - Git 커밋 전 자동 validation
  - `.claude/hooks/install-hooks.sh` - Hook 설치 스크립트
  - Exit code 기반 커밋 차단/허용 (0=pass, 1=fail, 2=warning)
- **🔍 통합 Validation** - install.sh에 validation 자동 실행
  - 설치/업그레이드 완료 후 자동 validation
  - `--quiet` 모드로 빠른 검증
  - Validation 리포트 자동 생성

### Enhanced ✨
- **validate-migration.sh** - 마이그레이션 검증 강화
  - `validate_fresh_install()` - 신규 설치 시나리오 검증
  - `validate_rollback_scenario()` - 롤백 메커니즘 검증
  - 5개 시나리오 검증 (v1.0→v2.6, v2.4→v2.6, v2.5→v2.6, 신규 설치, 롤백)
- **install.sh** - 설치 프로세스 개선
  - 롤백 함수 통합
  - Validation 시스템 자동 실행
  - 더 명확한 에러 메시지와 복구 안내
- **Critical 파일 목록 확장** - validation 시스템 필수 파일 추가
  - `.claude/lib/validate-system.sh`
  - `.claude/hooks/pre-commit`

### Changed 🔄
- **버전 체계** - 2.5.0 → 2.6.0
  - `INSTALLER_VERSION` 및 `TARGET_VERSION` 업데이트
  - 모든 마이그레이션 스크립트 버전 업데이트
- **README.md** - v2.6.0 기능 반영
  - 새로운 기능 섹션 추가
  - Validation 시스템 사용법 상세 설명
  - 마이그레이션 시나리오 업데이트
- **commit.md** - Pre-commit hook 안내 추가
  - Hook 설치 방법
  - 동작 방식 설명
  - Validation 실패 시 대응 방법

### Documentation 📚
- **Validation 시스템 가이드** 추가 (README.md)
  - 자동 검증 명령어
  - Pre-commit hook 설정
  - Validation 리포트 위치 및 형식
- **마이그레이션 가이드** 업데이트
  - 4가지 시나리오 상세 설명
  - 자동 롤백 메커니즘 설명
  - 백업 및 복구 절차
- **커밋 워크플로우** 업데이트
  - Pre-commit validation 통합
  - Hook 관리 방법

### Fixed 🐛
- **마이그레이션 안정성** - 실패 시 자동 롤백으로 데이터 손실 방지
- **문서-코드 일관성** - Validation 시스템으로 문서 품질 자동 보장
- **설치 검증** - 모든 설치 시나리오에서 파일 무결성 검증

### Infrastructure 🏗️
- `.claude/hooks/` - Git hook 디렉토리
- `.claude/cache/validation-reports/` - Validation 리포트 저장소
- `.claude/.backup/` - 마이그레이션 백업 디렉토리

### Breaking Changes 💥
- **None** - v2.5.0과 완전히 호환됩니다

### Migration Guide 📖
```bash
# v2.5 → v2.6 자동 업그레이드 (권장)
bash install.sh

# Pre-commit hook 설치 (선택사항)
bash .claude/hooks/install-hooks.sh

# Validation 실행
bash .claude/lib/validate-system.sh
```

---

### Added 🆕 (from Unreleased)
- **/pr**: Git 변경사항을 분석하여 GitHub PR을 자동으로 생성하고 템플릿을 자동 완성
  - 커밋 히스토리 자동 분석 및 타입별 그룹화
  - Breaking changes 자동 감지
  - `.specify/*.md` 워크플로우 파일과 연동하여 PR body 자동 생성
  - 템플릿 자동 완성 (변경사항, 작업 내용, 테스트, 참고 자료 섹션)
  - `--dry-run`, `--draft`, `--review`, `--validate` 등 다양한 옵션 지원

### Fixed 🐛
- **Critical: All workflows now executable** - Fixed major issue where triage/major/minor/micro were description-only documents
- **triage.md** - Added Implementation section with actual tool calls (AskUserQuestion, Skill, SlashCommand)
- **micro.md** - Added Implementation section with work type detection, file search (Grep), modification (Edit), and validation (Bash)
- **minor.md** - Added Implementation section with 11 steps including questions, reusability checks, file operations, and testing
- **major.md** - Added comprehensive Implementation section with 14 steps generating 7 files (spec.md, plan.md, tasks.md, research.md, data-model.md, quickstart.md, contracts/openapi.yaml)
- **Consolidated workflow-gates.json** - Merged duplicate files from root and .claude/ directories
- **Organized backup files** - Moved all backup files to `.claude/.backup/v1-v2-migration/` directory
- **Updated documentation** - Added missing `/micro` command explanation in README.md
- **Fixed install.sh file counts** - Corrected command count (11→9) and skill count (13→15)
- **Removed non-existent /test command** - Cleaned up Next Steps section
- **Enhanced v1.0 detection** - Added root fallback for workflow-gates.json version detection

### Changed 🔄
- **Workflow execution model** - All workflows transformed from "descriptions" to "executable commands" with explicit tool calls
- **major.md question reduction** - Consolidated 10 questions into 2 AskUserQuestion blocks (3 essential + 6 optional multiselect)
- **File generation automation** - major workflow now auto-generates 7 specification/planning files
- **Inline branch creation** - Replaced create-new-feature.sh script with inline Bash commands in major.md
- workflow-gates.json location standardized to `.claude/` directory
- workflow-gates.json version updated to 2.5.0
- Backup files organized under `.claude/.backup/` for better project structure
- install.sh now shows complete lib/ and config/ file lists including migration scripts

## [2.5.0] - 2025-11-07

### Added 🆕
- **📊 Real-time Metrics Dashboard** (`/dashboard` command)
  - Live workflow performance monitoring
  - Token usage tracking with savings calculation
  - Performance metrics (execution time, cache hit rate, parallel processing)
  - Quality indicators (test coverage, type check, lint results)
  - Productivity tracking (tasks, bugs, features)
  - Git integration (commits, changes, branch status)
- **Metrics Collection System**
  - `git-stats-helper.sh` - Git statistics collector
  - `metrics-collector.sh` - Core metrics collection functions
  - `dashboard-generator.sh` - Terminal dashboard renderer with colors
  - JSON-based metrics storage (current session, daily, summary)
  - Three view modes: `--current`, `--today`, `--summary`

### Enhanced ✨
- Integrated metrics collection with cache-helper.sh
- Beautiful ASCII dashboard with colors and emojis
- Automatic Git statistics tracking
- Session-based metric persistence

### Infrastructure 🏗️
- `.claude/cache/metrics/` - Metrics data storage
- `.claude/cache/workflow-history/` - Workflow execution history
- Metrics JSON schemas for structured data

## [2.4.0] - 2025-11-07

### Added 🆕
- `/test` command - Smart test workflow with automated test generation and execution
- **Unified agents** - New consolidated agents for better performance:
  - `architect-unified` - All architecture pattern validation (FSD, Clean, Hexagonal, DDD, etc.)
  - `reviewer-unified` - Comprehensive code review (quality, security, performance, impact)
  - `implementer-unified` - TDD-based implementation and bug fixing
  - `documenter-unified` - Commit messages and changelog documentation

### Changed 🔄
- **Major workflow consolidation**: 6 commands → 1 unified `/major` command
- **Question reduction**: 10 questions → 2 essential questions only
- **State management**: Added automatic save/resume for Major workflow
- **Agent consolidation**: 11 agents → 6 agents (45% reduction)
- **Command reduction**: 16 commands → 10 commands (38% reduction)
- **README optimization**: 395 lines → 104 lines (74% reduction)

### Removed 🗑️
- Individual major commands (`major-specify`, `major-clarify`, `major-plan`, `major-tasks`, `major-implement`)
- Duplicate folders (`agents/`, `skills/` at root level)
- Redundant agents (separate `architect`, `fsd-architect`, `code-reviewer`, etc.)
- `workflow-gates-v2.json` (consolidated into single version)

### Fixed 🐛
- triage.md: Replaced `[Enter]` key input with `AskUserQuestion` tool for Claude Code compatibility
- Registry.json: Clearly marked implemented vs planned architectures
- File structure: Applied single source principle, removed all duplications

### Breaking Changes 💥

#### 🚨 IMPORTANT: v2.4.0 contains significant breaking changes

**Removed Commands** (5 files):
- ❌ `.claude/commands/major-specify.md` → Use `/major` instead
- ❌ `.claude/commands/major-clarify.md` → Use `/major` instead
- ❌ `.claude/commands/major-plan.md` → Use `/major` instead
- ❌ `.claude/commands/major-tasks.md` → Use `/major` instead
- ❌ `.claude/commands/major-implement.md` → Use `/major` instead

**Removed Agents** (8 files):
- ❌ `.claude/agents/architect.md` → Use `architect-unified.md`
- ❌ `.claude/agents/fsd-architect.md` → Merged into `architect-unified.md`
- ❌ `.claude/agents/code-reviewer.md` → Use `reviewer-unified.md`
- ❌ `.claude/agents/security-scanner.md` → Merged into `reviewer-unified.md`
- ❌ `.claude/agents/impact-analyzer.md` → Merged into `reviewer-unified.md`
- ❌ `.claude/agents/quick-fixer.md` → Use `implementer-unified.md`
- ❌ `.claude/agents/test-guardian.md` → Merged into `implementer-unified.md`
- ❌ `.claude/agents/smart-committer.md` → Use `documenter-unified.md`
- ❌ `.claude/agents/changelog-writer.md` → Merged into `documenter-unified.md`

**Agent Mapping** (Old → New):
| Old Agent | New Agent | Notes |
|-----------|-----------|-------|
| `architect` | `architect-unified` | All architecture patterns supported |
| `fsd-architect` | `architect-unified` | FSD logic merged |
| `code-reviewer` | `reviewer-unified` | Security & performance included |
| `security-scanner` | `reviewer-unified` | Merged |
| `impact-analyzer` | `reviewer-unified` | Merged |
| `quick-fixer` | `implementer-unified` | Bug fixes & TDD |
| `test-guardian` | `implementer-unified` | TDD logic merged |
| `smart-committer` | `documenter-unified` | Git operations |
| `changelog-writer` | `documenter-unified` | Notion integration |

**File Structure Changes**:
- ❌ Root level `agents/` folder removed → Use `.claude/agents/`
- ❌ Root level `skills/` folder removed → Use `.claude/skills/`
- ❌ `workflow-gates-v2.json` removed → Use `workflow-gates.json`

**Configuration Changes**:
- `workflow-gates.json` format updated for v2.4.0
- Old v1.0 format is incompatible

## [2.3.0] - 2025-01-07

### Added 🆕
- `/review` command - Comprehensive code review system
- Multi-architecture support (12 patterns)
- Model optimization (Opus/Sonnet/Haiku auto-switching)
- Context7 integration

## [2.0.0] - 2025-01-06

### Added 🆕
- `/triage` command - Automatic workflow selection based on task complexity (75-85% token savings)
- `/commit` command - Smart conventional commits with automatic type detection
- `/pr-review` command - Automated GitHub PR review with security and performance checks
- `smart-committer` agent - Intelligent commit message generation with breaking changes detection
- `commit-guard` skill - Pre-commit validation with 3 levels (Quick, Standard, Full)
- Comprehensive documentation:
  - `SUB-AGENTS-GUIDE.md` - Detailed guide for all sub-agents
  - `SKILLS-GUIDE.md` - Complete skills system documentation
  - `IMPROVEMENT-PROPOSALS.md` - Future enhancement roadmap

### Enhanced ✨
- `code-reviewer` agent - Added GitHub CLI integration for PR operations
- `install.sh` - Updated for new commands and documentation
- README.md - Complete restructure with new features showcase

### Improved 📈
- **Token efficiency**: 60% → up to 85% reduction
- **Development speed**: 2.5x → 3x improvement
- **Quality assurance**: Automated validation at every step

## [1.0.0] - 2024-12-01

### Added
- Major workflow with spec-kit integration
- Minor workflow for bug fixes and improvements
- Micro workflow for quick changes
- 7 Sub-agents:
  - `quick-fixer` - Fast bug fixes
  - `changelog-writer` - Git to Notion documentation
  - `fsd-architect` - FSD architecture validation
  - `test-guardian` - TDD enforcement
  - `api-designer` - API contract design
  - `mobile-specialist` - Capacitor platform handling
  - `code-reviewer` - Security and performance review
- 7 Skills:
  - `bug-fix-pattern` - Common bug fix patterns
  - `daily-changelog-notion` - Notion changelog automation
  - `fsd-component-creation` - FSD component templates
  - `api-integration` - httpClient patterns
  - `form-validation` - React Hook Form + Zod
  - `platform-detection` - Platform-specific rendering
  - `mobile-build` - Android/iOS build automation
- `workflow-gates.json` - Quality gate configuration
- `/start` command for project initialization

### Infrastructure
- `.specify/` directory structure for spec-kit
- `.claude/` directory for workflows
- Installation script for easy setup

## [0.1.0] - 2024-11-01

### Initial Release
- Basic workflow structure
- Proof of concept for sub-agents
- Initial skill system

---

## Upgrade Guide

### 🚀 Automatic Upgrade (v2.5.0+)

The installer now supports automatic version detection and migration:

```bash
# Automatically detects existing version and runs migration
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
```

**What happens automatically**:
1. ✅ Detects existing installation version
2. ✅ Creates backup in `.claude/.backup/install-YYYYMMDD-HHMMSS/`
3. ✅ Runs appropriate migration scripts
4. ✅ Removes deprecated files
5. ✅ Updates configuration files
6. ✅ Preserves user customizations

---

### From v2.4.x to v2.5.0

**Changes**:
- New metrics dashboard system (`/dashboard`)
- New directory structure for metrics tracking
- Enhanced workflow history

**Automatic Migration**:
```bash
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
```

**What gets migrated**:
- ✅ Creates `.claude/cache/metrics/` directory structure
- ✅ Creates `.claude/cache/workflow-history/` directory
- ✅ Initializes metrics system
- ✅ Updates `workflow-gates.json` version to 2.5.0
- ✅ Backs up existing cache

**New features**:
```bash
/dashboard          # View current session metrics
/dashboard --today  # Today's statistics
/dashboard --summary # Full cumulative stats
```

---

### From v1.0.x to v2.5.0

**⚠️ IMPORTANT: v2.4.0+ contains breaking changes**

**Automatic Migration**:
```bash
# The installer will automatically:
# 1. Detect v1.0.x installation
# 2. Run v1→v2.4 migration
# 3. Run v2.4→v2.5 migration
# 4. Remove all deprecated files
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
```

**What gets removed automatically**:

**Commands** (5 files):
- `.claude/commands/major-specify.md` ❌
- `.claude/commands/major-clarify.md` ❌
- `.claude/commands/major-plan.md` ❌
- `.claude/commands/major-tasks.md` ❌
- `.claude/commands/major-implement.md` ❌

**Agents** (8 files):
- `.claude/agents/architect.md` ❌
- `.claude/agents/fsd-architect.md` ❌
- `.claude/agents/code-reviewer.md` ❌
- `.claude/agents/security-scanner.md` ❌
- `.claude/agents/impact-analyzer.md` ❌
- `.claude/agents/quick-fixer.md` ❌
- `.claude/agents/test-guardian.md` ❌
- `.claude/agents/smart-committer.md` ❌

**What gets backed up**:
- `workflow-gates.json` → `.claude/.backup/migration-YYYYMMDD-HHMMSS/`
- `.claude/config/` → `.claude/.backup/migration-YYYYMMDD-HHMMSS/`
- All deprecated files before deletion

**Command Changes**:
| Old Command | New Command | Notes |
|-------------|-------------|-------|
| `/major-specify` + 4 more | `/major` | Single unified command |
| N/A | `/dashboard` | New in v2.5.0 |

**Agent Changes**:
| Old Agent | New Agent | Notes |
|-----------|-----------|-------|
| `architect` | `architect-unified` | All architectures |
| `code-reviewer` | `reviewer-unified` | + security + performance |
| `quick-fixer` | `implementer-unified` | + TDD |
| `smart-committer` | `documenter-unified` | + changelog |

**After upgrade**:
```bash
# Test the new unified command
/major "implement user authentication"

# View metrics
/dashboard

# Continue using other commands as before
/triage
/commit
/review
```

---

### From v2.0.x to v2.5.0

**Changes**: v2.4.0 breaking changes + v2.5.0 metrics system

**Automatic Migration**:
```bash
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
```

Same process as v1.0.x → v2.5.0 upgrade.

---

### Manual Migration (if automatic fails)

If the automatic migration fails, follow these manual steps:

#### Step 1: Backup existing installation
```bash
cp -r .claude .claude.backup.$(date +%Y%m%d)
```

#### Step 2: Remove deprecated files manually
```bash
# Remove old major commands
rm -f .claude/commands/major-specify.md
rm -f .claude/commands/major-clarify.md
rm -f .claude/commands/major-plan.md
rm -f .claude/commands/major-tasks.md
rm -f .claude/commands/major-implement.md

# Remove old agents
rm -f .claude/agents/architect.md
rm -f .claude/agents/fsd-architect.md
rm -f .claude/agents/code-reviewer.md
rm -f .claude/agents/security-scanner.md
rm -f .claude/agents/impact-analyzer.md
rm -f .claude/agents/quick-fixer.md
rm -f .claude/agents/test-guardian.md
rm -f .claude/agents/smart-committer.md
rm -f .claude/agents/changelog-writer.md
```

#### Step 3: Install new version
```bash
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
```

#### Step 4: Verify installation
```bash
/major --help
/dashboard
```

---

### Rollback Procedure

If you need to rollback to a previous version:

#### Find your backup
```bash
ls -la .claude/.backup/
# or
ls -la .claude.backup.*
```

#### Restore from backup
```bash
# For automatic backups
cp -r .claude/.backup/install-YYYYMMDD-HHMMSS/* .claude/

# For manual backups
cp -r .claude.backup.YYYYMMDD/* .claude/
```

#### Reinstall specific version
```bash
# Clone specific version tag
git clone --branch v1.0.0 https://github.com/Liamns/claude-workflows
cd claude-workflows
bash install.sh /path/to/your/project
```

---

### From 0.1.0 to 2.5.0

Complete reinstallation recommended:
```bash
rm -rf .claude .specify
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
/start
```

---

### Troubleshooting

**Issue**: "Migration script not found"
**Solution**: The migration scripts are included in v2.5.0+. If you see this warning during install from older versions, the deprecated files will simply be overwritten rather than cleanly removed. No action needed.

**Issue**: "Deprecated commands still showing up"
**Solution**: Run manual cleanup:
```bash
bash .claude/lib/migrate-v1-to-v2.sh
```

**Issue**: "Old agents still being called"
**Solution**: Check your `.claude/commands/` files for references to old agent names and update them to unified names.

**Issue**: "Lost user customizations"
**Solution**: Restore from backup:
```bash
cp .claude/.backup/install-YYYYMMDD-HHMMSS/config/* .claude/config/
```